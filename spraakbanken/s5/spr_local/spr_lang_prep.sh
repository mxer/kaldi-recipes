#!/bin/bash

phonetisaurus-g2pfst --print_scores=false --model=dict/g2p/wfsa --wordlist=data/train/known_oov.txt | grep -v "     $" > data/train/known_oov.lex
cat data/train/known_oov.lex data/dict_nst/lexicon.txt | LC_ALL=C sort -u data/dict/lexicon.txt

utils/prepare_lang.sh data/dict "<UNK>" data/local/lang data/lang

