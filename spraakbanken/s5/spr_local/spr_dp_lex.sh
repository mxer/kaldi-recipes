#!/bin/bash
#SBATCH -t 4:00:00
#SBATCH --mem-per-cpu 30G

set -e

export LC_ALL=C

# Begin configuration section.
lowercase=false
accents=true
# End configuration options.

echo "$0 $@"  # Print the command line for logging

[ -f path.sh ] && . ./path.sh # source the path.
. parse_options.sh || exit 1;

if [ $# != 1 ]; then
   echo "usage: spr_local/spr_dp_lex.sh out_dir"
   echo "e.g.:  steps/spr_dp_lex.sh --lowercase true --accents false data-prep/lexicon_lc_na"
   echo "main options (for others, see top of script file)"
   echo "     --lowercase (true|false)   # Lowercase lexicon items"
   echo "     --accents (true|false)   # add accents to vowels"
   exit 1;
fi

if [ -d out_dir ]; then
    ok=0
    for f in "lexicon.txt" "g2p_wfsa"; do
        if [ ! -f data-prep/lexicon/$f ]; then
            ok=1
        fi
    done

    if [ $ok -eq 0 ]; then
        echo "There seems to be a lexicon in $out_dir, so we assume we don't need the original lexicon files. If data preparation fails, remove $out_dir and try again"
        exit 0
    fi
    rm -Rf $out_dir
fi

echo $(date) "Check the integrity of the archives"
wd=$(pwd)
(cd corpus && md5sum -c ${wd}/local/checksums/lex) || exit 1

data_dir=$(mktemp -d)

echo "Temporary directories (should be cleaned afterwards):" ${data_dir}

(cd corpus && cut -f3- -d" " ${wd}/local/checksums/lex | xargs tar xz --strip-components=1 -C ${data_dir} -f)

echo $(date) "Transform lexicon"
opt1="NONE"
opt2="noaccent"
if $lowercase; then
    opt1="lowercase"
fi
if $accents; then
    opt2="accent"
fi

spr_local/nst_lex_to_kaldi_format.py ${data_dir} ${data_dir}/lexicon.txt local/dict_prep/vowels local/dict_prep/consonants $opt1 $opt2

mkdir -p data-prep/lexicon
sort -u < ${data_dir}/lexicon.txt > ${out_dir}/lexicon.txt

echo $(date) "Train g2p"
phonetisaurus-align --s1s2_sep="]" --input=${out_dir}/lexicon.txt -ofile=${data_dir}/corpus | echo

estimate-ngram -s FixKN -o 7 -t ${data_dir}/corpus -wl ${data_dir}/arpa

phonetisaurus-arpa2wfst --lm=${data_dir}/arpa --ofile=${out_dir}/g2p_wfsa --split="]"

echo $(date) "Take out the trash"
rm -Rf ${data_dir}
