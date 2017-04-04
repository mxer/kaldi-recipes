#!/bin/bash

echo "$0 $@"  # Print the command line for logging
export LC_ALL=C



[ -f path.sh ] && . ./path.sh # source the path.
. parse_options.sh || exit 1;

if [ $# != 5 ]; then
   echo "usage: $0 in_ali out_ali target_data_dir numjobs utt2ali"
   exit 1;
fi

. ./cmd.sh ## You'll want to change cmd.sh to something that will work on your system.
           ## This relates to the queue.

inali=$1
outali=$2
targetdir=$3
numjobs=$4
utt2ali=$5

mkdir -p $outali
cp -r $inali/* $outali
rm -Rf $outali/*.gz $outali/trans.* $outali/log

echo $numjobs > $outali/num_jobs 

utils/split_data.sh $targetdir $numjobs
if [ -f $inali/ali.1.gz ]; then
  copy-int-vector "ark:gunzip -c $inali/ali.*.gz|" ark,scp:$outali/ali.ark,$outali/ali.scp

  for i in $(seq 1 $numjobs); do
    utils/filter_scp.pl $targetdir/split$numjobs/${i}/utt2spk < $utt2ali | utils/apply_map.pl -f 2 $outali/ali.scp | copy-int-vector "scp:-" "ark,t:|gzip -c > $outali/ali.${i}.gz"
  done
fi

if [ -f $inali/lat.1.gz ]; then
  lattice-copy "ark:gunzip -c $inali/lat.*.gz|" ark,scp:$outali/lat.ark,$outali/lat.scp

  for i in $(seq 1 $numjobs); do
    utils/filter_scp.pl $targetdir/split$numjobs/${i}/utt2spk < $utt2ali | utils/apply_map.pl -f 2 $outali/lat.scp | lattice-copy "scp:-" "ark:|gzip -c > $outali/lat.${i}.gz"
  done
fi


