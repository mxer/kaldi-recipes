#!/usr/bin/env python3
import os
import sys

import textgridshort


def main(wav_list, ort_list, out_text, out_scp, out_segments, out_spk2utt):
    wavs = {os.path.splitext(os.path.basename(f))[0]: f for f in open(wav_list)}
    orts = {os.path.splitext(os.path.basename(f))[0]: f for f in open(ort_list)}

    fd_text = open(out_text, 'w', encoding='utf-8')
    fd_scp = open(out_scp, 'w', encoding='utf-8')
    fd_segments = open(out_segments, 'w', encoding='utf-8')
    fd_spk2utt = open(out_spk2utt, 'w', encoding='utf-8')

    for k in orts.keys():
        if k not in wavs:
            continue
        wav = wavs[k]
        ort = orts[k]

        tgs = textgridshort.TextGridShort(ort)

        print("{} sph2pipe -f wav -p -c 1 {} |".format(k, wav), file=fd_scp)

        for record in tgs.records():
            utt_key, start, end, text = record
            print("{} {}".format(utt_key, text), file=fd_text)
            print("{} {}".format(utt_key, utt_key.split('-')[0]), file=fd_spk2utt)
            print("{} {} {} {}".format(utt_key, k, start, end), file=fd_segments)


if __name__ == "__main__":
    if len(sys.argv) != 7:
        exit("6 required arguments: wav_list, ort_list, output text file, output scp file, output segments file, utt2speak file")

    wav_list, ort_list, out_text, out_scp, out_segments, out_spk2utt = sys.argv[1:7]
    main(wav_list, ort_list, out_text, out_scp, out_segments, out_spk2utt)

