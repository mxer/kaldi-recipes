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

smallsize=5
bigsize=50

max_lm_order=0
if [ -f definitions/max_morph_lm_order ]; then
  max_lm_order=$(cat definitions/max_lm_order)
fi

for damp in "none" "log" "ones"; do
for size in $(seq 400 400 2000); do
for alpha in $(seq 1 4); do
    if [ ! -f data/segmentation/morfessor_${damp}_${size}_${alpha}/corpus.xz ]; then
        continue
    fi

    mkdir -p data/lm/morfessor_${damp}_${size}_${alpha}/vk/${smallsize}M
    mkdir -p data/lm/morfessor_${damp}_${size}_${alpha}/vk/${bigsize}M

    if [ ! -f data/lm/morfessor_${damp}_${size}_${alpha}/vk/${smallsize}M/arpa.xz ]; then
    job vk_${size}k_${smallsize}M 25 18 NONE -- common/train_varikn_model_limit.sh --init-d 0.05 data/segmentation/morfessor_${damp}_${size}_${alpha}/corpus.xz data/segmentation/morfessor_${damp}_${size}_${alpha}/vocab ${smallsize} ${max_lm_order} data/lm/morfessor_${damp}_${size}_${alpha}/vk/${smallsize}M/arpa.xz
    fi

    if [ ! -f data/lm/morfessor_${damp}_${size}_${alpha}/vk/${bigsize}M/arpa.xz ]; then
    job vk_${size}k_${bigsize}M 35 48 NONE -- common/train_varikn_model_limit.sh --init-d 0.005 data/segmentation/morfessor_${damp}_${size}_${alpha}/corpus.xz data/segmentation/morfessor_${damp}_${size}_${alpha}/vocab ${bigsize} ${max_lm_order} data/lm/morfessor_${damp}_${size}_${alpha}/vk/${bigsize}M/arpa.xz
    fi

done
done
done
