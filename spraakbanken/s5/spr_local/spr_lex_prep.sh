#!/bin/bash

echo $(date) "Check the integrity of the lexicon"
wd=$(pwd)
(cd corpus && md5sum -c ${wd}/local/checksums/lex) || exit "The spraakbanken lexicon gave unexpected md5 sums"

data_dir=$(mktemp -d)

echo "Temporary directories (should be cleaned afterwards):" ${data_dir}

(cd corpus && cut -f3- -d" " ${wd}/local/checksums/lex | xargs tar xz --strip-components=1 -C ${data_dir} -f)

mkdir -p data/dict/

find ${data_dir} -type f -name "*.pron" | xargs cat | iconv -f CP1252 -t UTF-8 | local/spr_pron_to_std.py local/dict_prep/vowels local/dict_prep/consonants data/dict/nonsilence_phones.txt data/dict/extra_questions.txt  > ${data_dir}/prepped_lex
cat local/dict_prep/extradict ${data_dir}/prepped_lex | LC_ALL=C sort -u > data/dict/lexicon.txt

echo "SIL" > data/dict/silence_phones.txt
echo "NSN" >> data/dict/silence_phones.txt

echo "SIL" > data/dict/optional_silence.txt

rm -Rf ${data_dir}
