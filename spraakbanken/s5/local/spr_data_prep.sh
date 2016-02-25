#!/bin/bash

export LC_ALL=C

lang=${1:-sv}

if [ -f data-prep/${lang}/train/wav.scp ]; then
   echo "data-prep/${lang}/train/wav.scp exists, so we assume we don't need the original corpus files. If data preparation fails, remove data-prep/$lang and try again"
else

for set in "train" "test"; do

echo $(date) "Check the integrity of the archives"
wd=$(pwd)
(cd corpus && md5sum -c ${wd}/local/checksums/${set}_${lang}) || exit "The spraakbanken ${set} archives gave unexpected md5 sums"

mkdir -p data-prep/${lang}/${set}
data_dir=$(mktemp -d)

echo "Temporary directories (should be cleaned afterwards):" ${data_dir}
#trap "{ rm -Rf ${data_dir} ; exit 255; }" EXIT

echo $(date) "Start untarring"
for t in $(cut -f3- -d" " local/checksums/${set}_${lang}); do
    tar xzf corpus/${t} --strip-components=3 -C ${data_dir}
done

echo $(date) "make lists"
local/make_wav_txt_lists.py ${data_dir} ${data_dir}/text ${data_dir}/wav.scp ${data_dir}/utt2spk

echo $(date) "sorting"
sort < ${data_dir}/text > data-prep/${lang}/${set}/text
sort < ${data_dir}/utt2spk > data-prep/${lang}/${set}/utt2spk
sort < ${data_dir}/wav.scp > ${data_dir}/wav.sorted.scp


echo $(date) "wav-copy"
wav-copy scp:${data_dir}/wav.sorted.scp ark,scp:data-prep/${lang}/${set}/wav.ark,data-prep/${lang}/${set}/wav.scp

echo $(date) "Start removing temp dirs"
rm -Rf ${data_dir}

done  # test train for-loop

fi  # Now data-prep/$lang exists and is filled

for set in "train" "test"; do
  mkdir -p data/${lang}/${set}
  cp data-prep/${lang}/${set}/wav.scp data/${lang}/${set}
  cp data-prep/${lang}/${set}/utt2spk data/${lang}/${set}
  cp data-prep/${lang}/${set}/text data/${lang}/${set}

  #TODO make text in the desired format
  utils/utt2spk_to_spk2utt.pl data/${lang}/${set}/utt2spk > data/${lang}/${set}/spk2utt
done

