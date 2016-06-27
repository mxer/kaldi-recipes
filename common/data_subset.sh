#!/bin/bash

for set in $(ls -1 definitions/selections/); do
    mkdir -p data/${set}
    common/filter_audio_dir.py data-prep/audio data/${set} definitions/selections/${set}
done
