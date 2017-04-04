#!/bin/bash
set -e

export LC_ALL=C

# Begin configuration section.
# End configuration options.

echo "$0 $@"  # Print the command line for logging

[ -f path.sh ] && . ./path.sh # source the path.
. parse_options.sh || exit 1;

if [ $# != 3 ]; then
   echo "usage: common/make_dict.sh vocab dict_in dir_out"
   echo "e.g.:  common/make_dict.sh data/segmenation/mj_1/vocab data/segmentation/mj_1/outlex data/dicts/mj_1"
   echo "main options (for others, see top of script file)"
   exit 1;
fi

vocab=$1
inlex=$2
outdir=$3

tmpdir=$(mktemp -d)
echo "Tmpdir: ${tmpdir}"
cat $vocab | grep -v "^<" | sed "s/^\+//" | sed "s/\+$//" | sed "s/^|//" | sed '/^\s*$/d' |  common/filter_lex.py $inlex - $tmpdir/found.lex $tmpdir/oov

cat data/lexicon/lexicon.txt definitions/dict_prep/lex | common/filter_lex.py - $tmpdir/oov ${tmpdir}/found2.lex ${tmpdir}/oov2

echo "$(wc -l ${tmpdir}/oov2) pronunciations are missing, estimating them with phonetisaurus"
phonetisaurus-g2pfst --print_scores=false --model=data/lexicon/g2p_wfsa --wordlist=${tmpdir}/oov2 | sed "s/\t$/\t#dis/" > ${tmpdir}/found3.lex

cat $tmpdir/found.lex $tmpdir/found2.lex $tmpdir/found3.lex > $tmpdir/all.lex
cat <(sed "s/^/|/" $tmpdir/all.lex) <(sed "s/^/\+/" $tmpdir/all.lex) <(sed "s/	/+	/" $tmpdir/all.lex) <(sed "s/	/+	/" $tmpdir/all.lex | sed "s/^/\+/") $tmpdir/all.lex  > $tmpdir/all_var.lex

mkdir -p ${outdir}
grep -v "^<" $vocab | sed '/^\s*$/d' | common/filter_lex.py $tmpdir/all_var.lex - - $tmpdir/oov3 | sort -u - definitions/dict_prep/lex <(echo "<w>	SIL") > ${outdir}/lexicon.txt

wc -l $tmpdir/oov3


echo "SIL" > ${tmpdir}/silence_phones.txt
cut -f2 definitions/dict_prep/lex >> ${tmpdir}/silence_phones.txt
sort -u < ${tmpdir}/silence_phones.txt > ${outdir}/silence_phones.txt

echo "SIL" > ${outdir}/optional_silence.txt

cut -f2- < ${outdir}/lexicon.txt | tr ' ' '\n' | sed 's/^[ \t]*//;s/[ \t]*$//' | sed '/^$/d' | sort -u | grep -v -F -f ${outdir}/silence_phones.txt > ${outdir}/nonsilence_phones.txt

#rm -Rf ${tmpdir}
