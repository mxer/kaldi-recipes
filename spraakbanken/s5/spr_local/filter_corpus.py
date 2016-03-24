#!/usr/bin/env python3
import os
import sys

import re


def read_uttkey_file(filename):
    d = {}
    for line in open(filename, encoding='utf-8'):
        utt, rest = line.strip().split(None, maxsplit=1)
        d[utt] = rest

    return d


def filter_uttkey_file(file_in, file_out, utt_keys):
    with open(file_out, 'w', encoding='utf-8') as f_out:
        for line in open(file_in, encoding='utf-8'):
            utt, rest = line.strip().split(None, maxsplit=1)
            if utt in utt_keys:
                print(line.strip(), file=f_out)


def main(source_dir, output_dir, specfile):
    specs = tuple(line.strip() for line in open(specfile, encoding='utf-8').readlines())

    types = read_uttkey_file(os.path.join(source_dir, 'utt2type'))

    key_regex = re.compile(specs[0])
    type_regex = re.compile(specs[1])

    final_utts = set()
    for key, type in read_uttkey_file(os.path.join(source_dir, 'utt2type')).items():
        if key_regex.match(key) is None or type_regex.match(type) is None:
            continue
        final_utts.add(key)

    for f in "utt2type", "wav.scp", "text", "utt2spk":
        filter_uttkey_file(os.path.join(source_dir, f), os.path.join(output_dir, f), final_utts)


if __name__ == "__main__":
    if len(sys.argv) != 4:
        exit("3 required arguments: source data directory, output data directory, specification")

    main(*sys.argv[1:])
