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

extra=_pr_tc
size=1400
alpha=5

for lmsize in "100" "150" "200"; do

    
    mkdir -p data/lm/morphjoin${extra}_${size}_${alpha}/vk/${lmsize}M

    job vk_${size}k_${lmsize}M 95 48 NONE -- common/train_varikn_model_limit.sh --init-d 0.001 data/segmentation/morphjoin${extra}_${size}_${alpha}/corpus.xz data/segmentation/morphjoin${extra}_${size}_${alpha}/vocab ${lmsize} 12 data/lm/morphjoin${extra}_${size}_${alpha}/vk/${lmsize}M/arpa.xz
done

