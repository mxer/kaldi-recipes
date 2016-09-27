#!/usr/bin/env python3

import lzma


import argparse

import sys


def main(wordmap,infile,outfile):
    wordmap = {p.split()[0]: p.strip().split(None,1)[1] for p in wordmap}
    wordmap["<s>"]  = "<s>"
    wordmap["</s>"] = "</s>"

    outfile = lzma.open(outfile, 'wt', encoding='utf-8')
    for line in lzma.open(infile, 'rt', encoding='utf-8'):
        print(" ".join(wordmap[w] for w in line.strip().split()), file=outfile)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('wordmap', type=argparse.FileType('r', encoding='utf-8'))
    parser.add_argument('infile', nargs='?', type=argparse.FileType('rb'), default=sys.stdin.buffer)
    parser.add_argument('outfile', nargs='?', type=argparse.FileType('wb'), default=sys.stdout.buffer)


    args = parser.parse_args()

    main(args.wordmap, args.infile, args.outfile)
