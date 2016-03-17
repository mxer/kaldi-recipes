#!/usr/bin/env python3

import sys

SIL_PHONE="SIL"

def main(g2p_dir, orig, vocab, new):
    orig_lex = {}
    for line in open(orig_lex, encoding='utf-8'):
        parts = line.strip().split()


if __name__ == "__main__":
    if len(sys.argv) != 5:
        exit("4 required arguments: g2p directory, orig lexicon, word list, new lexicon")

    main(*sys.argv[1:])