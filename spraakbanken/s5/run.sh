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

job prep_lex 30 4 NONE -- spr_local/spr_dp_lex.sh
job prep_corpus 4 24 NONE -- spr_local/spr_dp_corpus.sh
job prep_ngram 4 4 NONE -- spr_local/spr_dp_ngram.sh

job make_corpus_train 4 4 prep_lex,prep_corpus -- spr_local/spr_make_corpus.sh data/train train_clean
job make_corpus_dev 4 4 prep_lex,prep_corpus -- spr_local/spr_make_corpus.sh data/dev dev

job make_lex 4 4 prep_lex,make_corpus_train -- spr_local/spr_make_lex.sh data/dict_train data/train/vocab
job make_lang 4 4 make_lex -- utils/prepare_lang.sh data/dict_train "<UNK>" data/lang_train/local data/lang_train

job make_arpa_20k_2g 4 4 make_lang,prep_ngram -- spr_local/spr_make_arpa.sh --lowercase-text true data/20k_2gram 20 2
job make_arpa_20k_5g 15 4 make_lang,prep_ngram -- spr_local/spr_make_arpa.sh --lowercase-text true data/20k_5gram 20 5
job make_arpa_120k_2g 40 4 make_lang,prep_ngram -- spr_local/spr_make_arpa.sh --lowercase-text true data/120k_2gram 120 2
job make_arpa_120k_5g 40 4 make_lang,prep_ngram -- spr_local/spr_make_arpa.sh --lowercase-text true data/120k_5gram 120 5

mfccdir=mfcc
numjobs=40

for set in "train" "dev"; do
 job mfcc_$set 4 4 make_corpus_$set -- steps/make_mfcc.sh --cmd "${base_cmd} --mem 50M" --nj 20 data/${set} exp/make_mfcc/${set} ${mfccdir}
 job cmvn_$set 4 4 LAST      -- steps/compute_cmvn_stats.sh data/${set} exp/make_mfcc/${set} ${mfccdir}
 job val_data_$set 4 4 LAST  -- utils/validate_data_dir.sh data/${set}
done

job tra_mono0a 2 40 val_data_train,make_lang \
 -- steps/train_mono.sh --boost-silence 1.25 --nj ${numjobs} --cmd "$train_cmd" data/train data/lang_train exp/mono0a
job ali_mono0a 2 40 LAST \
 -- steps/align_si.sh --boost-silence 1.25 --nj ${numjobs} --cmd "$train_cmd" data/train data/lang_train exp/mono0a exp/mono0a_ali

job tra_tri1 2 40 ali_mono0a \
 -- steps/train_deltas.sh --boost-silence 1.25 --cmd "$train_cmd" 2000 10000 data/train data/lang_train exp/mono0a_ali exp/tri1
job ali_tri1 2 40 LAST \
 -- steps/align_si.sh --nj ${numjobs} --cmd "$train_cmd" data/train data/lang_train exp/tri1 exp/tri1_ali


job tra_tri2a 2 40 ali_tri1 \
 -- steps/train_deltas.sh --cmd "$train_cmd" 2500 15000 data/train data/lang_train exp/tri1_ali exp/tri2a
job ali_tri2b 2 40 LAST \
 -- steps/align_si.sh  --nj ${numjobs} --cmd "$train_cmd" --use-graphs true data/train data/lang exp/tri2a exp/tri2a_ali

job tra_tri2b 2 40 ali_tri1 \
 -- steps/train_lda_mllt.sh --cmd "$train_cmd" --splice-opts "--left-context=3 --right-context=3" 2500 15000 data/train data/lang_train exp/tri1_ali exp/tri2b
job ali_tri2b 2 40 LAST \
 -- steps/align_si.sh  --nj ${numjobs} --cmd "$train_cmd" --use-graphs true data/train data/lang_train exp/tri2b exp/tri2b_ali

job mkg_mono0a 26 40 tra_mono0a,make_arpa_20k_2g \
 -- utils/mkgraph.sh --mono data/20k_2gram exp/mono0a exp/mono0a/graph_nst_2g_20k
job dec_mono0a 6 40 LAST \
 -- steps/decode.sh --nj ${numjobs} --cmd "$decode_cmd" exp/mono0a/graph_nst_2g_20k data/dev exp/mono0a/decode_2g_20k_dev

for model in "tri1" "tri2a" "tri2b"; do
    job mkg_${model} 26 40 tra_${model},make_arpa_20k_2g \
     -- utils/mkgraph.sh data/20k_2gram exp/${model} exp/${model}/graph_nst_2g_20k
    job dec_${model} 6 40 LAST \
     -- steps/decode.sh --nj ${numjobs} --cmd "$decode_cmd" exp/${model}/graph_2g_20k data/dev exp/${model}/decode_2g_20k_dev
done
