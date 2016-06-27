#!/bin/bash

export LC_ALL=C

# Begin configuration section.
# End configuration options.

echo "$0 $@"  # Print the command line for logging

[ -f path.sh ] && . ./path.sh # source the path.
. parse_options.sh || exit 1;

if [ $# != 0 ]; then
   echo "usage: common_subset.sh"
   exit 1;
fi

for set in $(ls -1 definitions/selections/); do
    mkdir -p data/${set}
    common/filter_audio_dir.py data-prep/audio data/${set} definitions/selections/${set}
    utils/utt2spk_to_spk2utt.pl data/${set}/utt2spk > data/${set}/spk2utt
    local/make_transcript.py data/${set} data-prep/lexicon/lexicon.txt
    awk '{print substr($0, index($0, $1))}' < data/${set}/text | tr ' ' '\n' | sort -u > data/${set}/vocab
done
