#!/bin/bash

export LC_ALL=C

# Begin configuration section.
cmd=run.pl
# End configuration options.

echo "$0 $@"  # Print the command line for logging

[ -f path.sh ] && . ./path.sh # source the path.
. parse_options.sh || exit 1;

if [ $# != 3 ]; then
   echo "usage: common/make_tagged_morph.sh dirin dirout dictdirout"

   echo "main options (for others, see top of script file)"
   echo "    --cmd (run.pl|queue.pl...)      # specify how to run the sub-processes."

   exit 1;
fi

indir=$1
outdir=$2
dictdir=$3

tmpdir=$(mktemp -d)
cat data/lexicon/lexicon.txt > $tmpdir/inlex
if [ -f $indir/morphlex/lexicon.txt ]; then
    cat $indir/morphlex/lexicon.txt >> $tmpdir/inlex
fi

mkdir -p $outdir
mkdir -p $dictdir

rm -f $dictdir/lexicon.txt $dictdir/lexiconp.txt

sort -u -o $tmpdir/inlex $tmpdir/inlex

#common/matched_morph_approach.py $indir/morfessor.bin data/text/topwords $tmpdir/inlex $indir/outlex $outdir/wordmap1
#common/matched_morph_approach_stage2.py $outdir/wordmap1 $indir/outlex $outdir/wordmap2 $outdir/lex


last=$(cat data/text/split/numjobs)

mkdir -p $outdir/{log,tmp}


$cmd JOB=1000:$last $outdir/log/JOB.log common/matched_morph_approach_stage3.py $outdir/wordmap2 data/text/split/JOB  ${outdir}/tmp/JOB.out

cat $outdir/tmp/* | xz > $outdir/corpus.xz
rm -Rf $outdir/tmp

sort -u < $outdir/lex > $dictdir/lexicon.txt
cut -f1 $outdir/lex | sort -u > $outdir/vocab
