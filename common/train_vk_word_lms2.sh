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

#mkdir -p data/segmentation/word
#job make_word_segm 4 4 NONE -- common/preprocess_corpus.py data-prep/text/text.orig.xz data/segmentation/word/corpus.xz


max_lm_order=0
if [ -f definitions/max_lm_order ]; then
  max_lm_order=$(cat definitions/max_lm_order)
fi

size=2000
for lmsize in "100" "150" "200"; do




    mkdir -p data/lm/word/vk/${size}k_${lmsize}M

    job vk_${size}k_${lmsize}M 95 48 NONE -- common/train_varikn_model_limit.sh --init-d 0.001 data/segmentation/word/corpus.xz data/dicts/word_${size}k/vocab ${lmsize} ${max_lm_order} data/lm/word/vk/${size}k_${lmsize}M/arpa.xz
done
