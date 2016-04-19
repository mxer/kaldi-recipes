#!/bin/bash

. ./cmd.sh ## You'll want to change cmd.sh to something that will work on your system.
           ## This relates to the queue.

. ../../../util/slurm_dep_graph.sh

JOB_PREFIX=$(basename $(pwd))

function error_exit {
    echo "$1" >&2
    exit "${2:-1}"
}

if [ ! -d "corpus" ]; then
 error_exit "The directory corpus needs to exist, with the corpus files from nb.no downloaded in it. This can be a symlinked directory"
fi

if [ ! -d "data-prep" ]; then
 error_exit "The directory data-prep needs to exist. Either do 'mkdir data-prep', or make it a symlink to somewhere"
fi


job make_corpus_train 4 4 NONE -- spr_local/spr_make_corpus.sh data/train train_digits
job make_corpus_test 4 4 NONE -- spr_local/spr_make_corpus.sh data/test test_digits

job make_lex 4 4 make_corpus_train -- spr_local/spr_make_lex.sh --accents false data/dict_train data/train/vocab data-prep/lexicon_lc_na
job make_lang 4 4 make_lex -- utils/prepare_lang.sh data/dict_train "<UNK>" data/lang_train/local data/lang_train

mfccdir=mfcc
numjobs=10

for set in "train" "test"; do
 job mfcc_$set 4 4 make_corpus_$set -- steps/make_mfcc.sh --cmd "${base_cmd} --mem 50M" --nj ${numjobs} data/${set} exp/make_mfcc/${set} ${mfccdir}
 job cmvn_$set 4 4 LAST      -- steps/compute_cmvn_stats.sh data/${set} exp/make_mfcc/${set} ${mfccdir}
 job val_data_$set 4 4 LAST  -- utils/validate_data_dir.sh data/${set}
done

job tra_mono0a 2 40 val_data_train,make_lang \
 -- steps/train_mono.sh --boost-silence 1.25 --nj ${numjobs} --cmd "$train_cmd" data/train data/lang_train exp/mono0a
job ali_mono0a 2 40 LAST \
 -- steps/align_si.sh --boost-silence 1.25 --nj ${numjobs} --cmd "$train_cmd" data/train data/lang_train exp/mono0a exp/mono0a_ali

job tra_tri1 2 40 ali_mono0a \
 -- steps/train_deltas.sh --boost-silence 1.25 --cmd "$train_cmd" 300 3000 data/train data/lang_train exp/mono0a_ali exp/tri1
job ali_tri1 2 40 LAST \
 -- steps/align_si.sh --nj ${numjobs} --cmd "$train_cmd" data/train data/lang_train exp/tri1 exp/tri1_ali



