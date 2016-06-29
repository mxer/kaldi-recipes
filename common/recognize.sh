#!/bin/bash

export LC_ALL=C

# Begin configuration section.
# End configuration options.

echo "$0 $@"  # Print the command line for logging

[ -f path.sh ] && . ./path.sh # source the path.
. parse_options.sh || exit 1;

if [ $# != 5 ]; then
   echo "usage: common/train_varikn_model.sh corpus vocab d order outfile"
   echo "e.g.:  common/train_varikn_model.sh data-prep/text/text.orig.xz data/dicts/word_20k 0.05 3 data/word_lm/srilm_20k_3gram/arpa"
   echo "main options (for others, see top of script file)"

   exit 1;
fi