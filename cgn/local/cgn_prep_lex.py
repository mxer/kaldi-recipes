#!/usr/bin/env python3

import argparse
import html
import sys


def map_transcript(s):
    modifiers = {"+", "~", ":"}
    ignore = {"-", "'"}

    while len(s) > 0:
        if s[0] in ignore:
            pass
        elif len(s) > 1 and s[1] in modifiers:
            yield s[:2]
            s = s[1:]
        else:
            yield s[0]

        s = s[1:]


def main(inf, outf, lowercase):
    d = {"<UNK>": {("SPN",), }, }

    for line in inf:
        parts = line.split("\\")
        key, trans = html.unescape(parts[1]), parts[10]

        if lowercase:
            key = key.lower()

        if key not in d:
            d[key] = set()

        d[key].add(tuple(map_transcript(trans)))

    for key, value in d.items():
        for v in value:
            if len(" ".join(v).strip()) > 0:
                print("{} {}".format(key, " ".join(v)), file=outf)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('infile', nargs='?', type=argparse.FileType('r', encoding='ascii'), default=sys.stdin)
    parser.add_argument('outfile', nargs='?', type=argparse.FileType('w', encoding='utf-8'), default=sys.stdout)
    parser.add_argument('--lowercase', action='store_true', default=False)

    args = parser.parse_args()

    main(args.infile, args.outfile, args.lowercase)
