#!/bin/bash

export LC_ALL=C

# Begin configuration section.
cmd=run.pl
dampening=log
stage=0
# End configuration options.

echo "$0 $@"  # Print the command line for logging

[ -f path.sh ] && . ./path.sh # source the path.
. parse_options.sh || exit 1;

if [ $# != 2 ]; then
   echo "usage: common/train_basic_morfessor_segmentation.sh input_size_lex alpha"
   echo "e.g.:  common/train_basic_morfessor_segmentation.sh 300 2"
   echo "main options (for others, see top of script file)"
   echo "    --dampening none|log|ones"
   echo "    --cmd (run.pl|queue.pl...)      # specify how to run the sub-processes."
   exit 1;
fi

lex_size=$1
alpha=$2

name=morfessor_${dampening}_${lex_size}_${alpha}

dir=data/segmentation/$name
mkdir -p $dir
mkdir -p data/dicts/$name

if [ $stage -le 0 ]; then

head -n ${lex_size}000 data/text/topwords  | awk ' { t = $1; $1 = $2; $2 = t; print; } ' | morfessor-train -w ${alpha} -d ${dampening} -s $dir/morfessor.bin -S $dir/morfessor.txt --traindata-list --encoding="utf-8" -
fi

last=$(cat data/text/split/numjobs)

mkdir -p $dir/{log,tmp}


$cmd JOB=1000:$last $dir/log/JOB.log morfessor-segment -e utf-8 -L $dir/morfessor.txt data/text/split/JOB --output-newlines --output-format-separator="+ +" --output-format="{analysis} " \| sed "s#^\s*#<s> #g" \| sed "s/\s*$/ <\\/s>/g" \> ${dir}/tmp/JOB.out

grep -v "^#" $dir/morfessor.txt | sed "s/ + /+ +/g" | tr ' ' '\n' | sort -u > $dir/vocab


cat $dir/tmp/* | xz > $dir/corpus.xz
rm -Rf $dir/tmp
