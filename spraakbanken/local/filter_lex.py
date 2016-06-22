#!/usr/bin/env python3

import sys


def main(in_lex, vocab, out_lex, oov):
    d = {}
    for line in open(in_lex, encoding='utf-8'):
        key, trans = line.strip().split("\t", 1)
        if key not in d:
            d[key] = set()
        d[key].add(trans)

    out_lex = open(out_lex, 'w', encoding='utf-8')
    out_oov = open(oov, 'w', encoding='utf-8')

    for line in open(vocab, encoding='utf-8'):
        word = line.strip().split()[0]

        if word in d:
            for trans in d[word]:
                print("{}\t{}".format(word, trans), file=out_lex)
        else:
            print(word, file=out_oov)


if __name__ == "__main__":
    if len(sys.argv) != 5:
        exit("4 required arguments: in_lex, vocab, out_lex, oov")

    main(*sys.argv[1:])
