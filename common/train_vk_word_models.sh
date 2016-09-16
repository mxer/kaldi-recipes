#!/bin/bash
set -e

echo "$0 $@"  # Print the command line for logging

[ -f path.sh ] && . ./path.sh # source the path.
. parse_options.sh || exit 1;

if [ $# != 0 ]; then
   echo "usage: train_word_models.sh"
   exit 1;
fi

. ./cmd.sh ## You'll want to change cmd.sh to something that will work on your system.
           ## This relates to the queue.

. common/slurm_dep_graph.sh

JOB_PREFIX=$(cat id)_

mkdir -p data/segmentation/word
job make_word_segm 4 4 NONE -- common/preprocess_corpus.py data-prep/text/text.orig.xz data/segmentation/word/corpus.xz

smallsize=5
bigsize=50

max_lm_order=0
if [ -f definitions/max_lm_order ]; then
  max_lm_order=$(cat definitions/max_lm_order)
fi

for size in $(seq 200 200 2000); do
    if [ -e data/dicts/word_${size}k ]; then rm -Rf data/dicts/word_${size}k; fi
    if [ -e data/langs/word_${size}k ]; then rm -Rf data/langs/word_${size}k; fi
    mkdir -p data/dicts/word_${size}k
    mkdir -p data/langs/word_${size}k
    job make_vocab_${size}k 4 4 make_word_segm -- common/count_words.py --lexicon=data/lexicon/lexicon.txt --nmost=${size}000 data/segmentation/word/corpus.xz data/dicts/word_${size}k/vocab
    job make_lex_${size}k 4 4 make_vocab_${size}k -- common/make_dict.sh data/dicts/word_${size}k/vocab data/dicts/word_${size}k
    job make_lang_${size}k 4 4 make_lex_${size}k -- utils/prepare_lang.sh --phone-symbol-table data/lang/phones.txt data/dicts/word_${size}k "<UNK>" data/langs/word_${size}k/local data/langs/word_${size}k


    mkdir -p data/lm/word/vk/${size}k_${smallsize}M
    mkdir -p data/lm/word/vk/${size}k_${bigsize}M

    job vk_${size}k_${smallsize}M 50 24 make_vocab_${size}k -- common/train_varikn_model_limit.sh data/segmentation/word/corpus.xz data/dicts/word_${size}k/vocab ${smallsize} ${max_lm_order} data/lm/word/vk/${size}k_${smallsize}M/arpa.xz
    job recog_lang_${size}k_${smallsize}M 25 1 vk_${size}k_${smallsize}M,make_lang_${size}k -- common/make_recog_lang.sh data/lm/word/vk/${size}k_${smallsize}M/arpa.xz data/langs/word_${size}k data/recog_langs/word_v_${size}k_${smallsize}M

    job vk_${size}k_${bigsize}M 50 24 make_vocab_${size}k -- common/train_varikn_model_limit.sh data/segmentation/word/corpus.xz data/dicts/word_${size}k/vocab ${bigsize} ${max_lm_order} data/lm/word/vk/${size}k_${bigsize}M/arpa.xz
    job recog_lang_${size}k_${bigsize}M 25 1 vk_${size}k_${bigsize}M,make_lang_${size}k -- common/make_recog_lang.sh data/lm/word/vk/${size}k_${bigsize}M/arpa.xz data/langs/word_${size}k data/recog_langs/word_v_${size}k_${bigsize}M
done
