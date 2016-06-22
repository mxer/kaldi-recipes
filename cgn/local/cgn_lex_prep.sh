#!/bin/bash

echo $(date) "Check the integrity of the lexicon"
wd=$(pwd)
(cd corpus && md5sum -c ${wd}/local/checksums/lex) || exit "The cgn lexicon gave unexpected md5 sums"

data_dir=$(mktemp -d)

echo "Temporary directories (should be cleaned afterwards):" ${data_dir}

(cd corpus && cut -f3- -d" " ${wd}/local/checksums/lex | xargs cat > $data_dir/lex)

mkdir -p data/dict/

cat ${data_dir}/lex | local/cgn_pron_to_std.py local/dict_prep/vowels local/dict_prep/consonants data/dict/nonsilence_phones.txt data/dict/extra_questions.txt | LC_ALL=C sort -u > data/dict/lexicon.txt
echo "SIL" > data/dict/silence_phones.txt
echo "SPN" >> data/dict/silence_phones.txt

echo "SIL" > data/dict/optional_silence.txt

rm -Rf ${data_dir}