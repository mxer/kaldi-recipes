#!/bin/bash

nj=$1
input_suffix=$2
suffix=$3

common/chain/run_tdnn.sh --nj ${nj} --decode-nj ${nj} \
                                                            --train-set train${input_suffix}_mc \
                                                            --gmm tri3${input_suffix} \
                                                            --num-threads-ubm ${nj} \
                                                            --nnet3-affix "${suffix}" \
                                                            --tdnn-affix "a" \
                                                            --tree-affix "a" \
                                                            --stage 14 \
                                                            --train-exit-stage 0
