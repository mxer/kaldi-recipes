#!/bin/bash

export LC_ALL=C

lang=${1:-sv}

echo $(date) "Check the integrity of the lexicon"
wd=$(pwd)
(cd corpus && md5sum -c ${wd}/local/checksums/lex_${lang}) || exit "The spraakbanken ${set} archives gave unexpected md5 sums"

data_dir=$(mktemp -d)

echo "Temporary directories (should be cleaned afterwards):" ${data_dir}

(cd corpus && cut -f3- -d" " ${wd}/local/checksums/lex_${lang} | xargs tar xz --strip-components=1 -C ${data_dir} -f)

mkdir -p data/${lang}/dict/
find ${data_dir} -type f -name "*.pron" | xargs cat | iconv -f CP1252 -t UTF-8 | local/spr_pron_to_std.py local/dict_prep/${lang}_vowels local/dict_prep/${lang}_consonants | sort -u > data/${lang}/dict/lexicon.txt

rm -Rf ${data_dir}
