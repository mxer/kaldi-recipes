#!/bin/bash

. ./cmd.sh ## You'll want to change cmd.sh to something that will work on your system.
           ## This relates to the queue.

. ../../../util/slurm_dep_graph.sh

JOB_PREFIX=$(basename $(pwd))

function error_exit {
    echo "$1" >&2
    exit "${2:-1}"
}

set=test_kth
mfccdir=mfcc
numjobs=74

job make_corpus_${set} 4 4 NONE -- spr_local/spr_make_corpus.sh data/${set} ${set}
job mfcc_$set 4 4 make_corpus_$set -- steps/make_mfcc.sh --cmd "${base_cmd} --mem 50M" --nj ${numjobs} data/${set} exp/make_mfcc/${set} ${mfccdir}
job cmvn_$set 4 4 LAST      -- steps/compute_cmvn_stats.sh data/${set} exp/make_mfcc/${set} ${mfccdir}
job val_data_$set 4 4 LAST  -- utils/validate_data_dir.sh data/${set}
