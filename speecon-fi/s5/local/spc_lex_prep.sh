#!/bin/bash


mkdir -p data/dict/


iconv -f ISO_8859-15 -t UTF-8 corpus/TABLE/LEXICON.TBL | local/spc_make_lex.py data/dict/nonsilence_phones.txt | LC_ALL=C sort -u > data/dict/lexicon.txt
echo "SIL" > data/dict/silence_phones.txt
echo "NSN" >> data/dict/silence_phones.txt

echo "SIL" > data/dict/optional_silence.txt

> data/dict/extra_questions.txt
