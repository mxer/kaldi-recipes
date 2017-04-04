#!/bin/bash

export LC_ALL=C
set -e -o pipefail


echo "$0 $@"  # Print the command line for logging


cmd="slurm.pl --mem 2G"
[ -f path.sh ] && . ./path.sh # source the path.
. parse_options.sh || exit 1;

if [ $# != 3 ]; then
   echo "usage: $0 srcdir tgtdir style"
   exit 1;
fi

srcdir=$1
tgtdir=$2
style=$3

. ./cmd.sh ## You'll want to change cmd.sh to something that will work on your system.


oseparator="+ +"
oformat="{analysis} "
begin="<s> "

case $style in
pre)
  oseparator=" |"
  ;;
wma)
  oseparator=" "
  begin="<s> <w> "
  oformat="{analysis} <w> "
  ;;
esac

mkdir -p $tgtdir
cp $srcdir/{morfessor.txt,morfessor.bin,outlex} $tgtdir/

last=$(cat data/text/splits/numjobs)

mkdir -p $tgtdir/{log,tmp}


$cmd JOB=100:$last $tgtdir/log/JOB.log morfessor-segment -e utf-8 -l $tgtdir/morfessor.bin data/text/splits/JOB --output-newlines --output-format-separator="$oseparator" --output-format="$oformat" \| sed "s#^\s*#${begin}#g" \| sed "s/\s*$/ <\\/s>/g" \> ${tgtdir}/tmp/JOB.out

grep -v "^#" $tgtdir/morfessor.txt | cut -f2- -d" " | sed "s/ + /${oseparator}/g" | tr ' ' '\n' | sort -u - <(echo "<w>") > $tgtdir/vocab

cat $tgtdir/tmp/* | xz > $tgtdir/corpus.xz
rm -Rf $tgtdir/tmp

