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
model_dir=$3
lexfile=$4


mkdir -p $(model_dir)

common/preprocess_corpus.py $corpus | common/count_words.py --lexicon=data-prep/lexicon/lexicon.txt --nmost=${input_vocab_size} | cut -f1 > ${model_dir}/train_list

morfessor-train -e utf-8 -d ones -s ${model_dir}/morfessor.bin -S ${model_dir}/morfessor.txt ${model_dir}/train_list

cut -f2- -d" " < ${model_dir}/morfessor.txt | sed "s/ + /+ +/g" | tr ' ' '\n' | sed 's/^[ \t]*//;s/[ \t]*$//' | sed '/^$/d' |sort -u > ${lexfile}
