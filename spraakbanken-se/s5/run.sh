#!/bin/bash

. ./cmd.sh ## You'll want to change cmd.sh to something that will work on your system.
           ## This relates to the queue.

lang=${1:-se}

if [ ! -d "corpus" ]; then
 exit "The directory corpus needs to exist, with the corpus files from nb.no downloaded in it. This can be a symlinked directory" 
fi

if [ ! -d "data-prep" ]; then
 exit "The directory data-prep needs to exist. Either do 'mkdir data-prep', or make it a symlink to somewhere"
fi

local/spr_data_prep.sh ${lang} || exit "Could not prep corpus";

mfccdir=mfcc/${lang}

for set in "train" "test"; do
 steps/make_mfcc.sh --cmd "${train_cmd}" --nj 20 \
   data/${lang}/${set} exp/make_mfcc/${lang}/${set} ${mfccdir} || exit 1;
 steps/compute_cmvn_stats.sh data/${lang}/${set} exp/make_mfcc/${lang}/${set} ${mfccdir} || exit 1;

 utils/validate_data_dir.sh data/${lang}/${set} || exit "Directory data/${lang}/${set} was not properly set up"
done

