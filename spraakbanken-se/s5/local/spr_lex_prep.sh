#!/usr/bin/bash

lang=$1

echo $(date) "Check the integrity of the lexicon"
wd=$(pwd)
(cd corpus && md5sum -c ${wd}/local/checksums/lex_${lang}) || exit "The spraakbanken ${set} archives gave unexpected md5 sums"

data_dir=$(mktemp -d)

echo "Temporary directories (should be cleaned afterwards):" ${data_dir}

cut -f3- -d" " local/checksums/lex_${lang} | xargs tar xz --strip-components=1 -C ${data_dir} -f

mkdir -p data/${lang}/dict/
find ${data_dir} -name "*.pron" | xargs cat | iconv -f CP1252 -t UTF-8 | local/spr_pron_to_std.py local/dict_prep/${lang}_vowels local/dict_prep/${lang}_consonants 2> /dev/null | sort -u > data/${lang}/dict/lexicon.txt

rm -Rf ${data_dir}