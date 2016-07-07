#!/bin/bash

export LC_ALL=C

# Begin configuration section.
dataprep_dir=$WORK_DIR/data
# End configuration options.

echo "$0 $@"  # Print the command line for logging

[ -f path.sh ] && . ./path.sh # source the path.
. parse_options.sh || exit 1;

if [ $# != 2 ]; then
   echo "usage: local/data_prep.sh cgn_dir sonar_file"
   echo "e.g.:  local/data_prep.sh \$GROUP_DIR/c/cgn \$USER_DIR/c/SoNaR/20150602_SoNaRCorpus_NC_1.2.1.gz"
   echo "main options (for others, see top of script file)"
   echo "     --dataprep-dir director   # location to put the dataprep directory"

   exit 1;
fi

cgn_dir=$1
sonar_file=$2

if [ -d $dataprep_dir/cgn/kaldi-prep ]; then
    mv $dataprep_dir/cgn/kaldi-prep $dataprep_dir/cgn/kaldi-prep.$(date +%s)
fi

mkdir -p $dataprep_dir/cgn/kaldi-prep

command -v lfs > /dev/null && lfs setstripe -c 6 $dataprep_dir/cgn/kaldi-prep

if [ -e data-prep ]; then
rm data-prep
fi

ln -s $dataprep_dir/cgn/kaldi-prep data-prep


. ./cmd.sh
. common/slurm_dep_graph.sh
JOB_PREFIX=NL_
SLURM_EXTRA_ARGS="--gres=spindle:2"

job prep_audio 1 4 NONE -- local/data_prep_audio.sh $cgn_dir $dataprep_dir/cgn/kaldi-prep/audio
job prep_text 4 24 NONE -- local/data_prep_text.sh --cmd "$base_cmd" $sonar_file $dataprep_dir/cgn/kaldi-prep/text
job prep_lexicon 1 1 NONE -- local/data_prep_lexicon.sh $cgn_dir $dataprep_dir/cgn/kaldi-prep/lexicon

job g2p_train 1 1 prep_lexicon -- common/train_phonetisaurus.sh $dataprep_dir/cgn/kaldi-prep/lexicon/lexicon.txt $dataprep_dir/cgn/kaldi-prep/lexicon/g2p_wfsa
