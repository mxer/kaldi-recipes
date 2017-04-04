#!/bin/bash
#SBATCH -p coin,short-ivb,short-wsm,short-hsw,batch-hsw,batch-wsm,batch-ivb
#SBATCH -t 2:00:00
#SBATCH -n 1
#SBATCH --cpus-per-task=12
#SBATCH -N 1
#SBATCH --mem-per-cpu=6G
#SBATCH -o log/recognize-%j.out
#SBATCH -e log/recognize-%j.out
#SBATCH -x pe63


export LC_ALL=C

# Begin configuration section.
dataset=data/dev
skip_scoring=false
# End configuration options.

echo "$0 $@"  # Print the command line for logging

[ -f path.sh ] && . ./path.sh # source the path.
. parse_options.sh || exit 1;

if [ $# -lt 2 ]; then
   echo "usage: common/recognize.sh am_model base_lm big_lm"
   echo "e.g.:  common/recognize.sh exp/tri3 data/recog_langs/word_s_20k_2gram data/recog_langs/word_s_20k_5gram"
   echo "main options (for others, see top of script file)"

   exit 1;
fi

. ./cmd.sh ## You'll want to change cmd.sh to something that will work on your system.
           ## This relates to the queue.

am=$1
smalllm=$2


sname=$(basename $smalllm)

sam=$(basename ${am})
mkgraph_flags=""
decode_flags=""
if [ -f ${am}/frame_subsampling_factor ]; then
mkgraph_flags="--self-loop-scale 1.0"
decode_flags="--post-decode-acwt 10.0 --acwt 1.0"
fi
#srun -n1 utils/mkgraph.sh --remove-oov $mkgraph_flags ${smalllm} ${am} ${am}/graph_${sname}

nndir=$(dirname ${am})
suffix=$(echo "$nndir" | grep -o "_.*")

dsname=$(basename $dataset)
dsextra=""
if [ "$dsname" != "dev" ]; then 
dsextra=_$dsname
fi
srun -n1 steps/nnet3/decode.sh --iter 300 --beam 20.0 --lattice-beam 12.0 --skip-scoring $skip_scoring --nj 5 $decode_flags --scoring-opts "--min-lmwt 1" --online-ivector-dir ${am}/ivecs/ivectors_$(basename ${dataset})_hires ${am}/graph_${sname} ${dataset}_hires ${am}/decode300${dsextra}_${sname}
if [ $# -ge 3 ]; then

biglm=$3
bname=$(basename $biglm)
srun -n1 steps/lmrescore_const_arpa.sh --skip-scoring $skip_scoring $smalllm ${biglm} ${dataset}_hires ${am}/decode300${dsextra}_${sname} ${am}/decode300${dsextra}_${sname}_ca_${bname}
fi
