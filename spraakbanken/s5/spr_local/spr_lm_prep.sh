#!/bin/bash

echo $(date) "Check the integrity of the lm"
wd=$(pwd)
(cd corpus && md5sum -c ${wd}/local/checksums/ngram) || exit "The spraakbanken ngram file gave unexpected md5 sums"

data_dir=$(mktemp -d)
echo "Temporary directories (should be cleaned afterwards):" ${data_dir}

(cd corpus && cut -f3- -d" " ${wd}/local/checksums/ngram | xargs tar xz --strip-components=1 -C ${data_dir} -f)

if [ -d data/dict_recog ]; then rm -Rf data/dict_recog; fi

mkdir data/dict_recog
cp data/dict/{extra_questions.txt,nonsilence_phones.txt,optional_silence.txt,silence_phones.txt} data/dict_recog

iconv -f ISO8859-15 -t UTF-8 ${data_dir}/ngram1-1.frk | sed "s/\s*[0-9]\+ //" > ${data_dir}/vocab
spr_local/create_vocab_lex.py data/dict_nst/lexicon.txt ${data_dir}/vocab 20000 ${data_dir}/known.lex ${data_dir}/oov.list ${data_dir}/real_vocab
phonetisaurus-g2pfst --print_scores=false --model=data/g2p/wfsa --wordlist=${data_dir}/oov.list | grep -P -v "\t$" > ${data_dir}/oov.lex
cat ${data_dir}/oov.lex ${data_dir}/known.lex | LC_ALL=C sort -u > data/dict_recog/lexicon.txt

utils/prepare_lang.sh data/dict_recog "<UNK>" data/local/lang_recog data/lang_recog

for vocab_size in "20" "80" "100" "120"; do
for order in "2" "3"; do



langdir=data/lang_nst_${order}g_${vocab_size}k

lang_tmp_dir=$(mktemp -d)
echo "Temporary directories (should be cleaned afterwards):" ${lang_tmp_dir}

mkdir -p ${langdir}

cp -r data/lang_recog/* ${langdir}/

head -n ${vocab_size}000 ${data_dir}/real_vocab | LC_ALL=C sort -u > ${langdir}/vocab

for knd in $(seq ${order} -1 1); do


    INTERPOLATE=$(seq 1 ${order} | sed "s/^/-interpolate/" | tr "\n" " ")
    KNDISCOUNT=$(seq 1 $knd | sed "s/^/-kndiscount/" | tr "\n" " ")
    WBDISCOUNT=""
    if [ $knd != ${order} ]; then
        WBDISCOUNT=$(seq $((knd+1)) ${order} | sed "s/^/-wbdiscount/" | tr "\n" " ")
    fi

    echo $KNDISCOUNT $WBDISCOUNT


    iconv -f ISO8859-15 -t UTF-8 $data_dir/ngram[1-${order}].srt | spr_local/swap_counts.py | ngram-count -memuse -read - -lm $lang_tmp_dir/arpa -vocab ${langdir}/vocab -order ${order} $INTERPOLATE $KNDISCOUNT $WBDISCOUNT

    if [ $? == 0 ]; then
        break
    fi
done


arpa2fst ${lang_tmp_dir}/arpa | fstprint | utils/eps2disambig.pl | utils/s2eps.pl | fstcompile --isymbols=${langdir}/words.txt \
      --osymbols=${langdir}/words.txt  --keep_isymbols=false --keep_osymbols=false | \
     fstrmepsilon | fstarcsort --sort_type=ilabel > ${langdir}/G.fst

utils/validate_lang.pl ${langdir} || exit 1;
done
done

