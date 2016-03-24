#!/bin/bash

set -e

LC_ALL=C

if [ -d data-prep/lexicon ]; then
    ok=0
    for f in "lexicon.txt" "g2p_wfsa"; do
        if [ ! -f data-prep/lexicon/$f ]; then
            ok=1
        fi
    done

    if [ $ok -eq 0 ]; then
        echo "There seems to be a lexicon in data-prep/lexicon, so we assume we don't need the original lexicon files. If data preparation fails, remove data-prep/lexicon and try again"
        exit 0
    fi
    rm -Rf data-prep/lexicon
fi
echo $(date) "Check the integrity of the archives"
wd=$(pwd)
(cd corpus && md5sum -c ${wd}/local/checksums/lex) || exit 1

data_dir=$(mktemp -d)

echo "Temporary directories (should be cleaned afterwards):" ${data_dir}

(cd corpus && cut -f3- -d" " ${wd}/local/checksums/lex | xargs tar xz --strip-components=1 -C ${data_dir} -f)

echo $(date) "Transform lexicon"
spr_local/nst_lex_to_kaldi_format.py ${data_dir} ${data_dir}/lexicon.txt local/dict_prep/vowels local/dict_prep/consonants

sort -u < ${data_dir}/lexicon.txt > data/lexicon/lexicon.txt

echo $(date) "Train g2p"
phonetisaurus-align --s1s2_sep="]" --input=data/lexicon/lexicon.txt -ofile=${data_dir}/corpus | echo

estimate-ngram -s FixKN -o 7 -t ${data_dir}/corpus -wl ${data_dir}/arpa

phonetisaurus-arpa2wfst --lm=${data_dir}/arpa --ofile=data/lexicon/g2p_wfsa --split="]"

echo $(date) "Take out the trash"
rm -Rf ${data_dir}
