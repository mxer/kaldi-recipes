#!/bin/bash
###SBATCH --gres=spindle:1
set -e

export LC_ALL=C

# Begin configuration section.
init_d=0.02
# End configuration options.

echo "$0 $@"  # Print the command line for logging

[ -f path.sh ] && . ./path.sh # source the path.
. parse_options.sh || exit 1;

if [ $# != 5 ]; then
   echo "usage: common/train_varikn_model.sh corpus vocab limit(in M) order outfile"
   echo "e.g.:  common/train_varikn_model.sh data-prep/text/text.orig.xz data/dicts/word_20k 2 3 data/word_lm/srilm_20k_3gram/arpa"
   echo "main options (for others, see top of script file)"

   exit 1;
fi

corpus=$1
vocab=$2
l=$3
order=$4
outfile=$5

mkdir -p $(dirname $outfile)

tmpdir=$(mktemp -d)

sed "s/ /	/" $vocab <(echo "<s>") <(echo "</s>") | grep -v "<UNK>" | grep -v "#" | grep -v "<eps>" | cut -f1 | sort -u > $tmpdir/vocab

orderflag=""
if [ $order -gt 1 ]; then
orderflag="-n ${order}"
fi

common/corpus_split_varikn.py ${corpus} 100000 ${tmpdir}/dev ${tmpdir}/train
varigram_kn -3 -N ${orderflag} -D ${init_d} -V ${l}000000 -a -B ${tmpdir}/vocab -C -o ${tmpdir}/dev -O "0 0 1 2" ${tmpdir}/train - | xz > ${outfile}

rm -Rf ${tmpdir}
