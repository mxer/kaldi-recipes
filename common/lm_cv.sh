#!/bin/bash
set -e

export LC_ALL=C

# Begin configuration section.
# End configuration options.

echo "$0 $@"  # Print the command line for logging

. common/slurm_dep_graph.sh

[ -f path.sh ] && . ./path.sh # source the path.
. parse_options.sh || exit 1;

if [ $# != 1 ]; then
   echo "usage: common/lm_and_recog.sh segmentation"
   echo "e.g.:  common/lm_and_recog.sh segmentation"
   echo "main options (for others, see top of script file)"
   exit 1;
fi

segdir=$1

name=$(basename $segdir)


# Create LM

. definitions/lm_config

# Train small lm
lm_file=data/lm/${name}_cv_${small_contexts}M/arpa.xz
if [ ! -f $lm_file ] || [ $(stat -c %s ${lm_file}) -le 32 ]; then
  job vk_${small_contexts}M_${name} ${small_mem} 32 NONE -- \
    common/train_varikn_model_limit.sh --init-d ${small_initd} \
                                       ${segdir}/corpus.xz \
                                       ${segdir}/complete_vocab \
                                       ${small_contexts} \
                                       ${small_max_order} \
                                       ${lm_file}
fi


# Train big lm
lm_file=data/lm/${name}_cv_${big_contexts}M/arpa.xz
if [ ! -f $lm_file ] || [ $(stat -c %s ${lm_file}) -le 32 ]; then
  job vk_${big_contexts}M_${name} ${big_mem} 32 NONE -- \
    common/train_varikn_model_limit.sh --init-d ${big_initd} \
                                       ${segdir}/corpus.xz \
                                       ${segdir}/complete_vocab \
                                       ${big_contexts} \
                                       ${big_max_order} \
                                       ${lm_file}
fi

