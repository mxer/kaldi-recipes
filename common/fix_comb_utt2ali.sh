#!/bin/bash

echo "$0 $@"  # Print the command line for logging
export LC_ALL=C

min_seg_len=1.55


[ -f path.sh ] && . ./path.sh # source the path.
. parse_options.sh || exit 1;

if [ $# != 2 ]; then
   echo "usage: $0 comb_dir utt2ali"
   exit 1;
fi

. ./cmd.sh ## You'll want to change cmd.sh to something that will work on your system.
           ## This relates to the queue.

cdir=$1
utt2ali=$2

grep "\-comb[0-9] " $cdir/utt2utts > $cdir/actual_utt2utts

cut -f2- -d" " $utt2ali | tr ' ' '\n' | sort -u | sed "s/^/ /" | fgrep -f -  $cdir/actual_utt2utts | sed "s/ /_/g" | sed "s/_/ /" | awk '{print $2 " " $1}' > $cdir/map
utils/apply_map.pl -f 2- $utt2ali < $cdir/actual_utt2utts | sed "s/ /_/g" | sed "s/_/ /" | utils/apply_map.pl -f 2 --permissive $cdir/map | utils/filter_scp.pl -f 2 <(cut -f2 -d" " $cdir/map) > $cdir/utt2ali2
cat $utt2ali $cdir/utt2ali2 | sort -u | utils/filter_scp.pl $cdir/utt2spk > $cdir/utt2ali

rm $cdir/{map,utt2ali2,actual_utt2utts}

cut -f2 -d" " $cdir/utt2ali | sort -u > $cdir/ali_origs
