#!/bin/bash

infile=$1
outdir=$2

phonetisaurus-align --input=${infile} -ofile=${outdir}/corpus

ngram-count -order 7 -kn-modify-counts-at-end -gt1min 0 -gt2min 0 \                                                                                                                                      :(
-gt3min 0 -gt4min 0 -gt5min 0 -gt6min 0 -gt7min 0 -ukndiscount \
-ukndiscount1 -ukndiscount2 -ukndiscount3 -ukndiscount4 \
-ukndiscount5 -ukndiscount6 -ukndiscount7 -text ${outdir}/corpus -lm ${outdir}/arpa

phonetisaurus-arpa2wfst --lm=${outdir}/arpa --ofile=${outdir}/wfsa