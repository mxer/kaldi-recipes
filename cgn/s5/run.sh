#!/bin/bash

. ./cmd.sh ## You'll want to change cmd.sh to something that will work on your system.
           ## This relates to the queue.

function error_exit {
    echo "$1" >&2
    exit "${2:-1}"
}

if [ ! -d "corpus" ]; then
 error_exit "The directory corpus needs to exist, with the corpus files (data, corex, doc_{English,Dutch}). This can be a symlinked directory"
fi

if [ ! -d "data-prep" ]; then
 error_exit "The directory data-prep needs to exist. Either do 'mkdir data-prep', or make it a symlink to somewhere"
fi

local/cgn_lex_prep.sh  || error_exit "Could not prep lexicon";
local/cgn_data_prep.sh || error_exit "Could not prep corpus";

mfccdir=mfcc

for set in "train" "dev" "test"; do
 steps/make_mfcc.sh --cmd "${train_cmd}" --nj 20 \
   data/${set} exp/make_mfcc/${set} ${mfccdir} || error_exit "make_mfcc failed";
 steps/compute_cmvn_stats.sh data/${set} exp/make_mfcc/${set} ${mfccdir} || error_exit "compute cmvn failed";

 utils/validate_data_dir.sh data/${set} || error_exit "Directory data/${set} was not properly set up"
done
