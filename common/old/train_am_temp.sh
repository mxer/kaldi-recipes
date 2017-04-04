#!/bin/bash

echo "$0 $@"  # Print the command line for logging
export LC_ALL=C

min_seg_len=1.55


[ -f path.sh ] && . ./path.sh # source the path.
. parse_options.sh || exit 1;

if [ $# != 0 ]; then
   echo "usage: train_am.sh"
   exit 1;
fi

. ./cmd.sh ## You'll want to change cmd.sh to something that will work on your system.
           ## This relates to the queue.

train_cmd="srun run.pl"
base_cmd=$train_cmd
decode_cmd=$train_cmd

. common/slurm_dep_graph.sh

JOB_PREFIX=$(cat id)_

function error_exit {
    echo "$1" >&2
    exit "${2:-1}"
}

if [ ! -d "data-prep" ]; then
 error_exit "The directory data-prep needs to exist. Run local/data_prep.sh"
fi

set=train_mc_sp
job max2 3 1 val_data_${set}_hires_comb -- utils/data/modify_speaker_info.sh --utts-per-spk-max 2 \
    data/${set}_hires_comb data/${set}_hires_comb_max2



#IVECTOR training
numjobs=10
SLURM_EXTRA_ARGS="-c ${numjobs}"
job ali_tri3_mc 1 4 tra_tri3,utt2dur_train_mc \
 -- steps/align_si.sh  --nj ${numjobs} --cmd "$train_cmd"  data/train_mc data/lang exp/tri3 exp/tri3_ali_mc

mkdir -p exp/ivector/tri5
job train_lda_mllt_iv 4 4 val_data_${set}_hires,ali_tri3_mc \
 -- steps/train_lda_mllt.sh --cmd "$train_cmd" --num-iters 7 --mllt-iters "2 4 6" \
                            --splice-opts "--left-context=3 --right-context=3" \
                            3000 10000 data/train_hires data/lang \
                            exp/tri3_ali_mc exp/ivector/tri5

mkdir -p exp/ivector/diag_ubm
job diag_ubm 4 4 train_lda_mllt_iv,val_data_${set}_hires \
 -- steps/online/nnet2/train_diag_ubm.sh --cmd "$train_cmd" --nj $numjobs \
    --num-frames 700000 \
    --num-threads $numjobs \
    data/${set}_hires 512 \
    exp/ivector/tri5 exp/ivector/diag_ubm

SLURM_EXTRA_ARGS=""
job iv_extractor 8 4 LAST \
  -- steps/online/nnet2/train_ivector_extractor.sh --cmd "run.pl --max-jobs-run $[$numjobs/4]" --num-processes 1 --nj $numjobs \
    data/${set}_hires exp/ivector/diag_ubm exp/ivector/extractor


SLURM_EXTRA_ARGS="-c ${numjobs}"
job iv_train 4 4 iv_extractor,max2 \
 -- steps/online/nnet2/extract_ivectors_online.sh --cmd "$train_cmd" --nj $numjobs \
                                                  data/${set}_hires_comb_max2 exp/ivector/extractor \
                                                  exp/ivector/ivectors_${set}_hires_comb

for set in "dev" "test"; do
  job iv_${set} 4 4 iv_extractor,val_data_$set_hires \
   -- steps/online/nnet2/extract_ivectors_online.sh --cmd "$train_cmd" --nj $numjobs \
                                                  data/${set}_hires exp/ivector/extractor \
                                                  exp/ivector/ivectors_${set}_hires
done
