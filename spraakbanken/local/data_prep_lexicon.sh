#!/bin/bash
set -e

export LC_ALL=C

# Begin configuration section.
# End configuration options.

echo "$0 $@"  # Print the command line for logging

[ -f path.sh ] && . ./path.sh # source the path.
. parse_options.sh || exit 1;

if [ $# != 1 ]; then
   echo "usage: spr_local/spr_dp_lex.sh spr_dir out_dir "
   echo "e.g.:  steps/spr_dp_lex.sh \$GROUP_DIR/c/spraakbanken data-prep/lexicon_lc_na"
   echo "main options (for others, see top of script file)"
   exit 1;
fi

spr_dir=$1
out_dir=$2

echo $(date) "Check the integrity of the archives"
wd=$(pwd)
(cd ${spr_dir} && md5sum -c ${wd}/definitions/checksums/lex) || exit 1

data_dir=$(mktemp -d)

echo "Temporary directories (should be cleaned afterwards):" ${data_dir}

(cd ${spr_dir} && cut -f3- -d" " ${wd}/definitions/checksums/lex | xargs tar xz --strip-components=1 -C ${data_dir} -f)

echo $(date) "Transform lexicon"
opt1=""
opt2=""
if $lowercase; then
    opt1="--lowercase"
fi
if ! $accents; then
    opt2="--no-accents"
fi

spr_local/spr_prep_lex.py ${data_dir} ${data_dir}/lexicon.txt definitions/dict_prep/vowels definitions/dict_prep/consonants --lowercase --no-accents

mkdir -p ${out_dir}
sort -u < ${data_dir}/lexicon.txt > ${out_dir}/lexicon.txt

echo $(date) "Take out the trash"
rm -Rf ${data_dir}
