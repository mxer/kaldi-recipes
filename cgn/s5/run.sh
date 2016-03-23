#!/bin/bash

set -e

. ./cmd.sh ## You'll want to change cmd.sh to something that will work on your system.
           ## This relates to the queue.

JOB_PREFIX=NL

. ../../util/slurm_dep_graph.sh

function error_exit {
    echo "$1" >&2
    exit "${2:-1}"
}

if [ ! -d "corpus" ]; then
 error_exit "The directory corpus needs to exist, with the corpus files (data, corex, doc_{English,Dutch}). This can be a symlinked directory"
fi

if [ ! -d "data-prep" ]; then
 error_exit "The directory data-prep needs to exist. Either do 'mkdir data-prep', or make it a symlink to somewhere"
fi

job lex_prep 4 4 NONE -- local/cgn_lex_prep.sh
job data_prep 4 4 NONE -- local/cgn_data_prep.sh

mfccdir=mfcc
numjobs=40


for set in "train" "dev" "test"; do
 job mfcc_${set} 4 4 data_prep -- steps/make_mfcc.sh --cmd "${train_cmd}" --nj ${numjobs} \
   data/${set} exp/make_mfcc/${set} ${mfccdir} || error_exit "make_mfcc failed";
 job cmvn_${set} 4 4 LAST -- steps/compute_cmvn_stats.sh data/${set} exp/make_mfcc/${set} ${mfccdir} || error_exit "compute cmvn failed";

 job val_dat_${set} 4 4 LAST -- utils/validate_data_dir.sh data/${set} || error_exit "Directory data/${set} was not properly set up"
done

job prep_lang 4 4 lex_prep -- utils/prepare_lang.sh data/dict "<UNK>" data/local/lang data/lang

job tr_mono0a 40 4 prep_lang,val_dat_train -- steps/train_mono.sh --boost-silence 1.25 --nj ${numjobs} --cmd "$train_cmd" data/train data/lang exp/mono0a || error_exit "Train mono failed";
job ali_mono0a 40 4 LAST -- steps/align_si.sh --boost-silence 1.25 --nj ${numjobs} --cmd "$train_cmd" data/train data/lang exp/mono0a exp/mono0a_ali || error_exit "Align mono failed";

job tr_tri1 40 4 LAST -- steps/train_deltas.sh --boost-silence 1.25 --cmd "$train_cmd" 2000 10000 data/train data/lang exp/mono0a_ali exp/tri1 || error_exit "Triphone-delta failed";
job ali_tri1 40 4 LAST -- steps/align_si.sh --nj ${numjobs} --cmd "$train_cmd" data/train data/lang exp/tri1 exp/tri1_ali || error_exit "Align tri failed";

job tr_tri2a 40 4 ali_tri1 -- steps/train_deltas.sh --cmd "$train_cmd" 2500 15000 data/train data/lang exp/tri1_ali exp/tri2a || error_exit "delta-delta training failed";
job tr_tri2b 40 4 ali_tri1 -- steps/train_lda_mllt.sh --cmd "$train_cmd" --splice-opts "--left-context=3 --right-context=3" 2500 15000 data/train data/lang exp/tri1_ali exp/tri2b || error_exit "lda_mllt training failed";
job ali_tri2b 40 4 tr_tri2b -- steps/align_si.sh  --nj ${numjobs} --cmd "$train_cmd" --use-graphs true data/train data/lang exp/tri2b exp/tri2b_ali || "Align tri2b failed";
