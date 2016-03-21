#!/bin/bash

. ./cmd.sh ## You'll want to change cmd.sh to something that will work on your system.
           ## This relates to the queue.

function error_exit {
    echo "$1" >&2
    exit "${2:-1}"
}


if [ ! -d "corpus" ]; then
 exit "The directory corpus needs to exist, with the corpus files from nb.no downloaded in it. This can be a symlinked directory" 
fi

if [ ! -d "data-prep" ]; then
 exit "The directory data-prep needs to exist. Either do 'mkdir data-prep', or make it a symlink to somewhere"
fi

spr_local/spr_lex_prep.sh || error_exit "Could not prep lexicon";

spr_local/spr_g2p_train.sh --cmd "slurm.pl --mem 30G" data/dict_nst/lexicon.txt data/g2p &

spr_local/spr_data_prep.sh || error_exit "Could not prep corpus";

mfccdir=mfcc

for set in "train" "test"; do
 steps/make_mfcc.sh --cmd "${train_cmd}" --nj 20 \
   data/${set} exp/make_mfcc/${set} ${mfccdir} || error_exit "make_mfcc failed";
 steps/compute_cmvn_stats.sh data/${set} exp/make_mfcc/${set} ${mfccdir} || error_exit "compute cmvn failed";

 utils/validate_data_dir.sh data/${set} || error_exit "Directory data/${set} was not properly set up"
done

wait

spr_local/spr_lang_prep.sh || error_exit "Could not prep lang directory";

steps/train_mono.sh --boost-silence 1.25 --nj 10 --cmd "$train_cmd" data/train data/lang exp/mono0a || error_exit "Train mono failed";
steps/align_si.sh --boost-silence 1.25 --nj 10 --cmd "$train_cmd" data/train data/lang exp/mono0a exp/mono0a_ali || error_exit "Align mono failed";

steps/train_deltas.sh --boost-silence 1.25 --cmd "$train_cmd" 2000 10000 data/train data/lang exp/mono0a_ali exp/tri1 || error_exit "Triphone-delta failed";
steps/align_si.sh --nj 10 --cmd "$train_cmd" data/train data/lang exp/tri1 exp/tri1_ali || error_exit "Align tri failed";

steps/train_deltas.sh --cmd "$train_cmd" 2500 15000 data/train data/lang exp/tri1_ali exp/tri2a || error_exit "delta-delta training failed";
steps/train_lda_mllt.sh --cmd "$train_cmd" --splice-opts "--left-context=3 --right-context=3" 2500 15000 data/train data/lang exp/tri1_ali exp/tri2b || error_exit "lda_mllt training failed";
steps/align_si.sh  --nj 10 --cmd "$train_cmd" --use-graphs true data/train data/lang exp/tri2b exp/tri2b_ali || "Align tri2b failed";
