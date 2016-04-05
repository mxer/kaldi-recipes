#!/bin/bash
set -e
export LC_ALL=C

# Begin configuration section.
# End configuration options.

echo "$0 $@"  # Print the command line for logging

[ -f path.sh ] && . ./path.sh # source the path.
. parse_options.sh || exit 1;

if [ $# != 2 ]; then
   echo "usage: spr_local/spr_make_corpus.sh out_dir set"
   echo "e.g.:  steps/spr_make_corpus.sh data/train train"
   echo "main options (for others, see top of script file)"
   exit 1;
fi

outdir=$1
set=$2

if [ -d data/${set} ]; then rm -Rf data/${set}; fi

mkdir -p data/${set}

spr_local/filter_corpus.py data-prep/corpus data/${set} local/corpus_sets/${set}
utils/utt2spk_to_spk2utt.pl data/${set}/utt2spk > data/${set}/spk2utt

spr_local/preprocess_text.py data/${set} data-prep/lexicon/lexicon.txt