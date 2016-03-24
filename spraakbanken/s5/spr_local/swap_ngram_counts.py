#!/usr/bin/env python3

import sys


def swap_counts(in_f, out_f):
    for line in in_f:
        count, rest = line.strip(" \n").split(' ', maxsplit=1)
        print("{} {}".format(rest, count), file=out_f)


if __name__ == "__main__":
    if len(sys.argv) != 3:
        exit("2 required arguments: input, output")

    in_f = open(sys.argv[1], encoding='cp1252')
    out_f = open(sys.argv[2], 'w', encoding='utf-8')
    swap_counts(in_f, out_f)