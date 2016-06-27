#!/usr/bin/env python3
import argparse


def main(in_lex, vocab, out_lex, oov):
    d = {}
    for line in in_lex:
        key, trans = line.strip().split(None, 1)
        if key not in d:
            d[key] = set()
        d[key].add(trans)

    for line in vocab:
        word = line.strip().split()[0]

        if word in d:
            for trans in d[word]:
                print("{}\t{}".format(word, trans), file=out_lex)
        else:
            print(word, file=oov)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('inlex', type=argparse.FileType('r', encoding='utf-8'))
    parser.add_argument('invocab', type=argparse.FileType('r', encoding='utf-8'))
    parser.add_argument('outlex', type=argparse.FileType('w', encoding='utf-8'))
    parser.add_argument('oovlist', type=argparse.FileType('w', encoding='utf-8'))
    args = parser.parse_args()

    main(args.inlex, args.invocab, args.outlex, args.oovlist)
