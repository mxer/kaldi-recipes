#!/usr/bin/env python3

import os
import sys

import textgridshort


def main(in_dir, out_scp, out_segments, out_dir):
    fd_scp = open(out_scp, 'w', encoding='utf-8')
    fd_segments = open(out_segments, 'w', encoding='utf-8')

    fd_text = open(os.path.join(out_dir, 'text.orig'), 'w', encoding='utf-8')

    fd_utt2spk = open(os.path.join(out_dir, 'utt2spk'), 'w', encoding='utf-8')
    fd_utt2comp = open(os.path.join(out_dir, 'utt2type'), 'w', encoding='utf-8')
    fd_utt2accent = open(os.path.join(out_dir, 'utt2accent'), 'w', encoding='utf-8')

    wav_files = {}
    ort_files = {}
    comp = {}
    accent = {}

    for root, dirs, files in os.walk(os.path.normpath(in_dir)):
        parts = root.split(os.sep)
        if len(parts) < 2:
            continue

        if parts[-1] not in {"nl", "vl"}:
            continue

        for f in files:
            if f.endswith(".wav"):
                wav_files[f[:8]] = os.path.join(root, f)
                comp[f[:8]] = parts[-2]
                accent[f[:8]] = parts[-1]

            elif f.endswith(".ort.gz"):
                ort_files[f[:8]] = os.path.join(root, f)

    for k in ort_files.keys():
        if k not in wav_files:
            print("Help, {} wav not found".format(k))
            continue

        print("{} sox -G {} -b 16 -r 16000 -t wav - remix - |".format(k, wav_files[k]), file=fd_scp)
        tgs = textgridshort.TextGridShort(ort_files[k])

        for record in tgs.records():
            utt_key, start, end, text = record
            print("{} {}".format(utt_key, text), file=fd_text)
            print("{} {}".format(utt_key, utt_key.split('-')[0]), file=fd_utt2spk)
            print("{} {} {} {}".format(utt_key, k, start, end), file=fd_segments)

            print("{} {}".format(utt_key, comp[k]), file=fd_utt2comp)
            print("{} {}".format(utt_key, accent[k]), file=fd_utt2accent)


if __name__ == "__main__":
    if len(sys.argv) != 5:
        exit("4 required arguments: source data directory, output scp file, output segments file, output dir")

    main(*sys.argv[1:])
