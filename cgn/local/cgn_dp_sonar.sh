#!/bin/bash
set -e
export LC_ALL=C

# Begin configuration section.
cmd=run.pl
# End configuration options.

echo "$0 $@"  # Print the command line for logging

[ -f path.sh ] && . ./path.sh # source the path.
. parse_options.sh || exit 1;

if [ $# != 2 ]; then
   echo "usage: cgn_dp_sonar.sh infile outfile"
   echo "e.g.:  cgn_dp_sonar.sh 20150602_SoNaRCorpus_NC_1.2.1.gz data-prep/ngram/corpus"
   echo "main options (for others, see top of script file)"
   echo "     --cmd <cmd>                              # Command to run in parallel with"

   exit 1;
fi

infile=$1
outfile=$2

tmpdir=$(mktemp -d)

tar xf $infile -C ${tmpdir} ./SoNaRCorpus_NC_1.2/SONAR500/FoLiA/WR-P-E-G_subtitles/ ./SoNaRCorpus_NC_1.2/SONAR500/FoLiA/WR-P-P-B_books/ ./SoNaRCorpus_NC_1.2/SONAR500/FoLiA/WR-P-P-G_newspapers/ ./SoNaRCorpus_NC_1.2/SONAR500/FoLiA/WS-U-E-A_auto_cues/ ./SoNaRCorpus_NC_1.2/SONAR500/FoLiA/WS-U-T-B_texts_for_the_visually_impaired/

mkdir $tmpdir/filelists

find $tmpdir -name "*.folia.xml" -type f | split -l 10000 --numeric-suffixes=1000 -a4 - ${tmpdir}/filelists/

mkdir -p tmp

tartmpdir=$(mktemp -d --tmpdir=tmp/)

for f in $(ls -1 ${tmpdir}/filelists/); do
    tar cf $tartmpdir/$f.tar -T ${tmpdir}/filelists/$f
done

last=$(ls -1 ${tmpdir}/filelists/ | sort -n | tail -n1)

mkdir $tartmpdir/{out,log}

source activate pineapple

$cmd JOB=1000:$last $tartmpdir/log/JOB.log local/SoNaR_to_corpus.py $tartmpdir/JOB.tar $tartmpdir/out/JOB

cat $tartmpdir/out/* > $outfile

rm -Rf tmp/