#!/bin/bash
set -e

export LC_ALL=C

# Begin configuration section.
# End configuration options.

echo "$0 $@"  # Print the command line for logging

[ -f path.sh ] && . ./path.sh # source the path.
. parse_options.sh || exit 1;

if [ $# != 2 ]; then
   echo "usage: common/train_m2m.sh lexicon m2mdir"
   echo "e.g.:  common/train_m2m.sh data/lexicon/lexicon.txt data/m2m/fix2"
   echo "main options (for others, see top of script file)"

   exit 1;
fi

inlex=$1
outdir=$2


if [ -e ${outdir} ]; then rm -Rf ${outdir}; fi
mkdir -p ${outdir}

grep -v "+" $inlex | common/lex2mtmlex.py - ${outdir}/lex
m2m-aligner --sepInChar "+" --delX --maxY 6 --maxX 3 -i ${outdir}/lex -o ${outdir}/aligned