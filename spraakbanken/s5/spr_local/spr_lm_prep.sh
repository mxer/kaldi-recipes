#!/bin/bash

echo $(date) "Check the integrity of the lm"
wd=$(pwd)
(cd corpus && md5sum -c ${wd}/local/checksums/ngram) || exit "The spraakbanken ngram file gave unexpected md5 sums"

data_dir=$(mktemp -d)

echo "Temporary directories (should be cleaned afterwards):" ${data_dir}

(cd corpus && cut -f3- -d" " ${wd}/local/checksums/ngram | xargs tar xz --strip-components=1 -C ${data_dir} -f)

iconv -f ISO8859-15 -t UTF-8 $data_dir/ngram1-1.frk | head -n 200000 | sed "s/\s*[0-9]\+ //" > ${data_dir}/vocab

spr_local/get_oov.py data/dict_nst/lexicon.txt ${data_dir}/vocab > ${data_dir}/vocab_oov

phonetisaurus-g2pfst --print_scores=false --model=data/g2p/wfsa --wordlist=${data_dir}/vocab_oov | grep -P -v "\t$" > ${data_dir}/vocab_oov.lex

cat ${data_dir}/vocab_oov.lex data/dict_nst/lexicon.txt | LC_ALL=C sort -u > ${data_dir}/lexicon.txt

mkdir data/dict_recog
cp data/dict/{extra_questions.txt,nonsilence_phones.txt,optional_silence.txt,silence_phones.txt} data/dict_recog
cp ${data_dir}/lexicon.txt data/dict_recog

utils/prepare_lang.sh data/dict_recog "<UNK>" data/local/lang_recog data/lang_recog


for order in "2" "3"; do
for vocab_size in "20" "80" "100" "120"; do

INTERPOLATE=$(seq 1 $order | sed "s/^/-interpolate/" | tr "\n" " ")
KNDISCOUNT=$(seq 1 $knd | sed "s/^/-kndiscount/" | tr "\n" " ")

langdir=data/lang_nst_${order}g_${vocab_size}k

lang_tmp_dir=$(mktemp -d)
echo "Temporary directories (should be cleaned afterwards):" ${lang_tmp_dir}

mkdir -p ${langdir}

cp -r data/dict_recog/* ${langdir}/

head -n ${vocab_size}000 ${data_dir}/vocab | LC_ALL=C sort -u > ${langdir}/words.txt

iconv -f ISO8859-15 -t UTF-8 $data_dir/ngram[1-${order}].srt | spr_local/swap_counts.py | ngram-count -memuse -read - -lm $lang_tmp_dir/arpa -vocab ${langdir}/words.txt -order ${order} $INTERPOLATE $KNDISCOUNT

arpa2fst ${lang_tmp_dir}/arpa | fstprint | utils/eps2disambig.pl | utils/s2eps.pl | fstcompile --isymbols=${langdir}/words.txt \
      --osymbols=${langdir}/words.txt  --keep_isymbols=false --keep_osymbols=false | \
     fstrmepsilon | fstarcsort --sort_type=ilabel > ${langdir}/G.fst

utils/validate_lang.pl ${langdir} || exit 1;
done
done

