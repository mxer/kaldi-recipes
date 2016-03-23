#!/usr/bin/env python3

import os
import sys


PH_MAP = {}

SIL_PHONE = "SIL"


def map_transcript(trans):
    ot = trans

    syl_level = 0

    while len(trans) > 0:

        if trans.startswith('""'):
            syl_level = 3
            trans = trans[2:]
        elif trans.startswith('"'):
            syl_level = 2
            trans = trans[1:]
        elif trans.startswith('%'):
            syl_level = 1
            trans = trans[1:]
        elif trans.startswith('$'):
            syl_level = 0
            trans = trans[1:]
        elif trans.startswith('-'):
            trans = trans[1:]
        elif trans.startswith('¤'):
            trans = trans[1:]
        elif trans.startswith('_'):
            trans = trans[1:]
            yield SIL_PHONE
        else:
            succ = False
            for k in sorted(PH_MAP.keys(), key=lambda x: -len(x)):
                if not trans.startswith(k):
                    continue
                succ = True
                trans = trans[len(k):]

                if PH_MAP[k]:
                    yield k + str(syl_level)
                else:
                    yield k
                break
            if not succ:
                print("Unknown character {} in {}".format(trans[0], ot), file=sys.stderr)
                trans = trans[1:]


def transform_lexicon(input, output):
    d = {"<UNK>": [("SPN",)], }

    for line in input:
        if ";" not in line:
            continue

        parts = line.split(";")
        key, trans = parts[0], parts[11:12]

        d[key] = []
        for t in trans:
            d[key].append(tuple(map_transcript(t)))

    for key, value in d.items():
        for v in set(value):
            print("{}\t{}".format(key, " ".join(v)), file=output)


def init_ph_map(vowel_file, consonant_file):
    for l in open(vowel_file):
        if len(l.strip()) > 0:
            PH_MAP[l.strip()] = True

    for l in open(consonant_file):
        if len(l.strip()) > 0:
            PH_MAP[l.strip()] = False


if __name__ == "__main__":
    if len(sys.argv) != 5:
        exit("4 required arguments: source data directory, output lexicon, vowel file, consonants file")

    init_ph_map(*sys.argv[3:5])
    out_file = open(sys.argv[2], 'w', encoding='utf-8')

    for root, dirs, files in os.walk(os.path.normpath(sys.argv[1])):
        for f in files:
            if f.endswith(".pron"):
                in_file = open(os.path.join(root, f), encoding='cp1252')
                transform_lexicon(in_file, out_file)
