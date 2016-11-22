#!/bin/bash

. ./cmd.sh ## You'll want to change cmd.sh to something that will work on your system.
           ## This relates to the queue.

. common/slurm_dep_graph.sh

JOB_PREFIX=$(cat id)_

export LC_ALL=C

for extra in "" "_pr" "_tc" "_pr_tc" "_log_pr" "_log_pr_tc"; do
for s in $(seq 400 400 2000); do
for a in $(seq 1 8); do
 
cat definitions/dict_prep/lex >> data/dicts/morphjoin${extra}_${s}_${a}/lexicon.txt
sort -u -o data/dicts/morphjoin${extra}_${s}_${a}/lexicon.txt data/dicts/morphjoin${extra}_${s}_${a}/lexicon.txt
cp data/dict/*sil* data/dicts/morphjoin${extra}_${s}_${a}/

job prep_lang_${s}_${a} 5 2 NONE utils/prepare_lang.sh --phone-symbol-table data/lang/phones.txt data/dicts/morphjoin${extra}_${s}_${a} "<UNK>" data/langs/morphjoin${extra}_${s}_${a}/local data/langs/morphjoin${extra}_${s}_${a}

dim=5
job recog_lang_${s}_${a} 3 2 LAST common/make_recog_lang.sh --inwordbackoff true data/lm/morphjoin${extra}_${s}_${a}/vk/${dim}M/arpa.xz data/langs/morphjoin${extra}_${s}_${a} data/recog_langs/morphjoin${extra}_${s}_${a}_${dim}M

dim=50
job recog_lang_${s}_${a} 25 2 LAST common/make_recog_lang.sh --inwordbackoff true data/lm/morphjoin${extra}_${s}_${a}/vk/${dim}M/arpa.xz data/langs/morphjoin${extra}_${s}_${a} data/recog_langs/morphjoin${extra}_${s}_${a}_${dim}M

job const_arpa_${s}_${a} 12 2 LAST common/build_const_arpa_lm.sh data/lm/morphjoin${extra}_${s}_${a}/vk/50M/arpa.xz data/recog_langs/morphjoin${extra}_${s}_${a}_50M
done
done
done

