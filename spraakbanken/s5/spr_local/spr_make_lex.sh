#!/bin/bash
set -e
export LC_ALL=C

# Begin configuration section.
# End configuration options.

echo "$0 $@"  # Print the command line for logging

[ -f path.sh ] && . ./path.sh # source the path.
. parse_options.sh || exit 1;

if [ $# != 2 ]; then
   echo "usage: spr_local/spr_make_lex.sh out_dir vocab"
   echo "e.g.:  steps/spr_make_lex.sh data/lexicon data/train/vocab"
   echo "main options (for others, see top of script file)"
   exit 1;
fi

outdir=$1
vocab=$2

tmp_dir=$(mktemp -d)

echo "Temporary directories (should be cleaned afterwards):" ${tmp_dir}

spr_local/filter_lex.py data-prep/lexicon/lexicon.txt ${vocab} ${tmp_dir}/known.lex ${tmp_dir}/oov

phonetisaurus-g2pfst --print_scores=false --model=data-prep/lexicon/g2p_wfsa --wordlist=${tmp_dir}/oov | grep -P -v "\t$" > ${tmp_dir}/oov.lex

echo -e "<UNK>\tNSN" > ${tmp_dir}/unk.lex
cat ${tmp_dir}/known.lex ${tmp_dir}/oov.lex ${tmp_dir}/unk.lex | sort -u > ${outdir}/lexicon.txt

echo "SIL" > ${outdir}/silence_phones.txt
echo "NSN" >> ${outdir}/silence_phones.txt

echo "SIL" > ${outdir}/optional_silence.txt

spr_local/make_dict_files.py ${outdir} local/dict_prep/vowels local/dict_prep/consonants



rm -Rf ${tmp_dir}
