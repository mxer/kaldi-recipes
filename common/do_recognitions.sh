#!/bin/bash

. ./cmd.sh ## You'll want to change cmd.sh to something that will work on your system.
           ## This relates to the queue.

. common/slurm_dep_graph.sh

JOB_PREFIX=$(cat id)_

export LC_ALL=C

for extra in "" "_pr" "_tc" "_pr_tc" "_log_pr" "_log_pr_tc"; do
for s in $(seq 400 400 2000); do
for a in $(seq 1 8); do
 
#job mkgraph_${s}_${a} 20 2 NONE utils/mkgraph.sh --remove-oov --self-loop-scale 1.0 data/recog_langs/morphjoin${extra}_${s}_${a}_5M exp/chain_cleaned/tdnna_sp_bi exp/chain_cleaned/tdnna_sp_bi/graph_morphjoin${extra}_${s}_${a}_5M

job recog_${s}_${s} 4 4 NONE common/recognize_new.sh exp/chain_cleaned/tdnna_sp_bi data/recog_langs/morphjoin${extra}_${s}_${a}_5M data/recog_langs/morphjoin${extra}_${s}_${a}_50M

done
done
done

