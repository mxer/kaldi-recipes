#!/bin/bash

. ./cmd.sh
. common/slurm_dep_graph.sh


JOB_PREFIX=$(cat id)_

for size in 1200; do
  for alpha in 1 4; do
    if [ ! -f data/segmentation/morphjoin_${size}_${alpha}/corpus.xz ]; then
      stage=0
      if [ -f data/segmentation/morphjoin_${size}_${alpha}/morfessor.txt ]; then 
        stage=1 
      fi
      job jo_mo_${size}_${alpha} 4 80 NONE -- common/train_joint_morfessor_segmentation.sh --stage $stage --cmd "slurm.pl --mem 4G" ${size} $alpha
    fi
    if [ ! -f data/segmentation/morphjoin_pr_${size}_${alpha}/corpus.xz ]; then
      stage=0
      if [ -f data/segmentation/morphjoin_pr_${size}_${alpha}/morfessor.txt ]; then 
        stage=1 
      fi
      job jo_mo_pr_${size}_${alpha} 4 80 NONE -- common/train_joint_morfessor_segmentation.sh --stage $stage --cmd "slurm.pl --mem 4G" --use-predict-lex true ${size} $alpha
    fi

  done
  
  for alpha in "0.2" "0.5" "1" "2" "4"; do

    if [ ! -f data/segmentation/morphjoin_log_pr_${size}_${alpha}/corpus.xz ]; then
      stage=0
      if [ -f data/segmentation/morphjoin_log_pr_${size}_${alpha}/morfessor.txt ]; then
        stage=1
      fi
      job jo_mo_log_pr_${size}_${alpha} 4 80 NONE -- common/train_joint_morfessor_segmentation.sh --log true --stage $stage --cmd "slurm.pl --mem 4G" --use-predict-lex true ${size} $alpha
    fi

  done
done
