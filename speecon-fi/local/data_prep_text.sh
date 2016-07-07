#!/bin/bash
set -e

export LC_ALL=C

# Begin configuration section.
# End configuration options.

echo "$0 $@"  # Print the command line for logging

[ -f path.sh ] && . ./path.sh # source the path.
. parse_options.sh || exit 1;

if [ $# != 2 ]; then
   echo "usage: local/data_prep_audio.sh kielipankki_file data_prep_dir"
   echo "e.g.:  local/data_prep.sh \$GROUP_DIR/c/kielipankki/traindata.txt.gz ~w/d/some_data_prep/text"
   echo "main options (for others, see top of script file)"
   exit 1;
fi

kpk_file=$1
result_dir=$2

mkdir -p $result_dir

zcat $kpk_file | iconv -f ISO_8859-15 -t UTF-8 | xz > $result_dir/text.orig.xz
