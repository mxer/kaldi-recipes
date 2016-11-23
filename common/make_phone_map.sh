#!/bin/bash

export LC_ALL=C

# begin configuration section
# end configuration section

[ -f path.sh ] && . ./path.sh;

. utils/parse_options.sh

if [ $# != 2 ]; then
  echo "Usage: "
  echo "  $0 [options] <old-lang-dir> <new-lang-dir>"
  echo "e.g.:"
  exit 1;
fi


old_lang=$1
new_lang=$2

paste -d" " <(cut -f2 -d" " $old_lang/phones.txt) <(cut -f1 -d" " ${old_lang}/phones.txt | cut -f1 -d"_" | utils/apply_map.pl -f1 ${new_lang}/phones.txt) > $new_lang/phone_map
