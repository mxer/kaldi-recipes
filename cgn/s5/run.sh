#!/bin/bash

. ./cmd.sh ## You'll want to change cmd.sh to something that will work on your system.
           ## This relates to the queue.


if [ ! -d "corpus" ]; then
 exit "The directory corpus needs to exist, with the corpus files (data, corex, doc_{English,Dutch}). This can be a symlinked directory"
fi

if [ ! -d "data-prep" ]; then
 exit "The directory data-prep needs to exist. Either do 'mkdir data-prep', or make it a symlink to somewhere"
fi

local/cgn_data_prep.sh || exit "Could not prep corpus";

mfccdir=mfcc/

for set in "train" "dev" "test"; do
 steps/make_mfcc.sh --cmd "${train_cmd}" --nj 20 \
   data/${set} exp/make_mfcc/${set} ${mfccdir} || exit 1;
 steps/compute_cmvn_stats.sh data/${set} exp/make_mfcc/${set} ${mfccdir} || exit 1;

 utils/validate_data_dir.sh data/${set} || exit "Directory data/${set} was not properly set up"
done
