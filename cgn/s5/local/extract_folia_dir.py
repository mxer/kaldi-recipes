#!/usr/bin/env python3
import argparse
import os

from pynlpl.formats import folia


def main(indir, outfile):
    with open(outfile, 'w', encoding='utf-8') as of:
        for root, dirs, files in os.walk(indir):
            for f in files:
                if not f.endswith(".folia.xml"):
                    continue

                print("FILE: {}".format(f), file=of)
                print("FILE: {}".format(f))

                for s in folia.Document(file=os.path.join(root,f)).sentences():
                    print(s, file=of)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Extract corpus from SoNaR')
    parser.add_argument('indir')
    parser.add_argument('outfile')

    args = parser.parse_args()

    main(args.indir, args.outfile)
