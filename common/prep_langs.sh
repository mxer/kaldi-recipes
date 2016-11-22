#!/bin/bash
set -e

export LC_ALL=C

# Begin configuration section.
recog_data=data/dev
model=exp/chain_cleaned/tdnna_sp_bi
# End configuration options.

echo "$0 $@"  # Print the command line for logging

. common/slurm_dep_graph.sh

[ -f path.sh ] && . ./path.sh # source the path.
. parse_options.sh || exit 1;

if [ $# != 0 ]; then
   echo "usage: common/lm_and_recog.sh langdir segmentation"
   echo "e.g.:  common/lm_and_recog.sh langdir segmentation"
   echo "main options (for others, see top of script file)"
   exit 1;
fi

pdp=true
if [ -f definitions/position_dependent_phones ]; then
  pdp=$(cat definitions/position_dependent_phones)
fi


for f in $(ls -1 data/dicts); do
echo $f
if [ ! -f data/dicts/${f}/lexicon.txt ]; then
echo "lexicon.txt missing"
continue
fi

if [ -f data/langs/${f}/L.fst ]; then
echo "L alreay exists"
continue
fi

job prep_lang_${f} 4 1 NONE common/prepare_lang_morph.sh --position-dependent-phones $pdp --phone-symbol-table data/lang/phones.txt data/dicts/${f} "<UNK>" data/langs/${f}/local data/langs/${f}
done
