#!/bin/bash
set -e

export LC_ALL=C

# Begin configuration section.
# End configuration options.

echo "$0 $@"  # Print the command line for logging

[ -f path.sh ] && . ./path.sh # source the path.
. parse_options.sh || exit 1;

if [ $# != 2 ]; then
   echo "usage: local/data_prep_audio.sh spc_dir data_prep_dir"
   echo "e.g.:  local/data_prep.sh \$GROUP_DIR/c/speecon-fi/ data_prep_dir"
   echo "main options (for others, see top of script file)"
   exit 1;
fi

spc_dir=$1
result_dir=$2

raw_files_dir=$(mktemp -d)
data_dir=$(mktemp -d)

echo "Temporary directories (should be cleaned afterwards):" ${raw_files_dir} ${data_dir}

echo $(date) "Read the corpus"
local/spc_prep_corpus.py ${spc_dir} ${raw_files_dir}/wav.scp ${data_dir}

mkdir -p ${result_dir}

for f in $(ls -1 ${data_dir}); do
    sort < ${data_dir}/${f} > ${result_dir}/${f}
done

sort < ${raw_files_dir}/wav.scp > ${raw_files_dir}/sorted.scp


echo $(date) "Start wav-copy"
wav-copy scp:${raw_files_dir}/sorted.scp ark,scp:${result_dir}/wav.ark,${result_dir}/wav.scp

echo $(date) "Start removing temp dirs"
rm -Rf ${data_dir} ${raw_files_dir}
