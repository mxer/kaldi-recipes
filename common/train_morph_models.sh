#!/bin/bash

echo "$0 $@"  # Print the command line for logging

[ -f path.sh ] && . ./path.sh # source the path.
. parse_options.sh || exit 1;

if [ $# != 0 ]; then
   echo "usage: train_word_models.sh"
   exit 1;
fi

. ./cmd.sh ## You'll want to change cmd.sh to something that will work on your system.
           ## This relates to the queue.

. common/slurm_dep_graph.sh

JOB_PREFIX=$(cat id)_

mkdir -p data/segmentation/morph1
job train_morfessor 10 24 NONE -- common/train_morfessor_model.sh data-prep/text/text.orig.xz 300000 data/segmentation/morph1/morfessor.bin data/segmentation/morph1/vocab
job morfessor_segment 4 72 train_morfessor -- common/morfessor_segment.sh data-prep/text/text.orig.xz data/segmentation/morph1/morfessor.bin data/segmentation/morph1/corpus.xz

if [ -e data/dicts/morph1 ]; then rm -Rf data/dicts/morph1; fi
if [ -e data/langs/morph1_base ]; then rm -Rf data/langs/morph1_base; fi
if [ -e data/langs/morph1_fix1 ]; then rm -Rf data/langs/morph1_fix1; fi
mkdir -p data/dicts/morph1
mkdir -p data/langs/morph1_base
mkdir -p data/langs/morph1_fix1

job make_morph_lex 4 4 train_morfessor -- common/make_dict.sh data/segmentation/morph1/vocab data/dicts/morph1

job make_morph_lang 4 4 LAST -- utils/prepare_lang.sh --phone-symbol-table data/lang_train/phones.txt data/dicts/morph1 "<UNK>" data/langs/morph1_base/local data/langs/morph1_base
job make_morph_lang_fix1 4 4 LAST -- common/prepare_lang_morph.sh --phone-symbol-table data/lang_train/phones.txt data/dicts/morph1 "<UNK>" data/langs/morph1_fix1/local data/langs/morph1_fix1

for d in "0.05" "0.02" "0.01" "0.005" "0.002" "0.001"; do

    for order in "3" "5" "30"; do
        mkdir -p data/lm/morph1/vk/${d}_${order}g
        job vari_${d}_${order}g 45 72 morfessor_segment -- common/train_varikn_model.sh data/segmentation/morph1/corpus.xz data/segmentation/morph1/vocab ${d} ${order} data/lm/morph1/vk/${d}_${order}g/arpa.xz

        job recog_lang_${d}_${order}g 16 1 vari_${d}_${order}g,make_morph_lang -- common/make_recog_lang.sh data/lm/morph1/vk/${d}_${order}g/arpa.xz data/langs/morph1_base data/recog_langs/morph1_base_v_${d}_${order}gram
        job recog_lang_${d}_${order}g2 16 1 vari_${d}_${order}g,make_morph_lang -- common/make_recog_lang.sh --inwordbackoff true data/lm/morph1/vk/${d}_${order}g/arpa.xz data/langs/morph1_base data/recog_langs/morph1_base_backoff_v_${d}_${order}gram
        
        job recog_lang_${d}_${order}g_fix1 16 1 vari_${d}_${order}g,make_morph_lang_fix1 -- common/make_recog_lang.sh data/lm/morph1/vk/${d}_${order}g/arpa.xz data/langs/morph1_fix1 data/recog_langs/morph1_fix1_v_${d}_${order}gram
        job recog_lang_${d}_${order}g2_fix1 16 1 vari_${d}_${order}g,make_morph_lang_fix1 -- common/make_recog_lang.sh --inwordbackoff true data/lm/morph1/vk/${d}_${order}g/arpa.xz data/langs/morph1_fix1 data/recog_langs/morph1_fix1_backoff_v_${d}_${order}gram
    done
done
