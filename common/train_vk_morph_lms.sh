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

max_lm_order=12
#if [ -f definitions/max_lm_order ]; then
#  max_lm_order=$(cat definitions/max_lm_order)
#fi

extra=_pr
for size in $(seq 600 200 800); do
for alpha in $(seq 1 4); do

    mkdir -p data/lm/morphjoin${extra}_${size}_${alpha}/vk/${smallsize}M
    mkdir -p data/lm/morphjoin${extra}_${size}_${alpha}/vk/${bigsize}M

    job vk_${size}k_${smallsize}M 50 24 NONE -- common/train_varikn_model_limit.sh data/segmentation/morphjoin${extra}_${size}_${alpha}/corpus.xz data/segmentation/morphjoin${extra}_${size}_${alpha}/vocab ${smallsize} ${max_lm_order} data/lm/morphjoin${extra}_${size}_${alpha}/vk/${smallsize}M/arpa.xz
    job vk_${size}k_${bigsize}M 50 24 NONE -- common/train_varikn_model_limit.sh data/segmentation/morphjoin${extra}_${size}_${alpha}/corpus.xz data/segmentation/morphjoin${extra}_${size}_${alpha}/vocab ${bigsize} ${max_lm_order} data/lm/morphjoin${extra}_${size}_${alpha}/vk/${bigsize}M/arpa.xz

done
done
