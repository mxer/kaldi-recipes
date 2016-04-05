#!/usr/bin/env python3

import sys


def main(in_vocab, size, out_vocab,):
    vocab = set()
    size = int(size)

    for line in open(in_vocab, encoding='utf-8'):
        word = line.strip().split()[0]
        if any(x.isdigit() for x in word):
            continue

        punctuation = "\\/?.,!;:\"\'()-=+[]"
        if any(x in punctuation for x in word):
            continue

        vocab.add(word)
        if len(vocab) >= size:
            break

    with open(out_vocab, 'w', encoding='utf-8') as out_f:
        for w in vocab:
            print(w, file=out_f)


if __name__ == "__main__":
    if len(sys.argv) != 4:
        exit("3 arguments: in_vocab, desired_size, out_vocab")

    main(*sys.argv[1:])