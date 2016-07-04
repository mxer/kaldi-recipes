#!/usr/bin/env python3
import argparse
import tarfile

import sys
from pynlpl.formats import folia


def main(infile, outfile):

    t = tarfile.open(mode='r|*', fileobj=infile)

    for ti in t:
        if not ti.name.endswith(".folia.xml"):
            continue

        print("FILE: {}".format(ti.name), file=outfile)
        print("FILE: {}".format(ti.name), )

        for s in folia.Document(string=t.extractfile(ti).read()).sentences():
            print(s, file=outfile)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Extract corpus from SoNaR')
    parser.add_argument('infile', nargs='?', type=argparse.FileType('rb'), default=sys.stdin)
    parser.add_argument('outfile', nargs='?', type=argparse.FileType('w', encoding='utf-8'), default=sys.stdout)

    args = parser.parse_args()

    main(args.infile, args.outfile)
