#!/bin/bash

export LC_ALL=C

lang=$1

echo $(date) "Check the integrity of the archives"

if [ -d data-prep/$lang ]; then
   echo "data-prep/$lang exists, so we assume we don't need the original corpus files. If data preparation fails, remove data-prep/$lang and try again"
else

wd=$(pwd)
(cd corpus && md5sum -c $wd/local/checksums/train_$lang) || exit "The spraakbanken training archives gave unexpected md5 sums"
(cd corpus && md5sum -c $wd/local/checksums/test_$lang) || exit "The spraakbanken testing archives gave unexpected md5 sums"

mkdir -p data-prep/$lang/train
mkdir -p data-prep/$lang/test

test_data_dir=$(mktemp -d)
train_data_dir=$(mktemp -d)

echo "Temporary directories (should be cleaned afterwards):" $train_data_dir $test_data_dir

trap "{ rm -Rf $test_data_dir $train_data_dir ; exit 255; }" EXIT

echo $(date) "Start untarring"

for t in $(cut -f3- -d" " local/checksums/train_$lang); do
    tar xzf corpus/$t --strip-components=3 -C $train_data_dir
done

for t in $(cut -f3- -d" " local/checksums/test_$lang); do
    tar xzf corpus/$t --strip-components=3 -C $test_data_dir
done

echo $(date) "make lists train"
local/make_wav_txt_lists.py $train_data_dir $train_data_dir/text $train_data_dir/wav.scp $train_data_dir/utt2spk
echo $(date) "make lists test"
local/make_wav_txt_lists.py $test_data_dir $test_data_dir/text $test_data_dir/wav.scp $test_data_dir/utt2spk

echo $(date) "sorting"
sort < $train_data_dir/text > data-prep/$lang/train/text
sort < $test_data_dir/text > data-prep/$lang/test/text

sort < $train_data_dir/utt2spk > data-prep/$lang/train/utt2spk
sort < $test_data_dir/utt2spk > data-prep/$lang/test/utt2spk

sort < $train_data_dir/wav.scp > $train_data_dir/wav.sorted.scp
sort < $test_data_dir/wav.scp > $test_data_dir/wav.sorted.scp

echo $(date) "wav-copy train"
wav-copy scp:$train_data_dir/wav.sorted.scp ark,scp:data-prep/$lang/train/wav.ark,data-prep/$lang/train/wav.scp
echo $(date) "wav-copy test"
wav-copy scp:$test_data_dir/wav.sorted.scp ark,scp:data-prep/$lang/test/wav.ark,data-prep/$lang/test/wav.scp

echo $(date) "Start removing dirs"
rm -Rf $test_data_dir $train_data_dir

fi  # Now data-prep/$lang exists and is filled

for d in "train" "test"; do
  mkdir -p data/$lang/$d
  cp data-prep/$lang/$d/wav.scp data/$lang/$d
  cp data-prep/$lang/$d/utt2spk data/$lang/$d
  cp data-prep/$lang/$d/text data/$lang/$d

  #TODO make text in the desired format
  utils/utt2spk_to_spk2utt.pl data/$lang/$d/utt2spk > data/$lang/$d/spk2utt
done

