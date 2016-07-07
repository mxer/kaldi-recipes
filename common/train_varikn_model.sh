#!/bin/bash
#SBATCH --gres=spindle:1
set -e

export LC_ALL=C

# Begin configuration section.
# End configuration options.

echo "$0 $@"  # Print the command line for logging

[ -f path.sh ] && . ./path.sh # source the path.
. parse_options.sh || exit 1;

if [ $# != 5 ]; then
   echo "usage: common/train_varikn_model.sh corpus vocab d order outfile"
   echo "e.g.:  common/train_varikn_model.sh data-prep/text/text.orig.xz data/dicts/word_20k 0.05 3 data/word_lm/srilm_20k_3gram/arpa"
   echo "main options (for others, see top of script file)"

   exit 1;
fi

corpus=$1
vocab=$2
d=$3
order=$4
outfile=$5

e=$(python3 -c "print($d*1.3)")

tmpdir=$(mktemp -d)

cat $vocab > $tmpdir/vocab
echo "<s>" >> $tmpdir/vocab
echo "</s>" >> $tmpdir/vocab

common/corpus_split_varikn.py ${corpus} 100000 ${tmpdir}/train ${tmpdir}/dev
varigram_kn -N -n ${order} -D ${d} -E ${e} -a -B ${tmpdir}/vocab -C -o ${tmpdir}/dev -O "0 0 1 1 1 2 3 4" ${tmpdir}/train - | xz > ${outfile}

rm -Rf ${tmpdir}
