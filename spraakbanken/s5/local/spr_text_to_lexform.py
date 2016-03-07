#!/usr/bin/env python3

import sys


def map_word(word, lexicon, first_word_in_sentence):
    punc = None
    if "\\" in word:
        i = word.index("\\") -1
        punc = word[i:]
        word = word[:i]

    if word not in lexicon:
        word = word.strip(",;?.")
        if word not in lexicon and word.lower() in lexicon:
            word = word.lower()
        if word not in lexicon and first_word_in_sentence:
            word = word.lower()

    if punc is None:
        return [word]
    else:
        return [word, punc]


def map(text_in, text_out, oov_out, lexicon):
    oov = set()
    for line in text_in:
        key, rest = line.strip().split(None, 1)
        sent = []
        for i, word in enumerate(rest.split()):
            sent.extend(map_word(word, lexicon, i == 0))
        for word in sent:
            if word not in lexicon:
                if word not in oov:
                    oov.add(word)
                    print("OOV WORD: {}".format(word))

        print("{} {}".format(key, " ".join(sent)), file=text_out)

    for word in sorted(oov):
        print(word, file=oov_out)


if __name__ == "__main__":
    text_in = open(sys.argv[1], encoding='utf-8')
    text_out = open(sys.argv[2], 'w', encoding='utf-8')
    oov_out = open(sys.argv[3], 'w', encoding='utf-8')
    lexicon = {w.strip().split()[0] for w in open(sys.argv[4], encoding='utf-8')}

    map(text_in, text_out, oov_out, lexicon)
