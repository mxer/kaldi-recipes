#!/usr/bin/env python3

import sys


def transform_lexicon(input, output, phone_list):
    word_list = set()
    phone_set = set()
    for line in input:
        for word in line.split()[1:]:
            word_list.add(word)

    for word in word_list:
        print("{} {}".format(word, " ".join(list(word))), file=output)
        for c in word:
            phone_set.add(c)

    for phone in phone_set:
        print(phone, file=phone_list)


if __name__ == "__main__":
    transform_lexicon(sys.stdin, sys.stdout, open(sys.argv[1], 'w'))
