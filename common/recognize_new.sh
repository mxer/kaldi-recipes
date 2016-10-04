#!/bin/bash
#SBATCH -p coin,short-ivb,short-wsm,short-hsw,batch-hsw,batch-wsm,batch-ivb
#SBATCH -t 2:00:00
#SBATCH -n 12
#SBATCH -N 1
#SBATCH --mem-per-cpu=4G

export LC_ALL=C

# Begin configuration section.
dataset=data/dev
# End configuration options.

echo "$0 $@"  # Print the command line for logging

[ -f path.sh ] && . ./path.sh # source the path.
. parse_options.sh || exit 1;

if [ $# -lt 3 ]; then
   echo "usage: common/recognize.sh am_model base_lm big_lm"
   echo "e.g.:  common/recognize.sh exp/tri3 data/recog_langs/word_s_20k_2gram data/recog_langs/word_s_20k_5gram"
   echo "main options (for others, see top of script file)"

   exit 1;
fi

. ./cmd.sh ## You'll want to change cmd.sh to something that will work on your system.
           ## This relates to the queue.

am=$1
smalllm=$2
biglm=$3

sname=$(basename $smalllm)
bname=$(basename $biglm)

sam=$(basename ${am})
srun utils/mkgraph.sh ${smalllm} ${am} ${am}/graph_${sname}

nndir=$(dirname ${am})
suffix=$(echo "$nndir" | grep -o "_.*")
srun steps/nnet3/decode.sh --nj 3  --post-decode-acwt 10.0 --acwt 1.0 --scoring-opts "--min-lmwt 1" --num-threads 4 --online-ivector-dir exp/nnet3${suffix}/ivectors_$(basename ${dataset})_hires ${am}/graph_${sname} ${dataset}_hires ${am}/decode_${sname}
srun steps/lmrescore_const_arpa.sh  $smalllm ${biglm} ${dataset}_hires ${am}/decode_${sname} ${am}/decode_${sname}_ca_${bname}
