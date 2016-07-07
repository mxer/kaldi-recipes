#!/bin/bash
#SBATCH --gres=spindle:2
#SBATCH --tmp=500000

set -e

export LC_ALL=C

# Begin configuration section.
# End configuration options.

echo "$0 $@"  # Print the command line for logging

[ -f path.sh ] && . ./path.sh # source the path.
. parse_options.sh || exit 1;

if [ $# != 2 ]; then
   echo "usage: local/data_prep_audio.sh spraakbanken_dir data_prep_dir"
   echo "e.g.:  local/data_prep_audio.sh \$GROUP_DIR/c/spraakbanken some_data_prep_dir"
   echo "main options (for others, see top of script file)"
   exit 1;
fi

spr_dir=$1
result_dir=$2

find /tmp -maxdepth 1 -type d -ctime +1 -exec rm -rf {} +

echo $(date) "Check the integrity of the archives"
wd=$(pwd)
(cd ${spr_dir} && md5sum -c ${wd}/definitions/checksums/corpus) || exit "The spraakbankenarchives gave unexpected md5 sums"

raw_files_dir=$(mktemp -d)
data_dir=$(mktemp -d)

echo "Temporary directories (should be cleaned afterwards):" ${raw_files_dir} ${data_dir}

echo $(date) "Start untarring"
for t in $(cut -f3- -d" " definitions/checksums/corpus); do
    tar xzf ${spr_dir}/${t} --strip-components=3 -C ${raw_files_dir}
done

echo $(date) "Read the corpus"
local/spr_prep_corpus.py ${raw_files_dir} ${raw_files_dir}/wav.scp ${data_dir}

mkdir -p ${result_dir}

for f in $(ls -1 ${data_dir}); do
    sort < ${data_dir}/${f} > ${result_dir}/${f}
done

sort < ${raw_files_dir}/wav.scp > ${raw_files_dir}/sorted.scp


echo $(date) "Start wav-copy"
wav-copy scp:${raw_files_dir}/sorted.scp ark,scp:${result_dir}/wav.ark,${result_dir}/wav.scp

echo $(date) "Start removing temp dirs"
rm -Rf ${data_dir} ${raw_files_dir}
