#!/bin/bash

export LC_ALL=C

# Begin configuration section.
# End configuration options.

echo "$0 $@"  # Print the command line for logging

[ -f path.sh ] && . ./path.sh # source the path.
. parse_options.sh || exit 1;

if [ $# != 0 ]; then
   echo "usage: text_prep.sh"
   exit 1;
fi

#common/preprocess_corpus.py data-prep/text/text.orig.xz | common/count_words.py | grep -v "[0-9]" > data/text/topwords

mkdir -p data/text/split
common/preprocess_corpus.py data-prep/text/text.orig.xz | xzcat | sed "s/<s>//g" | sed "s#</s>##g" | split -l 100000 --numeric-suffixes=1000 -a4 - data/text/split/
cat data/text/split/* | common/count_words.py > data/text/topwords
count=$(ls -1 data/text/split/ | sort -n | grep -E "[0-9]+"| tail -n1)
echo "$count" > data/text/split/numjobs

mkdir -p data/text/splits
common/preprocess_corpus.py data-prep/text/text.orig.xz | xzcat | sed "s/<s>//g" | sed "s#</s>##g" | split -l 1000000 --numeric-suffixes=100 -a3 - data/text/splits/
count=$(ls -1 data/text/splits/ | sort -n | grep -E "[0-9]+"| tail -n1)
echo "$count" > data/text/splits/numjobs

mkdir -p data/segmentation/word
cat data/text/split/1* | xz -0 > data/segmentation/word/corpus.xz
