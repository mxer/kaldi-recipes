#!/usr/bin/env python3

import sys


def map(text_in, text_out):
    for line in text_in:
        key, rest = line.strip().split(None, 1)
        sent = []
        for i, word in enumerate(rest.split()):
            sent.append(word.translate(str.maketrans("", "", "_-.")))

        print("{} {}".format(key, " ".join(sent)), file=text_out)


if __name__ == "__main__":
    text_in = open(sys.argv[1], encoding='utf-8')
    text_out = open(sys.argv[2], 'w', encoding='utf-8')

    map(text_in, text_out)
