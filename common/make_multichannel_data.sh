#!/bin/bash
export LC_ALL=C

. utils/parse_options.sh

if [ $# != 3 ]; then
  echo "Usage: $0 <fullwavscp> <srcdir> <destdir>"
  echo "e.g.:"
  echo " $0 data-prep/audio/wav.scp data/train data/train_mc"
  exit 1
fi

wavscp=$1
srcdir=$2
destdir=$3

if [ "$destdir" == "$srcdir" ]; then
  echo "$0: this script requires <srcdir> and <destdir> to be different."
  exit 1
fi

utils/data/get_utt2dur.sh ${srcdir}

echo "start cutting"
cut -f1 -d" " $srcdir/utt2spk > $srcdir/utt

chdirs=()
echo "start for loop"
for ch in $(seq 0 9); do
  echo $ch
  grep "\\-ch${ch}\\-" $srcdir/wav.scp > /dev/null
  if [ $? -gt 0 ]; then
    echo "channel $ch was not in the data yet"
    #This channel was not yet present
    grep "\\-ch${ch}" $wavscp  > /dev/null
    if [ $? -eq 0 ]; then
      echo "lets process channel $ch"
      # And this channel is in the original data
      chdir=${destdir}_ch${ch}
      mkdir -p ${chdir}    
      
      sed "s/-ch[0-9]/-ch${ch}/g" < $srcdir/utt > $chdir/utt 
      paste -d" " $srcdir/utt $chdir/utt > $chdir/utt_map
      #sed "s/-ch[0-9]/-ch${ch}/g" < $srcdir/spk2utt > $chdir/spk2utt 
      #cat $srcdir/spk2utt | awk -v p=$prefix '{printf("%s %s%s\n", $1, p, $1);}' > $chdir/spk_map
      if [ ! -f $srcdir/utt2uniq ]; then
        paste -d" " $chdir/utt $srcdir/utt > $chdir/utt2uniq
      else
        utils/apply_map.pl -f1 $chdir/utt_map < $srcdir/utt2uniq > $uttdir/utt2uniq
      fi
      if [ -f $srcdir/segments ]; then
        sed "s/-ch[0-9]/-ch${ch}/g" <  $srcdir/segments > $chdir/segments     
      fi
      sed "s/-ch[0-9]/-ch${ch}/g" $srcdir/wav.scp | utils/filter_scp.pl - $wavscp  > $chdir/wav.scp
      

      sed "s/-ch[0-9]/-ch${ch}/g" < $srcdir/utt2spk > $chdir/utt2spk
#      cat $srcdir/utt2spk | utils/apply_map.pl -f 1 $chdir/utt_map  | utils/apply_map.pl -f 2 $chdir/spk_map >$chdir/utt2spk

      utils/utt2spk_to_spk2utt.pl <$chdir/utt2spk >$chdir/spk2utt


      if [ -f $srcdir/text ]; then
        sed "s/-ch[0-9]/-ch${ch}/g" < $srcdir/text > $chdir/text
      fi
      if [ -f $srcdir/spk2gender ]; then
        sed "s/-ch[0-9]/-ch${ch}/g" <$srcdir/spk2gender >$chdir/spk2gender
      fi

      sed "s/-ch[0-9]/-ch${ch}/g" < $srcdir/utt2dur > $chdir/utt2dur 
      
rm $chdir/utt_map $chdir/utt 2>/dev/null
      utils/validate_data_dir.sh --no-feats $chdir
      chdirs+=($chdir) 
       
    fi 
  fi
done
rm $srcdir/utt

if [ ${#chdirs[@]} -eq 0 ]; then
  echo "some simple copying"
  cp -r $srcdir $destdir
else
  utils/data/combine_data.sh $destdir $srcdir ${chdirs[*]} 
  rm -Rf ${chdirs[*]}
fi
utils/validate_data_dir.sh --no-feats $destdir

    

