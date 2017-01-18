#!/bin/bash

set -euo pipefail
. ./path.sh
module load m2m-aligner


in_lexicon=$1

mkdir -p data/m2m
LC_ALL=en_US.UTF-8 local/lexfilter.py < $in_lexicon > data/m2m/lexicon.txt
paste <(cut -f1 data/m2m/lexicon.txt | sed 's/\(.\)/\1 /g') <(cut -f2 data/m2m/lexicon.txt) > data/m2m/lexicon.news
m2m-aligner -i data/m2m/lexicon.news








