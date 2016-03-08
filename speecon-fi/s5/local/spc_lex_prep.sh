#!/bin/bash


mkdir -p data/dict/

cat data/train/text | local/spc_make_lex.py data/dict/nonsilence_phones.txt | LC_ALL=C sort -u > data/dict/lexicon.txt
echo "SIL" > data/dict/silence_phones.txt
echo "SPN" >> data/dict/silence_phones.txt

echo "SIL" > data/dict/optional_silence.txt

> data/dict/extra_questions.txt
