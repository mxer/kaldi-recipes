#!/bin/bash


corpus_dir=$GROUP_DIR/c/cgn

export LC_ALL=C

mkdir -p data/dev
mkdir -p data/train
mkdir -p data/test

train_data_dir=$(mktemp -d)

trap "{ rm -Rf $train_data_dir ; exit 255; }" EXIT

echo $(date) "Find files"

find $corpus_dir/data/audio/wav/comp-o/ -name "*.wav" >  $train_data_dir/wavlist
find $corpus_dir/data/annot/text/ort/comp-o/ -name "*.ort.gz" > $train_data_dir/ortlist

echo $(date) "Make lists"
local/make_wav_txt_lists.py $train_data_dir/wavlist $train_data_dir/ortlist $train_data_dir/text $train_data_dir/wav.scp $train_data_dir/segments $train_data_dir/utt2speak

echo $(date) "sorting"

grep "^.....9" $train_data_dir/text | sort > data/test/text
grep "^.....8" $train_data_dir/text | sort > data/dev/text
grep "^.....[0-7]" $train_data_dir/text | sort > data/train/text

grep "^.....9" $train_data_dir/utt2speak | sort > data/test/utt2speak
grep "^.....8" $train_data_dir/utt2speak | sort > data/dev/utt2speak
grep "^.....[0-7]" $train_data_dir/utt2speak | sort > data/train/utt2speak

grep "^.....9" $train_data_dir/segments | sort > data/test/segments
grep "^.....8" $train_data_dir/segments | sort > data/dev/segments
grep "^.....[0-7]" $train_data_dir/segments | sort > data/train/segments

cut -f2 -d" " data/test/segments | grep -f - $train_data_dir/wav.scp | sort > data/test/wav.scp
cut -f2 -d" " data/dev/segments | grep -f - $train_data_dir/wav.scp | sort > data/dev/wav.scp
cut -f2 -d" " data/train/segments | grep -f - $train_data_dir/wav.scp | sort > data/train/wav.scp

echo $(date) "Start removing dirs"
rm -Rf $train_data_dir


