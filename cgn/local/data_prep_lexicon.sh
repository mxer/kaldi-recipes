#!/bin/bash
set -e

export LC_ALL=C

# Begin configuration section.
cmd=run.pl
# End configuration options.

echo "$0 $@"  # Print the command line for logging

[ -f path.sh ] && . ./path.sh # source the path.
. parse_options.sh || exit 1;

if [ $# != 2 ]; then
   echo "usage: local/data_prep_audio.sh cgn_dir data_prep_dir"
   echo "e.g.:  local/data_prep.sh \$GROUP_DIR/c/cgn ~w/d/some_data_prep"
   echo "main options (for others, see top of script file)"
   echo "     --cmd <cmd>                              # Command to run in parallel with"
   exit 1;
fi

cgn_dir=$1
result_dir=$2

echo $(date) "Check the integrity of the lexicon"
wd=$(pwd)
(cd $cgn_dir && md5sum -c ${wd}/definitions/checksums/lex) || exit "The cgn lexicon gave unexpected md5 sums"

data_dir=$(mktemp -d)

echo "Temporary lexicon directories (should be cleaned afterwards):" ${data_dir}

(cd ${cgn_dir} && cut -f3- -d" " ${wd}/definitions/checksums/lex | xargs cat > ${data_dir}/lex)

mkdir -p ${result_dir}

local/cgn_prep_lex.py --lowercase ${data_dir}/lex | sort -u > ${result_dir}/lexicon.txt

rm -Rf ${data_dir}
