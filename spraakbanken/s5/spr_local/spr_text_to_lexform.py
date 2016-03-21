#!/usr/bin/env python3

import sys


def map_word(word, lexicon, first_word_in_sentence):
    if "\\" in word:
        i = word.index("\\") - 1
        return map_word(word[:i], lexicon, first_word_in_sentence) + map_word(word[i+2:], lexicon, False)

    if "." in word[:-1]:
        p1, p2 = word.split(".", 1)
        return map_word(p1, lexicon, first_word_in_sentence) + map_word(p2, lexicon, False)

    if "," in word[:-1]:
        p1, p2 = word.split(",", 1)
        return map_word(p1, lexicon, first_word_in_sentence) + map_word(p2, lexicon, False)

    if "?" in word[:-1]:
        p1, p2 = word.split("?", 1)
        return map_word(p1, lexicon, first_word_in_sentence) + map_word(p2, lexicon, False)

    if word not in lexicon:
        word = word.strip("!,;?.\"+-")
        if word not in lexicon and word.lower() in lexicon:
            word = word.lower()
        if word not in lexicon and first_word_in_sentence:
            word = word.lower()

    if len(word.strip()) > 0:
        return [word]
    else:
        return []


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
                    # print("OOV WORD: {}".format(word))

        print("{} {}".format(key, " ".join(sent)), file=text_out)

    for word in sorted(oov):
        print(word, file=oov_out)


if __name__ == "__main__":
    text_in = open(sys.argv[1], encoding='utf-8')
    text_out = open(sys.argv[2], 'w', encoding='utf-8')
    oov_out = open(sys.argv[3], 'w', encoding='utf-8')
    lexicon = {w.strip().split()[0] for w in open(sys.argv[4], encoding='utf-8')}

    map(text_in, text_out, oov_out, lexicon)
