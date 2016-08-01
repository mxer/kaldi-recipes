#!/usr/bin/env python3

import argparse
import bisect

import itertools


def main(m2m, vocab, outlex, oovlist):
    alignment = {}
    for line in m2m:
        l,r = line.strip().split("\t", 1)
        l_strings = tuple(x for x in l.replace("+", "").split("|") if len(x) > 0)
        l_indexes = tuple([0] + list(itertools.accumulate(len(x) for x in l_strings)))

        r_parts = tuple(tuple(x.split("+")) for x in r.replace("+", "").split("|") if len(x) > 0 )

        alignment[''.join(l_strings)] = (l_indexes, r_parts)

    for v in vocab:
        transcriptions = set()

        si = 1 if v.startswith('+') else 0
        se = len(v)-1 if v.endswith('+') else len(v)

        w = v.strip("+")

        for k, parts in alignment.items():
            start_index = si

            while True:
                try:
                    i = k.index(w, start_index, se)
                    ei = i + len(w)

                    sp = bisect.bisect_left(parts[0], i)
                    if i == parts[0][sp]:
                        possible_starts = {sp}
                    else:
                        possible_starts = {sp-1, sp}

                    ep = bisect.bisect_left(parts[0], ei)
                    if ei == parts[0][ep]:
                        possible_ends = {ep}
                    else:
                        possible_ends = {ep -1, ep}

                    for s, e in itertools.product(possible_starts, possible_ends):
                        transcriptions.add(tuple(itertools.chain(*parts[1][s:e])))

                    start_index = i + 1
                except ValueError:
                    break

        if len(transcriptions) == 0:
            print(v, file=oovlist)
        else:
            for t in transcriptions:
                print("{} {}".format(v, " ".join(t), file=outlex))

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('inm2m', type=argparse.FileType('r', encoding='utf-8'))
    parser.add_argument('invocab', type=argparse.FileType('r', encoding='utf-8'))
    parser.add_argument('outlex', type=argparse.FileType('w', encoding='utf-8'))
    parser.add_argument('oovlist', type=argparse.FileType('w', encoding='utf-8'))
    args = parser.parse_args()

    main(args.inm2m, args.invocab, args.outlex, args.oovlist)
