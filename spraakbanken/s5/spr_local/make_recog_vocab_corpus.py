#!/usr/bin/env python3

import sys

import collections


def main(in_vocab, size, out_vocab,):
    counter = collections.Counter()
    size = int(size)

    for line in open(in_vocab, encoding='utf-8'):
        for word in line.strip().split(" "):
            if any(x.isdigit() for x in word):
                continue

            punctuation = "\\/?.,!;:\"\'()-=+[]%§*¤ïÐ$&<>#@{}"
            if any(x in punctuation for x in word):
                continue

            counter[word] += 1

    with open(out_vocab, 'w', encoding='utf-8') as out_f:
        for w, c in counter.most_common(size):
            print(w, file=out_f)


if __name__ == "__main__":
    if len(sys.argv) != 4:
        exit("3 arguments: in_vocab, desired_size, out_vocab")

    main(*sys.argv[1:])
