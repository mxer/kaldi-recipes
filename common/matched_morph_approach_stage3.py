#!/usr/bin/env python3
import codecs
import lzma


import argparse

import sys


def main(wordmap,infile,outfile,wordsep):
    wordmap = {p.split()[0]: p.strip().split(None,1)[1] for p in wordmap}
    wordmap["<s>"]  = "<s>"
    wordmap["</s>"] = "</s>"

    for line in infile:
        parts = line.strip().split()
        if parts[0] != "<s>":
            parts = ["<s>"] + parts
        if parts[-1] != "</s>":
            parts.append("</s>")
        print(wordsep.join((wordmap[w] if w in wordmap else "<UNK>") for w in parts), file=outfile)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('wordmap', type=argparse.FileType('r', encoding='utf-8'))
    parser.add_argument('infile', nargs='?', type=argparse.FileType('r', encoding='utf-8'), default=codecs.getreader('utf-8')(sys.stdin.buffer))
    parser.add_argument('outfile', nargs='?', type=argparse.FileType('w', encoding='utf-8'), default=codecs.getwriter('utf-8')(sys.stdout.buffer))
    parser.add_argument('wordsep', nargs='?', default=" ")


    args = parser.parse_args()

    main(args.wordmap, args.infile, args.outfile, args.wordsep)
