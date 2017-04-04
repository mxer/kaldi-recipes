#!/bin/bash
#SBATCH -p coin,short-ivb,short-wsm,short-hsw,batch-hsw,batch-wsm,batch-ivb
#SBATCH -t 2:00:00
#SBATCH -n 1
#SBATCH --cpus-per-task=6
#SBATCH -N 1
#SBATCH --mem-per-cpu=8G
#SBATCH -o log/recognize-%j.out
#SBATCH -e log/recognize-%j.out


export LC_ALL=C

# Begin configuration section.
dataset=data/dev
skip_scoring=false
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
srun -n1 utils/mkgraph.sh ${smalllm} ${am} ${am}/graph_${sname}

nndir=$(dirname ${am})
suffix=$(echo "$nndir" | grep -o "_.*")

dsname=$(basename $dataset)
dsextra=""
if [ "$dsname" != "dev" ]; then 
dsextra=_$dsname
fi
srun -n1 steps/decode.sh --acwt 0.05 --max-active 10000 --lattice-beam 10.0 --scoring-opts "--max_lmwt 30" --skip-scoring $skip_scoring --nj 6 ${am}/graph_${sname} ${dataset} ${am}/decode${dsextra}_${sname}
srun -n1 steps/lmrescore_const_arpa.sh  --scoring-opts "--max_lmwt 30" --skip-scoring $skip_scoring $smalllm ${biglm} ${dataset} ${am}/decode${dsextra}_${sname} ${am}/decode${dsextra}_${sname}_ca_${bname}

