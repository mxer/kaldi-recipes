#!/bin/bash
#SBATCH -t 24:00:00
#SBATCH -p coin,batch-hsw,batch-wsm,batch-ivb
#SBATCH --mem-per-cpu 80G

export LC_ALL=C

set -e

. ./path.sh

lm=$1

model=morph_sami_v8_$(echo $lm | grep -o "N*W[0-9].*/N[0-9a-zA-Z\.-]*" | sed "s#/#_#")

echo $model

mkdir -p data/lm/$model

bzcat $lm | xz -0 > data/lm/$model/arpa.xz

xzcat data/lm/$model/arpa.xz | common/extract_vocab_from_arpa.py > data/lm/$model/vocab

bzcat $(dirname $lm)/{es,skk,web}.segmented.txt.bz2 | common/get_word_mapping.py > data/lm/$model/word_map

local/make_dict_est_morph8.sh data/lm/$model/vocab data/lm/$model/word_map data/dicts/$model

utils/prepare_lang.sh data/dicts/$model "<UNK>" data/langs/$model/local data/langs/$model

dir=data/langs/$model
tmpdir=data/langs/$model/local

LC_ALL=en_US.UTF-8 common/make_morph_lex.py < data/dicts/$model/lexiconp.txt > $tmpdir/lexiconp.txt


# First remove pron-probs from the lexicon.
perl -ape 's/(\S+\s+)\S+\s+(.+)/$1$2/;' <$tmpdir/lexiconp.txt >$tmpdir/align_lexicon.txt

# Note: here, $silphone will have no suffix e.g. _S because it occurs as optional-silence,
# and is not part of a word.
[ ! -z "$silphone" ] && echo "<eps> $silphone" >> $tmpdir/align_lexicon.txt

cat $tmpdir/align_lexicon.txt | \
 perl -ane '@A = split; print $A[0], " ", join(" ", @A), "\n";' | sort | uniq > $dir/phones/align_lexicon.txt

# create phones/align_lexicon.int
cat $dir/phones/align_lexicon.txt | utils/sym2int.pl -f 3- $dir/phones.txt | \
  utils/sym2int.pl -f 1-2 $dir/words.txt > $dir/phones/align_lexicon.int


case $model in
*pre)
  common/make_lfst_pre.py $(tail -n1 $dir/phones/disambig.txt) < $tmpdir/lexiconp_disambig.txt | fstcompile --isymbols=$dir/phones.txt --osymbols=$dir/words.txt --keep_isymbols=false --keep_osymbols=false | fstaddselfloops  $dir/phones/wdisambig_phones.int $dir/phones/wdisambig_words.int | fstarcsort --sort_type=olabel > $dir/L_disambig.fst
  ;;
*aff)
  common/make_lfst_inf.py $(tail -n1 $dir/phones/disambig.txt) < $tmpdir/lexiconp_disambig.txt | fstcompile --isymbols=$dir/phones.txt --osymbols=$dir/words.txt --keep_isymbols=false --keep_osymbols=false | fstaddselfloops  $dir/phones/wdisambig_phones.int $dir/phones/wdisambig_words.int | fstarcsort --sort_type=olabel > $dir/L_disambig.fst
  ;;
*)
  common/make_lfst_wma.py $(tail -n3 $dir/phones/disambig.txt) < $tmpdir/lexiconp_disambig.txt | fstcompile --isymbols=$dir/phones.txt --osymbols=$dir/words.txt --keep_isymbols=false --keep_osymbols=false | fstaddselfloops  $dir/phones/wdisambig_phones.int $dir/phones/wdisambig_words.int | fstarcsort --sort_type=olabel > $dir/L_disambig.fst
  ;;
esac

common/make_recog_lang.sh --inwordbackoff false data/lm/$model/arpa.xz data/langs/$model data/recog_langs/$model

utils/mkgraph.sh --remove-oov --self-loop-scale 1.0 data/recog_langs/$model exp/chain_cleaned_sp/tdnn exp/chain_cleaned_sp/tdnn/graph_$model

sbatch local/recognize.sh tdnn_ad data/recog_langs/$model
sbatch local/recognize.sh --dataset test tdnn_ad data/recog_langs/$model



