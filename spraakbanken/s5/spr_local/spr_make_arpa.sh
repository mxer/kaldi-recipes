#!/bin/bash
set -e
export LC_ALL=C

# Begin configuration section.
lowercase_text=false
# End configuration options.

echo "$0 $@"  # Print the command line for logging

[ -f path.sh ] && . ./path.sh # source the path.
. parse_options.sh || exit 1;

if [ $# != 3 ]; then
   echo "usage: spr_local/spr_make_arpa.sh out_file vocab order"
   echo "e.g.:  steps/spr_make_arpa.sh --lowercase-text true data/20k_3gram data/vocab/20k_lower 3"
   echo "main options (for others, see top of script file)"
   echo "     --lowercase-text (true|false)   # Lowercase everthing"
   exit 1;
fi

outdir=$1
vocab=$2
order=$3

if [ -d ${outdir} ]; then rm -Rf ${outdir}; fi
mkdir -p ${outdir}

filter_cmd="cat"
if $lowercase_text; then
    filter_cmd="spr_local/to_lower.py"
fi

echo "prepare lang"
utils/prepare_lang.sh --phone-symbol-table data/lang_train/phones.txt ${vocab} "<UNK>" ${outdir}/local ${outdir}


for knd in $(seq ${order} -1 0); do
    INTERPOLATE=$(seq 1 ${order} | sed "s/^/-interpolate/" | tr "\n" " ")

    MINCOUNT=""
    if [ $order -ge 1 ]; then
         MINCOUNT=$(seq 1 ${order} | sed "s/^/-gt/" | sed "s/$/min 3/" | tr "\n" " ")
    fi

    KNDISCOUNT=""
    if [ $knd -ge 1 ]; then
         KNDISCOUNT=$(seq 1 $knd | sed "s/^/-kndiscount/" | tr "\n" " ")
    fi

    WBDISCOUNT=""
    if [ $knd != ${order} ]; then
        WBDISCOUNT=$(seq $((knd+1)) ${order} | sed "s/^/-wbdiscount/" | tr "\n" " ")
    fi

    echo $KNDISCOUNT $WBDISCOUNT $MINCOUNT $INTERPOLATE

    again=0

    cat data-prep/ngram/[1-${order}]count | $filter_cmd | ngram-count -memuse -read - -lm ${outdir}/arpa -vocab ${vocab}/vocab -order ${order} $MINCOUNT $INTERPOLATE $KNDISCOUNT $WBDISCOUNT || again=1

    if [ $again -eq 0 ]; then
        break
    fi
done

arpa2fst ${outdir}/arpa | fstprint | utils/eps2disambig.pl | utils/s2eps.pl | fstcompile --isymbols=${outdir}/words.txt \
      --osymbols=${outdir}/words.txt  --keep_isymbols=false --keep_osymbols=false | \
     fstrmepsilon | fstarcsort --sort_type=ilabel > ${outdir}/G.fst

utils/validate_lang.pl ${outdir}
