#!/bin/bash
set -e

export LC_ALL=C

# Begin configuration section.
dataprep_dir=$WORK_DIR/data
lang=$(basename $(pwd))
# End configuration options.

echo "$0 $@"  # Print the command line for logging

[ -f path.sh ] && . ./path.sh # source the path.
. parse_options.sh || exit 1;

if [ $# != 3 ]; then
   echo "usage: local/data_prep.sh speechdat_dir speecon_dir kielipankkifile"
   echo "e.g.:  local/data_prep.sh $GROUP_DIR/c/speechdat-fi \$GROUP_DIR/c/speecon-fi \$GROUP_DIR/c/kielipankki/traindata.txt.gz"
   echo "main options (for others, see top of script file)"
   echo "     --dataprep-dir director   # location to put the dataprep directory"

   exit 1;
fi

spd_dir=$1
spc_dir=$2
kpk_file=$3

tdir=$dataprep_dir/speechdat-fi/kaldi-prep

if [ -d ${tdir} ]; then
    mv ${tdir} ${tdir}.$(date +%s)
fi

mkdir -p ${tdir}

command -v lfs > /dev/null && lfs setstripe -c 6 ${tdir}

if [ -e data-prep ]; then
rm data-prep
fi

ln -s ${tdir} data-prep


. ./cmd.sh
. common/slurm_dep_graph.sh

JOB_PREFIX=SPD_

job prep_audio 1 10 NONE -- local/data_prep_audio.sh ${spd_dir} ${tdir}/audio
job prep_text 4 1 NONE -- local/data_prep_text.sh ${kpk_file} ${tdir}/text
job prep_lexicon 1 1 NONE -- local/data_prep_lexicon.sh ${spc_dir} ${tdir}/lexicon

job g2p_train 2 4 prep_lexicon -- common/train_phonetisaurus.sh ${tdir}/lexicon/lexicon.txt ${tdir}/lexicon/g2p_wfsa
