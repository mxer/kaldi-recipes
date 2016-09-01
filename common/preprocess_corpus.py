#!/usr/bin/env python3
import argparse
import lzma
import sys
import unicodedata


def preprocess_corpus(inf, outf):
    outf = lzma.open(outf, 'wt', encoding='utf-8')
    for line in lzma.open(inf, 'rt', encoding='utf-8'):
        if line.startswith("FILE"):
            continue

        sent = []

        for w in line.lower().strip().split():
            if not any(unicodedata.category(c).startswith("L") for c in w):
                continue
            if w == "<s>" or w == "</s>":
                continue
            sent.append(w.strip("!?.,:;\"<>(){}[]#+"))

        if len(sent) == 0:
            continue

        print("<s> {} </s>".format(" ".join(sent)), file=outf)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='')
    parser.add_argument('infile', nargs='?', type=argparse.FileType('rb'), default=sys.stdin.buffer)
    parser.add_argument('outfile', nargs='?', type=argparse.FileType('wb'), default=sys.stdout.buffer)

    args = parser.parse_args()

    preprocess_corpus(args.infile, args.outfile)
