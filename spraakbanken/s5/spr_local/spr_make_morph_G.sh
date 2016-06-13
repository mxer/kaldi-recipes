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
if $lowercase_text; then
lc=true
fi
if $accents; then
ac=true
fi

vocab_dir=$(mktemp -d)

mkdir -p $outdir
echo "Temporary directories (should be cleaned afterwards):" ${vocab_dir}
spr_local/spr_make_vocab.sh --lowercase-text $lc --accents $ac ${vocab_dir} 200 $inlex

morfessor-train -s $outdir/morfessor.bin ${vocab_dir}/vocab -d ones

mkdir -p tmp
tmpcount=$(mktemp -d --tmpdir=tmp)
echo "Temporary directories (should be cleaned afterwards):" ${tmpcount}

spr_local/to_lower.py < data-prep/ngram/corpus | split -l 1000000 --numeric-suffixes=1000 -a4 - $tmpcount/

last=$(ls -1 $tmpcount | sort -n | tail -n1)
mkdir $tmpcount/out
mkdir $tmpcount/log
$cmd JOB=1000:$last $tmpcount/log/JOB.log morfessor-segment -l $outdir/morfessor.bin \< $tmpcount/JOB \> $tmpcount/out/JOB

cat $tmpcount/out/* $outdir/corpus





