#!/bin/bash

export LC_ALL=C

# Begin configuration section.
cmd=run.pl
use_predict_lex=false
stage=0
log=false
# End configuration options.

echo "$0 $@"  # Print the command line for logging

[ -f path.sh ] && . ./path.sh # source the path.
. parse_options.sh || exit 1;

if [ $# != 2 ]; then
   echo "usage: common/train_joint_morfessor_segmentation.sh input_size_lex alpha"
   echo "e.g.:  common/train_joint_morfessor_segmentation.sh 300 2"
   echo "main options (for others, see top of script file)"
   echo "    --use-predict-lex # Use the real top n words, predicting missing pronuns with phonetisaurus"
   echo "    --cmd (run.pl|queue.pl...)      # specify how to run the sub-processes."
   exit 1;
fi

lex_size=$1
alpha=$2

extra=""
if $log; then
    extra="${extra}_log"
fi
if $use_predict_lex; then
    extra="${extra}_pr"
fi

name=morphjoin${extra}_${lex_size}_${alpha}

dir=data/segmentation/$name
mkdir -p $dir
mkdir -p data/dicts/$name

if [ $stage -le 0 ]; then

dampflag="-d ones"
if $log; then
  dampflag="-d log"
fi

if $use_predict_lex; then
  tmpdir=$(mktemp -d)
  cut -f1 data/text/topwords | head -n${lex_size}000 > $dir/morfessor_invocab
  common/make_dict.sh $dir/morfessor_invocab $dir/morphlex
  grep -v "^<" $dir/morphlex/lexicon.txt | morfessjoint-train ${dampflag} --countfile data/text/topwords -w ${alpha} -t - -x $dir/outlex -s $dir/morfessor.bin -S $dir/morfessor.txt
else
  cut -f1 data/text/topwords | common/filter_lex.py --nfirst=${lex_size}000 data/lexicon/lexicon.txt - - /dev/null | morfessjoint-train ${dampflag} --countfile data/text/topwords -w ${alpha} -t - -x $dir/outlex -s $dir/morfessor.bin -S $dir/morfessor.txt
fi
fi

last=$(cat data/text/split/numjobs)

mkdir -p $dir/{log,tmp}


$cmd JOB=1000:$last $dir/log/JOB.log morfessor-segment -e utf-8 -L $dir/morfessor.txt data/text/split/JOB --output-newlines --output-format-separator="+ +" --output-format="{analysis} " \| sed "s#^\s*#<s> #g" \| sed "s/\s*$/ <\\/s>/g" \> ${dir}/tmp/JOB.out

grep -v "^#" $dir/morfessor.txt | sed "s/ + /+ +/g" | tr ' ' '\n' | sort -u > $dir/vocab


cut -f1 $dir/outlex > $dir/lex_keys
cut -f2- $dir/outlex > $dir/lex_vals

cat $dir/outlex > $dir/tmp_lex

sed "s/^/+/g" < $dir/lex_keys | paste - $dir/lex_vals >> $dir/tmp_lex
sed "s/$/+/g" < $dir/lex_keys | paste - $dir/lex_vals >> $dir/tmp_lex
sed "s/^/+/g" < $dir/lex_keys | sed "s/$/+/g" | paste - $dir/lex_vals >> $dir/tmp_lex

common/filter_lex.py $dir/tmp_lex $dir/vocab $dir/tmp_lex2 $dir/oov
cat definitions/dict_prep/lex >> $dir/tmp_lex2
sort -u $dir/tmp_lex2 > data/dicts/$name/lexicon.txt
cp data/dict/*sil* data/dicts/$name/


cat $dir/tmp/* | xz > $dir/corpus.xz
rm -Rf $dir/tmp

#rm -Rf $dir/tmp_lex* $dir/lex_keys $dir/lex_vals

