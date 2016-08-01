#!/usr/bin/env python3

import argparse
import bisect

import itertools

import sys


def main(m2m, morph_list, outlex, oovlist):
    alignment = {}
    for line in m2m:
        l,r = line.strip().split("\t", 1)
        l_strings = tuple(x for x in l.replace("+", "").split("|") if len(x) > 0)
        l_indexes = tuple([0] + list(itertools.accumulate(len(x) for x in l_strings)))

        r_parts = tuple(tuple(x.split("+")) for x in r.replace("+", " ").split("|") if len(x) > 0 )

        alignment[''.join(l_strings)] = (l_indexes, r_parts)

    print("m2m loaded", file=sys.stderr)
    for v in morph_list:
        word = v.strip().replace("+ +", "")
        if word not in alignment:
            print(v.strip(), file=oovlist)
            continue

        parts = alignment[word]
        si = 0
        for m in v.strip().split():
            cm = m.strip("+")
            ei = si + len(cm)

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
                    print("".format(m, " ".join(itertools.chain(*parts[1][s:e]))), file=outlex)
            si = ei

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('inm2m', type=argparse.FileType('r', encoding='utf-8'))
    parser.add_argument('inmorph', type=argparse.FileType('r', encoding='utf-8'))
    parser.add_argument('outlex', type=argparse.FileType('w', encoding='utf-8'))
    parser.add_argument('oovlist', type=argparse.FileType('w', encoding='utf-8'))
    args = parser.parse_args()

    main(args.inm2m, args.inmorph, args.outlex, args.oovlist)
