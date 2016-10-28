#!/bin/bash

. ./cmd.sh
. common/slurm_dep_graph.sh

for size in $(seq 400 400 2000); do
  for alpha in $(seq 1 4); do
      for d in "ones" "log" "none"; do


    if [ ! -f data/segmentation/morfessor_${d}_${size}_${alpha}/corpus.xz ]; then
      stage=0
      if [ -f data/segmentation/morfessor_${d}_${size}_${alpha}/morfessor.txt ]; then
        stage=1 
      fi
      job morf_${d}_${size}_${alpha} 4 4 NONE -- common/train_basic_morfessor_segmentation.sh --dampening ${d} --stage $stage --cmd "slurm.pl --mem 4G" ${size} $alpha
    fi

    done
  done
done
