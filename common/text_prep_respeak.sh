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

mkdir -p data/text_respeak/split
xzcat data-prep/text/text.orig.xz | sed "s/ . / smash punkt /" | sed "s/ , / smash kom /" | sed "s/ ? / smash fråg /" | sed "s/ ! / smash rop /" | sed "s/ - / smash tank /" | sed "s/ : / smash kol /" | xz -0 | common/preprocess_corpus.py  | xzcat | sed "s/<s>//g" | sed "s#</s>##g" | split -l 100000 --numeric-suffixes=1000 -a4 - data/text_respeak/split/
cat data/text_respeak/split/* | common/count_words.py > data/text_respeak/topwords
count=$(ls -1 data/text_respeak/split/ | sort -n | grep -E "[0-9]+"| tail -n1)
echo "$count" > data/text_respeak/split/numjobs

mkdir -p data/segmentation_respeak/word
cat data/text_respeak/split/1* | xz -0 > data/segmentation_respeak/word/corpus.xz
