#!/usr/bin/env python3
import argparse
import codecs

import sys


def transform(i,o):
    for line in i:
        if len(line.strip()) == 0:
            continue
        key, trans = line.strip().split(None, 1)
        ntrans = []
        for t in trans.split():
            if t.startswith("<"):
                continue
            ntrans.append(t.lower())
        print("{} {}".format(key, " ".join(ntrans)), file=o)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='')
    parser.add_argument('infile', nargs='?', type=argparse.FileType('r', encoding='utf-8'), default=codecs.getreader('utf-8')(sys.stdin.buffer))
    parser.add_argument('outfile', nargs='?', type=argparse.FileType('w', encoding='utf-8'), default=codecs.getwriter('utf-8')(sys.stdout.buffer))

    args = parser.parse_args()

    transform(args.infile, args.outfile)