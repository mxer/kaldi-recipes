#!/usr/bin/env python3

import collections
import glob
import os
import sys


class FilteredTranscription(Exception):
    pass


def read_ort(speaker_dir, utt, prefferd_trans=0):
    info = {p.split(": ")[0]: p.split(": ")[1].strip() for p in open(os.path.join(speaker_dir, utt+".FIO"), encoding="iso-8859-1") if len(p.strip()) > 4}
    ort = info["LBO"].split(',')[3]

    if "*" in ort[1:] or "[sta]" in ort or "[int]" in ort:
        raise FilteredTranscription

    # A single * on the beginning of a line is ignored
    if ort.startswith("*"):
        ort = ort[1:]
        print("Interesting transcription: {}".format(utt), file=sys.stderr)

    if "#" in ort:
        ort = ort.split("#")[prefferd_trans]

        word_parts = [p.split() for p in ort.split("#")]
        if len(word_parts) > 2:
            print("Interesting transcription: {}".format(utt), file=sys.stderr)

        l = len(word_parts[0])
        for wp in word_parts:
            if len(wp) != l:
                print("Interesting transcription: {}".format(utt), file=sys.stderr)

    return " ".join(ort.split())


def main(corp_dir, speaker_list, white_list, out_text, out_scp, out_spk2utt, is_train):

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

            try:
                preffered = 0
                if is_train:
                    preffered = 1
                ort = read_ort(d, utt, preffered)

                utt_key = utt[:5] + '-' + utt[5:] + "-0"

                print("{} {}".format(utt_key, ort), file=fd_text)
                print("{} {}".format(utt_key, utt[:5]), file=fd_spk2utt)
                print("{} sox -b 16 -e signed-integer -r 16000 -t raw {} -r 16000 -t wav - |".format(utt_key, os.path.join(d, utt + ".FI0")), file=fd_scp)
            except FileNotFoundError:
                print("{}.FIO missing".format(utt), file=sys.stderr)
                continue
            except FilteredTranscription:
                continue


if __name__ == "__main__":
    if len(sys.argv) != 8:
        exit("7 required arguments: dir, speaker_list, whitelist, output text file, output scp file, utt2speak file, set")

    corp_dir, speaker_list, white_list, out_text, out_scp, out_spk2utt, set = sys.argv[1:8]
    main(os.path.join(corp_dir, "ADULT1FI"), speaker_list, white_list, out_text, out_scp, out_spk2utt, set=="train")
