#!/bin/bash
set -e
export LC_ALL=C

# Begin configuration section.
lowercase_text=false
# End configuration options.

echo "$0 $@"  # Print the command line for logging

[ -f path.sh ] && . ./path.sh # source the path.
. parse_options.sh || exit 1;

if [ $# != 2 ]; then
   echo "usage: spr_local/spr_make_corpus.sh out_dir set"
   echo "e.g.:  steps/spr_make_corpus.sh data/train train"
   echo "main options (for others, see top of script file)"
   echo "     --lowercase-text (true|false)   # Lowercase everthing"
   exit 1;
fi

outdir=$1
set=$2

if [ -d ${outdir} ]; then rm -Rf ${outdir}; fi

mkdir -p ${outdir}

spr_local/filter_corpus.py data-prep/corpus ${outdir} local/corpus_sets/${set}
utils/utt2spk_to_spk2utt.pl ${outdir}/utt2spk > ${outdir}/spk2utt

lflag=""
if $lowercase_text; then
    lflag="--lower"
fi

spr_local/preprocess_text.py ${lflag} ${outdir} data/lexicon/lexicon.txt
