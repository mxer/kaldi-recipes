#!/usr/bin/env python3
import sys

import io

import collections

PH_MAP = {}

SIL_PHONE = "SIL"

PH_USED = collections.Counter()

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
            PH_USED[SIL_PHONE] += 1
            yield SIL_PHONE
        else:
            succ = False
            for k in sorted(PH_MAP.keys(), key=lambda x: -len(x)):
                if not trans.startswith(k):
                    continue
                succ = True
                trans = trans[len(k):]

                if PH_MAP[k]:
                    PH_USED[k + str(syl_level)] += 1
                    yield k + str(syl_level)
                else:
                    PH_USED[k] += 1
                    yield k
                break
            if not succ:
                print("Unknown character {} in {}".format(trans[0], ot), file=sys.stderr)
                trans = trans[1:]


def transform_lexicon(input, output, phone_list):
    d = {}
    for line in input:
        if ";" not in line:
            continue

        parts = line.split(";")
        key, trans = parts[0], parts[11:12]

        # for t in trans:
        #     if len(t) > 0:
        #         print("{} {}".format(key, " ".join(map_transcript(t))), file=output)
        d[key] = []
        for t in trans:
            d[key].append(tuple(map_transcript(t)))

    for key, value in d.items():
        for v in set(value):
            print("{} {}".format(key, " ".join(v)), file=output)

    # for phone, count in PH_USED.most_common():
    #     print("{} {: 7d}".format(phone, count), file=phone_list)

def init_ph_map(vowel_file, consonant_file):
    for l in open(vowel_file):
        if len(l.strip()) > 0:
            PH_MAP[l.strip()] = True

    for l in open(consonant_file):
        if len(l.strip()) > 0:
            PH_MAP[l.strip()] = False


if __name__ == "__main__":
    init_ph_map(sys.argv[1], sys.argv[2])
    # transform_lexicon(io.TextIOWrapper(sys.stdin.buffer, encoding='utf-8'),
    #                   io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8'), sys.stderr)
    transform_lexicon(sys.stdin, sys.stdout, sys.stderr)
