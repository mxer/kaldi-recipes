#!/bin/bash

export LC_ALL=C
set -euo pipefail

#prep=

xent_regularize=0.1
learning_rate_factor=5
leaky_hmm_coefficient=0.1
l2_regularize=0.00005
apply_deriv_weights=false

num_chunk_per_minibatch=128
initial_lrate=0.001
final_lrate=0.0001
max_param_change=2.0

num_epochs=4
preserve_model_interval=10

shrink_value=1.0

stage=-200

echo "$0 $@"  # Print the command line for logging


[ -f path.sh ] && . ./path.sh # source the path.
. parse_options.sh || exit 1;

if [ $# != 1 ]; then
   echo "usage: train_chain_model.sh config_name"
   exit 1;
fi

config_name=$1

. ./cmd.sh ## You'll want to change cmd.sh to something that will work on your system.
           ## This relates to the queue.

. common/slurm_dep_graph.sh

JOB_PREFIX=$(cat id)_

. definitions/chain/model/$config_name
. exp/chain/prep/$prep/config

dir=exp/chain/model/$config_name
egs=exp/chain/prep/$prep/tdnn/egs

SDG_LOG_DIR=$dir/log

if [ $stage -le 0 ]; then
. $xconfig_template

mkdir -p $dir/configs
cp $xconfig $dir/configs/network.xconfig

steps/nnet3/xconfig_to_configs.py --xconfig-file $dir/configs/network.xconfig --config-dir $dir/configs/

fi

for start_stage in $(seq -200 200 1600); do
if [ $[${start_stage}+200] -le $stage ]; then
continue
fi

real_start=$(($stage<$start_stage?$start_stage:$stage))
if [ $start_stage -lt -1 ]; then
SLURM_EXTRA_ARGS=" -c 6"
else
SLURM_EXTRA_ARGS=" -c 6 -p gpu,gpushort --gres=gpu:teslak80:4"
fi
job chain_${start_stage} 4 4 LAST -- steps/nnet3/chain/train.py \
    --cmd "$decode_cmd" \
    --feat.online-ivector-dir exp/chain/dataprep/$dataprep/ivec/ivectors_train \
    --chain.xent-regularize $xent_regularize \
    --chain.leaky-hmm-coefficient $leaky_hmm_coefficient \
    --chain.l2-regularize $l2_regularize \
    --chain.apply-deriv-weights $apply_deriv_weights \
    --egs.dir "$egs" \
    --egs.opts "--frames-overlap-per-eg $frames_overlap_per_eg" \
    --egs.chunk-width $chunk_width\
    --trainer.num-chunk-per-minibatch $num_chunk_per_minibatch \
    --trainer.frames-per-iter $frames_per_iter \
    --trainer.num-epochs $num_epochs \
    --trainer.optimization.num-jobs-initial 4 \
    --trainer.optimization.num-jobs-final 4 \
    --trainer.optimization.initial-effective-lrate $initial_lrate \
    --trainer.optimization.final-effective-lrate $final_lrate \
    --trainer.optimization.shrink-value $shrink_value \
    --trainer.max-param-change $max_param_change \
    --cleanup.remove-egs false \
    --feat-dir exp/chain/dataprep/$dataprep/data/train_comb \
    --tree-dir exp/chain/prep/$prep/tree \
    --lat-dir exp/chain/dataprep/$dataprep/lats \
    --cleanup.preserve-model-interval $preserve_model_interval \
    --dir $dir --stage $real_start --exit-stage $[${start_stage}+200]
done

exit
