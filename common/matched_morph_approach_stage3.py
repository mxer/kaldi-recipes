#!/usr/bin/env python3
import codecs
import lzma


import argparse

import sys


def main(wordmap,infile,outfile):
    wordmap = {p.split()[0]: p.strip().split(None,1)[1] for p in wordmap}
    wordmap["<s>"]  = "<s>"
    wordmap["</s>"] = "</s>"

    for line in infile:
        print(" ".join(wordmap[w] for w in line.strip().split()), file=outfile)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('wordmap', type=argparse.FileType('r', encoding='utf-8'))
    parser.add_argument('infile', nargs='?', type=argparse.FileType('r', encoding='utf-8'), default=codecs.getreader('utf-8')(sys.stdin.buffer))
    parser.add_argument('outfile', nargs='?', type=argparse.FileType('w', encoding='utf-8'), default=codecs.getwriter('utf-8')(sys.stdout.buffer))


    args = parser.parse_args()

    main(args.wordmap, args.infile, args.outfile)
