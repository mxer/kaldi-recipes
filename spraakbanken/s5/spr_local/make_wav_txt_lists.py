#!/usr/bin/env python3
import collections
import os
import subprocess
import sys

import re
import spl

BLACKLIST = {'bISa1', ''}


def main(in_dir, out_text, out_scp, out_spk2utt, whitelist):
    skip_counter = collections.Counter()
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

    fd_text = open(out_text, 'w', encoding='utf-8')
    fd_scp = open(out_scp, 'w', encoding='utf-8')
    fd_utt2spk = open(out_spk2utt, 'w', encoding='utf-8')

    speakers = collections.Counter()
    for key, val in spl_files.items():
        count = 0
        s = spl.Spl(val)
        for valid, record in s.records():
            if record[9].strip() in BLACKLIST:
                skip_counter[record[9].strip()] += 1
                continue

            type_key = re.search('\D+', record[9]).group()
            
            key_a = os.path.splitext(valid[9])[0]
            wav_key = key[:8] + key_a
            wav_key = wav_key.lower()
            utt_key = key[:8] + '-' + key_a[1:5] + '-' + key_a[5:] + "-1"

            if wav_key not in wav_files:
                continue

            if type_key not in whitelist:
                skip_counter[type_key] += 1
                continue

            if "(" in valid[0] or ")" in valid[0] or "+" in valid[0]:
                err_counter["invalid test"] +=1
                continue

            file_name = wav_files[wav_key]

            if os.stat(file_name).st_size == 0:
                print("{} is empty".format(file_name))
                continue
            try:
                num_sam = int(subprocess.check_output("soxi -s {}".format(file_name), shell=True))
            except subprocess.CalledProcessError:
                err_counter["Reading file error"] += 1
                #print("Error when reading {}".format(file_name), file=sys.stderr)
                continue

            if num_sam * 4 != int(valid[11]) - int(valid[10]):
                err_counter["Length incorrect error"] += 1
                #print("Length incorrect of {}".format(file_name), file=sys.stderr)
                continue

            count += 1

            print("{} sph2pipe -f wav -p -c 1 {} |".format(utt_key, file_name), file=fd_scp)
            print("{} {}".format(utt_key, " ".join(valid[0].split())), file=fd_text)
            print("{} {}".format(utt_key, utt_key[:13]), file=fd_utt2spk)

        if count > 0:
            # print("{} with speaker {}, {} utterances".format(key, s._infos['Speaker ID'], count))
            try:
                speakers[int(s._infos['Speaker ID'].strip().strip("#"))] += count
            except ValueError:
                speakers[s._infos['Speaker ID'].strip().strip("#")] += count

    for type, count in skip_counter.most_common():
        print("Skipped {} utterances of type {}".format(count, type), file=sys.stderr)

    for type, count in err_counter.most_common():
        print("Occured {} errors of type: {}".format(count, type), file=sys.stderr)

if __name__ == "__main__":
    if len(sys.argv) != 6:
        exit("5 required arguments: data directory, output text file, output scp file, utt2speak file, selection")

    in_dir, out_text, out_scp, out_spk2utt, selection = sys.argv[1:6]

    whitelist = set()
    if selection == "train":
        whitelist = {"ISa", "cISa", "FF", "CD", "dISa", "ISp", "pIWp", "prIWp", "cIWp", "phIWp", "IWp"}
    elif selection == "test":
        whitelist = {"ISa", "ISp"}
    else:
        print("This is a mistake, there should be a set selected.", file=sys.stderr)

    main(in_dir, out_text, out_scp, out_spk2utt, whitelist)
