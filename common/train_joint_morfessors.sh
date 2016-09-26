#!/bin/bash

. ./cmd.sh
. common/slurm_dep_graph.sh

for size in $(seq 1000 200 2000); do
  for alpha in $(seq 1 4); do
    job jo_mo_${size}_${alpha} 4 80 NONE -- common/train_joint_morfessor_segmentation.sh --cmd "slurm.pl --mem 4G" ${size} $alpha
#    job jo_mo_pr_${size}_${alpha} 4 80 NONE -- common/train_joint_morfessor_segmentation.sh --cmd "slurm.pl --mem 4G" --use-predict-lex true ${size} $alpha
  done
done
