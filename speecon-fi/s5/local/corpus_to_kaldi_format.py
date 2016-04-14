#!/usr/bin/env python3

import os
import sys


def read_info(fio_file):
    info = {p.split(": ")[0]: p.split(": ")[1].strip() for p in
            open(os.path.join(fio_file), encoding="iso-8859-1") if len(p.strip()) > 4}
    ort = info["LBO"].split(',')[3]
    prompt = info["LBR"].split(',')[5]
    sex = info["SEX"]
    age = info['AGE']
    accent = info["ACC"]

    if "#" in ort:
        ort1, ort2 = ort.split("#")
    else:
        ort1 = ort2 = ort

    return ort1, ort2, prompt, sex, age, accent


def main(in_dir, out_scp, out_dir):
    FIO_files = {}
    for root, dirs, files in os.walk(os.path.normpath(in_dir)):
        for f in files:
            if f.endswith(".FIO"):
                FIO_files[f[:8]] = os.path.join(root, os.path.splitext(f)[0])

    fd_scp = open(out_scp, 'w', encoding='utf-8')

    fd_ort1 = open(os.path.join(out_dir, 'text.ort1'), 'w', encoding='utf-8')
    fd_ort2 = open(os.path.join(out_dir, 'text.ort2'), 'w', encoding='utf-8')
    fd_prompt = open(os.path.join(out_dir, 'text.prompt'), 'w', encoding='utf-8')

    fd_utt2spk = open(os.path.join(out_dir, 'utt2spk'), 'w', encoding='utf-8')
    fd_utt2type = open(os.path.join(out_dir, 'utt2type'), 'w', encoding='utf-8')

    fd_utt2sex = open(os.path.join(out_dir, 'utt2sex'), 'w', encoding='utf-8')
    fd_utt2age = open(os.path.join(out_dir, 'utt2age'), 'w', encoding='utf-8')
    fd_utt2accent = open(os.path.join(out_dir, 'utt2accent'), 'w', encoding='utf-8')

    for key, path in FIO_files.items():
        speaker = key[:5]
        type = key[5:]
        ort1, ort2, prompt, sex, age, accent = read_info(path + ".FIO")

        for chan in range(4):
            file_name = "{}.FI{}".format(path, chan)
            if not os.path.exists(file_name):
                print("Missing: {}".format(file_name))
                continue

            utt_key = "{}-{}-{}".format(key[:5], key[5:8], chan)

            print("{} sox -b 16 -e signed-integer -r 16000 -t raw {} -r 16000 -t wav - |".format(utt_key, file_name), file=fd_scp)

            print("{} {}".format(utt_key, ort1), file=fd_ort1)
            print("{} {}".format(utt_key, ort2), file=fd_ort2)
            print("{} {}".format(utt_key, prompt), file=fd_prompt)

            print("{} {}".format(utt_key, speaker), file=fd_utt2spk)
            print("{} {}".format(utt_key, type), file=fd_utt2type)

            print("{} {}".format(utt_key, sex), file=fd_utt2sex)
            print("{} {}".format(utt_key, age), file=fd_utt2age)
            print("{} {}".format(utt_key, accent), file=fd_utt2accent)


if __name__ == "__main__":
    if len(sys.argv) != 4:
        exit("3 required arguments: source data directory, output wav file, output dir")

    main(*sys.argv[1:])