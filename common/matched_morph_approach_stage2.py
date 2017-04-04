#!/usr/bin/env python3

import argparse
import locale
locale.setlocale(locale.LC_ALL, 'C')

def read_lex(inf):
    lex = {}
    for line in inf:
        word, trans = line.split(None, 1)
        if word not in lex:
            lex[word] = []

        lex[word].append(tuple(trans.strip().split()))

    return lex

def main(wordmapin, jointlex, wordmapout, reallex):
    jointlex = read_lex(jointlex)
    jointlex["UNK"] = []
    new_lex = {}

    for line in wordmapin:
        parts = line.strip().split()
        word = parts[0]


        new_parts = []

        for part in parts[1:]:
            base_word = part.strip("|").strip("+").split("#")[0]
            indices = None
            if "#" in part:
                indices = [int(x) for x in part.strip("|").strip("+").split("#")[1].split(",")]

            num_orig_trans = len(jointlex[base_word])
            if indices is not None and num_orig_trans == len(indices):
                indices = None
            
            prefix = ""
            if part.startswith("+"): prefix="+"
            if part.startswith("|"): prefix="|"
            suffix = "+" if part.endswith("+") else ""

            index_string = "#{}".format(",".join(str(x) for x in indices)) if indices is not None else ""

            new_form = "{}{}{}{}".format(prefix,base_word,index_string,suffix)

            if new_form not in new_lex:
                new_lex[new_form] = set()

            if indices is None:
                for t in jointlex[base_word]:
                    new_lex[new_form].add(t)
            else:
                for i in indices:
                    new_lex[new_form].add(jointlex[base_word][i])

            new_parts.append(new_form)

        print("{}\t{}".format(word, " ".join(new_parts)),file=wordmapout)

    for k, v in sorted(new_lex.items(), key=lambda x: locale.strxfrm(x[0])):
        for trans in sorted(set(v), key=lambda x: tuple(locale.strxfrm(y) for y in x)):
            print("{}\t{}".format(k, " ".join(trans)), file=reallex)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('wordmapin', type=argparse.FileType('r', encoding='utf-8'))
    parser.add_argument('jointlex', type=argparse.FileType('r', encoding='utf-8'))
    parser.add_argument('wordmapout', type=argparse.FileType('w', encoding='utf-8'))
    parser.add_argument('reallex', type=argparse.FileType('w', encoding='utf-8'))


    args = parser.parse_args()

    main(args.wordmapin, args.jointlex, args.wordmapout, args.reallex)
