#!/bin/bash
set -e

export LC_ALL=C

# Begin configuration section.
# End configuration options.

echo "$0 $@"  # Print the command line for logging

[ -f path.sh ] && . ./path.sh # source the path.
. parse_options.sh || exit 1;

if [ $# != 3 ]; then
   echo "usage: common/make_dict.sh vocab dir_out m2m_aligned"
   echo "e.g.:  common/make_dict.sh data/train/vocab data/dict data/m2m/fix2/aligned"
   echo "main options (for others, see top of script file)"
   exit 1;
fi

vocab=$1
outdir=$2
m2m=$3

tmpdir=$(mktemp -d)
echo "Tmpdir: ${tmpdir}"

#First take the complete words that are already in the dict
cat data/lexicon/lexicon.txt definitions/dict_prep/lex | common/filter_lex.py - ${vocab} ${tmpdir}/complete_words.lex ${tmpdir}/oov1


common/make_m2m_lex.py ${m2m} ${tmpdir}/oov1 ${tmpdir}/partwords.lex ${tmpdir}/oov2

echo "$(wc -l ${tmpdir}/oov2) morphs were not found in dict and will be estimated by phonetisaurus"

phonetisaurus-g2pfst --print_scores=false --model=data/lexicon/g2p_wfsa --wordlist=${tmpdir}/oov2 | sed "s/\t$/\tSIL/" > ${tmpdir}/phonetisaurus.lex

mkdir -p ${outdir}
cat ${tmpdir}/complete_words.lex ${tmpdir}/partwords.lex ${tmpdir}/phonetisaurus.lex definitions/dict_prep/lex | sort -u > ${outdir}/lexicon.txt

echo "SIL" > ${tmpdir}/silence_phones.txt
cut -f2 definitions/dict_prep/lex >> ${tmpdir}/silence_phones.txt
sort -u < ${tmpdir}/silence_phones.txt > ${outdir}/silence_phones.txt

echo "SIL" > ${outdir}/optional_silence.txt

cut -f2- < ${outdir}/lexicon.txt | tr ' ' '\n' | sed 's/^[ \t]*//;s/[ \t]*$//' | sed '/^$/d' | sort -u | grep -v -F -f ${outdir}/silence_phones.txt > ${outdir}/nonsilence_phones.txt

rm -Rf ${tmpdir}
