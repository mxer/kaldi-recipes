#!/bin/bash

set -e

LC_ALL=C

if [ -d data-prep/corpus ]; then
    ok=0
    for f in "wav.ark" "wav.scp" "text" "utt2spk" "utt2set" "utt2type"; do
        if [ ! -f data-prep/corpus/$f ]; then
            ok=1
        fi
    done

    if [ $ok -eq 0 ]; then
        echo "There seems to be a corpus in data-prep/corpus, so we assume we don't need the original corpus files. If data preparation fails, remove data-prep/corpus and try again"
        exit 0
    fi
    rm -Rf data-prep/corpus
fi

echo $(date) "Check the integrity of the archives"
wd=$(pwd)
(cd corpus && md5sum -c ${wd}/local/checksums/corpus) || exit "The spraakbankenarchives gave unexpected md5 sums"

raw_files_dir=$(mktemp -d)
data_dir=$(mktemp -d)

echo "Temporary directories (should be cleaned afterwards):" ${raw_files_dir} ${data_dir}

echo $(date) "Start untarring"
for t in $(cut -f3- -d" " local/checksums/corpus); do
    tar xzf corpus/${t} --strip-components=3 -C ${raw_files_dir}
done

echo $(date) "Read the corpus"
spr_local/corpus_to_kaldi_format.py ${raw_files_dir} ${raw_files_dir}/wav.scp ${data_dir}

mkdir -p data-prep/corpus

for f in $(ls -1 ${data_dir}); do
    sort < ${data_dir}/${f} > data-prep/corpus/${f}
done

sort < ${raw_files_dir}/wav.scp > ${raw_files_dir}/sorted.scp


echo $(date) "Start wav-copy"
wav-copy scp:${raw_files_dir}/sorted.scp ark,scp:data-prep/corpus/wav.ark,data-prep/corpus/wav.scp

echo $(date) "Start removing temp dirs"
rm -Rf ${data_dir} ${raw_files_dir}
