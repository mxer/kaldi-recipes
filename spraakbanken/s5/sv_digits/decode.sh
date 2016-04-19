#!/bin/bash

. ./cmd.sh ## You'll want to change cmd.sh to something that will work on your system.
           ## This relates to the queue.

. ../../../util/slurm_dep_graph.sh

JOB_PREFIX=$(basename $(pwd))

function error_exit {
    echo "$1" >&2
    exit "${2:-1}"
}

mfccdir=mfcc
numjobs=10

numjobs=$(cat data/dev/spk2utt | wc -l)


echo "Changing numjobs to ${numjobs}"

numjobs=10
job mkg_mono0a 26 40 tra_mono0a,make_arpa_20k_2g \
 -- utils/mkgraph.sh --mono data/train_2gram exp/mono0a exp/mono0a/graph_train_2g
job dec_mono0a 6 40 LAST \
 -- steps/decode.sh --nj ${numjobs} --cmd "$decode_cmd" exp/mono0a/graph_train_2g data/test exp/mono0a/decode_train_2g_test


for model in "tri1"; do
    job mkg_${model} 26 40 tra_${model} \
     -- utils/mkgraph.sh data/train_2gram exp/${model} exp/${model}/graph_train_2g
    job dec_${model} 6 40 LAST \
     -- steps/decode.sh --nj ${numjobs} --cmd "$decode_cmd" exp/${model}/graph_train_2g data/test exp/${model}/decode_train_2g_test
done

