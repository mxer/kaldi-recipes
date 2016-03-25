#!/bin/bash
# Begin configuration section.
# End configuration options.

echo "$0 $@"  # Print the command line for logging

[ -f path.sh ] && . ./path.sh # source the path.
. parse_options.sh || exit 1;

if [ $# != 3 ]; then
   echo "usage: spr_local/spr_make_lex.sh out_dir vocab"
   echo "e.g.:  steps/spr_make_lex.sh data/lexicon data/train/words"
   echo "main options (for others, see top of script file)"
   exit 1;
fi

outdir=$1
vocab=$2

