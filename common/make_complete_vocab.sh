#!/bin/bash
#SBATCH --mem-per-cpu 2G
#SBATCH -p coin,short-ivb,short-wsm,short-hsw
#SBATCH -t 4:00:00
export LC_ALL=C
set -e -o pipefail


echo "$0 $@"  # Print the command line for logging


[ -f path.sh ] && . ./path.sh # source the path.
. parse_options.sh || exit 1;

if [ $# != 1 ]; then
   echo "usage: $0 segmdir"
   exit 1;
fi

dir=$1

. ./cmd.sh ## You'll want to change cmd.sh to something that will work on your system.


if [ ! -f $dir/complete_vocab ]; then
xzcat $dir/corpus.xz | tr ' ' '\n' | sort -u > $dir/complete_vocab
fi
