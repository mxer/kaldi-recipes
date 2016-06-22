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

dataset=dev
lm=20k_2gram
biglm=20k_5gram

numjobs=$(cat data/${dataset}/spk2utt | wc -l)
echo "Changing numjobs to ${numjobs}"

job split_data 4 40 NONE \
 -- utils/split_data.sh data/${dataset} $numjobs

am=mono0a
job mkg_${am} 26 40 split_data \
 -- utils/mkgraph.sh --mono data/${lm} exp/${am} exp/${am}/graph_${lm}
job dec_${am} 6 40 LAST \
 -- steps/decode.sh --nj ${numjobs} --cmd "$decode_cmd" exp/${am}/graph_${lm} data/${dataset} exp/${am}/decode_${lm}_${dataset}
job dec_bl_${am} 6 40 mkg_${am} \
 -- steps/decode_biglm.sh --nj ${numjobs} --cmd "$decode_cmd" exp/${am}/graph_${lm} data/${lm}/G.fst data/${biglm}/G.fst data/${dataset} exp/${am}/decode_${lm}_bl_${biglm}
job dec_rs_${am} 6 40 dec_${am} \
 -- steps/lmrescore.sh --cmd "$decode_cmd" data/${lm} data/${biglm} data/${dataset} exp/${am}/decode_${lm}_${dataset} exp/${am}/decode_${lm}_rs_${biglm}
prev=$am
for am in "tri1" "tri2a" "tri2b"; do
    job mkg_${am} 26 40 split_data,mkg_${prev} \
     -- utils/mkgraph.sh data/${lm} exp/${am} exp/${am}/graph_${lm}
    job dec_${am} 6 40 LAST \
     -- steps/decode.sh --nj ${numjobs} --cmd "$decode_cmd" exp/${am}/graph_${lm} data/${dataset} exp/${am}/decode_${lm}_${dataset}
    job dec_bl_${am} 6 40 mkg_${am} \
     -- steps/decode_biglm.sh --nj ${numjobs} --cmd "$decode_cmd" exp/${am}/graph_${lm} data/${lm}/G.fst data/${biglm}/G.fst data/${dataset} exp/${am}/decode_${lm}_bl_${biglm}
    job dec_rs_${am} 6 40 dec_${am} \
     -- steps/lmrescore.sh --cmd "$decode_cmd" data/${lm} data/${biglm} data/${dataset} exp/${am}/decode_${lm}_${dataset} exp/${am}/decode_${lm}_rs_${biglm}
    prev=$am
done

for am in "tri3b" "tri4a" "tri4b"; do
    job mkg_${am} 26 40 split_data,mkg_${prev} \
     -- utils/mkgraph.sh data/${lm} exp/${am} exp/${am}/graph_${lm}
    job dec_${am} 6 40 LAST \
     -- steps/decode_fmllr.sh --nj ${numjobs} --cmd "$decode_cmd" exp/${am}/graph_${lm} data/${dataset} exp/${am}/decode_${lm}_${dataset}
    job dec_rs_${am} 6 40 dec_${am} \
     -- steps/lmrescore.sh --cmd "$decode_cmd" data/${lm} data/${biglm} data/${dataset} exp/${am}/decode_${lm}_${dataset} exp/${am}/decode_${lm}_rs_${biglm}
    prev=$am
done
