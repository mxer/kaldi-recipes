#!/bin/bash


export LC_ALL=C

if [ -f data-prep/train/wav.scp ]; then
   echo "data-prep/train/wav.scp exists, so we assume we don't need the original corpus files. If data preparation fails, remove data-prep/* and try again"
else

data_dir=$(mktemp -d)

echo "Temporary directories (should be cleaned afterwards):" ${data_dir}


for set in "train" "dev" "eval"; do

echo $(date) "Make lists ${set}"
local/make_wav_txt_lists.py corpus/ local/dataset_def/${set} local/dataset_def/whitelist_${set} ${data_dir}/text ${data_dir}/wav.scp ${data_dir}/utt2spk


mkdir -p data-prep/${set}
echo $(date) "sorting (${set})"

LC_ALL=C sort < ${data_dir}/text > data-prep/${set}/text
LC_ALL=C sort < ${data_dir}/utt2spk > data-prep/${set}/utt2spk
LC_ALL=C sort < ${data_dir}/wav.scp > ${data_dir}/wav.${set}.scp

echo $(date) "wav-copy"
wav-copy scp:${data_dir}/wav.${set}.scp ark,scp:data-prep/${set}/wav.ark,data-prep/${set}/wav.scp

done  # test train for-loop

echo $(date) "Start removing temp dirs"

rm -Rf ${data_dir}

fi  # Now data-prep exists and is filled

for set in "train" "dev" "eval"; do
  mkdir -p data/${set}
  cp data-prep/${set}/wav.scp data/${set}
  cp data-prep/${set}/utt2spk data/${set}

  local/spc_text_to_lexform.py data-prep/${set}/text data/${set}/text

  utils/utt2spk_to_spk2utt.pl data/${set}/utt2spk > data/${set}/spk2utt
done

