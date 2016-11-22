#!/bin/bash

. ./cmd.sh
. common/slurm_dep_graph.sh
JOB_PREFIX=$(cat id)_

for extra in "" "_pr" "_log_pr"; do
  for size in "1200"; do
    for alpha in "0.2" "1" "2" "4"; do
      if [ -f data/segmentation/morphjoin${extra}_${size}_${alpha}/corpus.xz ]; then
        if [ ! -f data/segmentation/morphjoin${extra}_tc_${size}_${alpha}/corpus.xz ]; then
          job tc_mo_${size}_${alpha}${extra} 4 6 NONE -- common/make_tagged_morph.sh --cmd "slurm.pl --mem 4G" data/segmentation/morphjoin${extra}_${size}_${alpha} data/segmentation/morphjoin${extra}_tc_${size}_${alpha} data/dicts/morphjoin${extra}_tc_${size}_${alpha}
        fi 
      fi
    done
  done
done

