#!/bin/bash
set -e

export LC_ALL=C

# Begin configuration section.
# End configuration options.

echo "$0 $@"  # Print the command line for logging

[ -f path.sh ] && . ./path.sh # source the path.
. parse_options.sh || exit 1;

if [ $# != 2 ]; then
   echo "usage: local/make_dict.sh vocab dir_out"
   echo "e.g.:  local/make_dict.sh data/train/vocab data/dict"
   echo "main options (for others, see top of script file)"
   exit 1;
fi

vocab=$1
outdir=$2

tmpdir=$(mktemp -d)
echo "Tmpdir: ${tmpdir}"
cat data-prep/lexicon/lexicon.txt definitions/dict_prep/lex | common/filter_lex.py - ${vocab} ${tmpdir}/found.lex ${tmpdir}/oov

phonetisaurus-g2pfst --print_scores=false --model=data-prep/lexicon/g2p_wfsa --wordlist=${tmpdir}/oov | sed "s/\t$/\tSIL/" > ${tmpdir}/oov.lex

mkdir -p ${outdir}
cat ${tmpdir}/found.lex ${tmpdir}/oov.lex definitions/dict_prep/lex | sort -u > ${outdir}/lexicon.txt

echo "SIL" > ${tmpdir}/silence_phones.txt
cut -f2 definitions/dict_prep/lex > ${tmpdir}/silence_phones.txt
sort -u < ${tmpdir}/silence_phones.txt > ${outdir}/silence_phones.txt

awk '{print substr($0, index($0, $1))}' < ${outdir}/lexicon.txt | tr ' ' '\n' | sort -u | grep -v -F -f ${outdir}/silence_phones.txt > ${outdir}/nonsilence_phones.txt

rm -Rf ${tmpdir}
