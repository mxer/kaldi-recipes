#!/usr/bin/env python3
import sys


def map_transcript(trans):
    return [trans]


def transform_lexicon(input,output):
    d = {}
    for line in input:
        if ";" not in line:
            continue

        parts = line.split(";")
        key, trans = parts[0], parts[11]

        d[key] = map_transcript(trans)

    for key, value in d.items():
        print("{} {}".format(key, " ".join(value)), file=output)


if __name__ == "__main__":
    transform_lexicon(sys.stdin, sys.stdout)