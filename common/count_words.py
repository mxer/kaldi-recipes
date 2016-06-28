import argparse
import codecs

import sys

import collections


def count_words(inf, outf, nmost):
    c = collections.Counter()
    for line in inf:
        c.update(line.split())

    if "<s>" in c:
        del c["<s>"]

    if "</s>" in c:
        del c["</s>"]

    for k,c in c.most_common(nmost):
        print("{}\t{}".format(k,c), file=outf)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='')
    parser.add_argument('infile', nargs='?', type=argparse.FileType('r', encoding='utf-8'), default=codecs.getreader('utf-8')(sys.stdin.buffer))
    parser.add_argument('outfile', nargs='?', type=argparse.FileType('w', encoding='utf-8'), default=codecs.getwriter('utf-8')(sys.stdout.buffer))
    parser.add_argument("--nmost", type=int, default=None)

    args = parser.parse_args()

    count_words(args.infile, args.outfile, args.nmost)
