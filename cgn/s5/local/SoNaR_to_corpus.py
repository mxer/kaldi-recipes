#!/usr/bin/env python3
import argparse
import tarfile

from pynlpl.formats import folia


def main(selection, infile, outfile):
    with open(outfile, 'w', encoding='utf-8') as of:
        t = tarfile.TarFile(infile, 'r|*')

        while True:
            ti = t.next()
            if ti is None:
                break

            if not ti.name.endswith(".folia.xml") or not any(c in ti.name for c in selection):
                continue

            print("FILE: {}".format(ti.name), file=of)

            for s in folia.Document(string=t.extractfile(ti).read()).sentences():
                print(s.strip(), file=of)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Extract corpus from SoNaR')
    parser.add_argument('selection')
    parser.add_argument('infile')
    parser.add_argument('outfile')

    args = parser.parse_args()

    main({c for c in args.selection.split("|")}, args.infile, args.outfile)