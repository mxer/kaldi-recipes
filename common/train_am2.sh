#!/bin/bash

echo "$0 $@"  # Print the command line for logging

[ -f path.sh ] && . ./path.sh # source the path.
. parse_options.sh || exit 1;

if [ $# != 0 ]; then
   echo "usage: train_am.sh"
   exit 1;
fi

#. ./cmd.sh ## You'll want to change cmd.sh to something that will work on your system.
           ## This relates to the queue.

train_cmd="run.pl"
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

#rm -Rf data mfcc
mkdir data


lex_name="lexicon"
if [ -f definitions/lexicon ]; then
  lex_name=$(cat definitions/lexicon)
fi
ln -s ../data-prep/${lex_name}/ data/lexicon

pdp=true
if [ -f definitions/position_dependent_phones ]; then
  pdp=$(cat definitions/position_dependent_phones)
fi

job make_subset 1 1 NONE -- common/data_subset.sh
job make_lex 1 4 make_subset -- common/make_dict.sh data/train/vocab data/dict
job make_lang 1 4 make_lex -- utils/prepare_lang.sh --position-dependent-phones $pdp data/dict "<UNK>" data/lang/local data/lang
job text_prep 1 24 NONE -- common/text_prep.sh

#ln -s ../data-prep/lexicon_lc_na data/lexicon
#lex_req=prep_lex_lc_na
lowercase=true
accents=false

mfccdir=mfcc
numjobs=50

. definitions/best_model

mkdir -p mfcc
command -v lfs > /dev/null && lfs setstripe -c 6 $mfccdir

for set in "train" "dev" "test"; do
 job mfcc_$set 1 4 make_subset -- steps/make_mfcc.sh --cmd "slurm.pl --mem 500M" --nj ${numjobs} data/${set} exp/make_mfcc/${set} ${mfccdir}
 job cmvn_$set 1 4 LAST      -- steps/compute_cmvn_stats.sh data/${set} exp/make_mfcc/${set} ${mfccdir}
 job val_data_$set 1 4 LAST  -- utils/validate_data_dir.sh data/${set}
 job utt2dur_$set 1 4 LAST   -- utils/data/get_utt2dur.sh data/${set}
done

numjobs=15
job subset_10kshort 1 4 val_data_train \
 -- utils/subset_data_dir.sh --shortest data/train 10000 data/train_10kshort

SLURM_EXTRA_ARGS="-n ${numjobs} -N1"
job tra_mono 1 4 subset_10kshort,make_lang \
 -- steps/train_mono.sh --boost-silence 1.25 --nj ${numjobs} --cmd "$train_cmd" data/train_10kshort data/lang exp/mono

job ali_mono 1 4 tra_mono,val_data_train \
 -- steps/align_si.sh --boost-silence 1.25 --nj ${numjobs} --cmd "$train_cmd" data/train data/lang exp/mono exp/mono_ali

job tra_tri1 1 4 LAST \
 -- steps/train_deltas.sh --boost-silence 1.25 --cmd "$train_cmd" $tri1_leaves $tri1_gauss data/train data/lang exp/mono_ali exp/tri1

job ali_tri1 1 4 LAST \
 -- steps/align_si.sh --nj ${numjobs} --cmd "$train_cmd" data/train data/lang exp/tri1 exp/tri1_ali

job tra_tri2 1 4 LAST \
 -- steps/train_lda_mllt.sh --cmd "$train_cmd" --splice-opts "--left-context=3 --right-context=3" $tri2_leaves $tri2_gauss data/train data/lang exp/tri1_ali exp/tri2

job ali_tri2 1 4 LAST \
 -- steps/align_si.sh  --nj ${numjobs} --cmd "$train_cmd"  data/train data/lang exp/tri2 exp/tri2_ali

job tra_tri3 1 4 LAST \
 -- steps/train_sat.sh --cmd "$train_cmd" $tri3_leaves $tri3_gauss data/train data/lang exp/tri2_ali exp/tri3

SLURM_EXTRA_ARGS=""
job makemc_train 1 4 utt2dur_train -- common/make_multichannel_data.sh data-prep/audio/wav.scp data/train data/train_mc


set=train_mc
job mfcc_train_mc 1 4 makemc_train -- steps/make_mfcc.sh --cmd "slurm.pl --mem 200M" --nj ${numjobs} data/train_mc exp/make_mfcc/train_mc ${mfccdir}


SLURM_EXTRA_ARGS="-n ${numjobs} -N1"
job ivector_orig 2 40 mfcc_train_mc,tra_tri3 -- common/nnet3/run_ivector_common.sh --nj ${numjobs} \
                                                                         --train-set train_mc \
                                                                         --gmm tri3 \
                                                                         --num-threads-ubm ${numjobs} \
                                                                         --nnet3-affix "_orig"

job chain_orig_prep 4 4 ivector_orig -- common/chain/run_tdnn_01.sh ${numjobs} "" _orig

SLURM_EXTRA_ARGS="-n 10 -N1 --gres=gpu:teslak80:4 -p gpu,gpushort"
job chain_orig 4 4 chain_orig_prep -- common/chain/run_tdnn_02.sh ${numjobs} "" _orig

#job tdnn_orig 2 80 ivector_orig -- common/nnet3/run_tdnn.sh --nj ${numjobs} \
#                                                            --decode-nj ${numjobs} \
#                                                            --train-set train_mc \
#                                                            --gmm tri3 \
#                                                            --num-threads-ubm 20 \
#                                                            --nnet3-affix "_orig" \
#                                                            --tdnn-affix "a" \
#                                                            --stage 12

#job chain_orig 2 80 ivector_orig -- common/chain/run_tdnn.sh --nj ${numjobs} \
#                                                            --decode-nj ${numjobs} \
#                                                            --train-set train_mc \
#                                                            --gmm tri3 \
#                                                            --num-threads-ubm 20 \
#                                                            --nnet3-affix "_orig" \
#                                                            --tdnn-affix "a" \
#                                                            --tree-affix "a" \
#                                                            --stage 14



SLURM_EXTRA_ARGS="-n ${numjobs} -N1"
# Create a cleaned version of the model, which is supposed to be better for
job clean 2 40 tra_tri3 \
 -- steps/cleanup/clean_and_segment_data.sh --nj ${numjobs} --cmd "$decode_cmd" data/train data/lang exp/tri3 exp/tri3_cleaned_work data/train_cleaned

job ali_tri3_cleaned 2 40 LAST \
 -- steps/align_fmllr.sh --nj ${numjobs} --cmd "$train_cmd" data/train_cleaned data/lang exp/tri3 exp/tri3_ali_cleaned

job tra_tri3_cleaned 2 40 LAST \
 -- steps/train_sat.sh --cmd "$train_cmd" $tri3_leaves $tri3_gauss data/train_cleaned data/lang exp/tri3_ali_cleaned exp/tri3_cleaned

SLURM_EXTRA_ARGS=""
job makemc_train_cleaned 4 4 clean -- common/make_multichannel_data.sh data-prep/audio/wav.scp data/train_cleaned data/train_cleaned_mc

job mfcc_train_cleaned 4 4 LAST -- steps/make_mfcc.sh --cmd "slurm.pl --mem 200M" --nj ${numjobs} data/train_cleaned_mc exp/make_mfcc/train_cleaned_mc ${mfccdir}


SLURM_EXTRA_ARGS="-n ${numjobs} -N1"
job ivector_cleaned 2 40 tra_tri3_cleaned,mfcc_train_cleaned -- common/nnet3/run_ivector_common.sh --nj ${numjobs} \
                                                                         --train-set train_cleaned_mc \
                                                                         --gmm tri3_cleaned \
                                                                         --num-threads-ubm ${numjobs} \
                                                                         --nnet3-affix "_cleaned" \
                                                                         --orig-train-set train_cleaned

job chain_cleaned_prep 4 4 ivector_cleaned -- common/chain/run_tdnn_01.sh ${numjobs} _cleaned _cleaned

SLURM_EXTRA_ARGS="-n 10 -N1 --gres=gpu:teslak80:4 -p gpu,gpushort"
job chain_cleaned 4 4 chain_cleaned_prep -- common/chain/run_tdnn_02.sh ${numjobs} _cleaned _cleaned


#job tdnn_cleaned 2 80 ivector_cleaned -- common/nnet3/run_tdnn.sh --nj ${numjobs} \
#                                                            --decode-nj ${numjobs} \
#                                                            --train-set train_cleaned_mc \
#                                                            --gmm tri3_cleaned \
#                                                            --num-threads-ubm 20 \
#                                                            --nnet3-affix "_cleaned" \
#                                                            --tdnn-affix "a" \
#                                                            --stage 12

#job chain_cleaned 2 80 ivector_cleaned -- common/chain/run_tdnn.sh --nj ${numjobs} \
#                                                            --decode-nj ${numjobs} \
#                                                            --train-set train_cleaned_mc \
#                                                            --gmm tri3_cleaned \
#                                                            --num-threads-ubm 20 \
#                                                            --nnet3-affix "_cleaned" \
#                                                            --tdnn-affix "a" \
#                                                            --tree-affix "a" \
#                                                            --stage 14
