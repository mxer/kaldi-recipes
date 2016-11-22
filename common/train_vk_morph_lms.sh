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

d5M=0.01
if [ -f definitions/5M_lm_d ]; then
  d5M=$(cat definitions/5M_lm_d)
fi

d50M=0.001
if [ -f definitions/50M_lm_d ]; then
  d50M=$(cat definitions/50M_lm_d)
fi


for extra in "_log_pr" "_log_pr_tc" "" "_pr" "_tc" "_pr_tc"; do
for size in $(seq 400 400 2000); do
for alpha in "0.2" "0.5" $(seq 1 8); do
    if [ ! -f data/segmentation/morphjoin${extra}_${size}_${alpha}/corpus.xz ]; then
        continue
    fi

    mkdir -p data/lm/morphjoin${extra}_${size}_${alpha}/vk/${smallsize}M
    mkdir -p data/lm/morphjoin${extra}_${size}_${alpha}/vk/${bigsize}M

    if [ ! -f data/lm/morphjoin${extra}_${size}_${alpha}/vk/${smallsize}M/arpa.xz ]; then
    job vk_${size}k_${smallsize}M 25 18 NONE -- common/train_varikn_model_limit.sh --init-d $d5M data/segmentation/morphjoin${extra}_${size}_${alpha}/corpus.xz data/segmentation/morphjoin${extra}_${size}_${alpha}/vocab ${smallsize} ${max_lm_order} data/lm/morphjoin${extra}_${size}_${alpha}/vk/${smallsize}M/arpa.xz
    fi

    if [ ! -f data/lm/morphjoin${extra}_${size}_${alpha}/vk/${bigsize}M/arpa.xz ]; then
    job vk_${size}k_${bigsize}M 35 48 NONE -- common/train_varikn_model_limit.sh --init-d $d50M data/segmentation/morphjoin${extra}_${size}_${alpha}/corpus.xz data/segmentation/morphjoin${extra}_${size}_${alpha}/vocab ${bigsize} ${max_lm_order} data/lm/morphjoin${extra}_${size}_${alpha}/vk/${bigsize}M/arpa.xz
    fi

done
done
done
