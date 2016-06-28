#!/bin/bash

export LC_ALL=C

# Begin configuration section.
# End configuration options.

echo "$0 $@"  # Print the command line for logging

[ -f path.sh ] && . ./path.sh # source the path.
. parse_options.sh || exit 1;

if [ $# != 4 ]; then
   echo "usage: common/train_morfessor_model.sh corpus input_vocab_size morfessor_model lexicon"
   echo "e.g.:  common/train_morfessor_model.sh data-prep/text/text.orig 300000 morfessor_model.bin lexicon"
   echo "main options (for others, see top of script file)"

   exit 1;
fi

corpus=$1
input_vocab_size=$2
model=$3
lexfile=$4

common/preprocess_corpus.py $corpus | common/count_words.py --nmost=${input_vocab_size} | morfessor-train -d ones -s ${model} -x ${lexfile} -