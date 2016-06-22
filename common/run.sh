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

job prep_lex 30 4 NONE -- spr_local/spr_dp_lex.sh data-prep/lexicon
job prep_lex_lc 30 4 NONE -- spr_local/spr_dp_lex.sh --lowercase true data-prep/lexicon_lc
job prep_lex_na 30 4 NONE -- spr_local/spr_dp_lex.sh --accents false data-prep/lexicon_na
job prep_lex_lc_na 30 4 NONE -- spr_local/spr_dp_lex.sh --lowercase true --accents false data-prep/lexicon_lc_na

mkdir data
ln -s ../data-prep/lexicon_lc_na data/lexicon
lex_req=prep_lex_lc_na
lowercase=true
accents=false

job prep_corpus 4 24 NONE -- spr_local/spr_dp_corpus.sh
job prep_ngram 4 4 NONE -- spr_local/spr_dp_ngram.sh

job make_corpus_train 4 4 ${lex_req},prep_corpus -- spr_local/spr_make_corpus.sh data/train train_clean
job make_corpus_dev 4 4 ${lex_req},prep_corpus -- spr_local/spr_make_corpus.sh data/dev dev

job make_lex 4 4 ${lex_req},make_corpus_train -- spr_local/spr_make_lex.sh --accents ${accents} data/dict_train data/train/vocab data/lexicon
job make_lang 4 4 make_lex -- utils/prepare_lang.sh data/dict_train "<UNK>" data/lang_train/local data/lang_train

job make_vocab_20k 4 4 prep_ngram,make_lang -- spr_local/spr_make_vocab.sh --lowercase-text ${lowercase} --accents ${accents} data/vocab/20k_lower 20 data/lexicon
job make_vocab_120k 4 4 prep_ngram,make_lang -- spr_local/spr_make_vocab.sh --lowercase-text ${lowercase} --accents ${accents} data/vocab/120k_lower 120 data/lexicon

job make_arpa_20k_2g 2 4 make_vocab_20k -- spr_local/spr_make_arpa.sh --lowercase-text ${lowercase} data/20k_2gram data/vocab/20k_lower 2
job make_arpa_20k_5g 65 4 make_vocab_20k -- spr_local/spr_make_arpa.sh --lowercase-text ${lowercase} data/20k_5gram data/vocab/20k_lower 5
job make_arpa_120k_2g 4 4 make_vocab_120k -- spr_local/spr_make_arpa.sh --lowercase-text ${lowercase} data/120k_2gram data/vocab/120k_lower 2
job make_arpa_120k_5g 60 4 make_vocab_120k -- spr_local/spr_make_arpa.sh --lowercase-text ${lowercase} data/120k_5gram data/vocab/120k_lower 5

mfccdir=mfcc
numjobs=10

for set in "train" "dev"; do
 job mfcc_$set 4 4 make_corpus_$set -- steps/make_mfcc.sh --cmd "${base_cmd} --mem 50M" --nj ${numjobs} data/${set} exp/make_mfcc/${set} ${mfccdir}
 job cmvn_$set 4 4 LAST      -- steps/compute_cmvn_stats.sh data/${set} exp/make_mfcc/${set} ${mfccdir}
 job val_data_$set 4 4 LAST  -- utils/validate_data_dir.sh data/${set}
done

job subset_2kshort 2 4 val_data_train \
 -- utils/subset_data_dir.sh --shortest data/train 2000 data/train_2kshort

job subset_4k 2 4 val_data_train \
 -- utils/subset_data_dir.sh data/train 4000 data/train_4k

job subset_8k 2 4 val_data_train \
 -- utils/subset_data_dir.sh data/train 8000 data/train_8k

job tra_mono0a 2 40 subset_2kshort,make_lang \
 -- steps/train_mono.sh --boost-silence 1.25 --nj ${numjobs} --cmd "$train_cmd" data/train_2kshort data/lang_train exp/mono0a

numjobs=20
job ali_mono0a 2 40 tra_mono0a,subset_4k \
 -- steps/align_si.sh --boost-silence 1.25 --nj ${numjobs} --cmd "$train_cmd" data/train_4k data/lang_train exp/mono0a exp/mono0a_ali

job tra_tri1 2 40 ali_mono0a \
 -- steps/train_deltas.sh --boost-silence 1.25 --cmd "$train_cmd" 2000 10000 data/train_4k data/lang_train exp/mono0a_ali exp/tri1

numjobs=30
job ali_tri1 2 40 tra_tri1,subset_8k \
 -- steps/align_si.sh --nj ${numjobs} --cmd "$train_cmd" data/train_8k data/lang_train exp/tri1 exp/tri1_ali


job tra_tri2a 2 40 ali_tri1 \
 -- steps/train_deltas.sh --cmd "$train_cmd" 2500 15000 data/train_8k data/lang_train exp/tri1_ali exp/tri2a
job tra_tri2b 2 40 ali_tri1 \
 -- steps/train_lda_mllt.sh --cmd "$train_cmd" --splice-opts "--left-context=3 --right-context=3" 2500 15000 data/train_8k data/lang_train exp/tri1_ali exp/tri2b

job ali_tri2b 2 40 tra_tri2b \
 -- steps/align_si.sh  --nj ${numjobs} --cmd "$train_cmd" --use-graphs true data/train_8k data/lang_train exp/tri2b exp/tri2b_ali

job tra_tri3b 2 40 ali_tri2b \
 -- steps/train_sat.sh --cmd "$train_cmd" 2500 15000 data/train_8k data/lang_train exp/tri2b_ali exp/tri3b
job ali_tri3b 2 40 LAST \
 -- steps/align_fmllr.sh  --nj ${numjobs} --cmd "$train_cmd" data/train data/lang_train exp/tri3b exp/tri3b_ali

job tra_tri4a 2 40 ali_tri3b \
 -- steps/train_sat.sh  --cmd "$train_cmd" 4200 40000 data/train data/lang_train exp/tri3b_ali exp/tri4a

job tra_tri4b 2 40 ali_tri3b \
 -- steps/train_quick.sh --cmd "$train_cmd" 4200 40000 data/train data/lang_train exp/tri3b_ali exp/tri4b


#job mkg_mono0a 26 40 tra_mono0a,make_arpa_20k_2g \
# -- utils/mkgraph.sh --mono data/20k_2gram exp/mono0a exp/mono0a/graph_nst_2g_20k
#job dec_mono0a 6 40 LAST \
# -- steps/decode.sh --nj ${numjobs} --cmd "$decode_cmd" exp/mono0a/graph_nst_2g_20k data/dev exp/mono0a/decode_2g_20k_dev
#numjobs=10
#echo "Changing numjobs to ${numjobs}"
#for model in "tri1" "tri2a" "tri2b"; do
#    job mkg_${model} 26 40 tra_${model},make_arpa_20k_2g \
#     -- utils/mkgraph.sh data/20k_2gram exp/${model} exp/${model}/graph_nst_2g_20k
#    job dec_${model} 6 40 LAST \
#     -- steps/decode.sh --nj ${numjobs} --cmd "$decode_cmd" exp/${model}/graph_2g_20k data/dev exp/${model}/decode_2g_20k_dev
#done
#
#for model in "tri3b" "tri4a" "tri4b"; do
#    job mkg_${model} 26 40 tra_${model},make_arpa_20k_2g \
#     -- utils/mkgraph.sh data/20k_2gram exp/${model} exp/${model}/graph_nst_2g_20k
#    job dec_${model} 6 40 LAST \
#     -- steps/decode_fmllr.sh --nj ${numjobs} --cmd "$decode_cmd" exp/${model}/graph_2g_20k data/dev exp/${model}/decode_2g_20k_dev
#done

