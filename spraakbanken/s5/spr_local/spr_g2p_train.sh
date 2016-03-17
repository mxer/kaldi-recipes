#!/bin/bash
# Begin configuration section.
cmd=run.pl
# End configuration options.

echo "$0 $@"  # Print the command line for logging

[ -f path.sh ] && . ./path.sh # source the path.
. parse_options.sh || exit 1;

if [ $# != 2 ]; then
   echo "usage: spr_local/spr_g2p_train.sh in_lexicon g2p_dir"
   echo "e.g.:  steps/align_fmllr.sh data/dict_nst/lexicon.txt data/g2p"
   echo "main options (for others, see top of script file)"
   echo "  --cmd (utils/run.pl|utils/queue.pl <queue opts>) # how to run jobs."
   exit 1;
fi

infile=$1
outdir=$2

${cmd} JOB=1 ${outdir}/log/phonetisaurus-align.JOB phonetisaurus-align --s1s2_sep="]" --input=${infile} -ofile=${outdir}/corpus

estimate-ngram -s FixKN -o 7 -t ${outdir}/corpus -wl ${outdir}/arpa

phonetisaurus-arpa2wfst --lm=${outdir}/arpa --ofile=${outdir}/wfsa