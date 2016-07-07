#!/bin/bash
set -e

export LC_ALL=C

# Begin configuration section.
# End configuration options.

echo "$0 $@"  # Print the command line for logging

[ -f path.sh ] && . ./path.sh # source the path.
. parse_options.sh || exit 1;

if [ $# != 4 ]; then
   echo "usage: common/train_srilm_model.sh corpus vocab order outfile"
   echo "e.g.:  common/train_srilm_model.sh data-prep/text/text.orig.xz data/dicts/word_20k 3 data/word_lm/srilm_20k_3gram/arpa"
   echo "main options (for others, see top of script file)"

   exit 1;
fi

corpus=$1
vocab=$2
order=$3
outfile=$4

for wtb in $(seq 0 ${order}); do
    INTERPOLATE=$(seq 1 ${order} | sed "s/^/-interpolate/" | tr "\n" " ")

    MINCOUNT=""
    if [ $order -ge 1 ]; then
         MINCOUNT=$(seq 2 ${order} | sed "s/^/-gt/" | sed "s/$/min 3/" | tr "\n" " ")
    fi

    KNDISCOUNT=""
    if [ $wtb -lt ${order} ]; then
         KNDISCOUNT=$(seq $((wtb+1)) ${order} | sed "s/^/-kndiscount/" | tr "\n" " ")
    fi

    WBDISCOUNT=""
    if [ $wtb -gt 0 ]; then
        WBDISCOUNT=$(seq 1 ${wtb} | sed "s/^/-wbdiscount/" | tr "\n" " ")
    fi

    echo $KNDISCOUNT $WBDISCOUNT $MINCOUNT $INTERPOLATE

    again=0

    ngram-count -memuse -text ${corpus} -lm ${outfile} -vocab ${vocab} -order ${order} $MINCOUNT $INTERPOLATE $KNDISCOUNT $WBDISCOUNT || again=1

    if [ $again -eq 0 ]; then
        break
    fi
done
