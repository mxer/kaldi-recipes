#!/bin/bash
set -e

export LC_ALL=C

# Begin configuration section.
# End configuration options.

echo "$0 $@"  # Print the command line for logging

[ -f path.sh ] && . ./path.sh # source the path.
. parse_options.sh || exit 1;

if [ $# != 2 ]; then
   echo "usage: local/data_prep_audio.sh cgn_dir data_prep_dir"
   echo "e.g.:  local/data_prep.sh \$GROUP_DIR/c/cgn ~w/d/some_data_prep/audio"
   echo "main options (for others, see top of script file)"
   exit 1;
fi

cgn_dir=$1
result_dir=$2

raw_files_dir=$(mktemp -d)
data_dir=$(mktemp -d)

echo "Temporary audio directories (should be cleaned afterwards):" ${raw_files_dir} ${data_dir}

echo $(date) "Read the corpus"
local/cgn_prep_corpus.py $cgn_dir ${raw_files_dir}/wav.scp ${raw_files_dir}/segments ${data_dir}

mkdir -p $result_dir

for f in $(ls -1 ${data_dir}); do
    sort < ${data_dir}/${f} > $result_dir/${f}
done

sort < ${raw_files_dir}/wav.scp > ${raw_files_dir}/sorted.scp
sort < ${raw_files_dir}/segments > ${raw_files_dir}/segments.sorted


echo $(date) "Start extract-segments"
extract-segments --max-overshoot=3.0 scp:${raw_files_dir}/sorted.scp ${raw_files_dir}/segments.sorted ark,scp:${result_dir}/wav.ark,${result_dir}/wav.scp

echo $(date) "Start removing temp dirs"

rm -Rf ${data_dir} ${raw_files_dir}
