#!/bin/bash
# Begin configuration section.
# End configuration options.

echo "$0 $@"  # Print the command line for logging

[ -f path.sh ] && . ./path.sh # source the path.
. parse_options.sh || exit 1;

if [ $# != 3 ]; then
   echo "usage: spr_local/spr_make_arpa.sh out_dir vocabsize(in thousands) order"
   echo "e.g.:  steps/spr_make_arpa.sh data/20k_3gram 20 3"
   echo "main options (for others, see top of script file)"
   exit 1;
fi

outdir=$1
vocabsize=$2
order=$3
