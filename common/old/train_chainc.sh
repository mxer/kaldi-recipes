#!/bin/bash

export LC_ALL=C
set -e -o pipefail


echo "$0 $@"  # Print the command line for logging


[ -f path.sh ] && . ./path.sh # source the path.
. parse_options.sh || exit 1;

if [ $# != 2 ]; then
   echo "usage: train_chain.sh data-suffix lang-suffix"
   exit 1;
fi

dsuf=$1
lsuf=$2

. ./cmd.sh ## You'll want to change cmd.sh to something that will work on your system.
           ## This relates to the queue.

. common/slurm_dep_graph.sh

JOB_PREFIX=$(cat id)_


if [ ! -d data/lang_chain${lsuf} ]; then
cp -r data/lang${lsuf} data/lang_chain${lsuf}

steps/nnet3/chain/gen_topo.py $(cat data/lang_chain${lsuf}/phones/silence.csl) \
                              $(cat data/lang_chain${lsuf}/phones/nonsilence.csl) \
                               > data/lang_chain${lsuf}/topo
fi



gmm_dir=exp/tri3${dsuf}${lsuf}
ali_dir=exp/tri3${dsuf}${lsuf}_ali_train${dsuf}_mc_sp_comb
tree_dir=exp/chain${dsuf}/tree${lsuf}c
lat_dir=exp/chain${dsuf}/tri3${dsuf}${lsuf}_train${dsuf}_mc_sp_comb
dir=exp/chain${dsuf}/tdnn${lsuf}c
train_data_dir=data/train${dsuf}_mc_sp_hires_comb
lores_train_data_dir=data/train${dsuf}_mc_sp_comb
train_ivector_dir=exp/ivector/ivectors_train${dsuf}_mc_sp_hires_comb

#job align_data 1 1 NONE -- steps/align_fmllr.sh --nj 100 --cmd "$mfcc_cmd" $lores_train_data_dir data/lang${lsuf} $gmm_dir $ali_dir
#job align_lats 1 1 LAST -- steps/align_fmllr_lats.sh --nj 100 --cmd "slurm.pl --mem 2G" ${lores_train_data_dir} data/lang${lsuf} $gmm_dir $lat_dir

SLURM_EXTRA_ARGS="-c 10"
job build_tree 1 1 align_data -- steps/nnet3/chain/build_tree.sh --frame-subsampling-factor 3 \
      --context-opts "--context-width=2 --central-position=1" \
      --leftmost-questions-truncate -1 \
      --cmd "$train_cmd" 4000 ${lores_train_data_dir} data/lang_chain${lsuf} $ali_dir $tree_dir

SLURM_EXTRA_ARGS=""
job make_configs 1 1 build_tree steps/nnet3/tdnn/make_configs.py \
    --self-repair-scale-nonlinearity 0.00001 \
    --feat-dir ${train_data_dir} \
    --ivector-dir $train_ivector_dir \
    --tree-dir $tree_dir \
    --relu-dim 450 \
    --splice-indexes "-1,0,1 -1,0,1,2 -3,0,3 -3,0,3 -3,0,3 -6,-3,0 0" \
    --use-presoftmax-prior-scale false \
    --xent-regularize 0.1 \
    --xent-separate-forward-affine true \
    --include-log-softmax false \
    --final-layer-normalize-target 1.0 \
   $dir/configs

SLURM_EXTRA_ARGS="-c 10"

job chain_pre 2 1 make_configs,align_lats -- steps/nnet3/chain/train.py \
    --cmd "slurm.pl --mem 4G" \
    --feat.online-ivector-dir $train_ivector_dir \
    --feat.cmvn-opts "--norm-means=false --norm-vars=false" \
    --chain.xent-regularize 0.1 \
    --chain.leaky-hmm-coefficient 0.1 \
    --chain.l2-regularize 0.00005 \
    --chain.apply-deriv-weights false \
    --chain.lm-opts="--num-extra-lm-states=2000" \
    --egs.dir "$common_egs_dir" \
    --egs.opts "--frames-overlap-per-eg 0" \
    --egs.chunk-width 150 \
    --trainer.num-chunk-per-minibatch 64 \
    --trainer.frames-per-iter 1500000 \
    --trainer.num-epochs 4 \
    --trainer.optimization.num-jobs-initial 8 \
    --trainer.optimization.num-jobs-final 8 \
    --trainer.optimization.initial-effective-lrate 0.001 \
    --trainer.optimization.final-effective-lrate 0.0001 \
    --trainer.max-param-change 2.0 \
    --cleanup.remove-egs true \
    --feat-dir $train_data_dir \
    --tree-dir $tree_dir \
    --lat-dir $lat_dir \
    --dir $dir \
    --stage -100 \
    --exit-stage 0

for start_stage in $(seq 0 200 1000); do
SLURM_EXTRA_ARGS="-c 12 -p gpu,gpushort --gres=gpu:teslak80:8"
job chain_${start_stage} 2 4 LAST -- steps/nnet3/chain/train.py \
    --cmd "$decode_cmd" \
    --feat.online-ivector-dir $train_ivector_dir \
    --feat.cmvn-opts "--norm-means=false --norm-vars=false" \
    --chain.xent-regularize 0.1 \
    --chain.leaky-hmm-coefficient 0.1 \
    --chain.l2-regularize 0.00005 \
    --chain.apply-deriv-weights false \
    --chain.lm-opts="--num-extra-lm-states=2000" \
    --egs.dir "$common_egs_dir" \
    --egs.opts "--frames-overlap-per-eg 0" \
    --egs.chunk-width 150 \
    --trainer.num-chunk-per-minibatch 64 \
    --trainer.frames-per-iter 1500000 \
    --trainer.num-epochs 8 \
    --trainer.optimization.num-jobs-initial 8 \
    --trainer.optimization.num-jobs-final 8 \
    --trainer.optimization.initial-effective-lrate 0.001 \
    --trainer.optimization.final-effective-lrate 0.0001 \
    --trainer.max-param-change 2.0 \
    --cleanup.remove-egs true \
    --feat-dir $train_data_dir \
    --tree-dir $tree_dir \
    --lat-dir $lat_dir \
    --dir $dir --stage $start_stage --exit-stage $[${start_stage}+200]
done
