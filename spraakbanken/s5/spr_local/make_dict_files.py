#!/usr/bin/env python3
import os
import sys


def main(lex_dir, vowels, consonants):
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

    groups = []
    for _ in range(4):
        groups.append(set())

    for v in vowels:
        active_vowels = ["{}{}".format(v,a) for a in range(4) if "{}{}".format(v,a) in phones]
        if len(active_vowels) > 0:
            print(" ".join(sorted(active_vowels)), file=phones_f)

        for a in active_vowels:
            groups[int(a[-1])].add(a)

    quest_f = open(os.path.join(lex_dir, 'extra_questions.txt'), 'w', encoding='utf-8')
    for g in groups:
        print(" ".join(sorted(g)), file=quest_f)


if __name__ == "__main__":
    if len(sys.argv) != 4:
        exit("3 required arguments: lex_dir, vowels, consonants")

    main(*sys.argv[1:])