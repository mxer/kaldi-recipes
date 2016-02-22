#!/bin/bash

export LC_ALL=C

archive_dir=$1

echo $(date) "Check the integrity of the archives"
read -r -d '' SUMS <<'EOF'
90c5c106fa3f869599533201d73fe332  sve.16khz.0467-1.tar.gz
4d8efa0a71dca669754a3b6554f8e4b3  sve.16khz.0467-2.tar.gz
bef9c30ae7de4c77264dccfad349b7f3  sve.16khz.0467-3.tar.gz
9ef845e486136b5b13502dfdba6c9d25  sve.16khz.0468.tar.gz
EOF

(cd $archive_dir && echo "$SUMS" | md5sum -c -) || exit "The spraakbanken archives gave unexpected md5 sums"


mkdir -p data/train
mkdir -p data/test

test_data_dir=$(mktemp -d)
train_data_dir=$(mktemp -d)

echo "Temporary directories (should be cleaned afterwards):" $train_data_dir $test_data_dir

trap "{ rm -Rf $test_data_dir $train_data_dir ; exit 255; }" EXIT

echo $(date) "Start untarring"

tar xzf ${archive_dir}/sve.16khz.0467-1.tar.gz --strip-components=3 -C $train_data_dir
tar xzf ${archive_dir}/sve.16khz.0467-2.tar.gz --strip-components=3 -C $train_data_dir
tar xzf ${archive_dir}/sve.16khz.0467-3.tar.gz --strip-components=3 -C $train_data_dir

tar xzf ${archive_dir}/sve.16khz.0468.tar.gz --strip-components=3 -C $test_data_dir

echo $train_data_dir $test_data_dir

echo $(date) "make lists train"
local/make_wav_txt_lists.py $train_data_dir $train_data_dir/text $train_data_dir/wav.scp $train_data_dir/utt2spk
echo $(date) "make lists test"
local/make_wav_txt_lists.py $test_data_dir $test_data_dir/text $test_data_dir/wav.scp $test_data_dir/utt2spk

echo $(date) "sorting"
sort < $train_data_dir/text > data/train/text
sort < $test_data_dir/text > data/test/text

sort < $train_data_dir/utt2spk > data/train/utt2spk
sort < $test_data_dir/utt2spk > data/test/utt2spk

utils/utt2spk_to_spk2utt.pl data/train/utt2spk > data/train/spk2utt
utils/utt2spk_to_spk2utt.pl data/test/utt2spk > data/test/spk2utt

sort < $train_data_dir/wav.scp > $train_data_dir/wav.sorted.scp
sort < $test_data_dir/wav.scp > $test_data_dir/wav.sorted.scp

echo $(date) "wav-copy train"
wav-copy scp:$train_data_dir/wav.sorted.scp ark,scp:data/train/wav.ark,data/train/wav.scp
echo $(date) "wav-copy test"
wav-copy scp:$test_data_dir/wav.sorted.scp ark,scp:data/test/wav.ark,data/test/wav.scp

echo $(date) "Start removing dirs"
rm -Rf $test_data_dir $train_data_dir

