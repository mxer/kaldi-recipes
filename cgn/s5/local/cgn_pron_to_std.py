#!/usr/bin/env python3

import collections
import html
import sys

PH_MAP = {}
PH_USED = collections.Counter()


def map_transcript(trans):
    ot = trans

    syl_level = 0

    while len(trans) > 0:

        if trans.startswith("'"):
            syl_level = 1
            trans = trans[1:]
        elif trans.startswith('-'):
            syl_level = 0
            trans = trans[1:]
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


def transform_lexicon(input, output, phone_list, question_list):
    d = {}
    for line in input:
        if "\\" not in line:
            continue

        parts = line.split("\\")
        key, trans = parts[1], parts[10:11]
        key = html.unescape(key)

        d[key] = []
        for t in trans:
            d[key].append(tuple(map_transcript(t)))

    for key, value in d.items():
        for v in set(value):
            print("{} {}".format(key, " ".join(v)), file=output)

    question_map = [set() for _ in range(5)]

    for phone in PH_MAP.keys():
        phone_line = []
        if phone in PH_USED:
            phone_line.append(phone)
            question_map[4].add(phone)
        for i in range(4):
            k = phone + str(i)
            if k in PH_USED:
                phone_line.append(k)
                question_map[i].add(k)
        if len(phone_line) > 0:
            print(" ".join(phone_line), file=phone_list)

    for question in question_map:
        if len(question) > 0:
            print(" ".join(question), file=question_list)


def init_ph_map(vowel_file, consonant_file):
    for l in open(vowel_file):
        if len(l.strip()) > 0:
            PH_MAP[l.strip()] = True

    for l in open(consonant_file):
        if len(l.strip()) > 0:
            PH_MAP[l.strip()] = False


if __name__ == "__main__":
    init_ph_map(sys.argv[1], sys.argv[2])
    transform_lexicon(sys.stdin, sys.stdout, open(sys.argv[3], 'w'), open(sys.argv[4], 'w'))
