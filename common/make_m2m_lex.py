#!/usr/bin/env python3

import argparse


def main(m2m, vocab, outlex, oovlist):
    alignment = {}
    for line in m2m:
        l,r = line.strip().split("\t", 1)
        l_parts = tuple(x for x in l.replace("+", "").split("|") if len(x) > 0)
        r_parts = tuple(tuple(x.split("+")) for x in r.replace("+", "").split("|") if len(x) > 0 )

        alignment[''.join(l_parts)] = (l_parts, r_parts)

    for v in vocab:
        transcriptions = set()
        si = 1 if v.startswith('+') else 0
        se = len(v)-1 if v.endswith('+') else len(v)

        for k, parts in alignment.items():
            if v in k:
                pass #todo




if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('inm2m', type=argparse.FileType('r', encoding='utf-8'))
    parser.add_argument('invocab', type=argparse.FileType('r', encoding='utf-8'))
    parser.add_argument('outlex', type=argparse.FileType('w', encoding='utf-8'))
    parser.add_argument('oovlist', type=argparse.FileType('w', encoding='utf-8'))
    args = parser.parse_args()



    main(args.inm2m, args.invocab, args.outlex, args.oovlist)
