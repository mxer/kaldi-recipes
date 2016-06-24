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
   echo "usage: local/data_prep_audio.sh sonar_dir data_prep_dir"
   echo "e.g.:  local/data_prep.sh \$GROUP_DIR/w/c/SoNaR/sonar_file.tgz ~w/d/some_data_prep/text"
   echo "main options (for others, see top of script file)"
   echo "     --cmd <cmd>                              # Command to run in parallel with"
   exit 1;
fi

sonar_file=$1
result_dir=$2

echo $(date) "Start text gathering"
tmpdir=$(mktemp -d)

tar xf $sonar_file -C ${tmpdir} ./SoNaRCorpus_NC_1.2/SONAR500/FoLiA/WR-P-E-G_subtitles/ ./SoNaRCorpus_NC_1.2/SONAR500/FoLiA/WR-P-P-B_books/ ./SoNaRCorpus_NC_1.2/SONAR500/FoLiA/WR-P-P-G_newspapers/ ./SoNaRCorpus_NC_1.2/SONAR500/FoLiA/WS-U-E-A_auto_cues/ ./SoNaRCorpus_NC_1.2/SONAR500/FoLiA/WS-U-T-B_texts_for_the_visually_impaired/

mkdir $tmpdir/filelists

find $tmpdir -name "*.folia.xml" -type f | split -l 10000 --numeric-suffixes=1000 -a4 - ${tmpdir}/filelists/

echo $(date) "Create text jobs"
tartmpdir=$(mktemp -d --tmpdir=./)

for f in $(ls -1 ${tmpdir}/filelists/); do
    tar cf $tartmpdir/$f.tar -T ${tmpdir}/filelists/$f
done

last=$(ls -1 ${tmpdir}/filelists/ | sort -n | tail -n1)

mkdir $tartmpdir/{out,log}

source activate pineapple

echo $(date) "Run text jobs"

$cmd JOB=1000:$last $tartmpdir/log/JOB.log local/SoNaR_to_corpus.py $tartmpdir/JOB.tar $tartmpdir/out/JOB

mkdir -p $result_dir

cat $tartmpdir/out/* | xz > ${result_dir}/text.orig.xz

rm -Rf $tartmpdir
