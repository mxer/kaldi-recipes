#!/bin/bash

. ./cmd.sh ## You'll want to change cmd.sh to something that will work on your system.
           ## This relates to the queue.

. ../../../util/slurm_dep_graph.sh

JOB_PREFIX=$(basename $(pwd))

function error_exit {
    echo "$1" >&2
    exit "${2:-1}"
}

if [ ! -d "corpus" ]; then
 error_exit "The directory corpus needs to exist, with the corpus files from nb.no downloaded in it. This can be a symlinked directory"
fi

if [ ! -d "data-prep" ]; then
 error_exit "The directory data-prep needs to exist. Either do 'mkdir data-prep', or make it a symlink to somewhere"
fi

job lex_prep 4 4 NONE  -- spr_local/spr_lex_prep.sh
job g2p_train 30 4 LAST -- spr_local/spr_g2p_train.sh data/dict_nst/lexicon.txt data/g2p
job data_prep 4 4 NONE -- spr_local/spr_data_prep.sh

mfccdir=mfcc
numjobs=40

for set in "train" "test"; do
 job mfcc_$set 4 4 data_prep -- steps/make_mfcc.sh --cmd "${base_cmd} --mem 50M" --nj 20 data/${set} exp/make_mfcc/${set} ${mfccdir}
 job cmvn_$set 4 4 LAST      -- steps/compute_cmvn_stats.sh data/${set} exp/make_mfcc/${set} ${mfccdir}
 job val_data_$set 4 4 LAST  -- utils/validate_data_dir.sh data/${set}
done


job lang_prep 4 4 data_prep,g2p_train,lex_prep -- spr_local/spr_lang_prep.sh

job lm_prep 60 4 LAST -- spr_local/spr_lm_prep.sh

job tra_mono0a 2 40 val_data_train,lang_prep -- steps/train_mono.sh --boost-silence 1.25 --nj ${numjobs} --cmd "$train_cmd" data/train data/lang exp/mono0a || error_exit "Train mono failed";
job ali_mono0a 2 40 LAST                    -- steps/align_si.sh --boost-silence 1.25 --nj ${numjobs} --cmd "$train_cmd" data/train data/lang exp/mono0a exp/mono0a_ali || error_exit "Align mono failed";

job tra_tri1 2 40 ali_mono0a -- steps/train_deltas.sh --boost-silence 1.25 --cmd "$train_cmd" 2000 10000 data/train data/lang exp/mono0a_ali exp/tri1 || error_exit "Triphone-delta failed";
job ali_tri1 2 40 LAST       -- steps/align_si.sh --nj ${numjobs} --cmd "$train_cmd" data/train data/lang exp/tri1 exp/tri1_ali || error_exit "Align tri failed";


job tra_tri2a 2 40 ali_tri1 -- steps/train_deltas.sh --cmd "$train_cmd" 2500 15000 data/train data/lang exp/tri1_ali exp/tri2a || error_exit "delta-delta training failed";
job ali_tri2b 2 40 LAST     -- steps/align_si.sh  --nj ${numjobs} --cmd "$train_cmd" --use-graphs true data/train data/lang exp/tri2a exp/tri2a_ali || "Align tri2b failed";

job tra_tri2b 2 40 ali_tri1 -- steps/train_lda_mllt.sh --cmd "$train_cmd" --splice-opts "--left-context=3 --right-context=3" 2500 15000 data/train data/lang exp/tri1_ali exp/tri2b || error_exit "lda_mllt training failed";
job ali_tri2b 2 40 LAST     -- steps/align_si.sh  --nj ${numjobs} --cmd "$train_cmd" --use-graphs true data/train data/lang exp/tri2b exp/tri2b_ali || "Align tri2b failed";

job mkg_mono0a 2 40 tra_mono0a,lm_prep -- utils/mkgraph.sh --mono data/lang_nst_2g_20k exp/mono0a exp/mono0a/graph_nst_2g_20k
job dec_mono0a 2 40 LAST               -- steps/decode.sh --nj ${numjobs} --cmd "$decode_cmd" exp/mono0a/graph_nst_2g_20k data/test exp/mono0a/decode_nst_2g_20k_test

job mkg_tri1 2 40 tra_tri1,lm_prep -- utils/mkgraph.sh data/lang_nst_2g_20k exp/tri1 exp/tri1/graph_nst_2g_20k
job dec_tri1 2 40 LAST             -- steps/decode.sh --nj ${numjobs} --cmd "$decode_cmd" exp/tri1/graph_nst_2g_20k data/test exp/tri1/decode_nst_2g_20k_test

job mkg_tri2a 2 40 tra_tri2a,lm_prep -- utils/mkgraph.sh data/lang_nst_2g_20k exp/tri2a exp/tri2a/graph_nst_2g_20k
job dec_tri2a 2 40 LAST             -- steps/decode.sh --nj ${numjobs} --cmd "$decode_cmd" exp/tri2a/graph_nst_2g_20k data/test exp/tri2a/decode_nst_2g_20k_test

job mkg_tri2b 2 40 tra_tri2b,lm_prep -- utils/mkgraph.sh data/lang_nst_2g_20k exp/tri2b exp/tri2b/graph_nst_2g_20k
job dec_tri2b 2 40 LAST             -- steps/decode.sh --nj ${numjobs} --cmd "$decode_cmd" exp/tri2b/graph_nst_2g_20k data/test exp/tri2b/decode_nst_2g_20k_test

