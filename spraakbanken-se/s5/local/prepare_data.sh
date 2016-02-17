#!/bin/bash

export LC_ALL=C

mkdir -p data/train
mkdir -p data/test

test_data_dir=$(mktemp -d)
train_data_dir=$(mktemp -d)

echo $train_data_dir $test_data_dir

trap "{ rm -Rf $test_data_dir $train_data_dir ; exit 255; }" EXIT

echo $(date) "Start untarring"

tar xzf /teamwork/t40511_asr/c/språkbanken/se/nst-16khz/sve.16khz.0467-1.tar.gz --strip-components=3 -C $train_data_dir
tar xzf /teamwork/t40511_asr/c/språkbanken/se/nst-16khz/sve.16khz.0467-2.tar.gz --strip-components=3 -C $train_data_dir
tar xzf /teamwork/t40511_asr/c/språkbanken/se/nst-16khz/sve.16khz.0467-3.tar.gz --strip-components=3 -C $train_data_dir

tar xzf /teamwork/t40511_asr/c/språkbanken/se/nst-16khz/sve.16khz.0468.tar.gz --strip-components=3 -C $test_data_dir

echo $train_data_dir $test_data_dir

echo $(date) "make lists train"
./make_wav_txt_lists.py $train_data_dir $train_data_dir/text $train_data_dir/wav.scp $train_data_dir/utt2speak
echo $(date) "make lists test"
./make_wav_txt_lists.py $test_data_dir $test_data_dir/text $test_data_dir/wav.scp $test_data_dir/utt2speak

echo $(date) "sorting"
sort < $train_data_dir/text > data/train/text
sort < $test_data_dir/text > data/test/text

sort < $train_data_dir/utt2speak > data/train/utt2speak
sort < $test_data_dir/utt2speak > data/test/utt2speak

sort < $train_data_dir/wav.scp > $train_data_dir/wav.sorted.scp
sort < $test_data_dir/wav.scp > $test_data_dir/wav.sorted.scp

echo $(date) "wav-copy train"
wav-copy scp:$train_data_dir/wav.sorted.scp ark,scp:data/train/wav.ark,data/train/wav.scp
echo $(date) "wav-copy test"
wav-copy scp:$test_data_dir/wav.sorted.scp ark,scp:data/test/wav.ark,data/test/wav.scp

echo $(date) "Start removing dirs"
rm -Rf $test_data_dir $train_data_dir

