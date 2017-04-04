#!/bin/bash
set -e

export LC_ALL=C

# Begin configuration section.
cleanup=true
# End configuration options.

echo "$0 $@"  # Print the command line for logging

[ -f path.sh ] && . ./path.sh # source the path.
module load et-g2p

. parse_options.sh || exit 1;

if [ $# != 3 ]; then
   echo "usage: common/make_dict.sh vocab morfessor_model dir_out"
   echo "e.g.:  common/make_dict.sh data/train/vocab morfessor.txt data/dict"
   echo "main options (for others, see top of script file)"
   exit 1;
fi

vocab=$1
wordmap=$2
outdir=$3

mkdir -p ${outdir}
tmpdir=$(mktemp -d --tmpdir=$outdir)
echo "Tmpdir: ${tmpdir}"

LC_ALL=en_US.UTF-8 make_est_lex_m2m_stage1.py $wordmap lextest4/lexicon.news.m-mAlign.2-2.1-best.conYX.align > ${tmpdir}/m2m.lex
for i in $(seq 1 10); do
LC_ALL=en_US.UTF-8 make_est_lex_m2m_stage2.py $tmpdir/m2m.lex $wordmap lextest4/lexicon.txt >> ${tmpdir}/m2m.lex
sed -i "s/\t$/\tSPN/" ${tmpdir}/m2m.lex
LC_ALL=C sort -u -o $tmpdir/m2m.lex $tmpdir/m2m.lex
done

#LC_ALL=C sort -u -o ${tmpdir}/m2m.lex ${tmpdir}/m2m.lex

cat data/lexicon/lexicon.txt definitions/dict_prep/lex ${tmpdir}/m2m.lex | common/filter_lex.py - ${vocab} ${tmpdir}/found.lex ${tmpdir}/oov

echo "$(wc -l ${tmpdir}/oov) pronunciations are missing, estimating them with e2-g2p"
LC_ALL=en_US.UTF-8 vocab2dict-ee.sh < ${tmpdir}/oov | sed "s/\t$/\tSPN/" > ${tmpdir}/oov.lex

cat ${tmpdir}/found.lex ${tmpdir}/oov.lex definitions/dict_prep/lex | sort -u > ${outdir}/lexicon.txt
rm -f ${outdir}/lexiconp.txt

echo "SIL" > ${tmpdir}/silence_phones.txt
cut -f2 definitions/dict_prep/lex >> ${tmpdir}/silence_phones.txt
sort -u < ${tmpdir}/silence_phones.txt > ${outdir}/silence_phones.txt

echo "SIL" > ${outdir}/optional_silence.txt

cut -f2- < ${outdir}/lexicon.txt | tr ' ' '\n' | sed 's/^[ \t]*//;s/[ \t]*$//' | sed '/^$/d' | sort -u | grep -v -F -f ${outdir}/silence_phones.txt > ${outdir}/nonsilence_phones.txt

echo $cleanup
if $cleanup; then
rm -Rf ${tmpdir}
#else
#mv ${tmpdir} $outdir/lextmp
fi
