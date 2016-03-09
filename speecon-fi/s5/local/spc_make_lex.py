#!/usr/bin/env python3

import sys


def transform_lexicon(input, output, phone_list):
    phone_set = set()

    for line in input:
        orth, freq, pron, _ = line.split("\t")
        if freq == "Frequency":
            continue

        pron = pron.split()
        for c in pron:
            phone_set.add(c)

        print("{} {}".format(orth, " ".join(pron)), file=output)

    for s in "[spk]", "<UNK>":
        print("{} {}".format(s, "NSN"), file=output)

    for phone in phone_set:
        print(phone, file=phone_list)


if __name__ == "__main__":
    transform_lexicon(sys.stdin, sys.stdout, open(sys.argv[1], 'w'))
