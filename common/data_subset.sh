#!/bin/bash

for set in $(ls -1 definitions/dataset_def/); do
    mkdir -p data/${set}
    common/filter_audio_dir.py data-prep/audio data/${set} definitions/dataset_def/${set}
done