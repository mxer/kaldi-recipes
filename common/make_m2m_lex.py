#!/usr/bin/env python3

import argparse
import bisect

import itertools

import sys


def main(m2m, vocab, outlex, oovlist):
    alignment = {}
    for line in m2m:
        l,r = line.strip().split("\t", 1)
        l_strings = tuple(x for x in l.replace("+", "").split("|") if len(x) > 0)
        l_indexes = tuple([0] + list(itertools.accumulate(len(x) for x in l_strings)))

        r_parts = tuple(tuple(x.split("+")) for x in r.replace("+", "").split("|") if len(x) > 0 )

        alignment[''.join(l_strings)] = (l_indexes, r_parts)

    print("m2m loaded", file=sys.stderr)
    for v in vocab:
        v = v.strip()
        print("word {}".format(v), file=sys.stderr)
        transcriptions = set()
        #
        # si = 1 if v.startswith('+') else 0
        # se = len(v)-1 if v.endswith('+') else len(v)

        w = v.strip("+")

        for k, parts in alignment.items():

            if w not in k:
                continue

            if not v.startswith('+'):
                if not k.startswith(w):
                    continue
                si = 0
                ei = len(w)
            elif not v.endswith('+'):
                if not k.endswith(w):
                    continue
                si = len(k) - len(w)
                ei = len(k)
            else:
                si = k.index(w)
                ei = si + len(w)

            sp = bisect.bisect_left(parts[0], si)
            if si == parts[0][sp]:
                possible_starts = {sp}
            else:
                possible_starts = {sp - 1, sp}

            ep = bisect.bisect_left(parts[0], ei)
            if ei == parts[0][ep]:
                possible_ends = {ep}
            else:
                possible_ends = {ep - 1, ep}

            for s, e in itertools.product(possible_starts, possible_ends):
                if e > s:
                    transcriptions.add(tuple(itertools.chain(*parts[1][s:e])))

        if len(transcriptions) == 0:
            print(v, file=oovlist)
        else:
            for t in transcriptions:
                print("{} {}".format(v, " ".join(t)), file=outlex)

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('inm2m', type=argparse.FileType('r', encoding='utf-8'))
    parser.add_argument('invocab', type=argparse.FileType('r', encoding='utf-8'))
    parser.add_argument('outlex', type=argparse.FileType('w', encoding='utf-8'))
    parser.add_argument('oovlist', type=argparse.FileType('w', encoding='utf-8'))
    args = parser.parse_args()

    main(args.inm2m, args.invocab, args.outlex, args.oovlist)
