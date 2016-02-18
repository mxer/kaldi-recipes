#!/bin/bash


corpus_dir=$GROUP_DIR/c/cgn

export LC_ALL=C

mkdir -p data/dev
mkdir -p data/train
mkdir -p data/test

train_data_dir=$(mktemp -d)

find $corpus_dir/data/audio/wav/comp-o/ -name "*.wav" >  $train_data_dir/wavlist
find $corpus_dir/data/annot/text/ort/comp-o/ -name "*.wav" > $train_data_dir/ortlist

local/make_wav_txt_lists.py $train_data_dir/wavlist $train_data_dir/ortlist $train_data_dir/text $train_data_dir/wav.scp $train_data_dir/segments $train_data_dir/utt2speak

grep "^.....9" $train_data_dir/text > data/test/text
grep "^.....8" $train_data_dir/text > data/dev/text
grep "^.....[0-7]" $train_data_dir/text > data/train/text

grep "^.....9" $train_data_dir/utt2speak > data/test/utt2speak
grep "^.....8" $train_data_dir/utt2speak > data/dev/utt2speak
grep "^.....[0-7]" $train_data_dir/utt2speak > data/train/utt2speak

grep "^.....9" $train_data_dir/segments > data/test/segments
grep "^.....8" $train_data_dir/segments > data/dev/segments
grep "^.....[0-7]" $train_data_dir/segments > data/train/segments

cut -f2 -d" " data/test/segments | grep -f - $train_data_dir/wav.scp > data/test/wav.scp
cut -f2 -d" " data/dev/segments | grep -f - $train_data_dir/wav.scp > data/dev/wav.scp
cut -f2 -d" " data/train/segments | grep -f - $train_data_dir/wav.scp > data/train/wav.scp




