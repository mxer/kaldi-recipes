#!/bin/bash

export LC_ALL=C

# Begin configuration section.
# End configuration options.

echo "$0 $@"  # Print the command line for logging

[ -f path.sh ] && . ./path.sh # source the path.
. parse_options.sh || exit 1;

if [ $# != 3 ]; then
   echo "usage: common/morfessor_segement.sh in_corpus morfessor_model out_corpus"
   echo "e.g.:  common/train_morfessor_model.sh data-prep/text/text.orig morfessor_model.bin data/morph1/corpus.xz"
   echo "main options (for others, see top of script file)"

   exit 1;
fi

corpusin=$1
model=$2
corpusout=$3

common/preprocess_corpus.py ${corpusin} | xzcat | morfessor-segment -e utf-8 -l ${model} - | xz > ${corpusout}
