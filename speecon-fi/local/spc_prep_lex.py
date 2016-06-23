#!/usr/bin/env python3
import argparse
import sys


def transform_lexicon(input, output):
    phone_set = set()

    for line in input:
        orth, freq, pron, _ = line.split("\t")
        if freq == "Frequency":
            continue

        pron = pron.split()
        for c in pron:
            phone_set.add(c)

        print("{} {}".format(orth, " ".join(pron)), file=output)

    for s in "[spk]", "<UNK>":
        print("{} {}".format(s, "SPN"), file=output)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='')
    parser.add_argument('infile', nargs='?', type=argparse.FileType('r', encoding='iso-8859-15'), default=sys.stdin)
    parser.add_argument('outfile', nargs='?', type=argparse.FileType('w', encoding='utf-8'), default=sys.stdout)

    args = parser.parse_args()

    transform_lexicon(args.infile, args.outfile)
