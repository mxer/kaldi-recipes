#!/bin/bash

echo $(date) "Check the integrity of the lm"
wd=$(pwd)
(cd corpus && md5sum -c ${wd}/local/checksums/ngram) || exit "The spraakbanken ngram file gave unexpected md5 sums"

data_dir=$(mktemp -d)

echo "Temporary directories (should be cleaned afterwards):" ${data_dir}

(cd corpus && cut -f3- -d" " ${wd}/local/checksums/ngram | xargs tar xz --strip-components=1 -C ${data_dir} -f)

for order in "2" "3"; do
for vocab_size in "20" "80" "100" "120"; do

INTERPOLATE=$(seq 1 $order | sed "s/^/-interpolate/" | tr "\n" " ")
KNDISCOUNT=$(seq 1 $knd | sed "s/^/-kndiscount/" | tr "\n" " ")

langdir=data/lang_nst_${order}g_${vocab_size}k

lang_tmp_dir=$(mktemp -d)
echo "Temporary directories (should be cleaned afterwards):" ${lang_tmp_dir}

mkdir -p ${langdir}

cp -r data/lang/* ${langdir}/

iconv -f ISO8859-15 -t UTF-8 $data_dir/ngram1-1.frk | head -n ${vocab_size}000 | sed "s/\s*[0-9]\+ //" > ${langdir}/vocab

iconv -f ISO8859-15 -t UTF-8 $data_dir/ngram[1-${order}].srt | spr_local/swap_counts.py | ngram-count -memuse -read - -lm $lang_tmp_dir/arpa -vocab ${langdir}/vocab -order ${order} $INTERPOLATE $KNDISCOUNT 

done
done

