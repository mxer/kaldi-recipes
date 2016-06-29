#!/bin/bash

export LC_ALL=C

# Begin configuration section.
dataset=data/dev
# End configuration options.

echo "$0 $@"  # Print the command line for logging

[ -f path.sh ] && . ./path.sh # source the path.
. parse_options.sh || exit 1;

if [ $# != 3 ]; then
   echo "usage: common/recognize.sh am_models base_lm big_lm"
   echo "e.g.:  common/recognize.sh tri2b,tri4a data/recog_langs/word_s_20k_2gram data/recog_langs/word_s_20k_5gram"
   echo "main options (for others, see top of script file)"

   exit 1;
fi

. ./cmd.sh ## You'll want to change cmd.sh to something that will work on your system.
           ## This relates to the queue.

. common/slurm_dep_graph.sh

JOB_PREFIX=$(cat id)_

ammodels=$1
smalllm=$2
biglm=$3

sname=$(basename $smalllm)
bname=$(basename $biglm)

prev=NONE
IFS=,

ams=(${ammodels})

nj=$(cat ${dataset}/spk2utt | wc -l)

for am in "${ams[@]}"; do
  case $am in
  mono*)
    echo job ${am} 26 40 $prev -- utils/mkgraph.sh --mono ${smalllm} exp/${am} exp/${am}/graph_${sname}
    ;;
  tri*)
    echo job ${am} 26 40 $prev -- utils/mkgraph.sh ${smalllm} exp/${am} exp/${am}/graph_${sname}
    ;;
  esac

  case $am in
  mono*|tri[1-2]*)
    echo job dec_bl_${am} 6 40 LAST -- steps/decode_biglm.sh --nj ${nj} --cmd "$decode_cmd" exp/${am}/graph_${sname} $smalllm/G.fst ${biglm}/G.fst ${dataset} exp/${am}/decode_${sname}_bl_${bname}
    ;;
  tri[3-4]*)
    echo job dec_${am} 6 40 LAST -- steps/decode_fmllr.sh --nj ${nj} --cmd "$decode_cmd" --max-fmllr-jobs ${nj} exp/${am}/graph_${sname} ${dataset} exp/${am}/decode_${sname}
    echo job dec_rs_${am} 6 40 dec_${am} -- steps/lmrescore.sh --cmd "$decode_cmd" $smalllm ${biglm} ${dataset} exp/${am}/decode_${sname} exp/${am}/decode_${sname}_rs_${bname}
    ;;
  esac

  prev=$am
done
