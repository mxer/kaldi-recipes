#!/usr/bin/env python3
import argparse
import os
import sys

import collections


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


def main(dir, lexicon, lowercase=False):
    lexicon = {l.strip().split("\t")[0] for l in open(lexicon, encoding='utf-8')}
    vocab = collections.Counter()

    cleaned_f = open(os.path.join(dir, 'text'), 'w', encoding='utf-8')

    for line in open(os.path.join(dir, 'text.orig'), encoding='utf-8'):
        key, rest = line.strip().split(None, 1)
        sent = []
        for i, word in enumerate(rest.split()):
            if lowercase:
                word = word.lower()
            sent.extend(map_word(word, lexicon, i == 0))

        for word in sent:
            vocab[word] += 1

        print("{} {}".format(key, " ".join(sent)), file=cleaned_f)

    with open(os.path.join(dir, 'vocab'), 'w', encoding='utf-8') as vocab_f:
        for word, count in vocab.most_common():
            print("{}\t{}".format(word, count), file=vocab_f)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Preprocess text')
    parser.add_argument('--lowercase', dest='lowercase', default=False, action='store_true', help='Lowercase dict keys')

    parser.add_argument('directory')
    parser.add_argument('lexicon')

    args = parser.parse_args()

    main(args.directory, args.lexicon, args.lowercase)
