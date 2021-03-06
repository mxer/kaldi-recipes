#!/usr/bin/env python3
import locale
locale.setlocale(locale.LC_ALL, 'C')
import argparse
import codecs
import collections
import itertools
import lzma
import sys
import unicodedata

from signal import signal, SIGPIPE, SIG_DFL 
signal(SIGPIPE,SIG_DFL) 

def count_words(inf, outf, nmost, lexicon, inword_punc):
    inword_punc = set(inword_punc)
    chars_in_lex = None
    if lexicon is not None:
        lexicon = {p.split()[0] for p in lexicon}
        chars_in_lex = set(itertools.chain(*lexicon))

#    inf = lzma.open(inf, 'rt', encoding='utf-8')
    c = collections.Counter()
    for line in inf:
        for word in line.split():
            if lexicon is not None and (word in lexicon or all(c in chars_in_lex and (unicodedata.category(c).startswith("L") or (c in inword_punc)) for c in word)):
                c[word] += 1
            elif lexicon is None and all(unicodedata.category(c).startswith("L") or (c in inword_punc) for c in word):
                c[word] += 1

    if "<s>" in c:
        del c["<s>"]

    if "</s>" in c:
        del c["</s>"]

    for k,c in sorted(c.items(), key=lambda x: (-x[1], locale.strxfrm(x[0]))):
        print("{}\t{}".format(k,c), file=outf)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='')
    parser.add_argument('infile', nargs='?', type=argparse.FileType('r', encoding='utf-8'), default=codecs.getreader('utf-8')(sys.stdin.buffer))
    parser.add_argument('outfile', nargs='?', type=argparse.FileType('w', encoding='utf-8'), default=codecs.getwriter('utf-8')(sys.stdout.buffer))
    parser.add_argument("--nmost", type=int, default=None)
    parser.add_argument("--lexicon", type=argparse.FileType('r', encoding='utf-8'), default=None, help="Accept always items that are in this lexicon")
    parser.add_argument("--inword_punc", default="-:'", help="reject words that have punctuation other than this")

    args = parser.parse_args()

    count_words(args.infile, args.outfile, args.nmost, args.lexicon, args.inword_punc)
