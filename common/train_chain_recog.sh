#!/bin/bash
#SBATCH -p coin,short-ivb,short-wsm,short-hsw,batch-hsw,batch-wsm,batch-ivb
#SBATCH -t 2:00:00
#SBATCH -n 1
#SBATCH --cpus-per-task=9
#SBATCH -N 1
#SBATCH --mem-per-cpu=6G
#SBATCH -o log/recognize-%j.out
#SBATCH -e log/recognize-%j.out
#SBATCH -x pe63


export LC_ALL=C

# Begin configuration section.
dataset=dev
skip_scoring=false
# End configuration options.

echo "$0 $@"  # Print the command line for logging

[ -f path.sh ] && . ./path.sh # source the path.
. parse_options.sh || exit 1;

if [ $# -lt 2 ]; then
   echo "usage: common/recognize.sh config iter"
   echo "e.g.:  common/recognize.sh tdnn_a 100"
   echo "main options (for others, see top of script file)"

   exit 1;
fi

. ./cmd.sh ## You'll want to change cmd.sh to something that will work on your system.
           ## This relates to the queue.

config_name=$1
iter=$2

. definitions/chain/model/$config_name
. exp/chain/prep/$prep/config


dir=exp/chain/model/$config_name
graph=exp/chain/prep/$prep/graph

decode_flags="--post-decode-acwt 10.0 --acwt 1.0"


dsname=$dataset
dsextra=""
if [ "$dsname" != "dev" ]; then 
dsextra=_$dsname
fi

ivecs=exp/chain/dataprep/$dataprep/ivec/ivectors_$dsname
feats=exp/chain/dataprep/$dataprep/data/$dsname

srun -n1 steps/nnet3/decode.sh --iter $iter --beam 20.0 --lattice-beam 1.0 --skip-scoring $skip_scoring --nj 7 $decode_flags --scoring-opts "--min-lmwt 1" --online-ivector-dir $ivecs $graph $feats $dir/decode${iter}${dsextra}

