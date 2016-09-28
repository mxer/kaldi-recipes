#!/usr/bin/env python3

import argparse


def main(vocab, text):
    vocab = set(l.strip().split()[0] for l in vocab)

    count = 0
    count_oov = 0
    for line in text:
        for word in line.strip().split()[1:]:
            count += 1
            if word not in vocab:
                count_oov += 1

    print("OOV rate {}".format(float(count_oov) / float(count)))


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('vocab', type=argparse.FileType('r', encoding='utf-8'))
    parser.add_argument('text', type=argparse.FileType('r', encoding='utf-8'))

    args = parser.parse_args()

    main(args.vocab, args.text)
