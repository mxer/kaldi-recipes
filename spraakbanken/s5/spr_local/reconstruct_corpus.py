#!/usr/bin/env python3

import argparse
import collections
import random

import sys


def reconstruct(f_in, f_out):
    sentence_starts = []

    contexts = {}

    for line in f_in:
        parts = line.split()
        words = parts[:-1]
        count = int(parts[-1])

        if words[0] == "<s>" and words[-1] == "</s>":
            for _ in range(count):
                print(" ".join(words), file=f_out)
            continue

        context = tuple(words[:-1])
        if context not in contexts:
            contexts[context] = collections.Counter()

        contexts[context][words[-1]] += count

    random.shuffle(sentence_starts)

    c = len(sentence_starts[0]) - 1

    for start in sentence_starts:
        line = list(start)
        while line[-1] != "</s>":
            context = line[:-c]
            next_word = contexts[context].most_common(1)[0][0]
            contexts[context][next_word] -= 1
            line.append(next_word)

        print(" ".join(line), file=f_out)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Construct corpus')

    parser.add_argument('infile', nargs='?', type=argparse.FileType('r', encoding='utf-8'), default=sys.stdin)
    parser.add_argument('outfile', nargs='?', type=argparse.FileType('w', encoding='utf-8'), default=sys.stdout)

    args = parser.parse_args()

    reconstruct(args.infile, args.outfile)


