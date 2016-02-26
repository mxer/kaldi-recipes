#!/usr/bin/env python3

import sys


def map(text_in, text_out, lexicon, mwe_lex):
    for line in text_in:
        key, rest = line.strip().split(None, 1)
        sent = []
        for word in rest.split():
            r = word
            if word not in lexicon:

                if word.strip(".,!\":;\'") in lexicon:
                    r = word.strip(".,!\":;\'")
                elif word.strip(".,!\":;\'").lower() in lexicon:
                    r = word.strip(".,!\":;\'").lower()
                else:
                    print("OOV word: {}".format(word))
            sent.append(r)
        print("{} {}".format(key, " ".join(sent)), file=text_out)


if __name__ == "__main__":
    text_in = open(sys.argv[1], encoding='utf-8')
    text_out = open(sys.argv[2], 'w', encoding='utf-8')
    lexicon = {w.strip().split()[0] for w in open(sys.argv[3], encoding='utf-8')}

    map(text_in, text_out, lexicon, {})
