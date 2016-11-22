#!/bin/bash

. ./cmd.sh ## You'll want to change cmd.sh to something that will work on your system.
           ## This relates to the queue.

. common/slurm_dep_graph.sh

JOB_PREFIX=$(cat id)_

export LC_ALL=C

for s in $(seq 200 200 2000); do
 
#cat definitions/dict_prep/lex >> data/dicts/word_${s}k/lexicon.txt
#sort -u -o data/dicts/word_${s}k/lexicon.txt data/dicts/word_${s}k/lexicon.txt


job make_dict 5 1 NONE common/make_dict.sh data/dicts/word_${s}k/vocab data/dicts/word_${s}k

job prep_lang_${s}_${a} 8 2 LAST utils/prepare_lang.sh --phone-symbol-table data/lang/phones.txt data/dicts/word_${s}k "<UNK>" data/langs/word_${s}k/local data/langs/word_${s}k

dim=5
job recog_lang_${s}_${a} 3 2 LAST common/make_recog_lang.sh data/lm/word/vk/${s}k_${dim}M/arpa.xz data/langs/word_${s}k data/recog_langs/word_vk_${s}k_${dim}M

dim=50
job recog_lang_${s}_${a} 25 2 LAST common/make_recog_lang.sh data/lm/word/vk/${s}k_${dim}M/arpa.xz data/langs/word_${s}k data/recog_langs/word_vk_${s}k_${dim}M


job const_arpa_${s}_${a} 12 2 LAST common/build_const_arpa_lm.sh data/lm/word/vk/${s}k_${dim}M/arpa.xz data/recog_langs/word_vk_${s}k_50M
done

