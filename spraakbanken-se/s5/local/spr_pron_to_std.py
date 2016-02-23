#!/usr/bin/env python3
import sys


def map_transcript(trans):
    syllables = trans.split("$")

    for syl in syllables:
        syl_level = ""
        if syl.starswith('""'):
            syl_level = "3"
            syl = syl[2:]
        elif syl.starswith('"'):
            syl_level = "2"
            syl = syl[1:]
        elif syl.starswith('%'):
            syl_level = "1"
            syl = syl[1:]




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