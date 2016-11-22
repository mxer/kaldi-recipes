#!/bin/bash

. ./cmd.sh ## You'll want to change cmd.sh to something that will work on your system.
           ## This relates to the queue.

. common/slurm_dep_graph.sh

JOB_PREFIX=$(cat id)_

export LC_ALL=C

for s in $(seq 200 200 2000); do
 
#job mkgraph_${s} 20 2 NONE utils/mkgraph.sh --remove-oov --self-loop-scale 1.0 data/recog_langs/word_vk_${s}k_5M exp/chain_cleaned/tdnna_sp_bi exp/chain_cleaned/tdnna_sp_bi/graph_word_vk_${s}k_5M

job recog_${s} 4 4 NONE common/recognize_new.sh exp/chain_cleaned/tdnna_sp_bi data/recog_langs/word_vk_${s}k_5M data/recog_langs/word_vk_${s}k_50M

done

