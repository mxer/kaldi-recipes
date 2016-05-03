#!/bin/bash
set -e
export LC_ALL=C

# Begin configuration section.
lowercase_text=false
accents=true
# End configuration options.

echo "$0 $@"  # Print the command line for logging

[ -f path.sh ] && . ./path.sh # source the path.
. parse_options.sh || exit 1;

if [ $# != 3 ]; then
   echo "usage: spr_local/spr_make_vocab.sh out_file vocabsize(in thousands) lexicon"
   echo "e.g.:  steps/spr_make_vocab.sh --lowercase-text true data/vocab/20k_lower 20 data-prep/lexicon"
   echo "main options (for others, see top of script file)"
   echo "     --lowercase-text (true|false)   # Lowercase everthing"
   echo "     --accents (true|false)   # use accents on phones"
   exit 1;
fi

outdir=$1
vocabsize=$2
lex=$3

if [ -d ${outdir} ]; then rm -Rf ${outdir}; fi
mkdir -p ${outdir}

tmp_dir=$(mktemp -d)
echo "Temporary directories (should be cleaned afterwards):" ${tmp_dir}

filter_cmd="cat"
if $lowercase_text; then
    filter_cmd="spr_local/to_lower.py"
fi

cat data-prep/ngram/vocab | $filter_cmd > ${tmp_dir}/in_vocab

echo "Make vocab"
spr_local/make_recog_vocab.py ${tmp_dir}/in_vocab ${vocabsize}000 ${tmp_dir}/vocab

echo "Make lex"
spr_local/spr_make_lex.sh --accents ${accents} ${outdir} ${tmp_dir}/vocab ${lex}

mv ${tmp_dir}/vocab ${outdir}/vocab
