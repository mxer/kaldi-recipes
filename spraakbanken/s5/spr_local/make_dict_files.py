#!/usr/bin/env python3
import argparse
import os
import sys


def main(lex_dir, vowels, consonants, accents):
    consonants = {c.strip() for c in open(consonants, encoding='utf-8')}
    vowels = {c.strip() for c in open(vowels, encoding='utf-8')}

    phones = set()
    for line in open(os.path.join(lex_dir, 'lexicon.txt'), encoding='utf-8'):
        word, trans = line.strip().split("\t", 1)
        for t in trans.split():
            phones.add(t)

    phones_f = open(os.path.join(lex_dir, 'nonsilence_phones.txt'), 'w', encoding='utf-8')

    for c in consonants:
        if c in phones:
            print(c, file=phones_f)

    quest_f = open(os.path.join(lex_dir, 'extra_questions.txt'), 'w', encoding='utf-8')

    if accents:
        groups = []
        for _ in range(4):
            groups.append(set())

        for v in vowels:
            active_vowels = ["{}{}".format(v,a) for a in range(4)]# if "{}{}".format(v,a) in phones]
            if len(active_vowels) > 0:
                print(" ".join(sorted(active_vowels)), file=phones_f)

            for a in active_vowels:
                groups[int(a[-1])].add(a)

        for g in groups:
            if len(g) > 0:
                print(" ".join(sorted(g)), file=quest_f)
    else:
        for v in vowels:
            if v in phones:
                print(v, file=phones_f)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Make necessary files for dict directory')
    parser.add_argument('--no-accents', dest='accents', default=True, action='store_false',
                        help='Do not add accents to vowels')
    parser.add_argument('lexdir')
    parser.add_argument('vowelfile')
    parser.add_argument('consonantfile')

    args = parser.parse_args()

    main(args.lexdir, args.vowelfile, args.consonantfile, args.accents)