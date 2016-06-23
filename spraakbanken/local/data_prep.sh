#!/bin/bash

export LC_ALL=C

# Begin configuration section.
dataprep_dir=$WORK_DIR/data
lang=$(basename $(pwd))
# End configuration options.

echo "$0 $@"  # Print the command line for logging

[ -f path.sh ] && . ./path.sh # source the path.
. parse_options.sh || exit 1;

if [ $# != 1 ]; then
   echo "usage: local/data_prep.sh spraakbanken_dir"
   echo "e.g.:  local/data_prep.sh \$GROUP_DIR/c/spraakbanken \$USER_DIR/c/SoNaR/20150602_SoNaRCorpus_NC_1.2.1.gz"
   echo "main options (for others, see top of script file)"
   echo "     --dataprep-dir director   # location to put the dataprep directory"

   exit 1;
fi

spr_dir=$1

if [ -d $dataprep_dir/spraakbanken/$lang/kaldi-prep ]; then
    mv $dataprep_dir/spraakbanken/$lang/kaldi-prep $dataprep_dir/spraakbanken/$lang/kaldi-prep.$(date +%s)
fi

mkdir -p $dataprep_dir/spraakbanken/$lang/kaldi-prep

command -v lfs > /dev/null && lfs setstripe -c 6 $dataprep_dir/spraakbanken/$lang/kaldi-prep

if [ -e data-prep ]; then
rm data-prep
fi

ln -s $dataprep_dir/spraakbanken/$lang/kaldi-prep data-prep


. ./cmd.sh
. common/slurm_dep_graph.sh

JOB_PREFIX=$(basename $(pwd))

job prep_audio 4 24 NONE -- local/data_prep_audio.sh $spr_dir $dataprep_dir/spraakbanken/$lang/kaldi-prep/audio
job prep_text 4 24 NONE -- local/data_prep_text.sh $spr_dir $dataprep_dir/spraakbanken/$lang/kaldi-prep/text
job prep_lexicon 70 4 NONE -- local/data_prep_lexicon.sh $spr_dir $dataprep_dir/spraakbanken/$lang/kaldi-prep/lexicon

job g2p_train 25 24 prep_lexicon -- common/train_phonetisaurus.sh $dataprep_dir/spraakbanken/$lang/kaldi-prep/lexicon/lexicon.txt $dataprep_dir/spraakbanken/$lang/kaldi-prep/lexicon/g2p_wfsa
