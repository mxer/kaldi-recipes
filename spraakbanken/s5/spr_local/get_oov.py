#!/usr/bin/env python3

import sys

def main(lexicon_file, vocab_file):
    lexicon = {p.split()[0] for p in open(lexicon_file, encoding='utf-8')}

    for v in open(vocab_file, encoding='utf-8'):
        if v.strip() not in lexicon:
            print(v)


if __name__ == "__main__":
    if len(sys.argv) != 3:
        exit("3 required arguments: lexicon, vocab")

    main(*sys.argv[1:])
