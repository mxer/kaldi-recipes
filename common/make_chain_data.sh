#!/bin/bash

export LC_ALL=C

# Begin configuration section.
speeds="0.9 1.1"
# End configuration section.

echo "$0 $@"  # Print the command line for logging

if [ -f path.sh ]; then . ./path.sh; fi
. parse_options.sh || exit 1;

if [ $# -le 2 ]; then
  echo "Usage: $0 <src-data-dir> <dest-data-dir> <wav.scp> [ <channelextra> <channelextra2> ..]"
  exit 1
fi

srcdir=$1
destdir=$2
wavscp=$3
shift 3

comb_dirs=""

if [ -f $srcdir/utt2ali ]; then
  echo "warning, $srcdir/utt2ali exists, but will be overwritten"
fi
  
utils/data/get_utt2dur.sh $srcdir
paste -d" " <(cut -f1 -d" " $srcdir/utt2spk) <(cut -f1 -d" " $srcdir/utt2spk) > $srcdir/utt2uniq
utils/data/fix_data_dir.sh $srcdir

origs=$(mktemp)
cut -f1 -d" " $srcdir/utt2spk > $origs
for speed in $speeds; do
  utils/data/perturb_data_dir_speed.sh $speed ${srcdir} ${destdir}_speed$speed 
  utils/data/fix_data_dir.sh ${destdir}_speed$speed
  paste -d" " <(cut -f1 -d" " ${destdir}_speed$speed/utt2spk) <(cut -f1 -d" " ${destdir}_speed$speed/utt2spk) > ${destdir}_speed$speed/utt2ali
  comb_dirs="${comb_dirs} ${destdir}_speed$speed"
done

for channel in $*; do
  expr="s/-ch[0-9]/-ch${channel}/g"
  ddir=${destdir}_ch${channel}
  mkdir $ddir
  
  utils/filter_scp.pl <(sed "$expr" $srcdir/wav.scp) < $wavscp > $ddir/wav.scp
  
  for f in utt2uniq utt2spk segments; do
    if [ -f ${srcdir}/$f ]; then
      sed "$expr" < $srcdir/$f > $ddir/$f  
    fi
  done 

  paste -d" " <(cut -f1 -d" " $srcdir/utt2spk) <(cut -f1 -d" " $srcdir/utt2spk | sed "$expr") > ${ddir}/map
  paste -d" " <(cut -f1 -d" " $srcdir/utt2spk | sed "$expr") <(cut -f1 -d" " $srcdir/utt2spk) > ${ddir}/rmap

  for f in utt2lang utt2dur text; do
    if [ -f ${srcdir}/$f ]; then
      utils/apply_map.pl -f 1 ${ddir}/map < $srcdir/$f > $ddir/$f
    fi
  done
  
  utils/utt2spk_to_spk2utt.pl < $ddir/utt2spk > $ddir/spk2utt
  cut -f1 -d" " $ddir/utt2spk >> $origs

  utils/fix_data_dir.sh $ddir
  paste -d" " <(cut -f1 -d" " $ddir/utt2spk) <(cut -f1 -d" " $ddir/utt2spk) | utils/apply_map.pl -f 2 ${ddir}/rmap > $ddir/utt2uniq
  cp $ddir/utt2uniq $ddir/utt2ali
  
  for speed in $speeds; do
    utils/data/perturb_data_dir_speed.sh $speed ${ddir} ${ddir}_speed$speed 
    #mv ${ddir}_speed$speed/utt2uniq ${ddir}_speed$speed/utt2uniq.backup
    utils/apply_map.pl -f 2 <(awk '{print $2 " " $1}' ${destdir}_speed$speed/utt2uniq) < ${ddir}_speed$speed/utt2uniq > ${ddir}_speed$speed/utt2ali
    #utils/apply_map.pl -f 2 ${ddir}/rmap < ${ddir}_speed$speed/utt2uniq.backup > ${ddir}_speed$speed/utt2uniq
    comb_dirs="${comb_dirs} ${ddir}_speed$speed"
  done
  
  comb_dirs="${comb_dirs} ${ddir}"
done


cp $srcdir/utt2uniq $srcdir/utt2ali
echo $srcdir $comb_dirs
utils/combine_data.sh --extra-files 'utt2ali' $destdir $srcdir $comb_dirs
sort -u -o $destdir/utt2ali $destdir/utt2ali
rm $srcdir/utt2ali
cat $origs | sort -u > $destdir/origs
rm $origs
rm -Rf $comb_dirs

utils/validate_data_dir.sh --no-feats $destdir

#mv $destdir/wav.scp $destdir/wav.scp.backup
#utils/filter_scp.pl $wavscp < $destdir/wav.scp.backup > $destdir/wav.scp 

#utils/fix_data_dir.sh $destdir
