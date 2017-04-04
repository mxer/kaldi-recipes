#!/bin/bash

echo "$0 $@"  # Print the command line for logging
export LC_ALL=C

min_seg_len=1.55


[ -f path.sh ] && . ./path.sh # source the path.
. parse_options.sh || exit 1;

if [ $# != 2 ]; then
   echo "usage: train_nnet_prep.sh dsuffix alidir"
   exit 1;
fi

. ./cmd.sh ## You'll want to change cmd.sh to something that will work on your system.
           ## This relates to the queue.

dsuf=$1
alidir=$2

. common/slurm_dep_graph.sh

JOB_PREFIX=$(cat id)_

mfccdir=mfcc
numjobs=100

tset=train$dsuf
if [ ! -f data/${tset}/utt2ali ]; then
  paste -d " " <(cut -f1 -d" " data/${tset}/utt2spk) <(cut -f1 -d" " data/${tset}/utt2spk) > data/${tset}/utt2ali
fi

if [ ! -f data/${tset}/utt2uniq ]; then
  paste -d " " <(cut -f1 -d" " data/${tset}/utt2spk) <(cut -f1 -d" " data/${tset}/utt2spk) > data/${tset}/utt2uniq
fi

if [ ! -f data/${tset}/origs ]; then
  cut -f1 -d" " $data/${tset}/utt2spk > data/${tset}/origs
fi
mkdir -p data/${tset}_hires
cp data/${tset}/{utt2ali,utt2uniq} data/${tset}_hires

if [ ! -f data/${tset}/feats.scp ]; then
 job mfcc_$tset 1 4 NONE -- steps/make_mfcc.sh --cmd "$mfcc_cmd" --nj ${numjobs} data/${tset} exp/make_mfcc/${tset} ${mfccdir}
 job cmvn_$tset 1 4 LAST      -- steps/compute_cmvn_stats.sh data/${tset} exp/make_mfcc/${tset} ${mfccdir}
 job fix_data_$tset 4 4 LAST  -- utils/fix_data_dir.sh data/${tset}
fi

job val_data_$tset 1 4 LAST  -- utils/validate_data_dir.sh data/${tset}

for set in "$tset" "dev" "test"; do
 job copy_h_$set 1 4 val_data_$set -- utils/copy_data_dir.sh data/$set data/${set}_hires
 if [ "$set" == "$tset" ]; then
   job perturb_$set 1 4 LAST      -- utils/data/perturb_data_dir_volume.sh data/${set}_hires 
 fi
 job mfcc_hires_$set 1 4 LAST     -- steps/make_mfcc.sh --mfcc-config conf/mfcc_hires.conf --cmd "$mfcc_cmd" --nj ${numjobs} data/${set}_hires
 job cmvn_hires_$set 1 4 LAST     -- steps/compute_cmvn_stats.sh data/${set}_hires
 job fix_hires_$set 4 4 LAST      -- utils/fix_data_dir.sh data/${set}_hires
 job val_data_${set}_hires 1 4 LAST -- utils/validate_data_dir.sh data/${set}_hires
done

for set in "$tset" "${tset}_hires"; do
job comb_segments_${set}_1 3 1 val_data_$set \
 -- utils/data/combine_short_segments.sh --cleanup false data/${set} $min_seg_len data/${set}_comb
job cmvn_comb_$set 3 1 LAST -- steps/compute_cmvn_stats.sh data/${set}_comb
job fix_comb_utt2ali 3 1 LAST -- common/fix_comb_utt2ali.sh data/${set}_comb data/${set}/utt2ali
job fix_comb_$set 3 1 LAST -- utils/fix_data_dir.sh data/${tset}_comb
job val_data_${set}_comb 3 1 LAST -- utils/validate_data_dir.sh --no-wav data/${set}_comb
job max2_${set} 3 1 LAST -- utils/data/modify_speaker_info.sh --utts-per-spk-max 2 data/${set}_comb data/${set}_comb_max2
done

job get_orig_subset 3 1 val_data_${tset}_hires -- utils/data/subset_data_dir.sh --utt-list data/${tset}/origs data/${tset}_hires data/${tset}_orig_hires
job fix_data_orig 3 1 LAST -- utils/fix_data_dir.sh data/${tset}_orig_hires

mkdir -p exp/ivector${dsuf}/in_ali
numjobs=10
job map_ali 4 4 LAST -- common/map_ali.sh $alidir exp/ivector${dsuf}/in_ali data/${tset}_orig_hires $numjobs data/${tset}/utt2ali

SLURM_EXTRA_ARGS="-c ${numjobs}"
mkdir -p exp/ivector${dsuf}/tri5
job train_lda_mllt_iv 4 4 LAST \
 -- steps/train_lda_mllt.sh --cmd "$train_cmd" --num-iters 7 --mllt-iters "2 4 6" \
                            --splice-opts "--left-context=3 --right-context=3" \
                            3000 10000 data/${tset}_orig_hires data/lang \
                            exp/ivector${dsuf}/in_ali exp/ivector${dsuf}/tri5

SLURM_EXTRA_ARGS=""
mkdir -p exp/ivector${dsuf}/diag_ubm
job diag_ubm 4 4 LAST \
 -- steps/online/nnet2/train_diag_ubm.sh --cmd "slurm.pl --mem 4G" --nj $numjobs \
    --num-frames 700000 \
    --num-threads 20 \
    data/${tset}_orig_hires 512 \
    exp/ivector${dsuf}/tri5 exp/ivector${dsuf}/diag_ubm

job iv_extractor 8 24 LAST \
  -- steps/online/nnet2/train_ivector_extractor.sh --cmd "slurm.pl --mem 4G" --nj $numjobs \
    data/${tset}_orig_hires exp/ivector${dsuf}/diag_ubm exp/ivector${dsuf}/extractor

SLURM_EXTRA_ARGS="-c ${numjobs}"
job iv_${tset} 4 4 iv_extractor,max2_${tset} \
 -- steps/online/nnet2/extract_ivectors_online.sh --cmd "$train_cmd" --nj $numjobs \
                                                  data/${tset}_hires_comb_max2 exp/ivector${dsuf}/extractor \
                                                  exp/ivector${dsuf}/ivectors_${tset}_hires_comb
numjobs=5

SLURM_EXTRA_ARGS="-c ${numjobs}"
for set in "dev" "test"; do
  job iv_${set} 4 4 iv_extractor,val_data_${set}_hires \
   -- steps/online/nnet2/extract_ivectors_online.sh --cmd "$train_cmd" --nj $numjobs \
                                                  data/${set}_hires exp/ivector${dsuf}/extractor \
                                                  exp/ivector${dsuf}/ivectors_${set}_hires
done

SLURM_EXTRA_ARGS=""
mkdir -p exp/chain${dsuf}_ali

job subset_ali 1 1 val_data_${tset}_comb -- utils/data/subset_data_dir.sh --utt-list data/${tset}_comb/ali_origs data/${tset}_comb exp/chain${dsuf}_ali/data_orig

job align_data 1 1 subset_ali -- steps/align_fmllr.sh --nj 100 --cmd "slurm.pl --mem 2G" exp/chain${dsuf}_ali/data_orig data/lang $alidir exp/chain${dsuf}_ali/ali_orig
job map_ali2 1 1 LAST -- common/map_ali.sh exp/chain${dsuf}_ali/ali_orig exp/chain${dsuf}_ali/ali data/${tset}_comb 50 data/${tset}_comb/utt2ali
job align_lats 1 1 subset_ali -- steps/align_fmllr_lats.sh --nj 100 --cmd "slurm.pl --mem 2G" exp/chain${dsuf}_ali/data_orig data/lang $alidir exp/chain${dsuf}_ali/lat_orig
job map_lat2 1 1 LAST -- common/map_ali.sh exp/chain${dsuf}_ali/lat_orig exp/chain${dsuf}_ali/lat data/${tset}_comb 50 data/${tset}_comb/utt2ali


