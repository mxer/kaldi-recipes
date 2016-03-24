#!/usr/bin/env python3
import collections
import os
import subprocess
import sys

import spl


def main(in_dir, out_scp, out_dir):
    err_counter = collections.Counter()

    wav_files = {}
    spl_files = {}

    for root, dirs, files in os.walk(os.path.normpath(in_dir)):
        parts = root.split(os.sep)

        for f in files:
            if f.endswith(".wav") and f.startswith("u"):
                key = parts[-2] + os.path.splitext(f)[0]
                wav_files[key.lower()] = os.path.join(root, f)

            if f.endswith(".spl"):
                key = parts[-1] + os.path.splitext(f)[0]
                spl_files[key.lower()] = os.path.join(root, f)

    fd_text = open(os.path.join(out_dir, 'text'), 'w', encoding='utf-8')
    fd_scp = open(out_scp, 'w', encoding='utf-8')
    fd_utt2spk = open(os.path.join(out_dir, 'utt2spk'), 'w', encoding='utf-8')
    fd_utt2type = open(os.path.join(out_dir, 'utt2type'), 'w', encoding='utf-8')

    for key, val in spl_files.items():
        s = spl.Spl(val)
        for valid, record in s.records():

            spl_wav_filename = os.path.splitext(valid[9])[0]
            wav_key = key[:8] + spl_wav_filename
            wav_key = wav_key.lower()

            utt_type = record[9]
            utt_text = " ".join(valid[0].split())
            if wav_key not in wav_files:
                err_counter["No such wavfile"] += 1
                continue

            file_name = wav_files[wav_key]

            if os.stat(file_name).st_size == 0:
                err_counter["File empty error"] += 1
                continue
            try:
                num_sam = int(subprocess.check_output("soxi -s {}".format(file_name), stderr=subprocess.STDOUT, shell=True))
            except subprocess.CalledProcessError:
                err_counter["Reading file error"] += 1
                continue

            if num_sam * 4 != int(valid[11]) - int(valid[10]):
                err_counter["Length incorrect error"] += 1
                continue

            for channel in ("1", "2"):
                utt_key = "{}-{}-{}-{}".format(key[:8], spl_wav_filename[1:5], spl_wav_filename[5:], channel)

                print("{} sph2pipe -f wav -p -c {} {} |".format(utt_key, channel, file_name), file=fd_scp)
                print("{} {}".format(utt_key, utt_text), file=fd_text)
                print("{} {}".format(utt_key, utt_key[:13]), file=fd_utt2spk)
                print("{} {}".format(utt_key, utt_type), file=fd_utt2type)

    for type, count in err_counter.most_common():
        print("{} errors of type \"{}\" occured".format(count, type), file=sys.stderr)


if __name__ == "__main__":
    if len(sys.argv) != 4:
        exit("3 required arguments: source data directory, output wav file, output dir")

    main(*sys.argv[1:])