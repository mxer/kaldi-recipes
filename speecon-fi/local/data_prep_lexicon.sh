#!/bin/bash

set -e

export LC_ALL=C

# Begin configuration section.
# End configuration options.

echo "$0 $@"  # Print the command line for logging

[ -f path.sh ] && . ./path.sh # source the path.
. parse_options.sh || exit 1;

if [ $# != 2 ]; then
   echo "usage: local/data_prep_audio.sh speecon_dir data_prep_dir"
   echo "e.g.:  local/data_prep.sh \$GROUP_DIR/c/speecon-fi ~w/d/some_data_prep"
   echo "main options (for others, see top of script file)"
   exit 1;
fi

spc_dir=$1
result_dir=$2

find ${spc_dir} -name "LEXICON.TBL" | xargs cat | local/spc_prep_lex.py | sort -u > ${result_dir}/lexicon.txt
