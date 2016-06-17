#!/bin/bash
set -e
export LC_ALL=C

# Begin configuration section.
lowercase_text=false
accents=true
cmd=run.pl

# End configuration options.

echo "$0 $@"  # Print the command line for logging

[ -f path.sh ] && . ./path.sh # source the path.
. parse_options.sh || exit 1;

if [ $# != 2 ]; then
   echo "usage: spr_local/spr_make_morph_G.sh in_lex_dir out_G_dir"
   echo "e.g.:  spr_local/spr_make_lex.sh data/lexicon data/morph_2g"
   echo "main options (for others, see top of script file)"
   echo "     --lowercase-text (true|false)   # Lowercase everthing"
   echo "     --accents (true|false)   # use accents on phones"
   echo "     --cmd <cmd>                              # Command to run in parallel with"

   exit 1;
fi

inlex=$1
outdir=$2

lc=false
ac=false
#if $lowercase_text; then
lc=true
#fi
#if $accents; then
#ac=true
#fi

vocab_dir=$(mktemp -d)

mkdir -p $outdir
echo "Temporary directories (should be cleaned afterwards):" ${vocab_dir}
spr_local/spr_make_vocab.sh --lowercase-text $lc --accents $ac ${vocab_dir} 200 $inlex

if [ ! -f $outdir/morfessor.bin ]; then

morfessor-train -s $outdir/morfessor.bin -S $outdir/morfessor.txt ${vocab_dir}/vocab -d ones
fi

mkdir -p tmp
tmpcount=$(mktemp -d --tmpdir=tmp)
echo "Temporary directories (should be cleaned afterwards):" ${tmpcount}

spr_local/to_lower.py < data-prep/ngram/corpus | split -l 100000 --numeric-suffixes=1000 -a4 - $tmpcount/

last=$(ls -1 $tmpcount | sort -n | tail -n1)
mkdir $tmpcount/out
mkdir $tmpcount/log
#$cmd JOB=1000:$last $tmpcount/log/JOB.log morfessor-segment --encoding=utf-8 -l $outdir/morfessor.bin -o $tmpcount/out/JOB $tmpcount/JOB 
$cmd JOB=1000:$last $tmpcount/log/JOB.log spr_local/smart_morfessor_segment.py $outdir/morfessor.bin $tmpcount/JOB $tmpcount/out/JOB 

cat $tmpcount/out/* > $outdir/corpus

rm -Rf $tmpcount $vocab_dir

spr_local/make_recog_vocab_corpus.py $outdir/corpus 100 $outdir/morph_vocab
spr_local/spr_make_lex.sh --accents false ${outdir}/lex $outdir/morph_vocab data/lexicon
utils/prepare_lang.sh --phone-symbol-table data/lang_train/phones.txt $outdir/morph_vocab "<UNK>" ${outdir}/lang/local ${outdir}/lang

order=3

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

    ngram-count -memuse -text $outdir/corpus -lm  ${outdir}/lang/arpa -vocab $outdir/morph_vocab/vocab -order ${order} $MINCOUNT $INTERPOLATE $KNDISCOUNT $WBDISCOUNT || again=1

    if [ $again -eq 0 ]; then
        break
    fi
done

arpa2fst ${outdir}/lang/arpa | fstprint | utils/eps2disambig.pl | utils/s2eps.pl | fstcompile --isymbols=${outdir}/lang/words.txt \
      --osymbols=${outdir}/lang/words.txt  --keep_isymbols=false --keep_osymbols=false | \
     fstrmepsilon | fstarcsort --sort_type=ilabel > ${outdir}/lang/G.fst

utils/validate_lang.pl ${outdir}/lang

