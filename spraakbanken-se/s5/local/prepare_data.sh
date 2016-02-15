#!/bin/bash

test_data_dir=$(mktemp -d)
train_data_dir=$(mktemp -d)

trap "{ rm -f $test_data_dir $train_data_dir ; exit 255; }" EXIT

tar xzvf /teamwork/t40511_asr/c/språkbanken/se/nst-16khz/sve.16khz.0467-1.tar.gz --strip-components=3 -C $train_data_dir
tar xzvf /teamwork/t40511_asr/c/språkbanken/se/nst-16khz/sve.16khz.0467-2.tar.gz --strip-components=3 -C $train_data_dir
tar xzvf /teamwork/t40511_asr/c/språkbanken/se/nst-16khz/sve.16khz.0467-3.tar.gz --strip-components=3 -C $train_data_dir

tar xzvf /teamwork/t40511_asr/c/språkbanken/se/nst-16khz/sve.16khz.0468.tar.gz --strip-components=3 -C $test_data_dir

