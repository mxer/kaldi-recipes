#!/bin/bash

set -e

LC_ALL=C

if [ -d data-prep/ngram ]; then
    ok=0
    for f in "1count" "2count"; do
        if [ ! -f data-prep/ngram/$f ]; then
            ok=1
        fi
    done

    if [ $ok -eq 0 ]; then
        echo "There seems to be a lm in data-prep/ngram, so we assume we don't need the original ngram files. If data preparation fails, remove data-prep/ngram and try again"
        exit 0
    fi
    rm -Rf data-prep/ngram
fi
echo $(date) "Check the integrity of the archives"
wd=$(pwd)
(cd corpus && md5sum -c ${wd}/local/checksums/ngram) || exit 1

data_dir=$(mktemp -d)

echo "Temporary directories (should be cleaned afterwards):" ${data_dir}

(cd corpus && cut -f3- -d" " ${wd}/local/checksums/ngram | xargs tar xz --strip-components=1 -C ${data_dir} -f)

echo $(date) "Copy files to right locations"

spr_local/swap_ngram_counts.py ${data_dir}/ngram1-1.frk data-prep/ngram/vocab

order=1
while [ -f "${data_dir}/ngram${order}.srt" ]; do
spr_local/swap_ngram_counts.py ${data_dir}/ngram${order}.srt data-prep/ngram/${order}count
done


echo $(date) "Take out the trash"
rm -Rf ${data_dir}
