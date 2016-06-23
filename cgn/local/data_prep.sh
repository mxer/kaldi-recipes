#!/bin/bash

set -e

export LC_ALL=C

# Begin configuration section.
dataprep_dir=$WORK_DIR/data
cmd=run.pl
# End configuration options.

echo "$0 $@"  # Print the command line for logging

[ -f path.sh ] && . ./path.sh # source the path.
. parse_options.sh || exit 1;

if [ $# != 1 ]; then
   echo "usage: local/data_prep.sh cgn_dir sonar_file"
   echo "e.g.:  local/data_prep.sh \$GROUP_DIR/c/cgn \$USER_DIR/c/SoNaR/20150602_SoNaRCorpus_NC_1.2.1.gz"
   echo "main options (for others, see top of script file)"
   echo "     --cmd <cmd>                              # Command to run in parallel with"
   echo "     --dataprep-dir director   # location to put the dataprep directory"

   exit 1;
fi

cgn_dir=$1
sonar_file=$2

if [ -d $dataprep_dir/cgn/kaldi-prep ]; then
    mv $dataprep_dir/cgn/kaldi-prep.$(date +%s)
fi

mkdir -p $dataprep_dir/cgn/kaldi-prep

command -v lfs > /dev/null && lfs setstripe -c 6 $dataprep_dir/cgn/kaldi-prep

#AUDIO
raw_files_dir=$(mktemp -d)
data_dir=$(mktemp -d)

echo "Temporary audio directories (should be cleaned afterwards):" ${raw_files_dir} ${data_dir}

echo $(date) "Read the corpus"
local/cgn_prep_corpus.py $cgn_dir ${raw_files_dir}/wav.scp ${raw_files_dir}/segments ${data_dir}

mkdir -p $dataprep_dir/audio

for f in $(ls -1 ${data_dir}); do
    sort < ${data_dir}/${f} > $dataprep_dir/audio/${f}
done

sort < ${raw_files_dir}/wav.scp > ${raw_files_dir}/sorted.scp
sort < ${raw_files_dir}/segments > ${raw_files_dir}/segments.sorted


echo $(date) "Start extract-segments"
extract-segments --max-overshoot=3.0 scp:${raw_files_dir}/sorted.scp ${raw_files_dir}/segments.sorted ark,scp:${dataprep_dir}/audio/wav.ark,${dataprep_dir}/audio/wav.scp

echo $(date) "Start removing temp dirs"

rm -Rf ${data_dir} ${raw_files_dir}


#LEXICON

echo $(date) "Check the integrity of the lexicon"
wd=$(pwd)
(cd $cgn_dir && md5sum -c ${wd}/definitions/checksums/lex) || exit "The cgn lexicon gave unexpected md5 sums"

data_dir=$(mktemp -d)

echo "Temporary lexicon directories (should be cleaned afterwards):" ${data_dir}

(cd $cgn_dir && cut -f3- -d" " ${wd}/definitions/checksums/lex | xargs cat > $data_dir/lex)

mkdir -p ${dataprep_dir}/lexicon

local/cgn_prep_lex.py --lowercase ${data_dir}/lex | sort -u > ${dataprep_dir}/lexicon/lexicon.txt

rm -Rf ${data_dir}

#TEXT
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

mkdir -p mkdir -p ${dataprep_dir}/text

cat $tartmpdir/out/* | xz > ${dataprep_dir}/text/text.orig.xz

rm -Rf $tartmpdir