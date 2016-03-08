#!/bin/bash

export LC_ALL=C

if [ -f data-prep/train/wav.scp ]; then
   echo "data-prep/train/wav.scp exists, so we assume we don't need the original corpus files. If data preparation fails, remove data-prep/* and try again"
else

data_dir=$(mktemp -d)

echo "Temporary directories (should be cleaned afterwards):" ${data_dir}

echo $(date) "Find files"

find corpus/data/audio/wav/comp-o/ -name "*.wav" >  ${data_dir}/wavlist
find corpus/data/annot/text/ort/comp-o/ -name "*.ort.gz" > ${data_dir}/ortlist


echo $(date) "Make lists"
local/make_wav_txt_lists.py ${data_dir}/wavlist ${data_dir}/ortlist ${data_dir}/text ${data_dir}/wav.scp ${data_dir}/segments ${data_dir}/utt2spk


for set in "train" "dev" "test"; do

mkdir -p data-prep/${set}
echo $(date) "sorting (${set})"

grep -f local/dataset_def/${set} ${data_dir}/text | sort > data-prep/${set}/text
grep -f local/dataset_def/${set} ${data_dir}/utt2spk | sort > data-prep/${set}/utt2spk
grep -f local/dataset_def/${set} ${data_dir}/segments | sort > data-prep/${set}/segments

cut -f2 -d" " data-prep/${set}/segments | grep -f - $data_dir/wav.scp | sort > $data_dir/wav.${set}.scp

echo $(date) "wav-copy"
wav-copy scp:${data_dir}/wav.${set}.scp ark,scp:data-prep/${set}/wav.ark,data-prep/${set}/wav.scp

echo $(date) "Start removing temp dirs"

done  # test train for-loop

rm -Rf ${data_dir}

fi  # Now data-prep exists and is filled

for set in "train" "dev" "test"; do
  mkdir -p data/${set}
  cp data-prep/${set}/wav.scp data/${set}
  cp data-prep/${set}/utt2spk data/${set}
  cp data-prep/${set}/segments data/${set}

  local/cgn_text_to_lexform.py data-prep/${set}/text data/${set}/text

  utils/utt2spk_to_spk2utt.pl data/${set}/utt2spk > data/${set}/spk2utt
done


