#!/bin/bash

export LC_ALL=C

# Begin configuration section.
extra_files= # specify additional files in 'src-data-dir' to merge, ex. "file1 file2 ..."
skip_fix=false # skip the fix_data_dir.sh in the end
# End configuration section.

echo "$0 $@"  # Print the command line for logging

if [ -f path.sh ]; then . ./path.sh; fi
. parse_options.sh || exit 1;

if [ $# -le 3 ]; then
  echo "Usage: $0 <src-data-dir> <dest-data-dir> <wav.scp> <channelextra> [<channelextra2> ..]"
  exit 1
fi

srcdir=$1
destdir=$2
wavscp=$3
shift 3

comb_dirs=""

if [ -f $srcdir/utt2ali ]; then
  echo "$srcdir/utt2ali is not supposed to exist"
  exit 1
fi

for channel in $*; do
  expr="s/-ch[0-9]-/-ch${channel}-/g"
  utils/copy_data_dir.sh $srcdir ${srcdir}-ch${channel}  

  paste -d" " <(cut -f1 -d" " $srcdir/utt2spk | sed "$expr") <(cut -f1 -d" " $srcdir/utt2spk) > ${srcdir}-ch${channel}/utt2ali

  rm -f ${srcdir}-ch${channel}/{feats.scp,cmvn.scp,spk2utt}

  for f in segments utt2spk text wav.scp; do
    if [ -f ${srcdir}-ch${channel}/$f ]; then
      sed -i "$expr" ${srcdir}-ch${channel}/$f
    fi
  done
  
  
  paste -d" " <(cut -f1 -d" " $srcdir/utt2spk | sed "$expr") <(cut -f1 -d" " $srcdir/utt2spk) > ${srcdir}-ch${channel}/utt2ali
  
  comb_dirs="${comb_dirs} ${srcdir}-ch${channel}"
done

utils/combine_data.sh $destdir $srcdir $comb_dirs
mv $destdir/wav.scp $destdir/wav.scp.backup
utils/filter_scp.pl $wavscp < $destdir/wav.scp.backup > $destdir/wav.scp 

utils/fix_data_dir.sh $destdir
