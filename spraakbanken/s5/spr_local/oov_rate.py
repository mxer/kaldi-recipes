#!/usr/bin/env python3

import sys


def oov_rate(test_list, vocab):
    vocab = {line.strip().split()[0].lower() for line in open(vocab, encoding='utf-8')}

    tot_count = 0
    oov_count = 0

    for line in open(test_list, encoding='utf-8'):
        word, count = line.strip().split()
        count = int(count)

        tot_count += count
        if word.lower() not in vocab:
            print(word.lower())
            oov_count += count

    return oov_count / tot_count


if __name__ == "__main__":
    if len(sys.argv) != 3:
        exit("2 required arguments: test_list and vocab")

    test_list, vocab = sys.argv[1:3]

    print(oov_rate(test_list, vocab))
