#!/bin/bash
set -e
export LC_ALL=C

# Begin configuration section.
accents=true
# End configuration options.

echo "$0 $@"  # Print the command line for logging

[ -f path.sh ] && . ./path.sh # source the path.
. parse_options.sh || exit 1;

if [ $# != 3 ]; then
   echo "usage: spr_local/spr_make_lex.sh out_dir vocab lex_dir"
   echo "e.g.:  steps/spr_make_lex.sh data/lexicon data/train/vocab data-prep/lexicon_lc_na"
   echo "main options (for others, see top of script file)"
   echo "     --accents (true|false)   # add accents to vowels"
   exit 1;
fi

outdir=$1
vocab=$2
lexdir=$3

if [ -d ${outdir} ]; then rm -Rf ${outdir}; fi
mkdir ${outdir}

tmp_dir=$(mktemp -d)

echo "Temporary directories (should be cleaned afterwards):" ${tmp_dir}

spr_local/filter_lex.py ${lexdir}/lexicon.txt ${vocab} ${tmp_dir}/known.lex ${tmp_dir}/oov

phonetisaurus-g2pfst --print_scores=false --model=${lexdir}/g2p_wfsa --wordlist=${tmp_dir}/oov | sed "s/\t$/\tSIL/" > ${tmp_dir}/oov.lex #grep -P -v "\t$" > ${tmp_dir}/oov.lex

echo -e "<UNK>\tNSN" > ${tmp_dir}/unk.lex
cat ${tmp_dir}/known.lex ${tmp_dir}/oov.lex ${tmp_dir}/unk.lex | sort -u > ${outdir}/lexicon.txt

echo "SIL" > ${outdir}/silence_phones.txt
echo "NSN" >> ${outdir}/silence_phones.txt

echo "SIL" > ${outdir}/optional_silence.txt

opt=""
if ! $accents; then
opt="--no-accents"
fi

echo "$opt"
spr_local/make_dict_files.py $opt ${outdir} local/dict_prep/vowels local/dict_prep/consonants


rm -Rf ${tmp_dir}
