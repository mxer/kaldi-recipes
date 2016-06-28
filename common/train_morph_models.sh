#!/bin/bash

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

mkdir -p data/segmentation/morph1
job train_morfessor 10 10 NONE -- train_morfessor_model.sh data-prep/text/text.orig.xz 300000 data/segmentation/morph1/morfessor.bin data/segmentation/morph1/vocab
job morfessor_segment 4 4 train_morfessor -- morfessor_segment.sh data-prep/text/text.orig.xz data/segmentation/morph1/morfessor.bin data/segmentation/morph1/corpus.xz

for d in "0.05" "0.02" "0.01"; do

    for order in "3" "5" "30"; do
        mkdir -p data/lm/morph1/vk/${d}_${order}g
        job vari_${d}_${order}g 60 24 morfessor_segment -- common/train_varikn_model.sh data/segmentation/morph1/corpus.xz data/segmentation/morph1/vocab ${d} ${order} data/lm/morph1/vk/${d}_${order}g/arpa.xz
    done
done
