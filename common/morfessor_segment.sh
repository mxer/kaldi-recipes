#!/bin/bash

set -e

export LC_ALL=C

# Begin configuration section.
cmd=run.pl
# End configuration options.

echo "$0 $@"  # Print the command line for logging

[ -f path.sh ] && . ./path.sh # source the path.
. parse_options.sh || exit 1;

if [ $# != 3 ]; then
   echo "usage: common/morfessor_segement.sh in_corpus morfessor_model out_corpus"
   echo "e.g.:  common/train_morfessor_model.sh data-prep/text/text.orig morfessor_model.bin data/morph1/corpus.xz"
   echo "main options (for others, see top of script file)"
   echo "     --cmd <cmd>                              # Command to run in parallel with"
   exit 1;
fi

corpusin=$1
model=$2
corpusout=$3

tmpdir=$(mktemp -d --tmpdir=./)

common/preprocess_corpus.py ${corpusin} | xzcat | sed "s#<s>##g;s#</s>##g" | split -l 100000 --numeric-suffixes=1000 -a4 - ${tmpdir}/

last=$(ls -1 ${tmpdir}/ | sort -n | tail -n1)

JOB=1000:$last $tmpdir/log/JOB.log morfessor-segment -e utf-8 -l ${model} ${tmpdir}/JOB --output-newlines --output-format-separator="+ +" --output-format="{analysis} " | sed "s#^\s*#<s> #g" | sed "s/\s*$/ <\\/s>/g" \> ${tmpdir}/JOB.out

cat ${tmpdir}/*.out | xz > ${corpusout}

rm ${tmpdir}