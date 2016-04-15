#!/bin/bash
#SBATCH -t 1-00:00:00

set -e

export LC_ALL=C

if [ -d data-prep/corpus ]; then
    ok=0
    for f in "wav.ark" "wav.scp" "text.orig"  "utt2spk" "utt2type"; do
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

raw_files_dir=$(mktemp -d)
data_dir=$(mktemp -d)

echo "Temporary directories (should be cleaned afterwards):" ${raw_files_dir} ${data_dir}

echo $(date) "Read the corpus"
local/corpus_to_kaldi_format.py corpus ${raw_files_dir}/wav.scp ${raw_files_dir}/segments ${data_dir}

mkdir -p data-prep/corpus

for f in $(ls -1 ${data_dir}); do
    sort < ${data_dir}/${f} > data-prep/corpus/${f}
done

sort < ${raw_files_dir}/wav.scp > ${raw_files_dir}/sorted.scp
sort < ${raw_files_dir}/segments > ${raw_files_dir}/segments.sorted


echo $(date) "Start extract-segments"
extract-segments --max-overshoot 3 scp:${raw_files_dir}/sorted.scp ${raw_files_dir}/segments.sorted ark,scp:data-prep/corpus/wav.ark,data-prep/corpus/wav.scp

echo $(date) "Start removing temp dirs"
rm -Rf ${data_dir} ${raw_files_dir}
