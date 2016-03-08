#!/usr/bin/env python3

import collections
import glob
import os
import sys


def read_ort(speaker_dir, utt):
    info = {p.split(": ")[0]: p.split(": ")[1].strip() for p in open(os.path.join(speaker_dir, utt+".FIO"), encoding="iso-8859-1") if len(p.strip()) > 4}
    return info["LBO"].split(',')[3]

def main(corp_dir, speaker_list, white_list, out_text, out_scp, out_spk2utt):

    fd_text = open(out_text, 'w', encoding='utf-8')
    fd_scp = open(out_scp, 'w', encoding='utf-8')
    fd_spk2utt = open(out_spk2utt, 'w', encoding='utf-8')

    skip_counter = collections.Counter()

    allowed_types = {l.strip() for l in open(white_list) if len(l.strip()) > 0}

    speaker_dirs = {os.path.basename(p): p for p in glob.glob(os.path.join(corp_dir, "*", "*"))}

    for speaker in open(speaker_list):
        speaker = speaker.strip()
        if speaker not in speaker_dirs:
            print("Data directory for {} not found".format(speaker))
            continue
        d = speaker_dirs[speaker]

        all_utt = {i[:8] for i in os.listdir(d)}

        for utt in all_utt:
            type_key = utt[5:7]
            if type_key not in allowed_types:
                skip_counter[type_key] += 1
                continue

            if not os.path.exists(os.path.join(d, utt + ".FI0")):
                print("{}.FI0 missing".format(utt), file=sys.stderr)
                continue

            ort = ""
            try:
                ort = read_ort(d, utt)
            except FileNotFoundError:
                print("{}.FIO missing".format(utt), file=sys.stderr)
                continue

            utt_key = utt[:5] + '-' + utt[5:] + "-0"

            print("{} {}".format(utt_key, ort), file=fd_text)
            print("{} {}".format(utt_key, utt[:5]), file=fd_spk2utt)
            print("{} sox -b 16 -e signed-integer -r 16000 -t raw {} -r 16000 -t wav - |".format(utt_key, os.path.join(d, utt + ".FI0")), file=fd_scp)


    for type, count in skip_counter.most_common():
        print("Skipped {} utterances of type {}".format(count, type), file=sys.stderr)


if __name__ == "__main__":
    if len(sys.argv) != 7:
        exit("6 required arguments: dir, speaker_list, whitelist, output text file, output scp file, utt2speak file")

    corp_dir, speaker_list, white_list, out_text, out_scp, out_spk2utt = sys.argv[1:7]
    main(corp_dir, speaker_list, white_list, out_text, out_scp, out_spk2utt)
