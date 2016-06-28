#!/bin/bash

set -e

export LC_ALL=C

# Begin configuration section.
# End configuration options.

echo "$0 $@"  # Print the command line for logging

[ -f path.sh ] && . ./path.sh # source the path.
. parse_options.sh || exit 1;

if [ $# != 2 ]; then
   echo "usage: local/data_prep_text.sh spr_dir data_prep_dir"
   echo "e.g.:  local/data_prep.sh \$GROUP_DIR/c/spraakbanken data-prep/text"
   echo "main options (for others, see top of script file)"
   exit 1;
fi

spr_dir=$1
result_dir=$2

find /tmp -maxdepth 1 -type d -ctime +1 -exec rm -rf {} +

echo $(date) "Check the integrity of the archives"
wd=$(pwd)
(cd ${spr_dir} && md5sum -c ${wd}/definitions/checksums/ngram) || exit 1

data_dir=$(mktemp -d)

echo "Temporary directories (should be cleaned afterwards):" ${data_dir}

(cd ${spr_dir} && cut -f3- -d" " ${wd}/definitions/checksums/ngram | xargs tar xz --strip-components=1 -C ${data_dir} -f)

echo $(date) "Copy files to right locations"

mkdir -p ${result_dir}

order=1
while [ -f "${data_dir}/ngram${order}.srt" ]; do
local/swap_ngram_counts.py ${data_dir}/ngram${order}.srt ${result_dir}/${order}count
order=$((order+1))
done


grep -h "<s> .* </s>" ${result_dir}/[2-5]count > $data_dir/input
cat ${result_dir}/6count >> $data_dir/input

counts-to-corpus < $data_dir/input | xz > ${result_dir}/text.orig.xz

echo $(date) "Take out the trash"
rm -Rf ${data_dir}

