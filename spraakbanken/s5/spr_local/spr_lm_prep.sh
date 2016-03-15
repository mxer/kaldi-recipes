#!/bin/bash

echo $(date) "Check the integrity of the lm"
wd=$(pwd)
(cd corpus && md5sum -c ${wd}/local/checksums/ngram) || exit "The spraakbanken ngram file gave unexpected md5 sums"

data_dir=$(mktemp -d)

echo "Temporary directories (should be cleaned afterwards):" ${data_dir}

(cd corpus && cut -f3- -d" " ${wd}/local/checksums/ngram | xargs tar xz --strip-components=1 -C ${data_dir} -f)

for order in "3"; do
for vocab_size in "20" "80" "100" "120"; do

langdir=data/lang_nst_${order}g_${vocab_size}k

lang_tmp_dir=$(mktemp -d)

mkdir -p ${langdir}

cp -r data/lang/* ${langdir}/

iconv -f ISO8859-15 -t UTF-8 $data_dir/ngram1-1.frk | head -n ${vocab_size}000 > ${langdir}/vocab

iconv -f ISO8859-15 -t UTF-8 $data_dir/ngram[1-${order}].srt | spr_local/swap_counts.py | ngram-count -read - -lm $lang_tmp_dir/arpa -vocab ${langdir}/vocab -order ${order} -interpolate -kndiscount1 -kndiscount2 -kndiscount3

done
done

