#!/bin/bash
set -e

export LC_ALL=C

# Begin configuration section.
recog_data=data/dev
model=exp/chain_cleaned/tdnna_sp_bi
# End configuration options.

echo "$0 $@"  # Print the command line for logging

. common/slurm_dep_graph.sh

[ -f path.sh ] && . ./path.sh # source the path.
. parse_options.sh || exit 1;

if [ $# != 2 ]; then
   echo "usage: common/lm_and_recog.sh langdir segmentation"
   echo "e.g.:  common/lm_and_recog.sh langdir segmentation"
   echo "main options (for others, see top of script file)"
   exit 1;
fi

langdir=$1
segdir=$2

name=$(basename $langdir)


# Create LM

. definitions/lm_config

# Train small lm
lm_file=data/lm/${name}_${small_contexts}M/arpa.xz
if [ ! -f $lm_file ] || [ $(stat -c %s ${lm_file}) -le 32 ]; then
  job vk_${small_contexts}M_${name} ${small_mem} 32 NONE -- \
    common/train_varikn_model_limit.sh --init-d ${small_initd} \
                                       ${segdir}/corpus.xz \
                                       ${langdir}/words.txt \
                                       ${small_contexts} \
                                       ${small_max_order} \
                                       ${lm_file}
fi

#and a small recoglang
rl_dir_small=data/recog_langs/${name}_${small_contexts}M
fst_file=${rl_dir_small}/G.fst

if [ ! -f $fst_file ] || [ $(stat -c %s ${fst_file}) -le 32 ] || [ $fst_file -ot $lm_file ]; then
  job rl_${small_contexts}M_${name} ${small_mem} 2 vk_${small_contexts}M_${name} -- \
    common/make_recog_lang.sh ${lm_file} ${langdir} ${rl_dir_small}
fi


# Train big lm
lm_file=data/lm/${name}_${big_contexts}M/arpa.xz
if [ ! -f $lm_file ] || [ $(stat -c %s ${lm_file}) -le 32 ]; then
  job vk_${big_contexts}M_${name} ${big_mem} 32 NONE -- \
    common/train_varikn_model_limit.sh --init-d ${big_initd} \
                                       ${segdir}/corpus.xz \
                                       ${langdir}/words.txt \
                                       ${big_contexts} \
                                       ${big_max_order} \
                                       ${lm_file}
fi

#and a big recoglang
rl_dir_big=data/recog_langs/${name}_${big_contexts}M
fst_file=${rl_dir_big}/G.fst

if [ ! -f $fst_file ] || [ $(stat -c %s ${fst_file}) -le 32 ] || [ $fst_file -ot $lm_file ]; then
  job rl_${big_contexts}M_${name} ${small_mem} 2 vk_${big_contexts}M_${name} -- \
    common/make_recog_lang.sh ${lm_file} ${langdir} ${rl_dir_big}
fi

#and carpa
carpa_file=${rl_dir_big}/G.carpa
if [ ! -f $carpa_file ] || [ $(stat -c %s ${carpa_file}) -le 32 ] || [ $carpa_file -ot $lm_file ]; then
  job ca_${big_contexts}M_${name} ${small_mem} 2 rl_${big_contexts}M_${name} -- \
    common/build_const_arpa_lm.sh ${lm_file} ${rl_dir_big}
fi


#Make graph
graph_dir=${model}/graph_${name}_${small_contexts}M
graph_file=${graph_dir}/HCLG.fst

mkgraph_flags=""
if [ -f ${model}/frame_subsampling_factor ]; then
  mkgraph_flags="--self-loop-scale 1.0"
fi

if [ ! -f $graph_file ] || [ $(stat -c %s ${graph_file}) -le 32 ] || [ $graph_file -ot $rl_dir_small/G.fst ]; then
  job mk_${name} 70 8 rl_${small_contexts}M_${name} -- \
    utils/mkgraph.sh --remove-oov $mkgraph_flags ${rl_dir_small} ${model} ${graph_dir}
fi

#Do recognition
dec_dir=${model}/decode_${name}_${small_contexts}M
dec_ca_dir=${model}/decode_${name}_${small_contexts}M_ca_${big_contexts}M

if [ ! -f $dec_dir/lat.1.gz ] || [ $dec_dir/lat.1.gz -ot $graph_file ]; then
  job dec_${name} 6 3 mk_${name},ca_${big_contexts}M_${name} -- \
    common/recognize_new.sh $model $rl_dir_small $rl_dir_big
fi
