#!/usr/bin/env python3
import collections
import os
import subprocess
import sys

import spl


def main(in_dir, out_text, out_scp, out_spk2utt):
    wav_files = {}
    spl_files = {}

    for root, dirs, files in os.walk(os.path.normpath(in_dir)):
        parts = root.split(os.sep)

        for f in files:
            if f.endswith(".wav") and f.startswith("u"):
                key = parts[-2] + os.path.splitext(f)[0]
                wav_files[key] = os.path.join(root, f)

            if f.endswith(".spl"):
                key = parts[-1] + os.path.splitext(f)[0]
                spl_files[key] = os.path.join(root, f)

    fd_text = open(out_text, 'w', encoding='utf-8')
    fd_scp = open(out_scp, 'w', encoding='utf-8')
    fd_utt2spk = open(out_spk2utt, 'w', encoding='utf-8')

    speakers = collections.Counter()
    for key, val in spl_files.items():
        count = 0
        s = spl.Spl(val)
        for valid, record in s.records():
            wav_key = key[:8] + os.path.splitext(valid[9])[0]
            utt_key = key[:8] + '-' + wav_key[1:5] + '-' + wav_key[5:] + "-1"
            if wav_key not in wav_files:
                continue

            file_name = wav_files[wav_key]

            if os.stat(file_name).st_size == 0:
                print("{} is empty".format(file_name))
                continue
            try:
                num_sam = int(subprocess.check_output("soxi -s {}".format(file_name), shell=True))
            except subprocess.CalledProcessError:
                print("Error when reading {}".format(file_name))
                continue

            if num_sam * 4 != int(valid[11]) - int(valid[10]):
                print("Length incorrect of {}".format(file_name))
                continue

            count += 1

            print("{} sph2pipe -f wav -p -c 1 {} |".format(utt_key, file_name), file=fd_scp)
            print("{} {}".format(utt_key, valid[0]), file=fd_text)
            print("{} {}".format(utt_key, key[:13]), file=fd_utt2spk)

        if count > 0:
            # print("{} with speaker {}, {} utterances".format(key, s._infos['Speaker ID'], count))
            try:
                speakers[int(s._infos['Speaker ID'].strip().strip("#"))] += count
            except ValueError:
                speakers[s._infos['Speaker ID'].strip().strip("#")] += count


# for s,c in speakers.items():
#        print("{} {}".format(s,c))

if __name__ == "__main__":
    if len(sys.argv) != 5:
        exit("4 required arguments: data directory, output text file, output scp file, utt2speak file")

    in_dir, out_text, out_scp, out_spk2utt = sys.argv[1:5]
    main(in_dir, out_text, out_scp, out_spk2utt)
