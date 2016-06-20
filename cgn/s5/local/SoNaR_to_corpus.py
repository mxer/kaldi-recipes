#!/usr/bin/env python3
import argparse
import tarfile

from pynlpl.formats import folia


def main(selection, infile, outfile):
    with open(outfile, 'w', encoding='utf-8') as of:
        t = tarfile.open(infile, 'r|*')

        for ti in t:
            if not ti.name.endswith(".folia.xml") or not any(c in ti.name for c in selection):
                print(".", end="")
                continue

            print("FILE: {}".format(ti.name), file=of)
            print("FILE: {}".format(ti.name), )

            for s in folia.Document(string=t.extractfile(ti).read()).sentences():
                print(s, file=of)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Extract corpus from SoNaR')
    parser.add_argument('selection')
    parser.add_argument('infile')
    parser.add_argument('outfile')

    args = parser.parse_args()

    main({c for c in args.selection.split("|")}, args.infile, args.outfile)
