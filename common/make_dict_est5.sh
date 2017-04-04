#!/bin/bash
set -e

export LC_ALL=C

# Begin configuration section.
# End configuration options.

echo "$0 $@"  # Print the command line for logging

[ -f path.sh ] && . ./path.sh # source the path.
. parse_options.sh || exit 1;

if [ $# != 2 ]; then
   echo "usage: common/make_dict.sh vocab dir_out"
   echo "e.g.:  common/make_dict.sh data/train/vocab data/dict"
   echo "main options (for others, see top of script file)"
   exit 1;
fi

vocab=$1
outdir=$2
mkdir -p $outdir

tmpdir=$(mktemp -d --tmpdir=$outdir)
echo "Tmpdir: ${tmpdir}"
cat data/lexicon/lexicon.txt definitions/dict_prep/lex | common/filter_lex.py - ${vocab} ${tmpdir}/found.lex ${tmpdir}/oov

grep -v "[A-Z]" $tmpdir/oov > $tmpdir/oov_low
grep "[A-Z]" $tmpdir/oov > $tmpdir/oov_high

echo "$(wc -l ${tmpdir}/oov) pronunciations are missing, estimating them with phonetisaurus"
phonetisaurus-g2pfst --print_scores=false --model=data/lexicon/g2p_wfsa --wordlist=${tmpdir}/oov_low | sed "s/\t$/\tSPN/" > ${tmpdir}/oov_low.lex


echo "$(wc -l ${tmpdir}/oov) pronunciations are missing, estimating them with e2-g2p"
LC_ALL=en_US.UTF-8 vocab2dict-ee.sh < ${tmpdir}/oov_high | sed "s/\t$/\tSPN/" > ${tmpdir}/oov_high.lex


cat ${tmpdir}/found.lex ${tmpdir}/oov_high.lex ${tmpdir}/oov_low.lex definitions/dict_prep/lex | sort -u > ${outdir}/lexicon.txt
rm -f ${outdir}/lexiconp.txt

echo "SIL" > ${tmpdir}/silence_phones.txt
cut -f2 definitions/dict_prep/lex >> ${tmpdir}/silence_phones.txt
sort -u < ${tmpdir}/silence_phones.txt > ${outdir}/silence_phones.txt

echo "SIL" > ${outdir}/optional_silence.txt

cut -f2- < ${outdir}/lexicon.txt | tr ' ' '\n' | sed 's/^[ \t]*//;s/[ \t]*$//' | sed '/^$/d' | sort -u | grep -v -F -f ${outdir}/silence_phones.txt > ${outdir}/nonsilence_phones.txt

#rm -Rf ${tmpdir}
