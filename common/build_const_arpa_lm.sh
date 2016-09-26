#!/bin/bash

# Copyright 2014  Guoguo Chen
# Apache 2.0

# This script reads in an Arpa format language model, and converts it into the
# ConstArpaLm format language model.

# begin configuration section
# end configuration section

[ -f path.sh ] && . ./path.sh;

. utils/parse_options.sh

if [ $# != 2 ]; then
  echo "Usage: "
  echo "  $0 [options] <arpa-lm-path> <new-lang-dir>"
  echo "e.g.:"
  echo "  $0 data/local/lm/3-gram.full.arpa.xz data/lang_test_tgmed"
  echo "Options"
  exit 1;
fi

export LC_ALL=C

arpa_lm=$1
new_lang=$2


unk=`cat $new_lang/oov.int`
bos=`grep "<s>" $new_lang/words.txt | awk '{print $2}'`
eos=`grep "</s>" $new_lang/words.txt | awk '{print $2}'`
if [[ -z $bos || -z $eos ]]; then
  echo "$0: <s> and </s> symbols are not in $new_lang/words.txt"
  exit 1
fi


arpa-to-const-arpa --bos-symbol=$bos \
  --eos-symbol=$eos --unk-symbol=$unk \
  "xzcat $arpa_lm | utils/map_arpa_lm.pl $new_lang/words.txt|"  $new_lang/G.carpa  || exit 1;

exit 0;
