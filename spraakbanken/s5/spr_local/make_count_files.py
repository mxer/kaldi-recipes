#!/usr/bin/env python3

import argparse

import collections
import os
from fractions import Fraction


def main(countfile, origcount, order, outdir):
    vocab = {"<s>": 0, "</s>": 1}

    counters = [None]
    for _ in range(order+1):
        counters.append(collections.Counter())

    def map_vocab(line):

        for w in set(line):
            if w not in vocab:
                vocab[w] = len(vocab)

        return [vocab[w] for w in line]

    for line in open(countfile, encoding='utf-8'):
        parts = line.split()
        words = parts[:-1]
        count = int(parts[-1])
        iwords = map_vocab(words)

        always_one = False
        if iwords[0] == 0 and iwords[-1] == 1:
            always_one = True
        for to in range(1, order+1):
            for s in range(0, len(iwords)-to+1):
                tt = tuple(iwords[s:s+to])
                parts = 1
                if iwords[0] == 0 and s+to < origcount:
                    parts += origcount - (s+to)
                if iwords[-1] == 1 and s > 0:
                    parts += s
                if 0 in tt or 1 in tt or always_one:
                    counters[to][tt] += count
                else:
                    counters[to][tt] += parts * Fraction(count,(origcount-to+1))

    rev_vocab = [k for k,v in sorted(vocab.items(), key=lambda x: x[1])]
    for i in range(1, order+1):
        with open(os.path.join(outdir, '{}count'.format(i)), 'w', encoding='utf-8') as of:
            for k, c in counters[i].most_common():
                print("{} {}".format(" ".join(rev_vocab[j] for j in k), int(c)), file=of)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Make count files')
    parser.add_argument('countfile')
    parser.add_argument('origcount', type=int)
    parser.add_argument('order', type=int)
    parser.add_argument('outdir')

    args = parser.parse_args()
    main(args.countfile, args.origcount, args.order, args.outdir)