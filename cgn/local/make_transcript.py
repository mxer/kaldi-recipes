#!/usr/bin/env python3
import argparse
import os


def main(dir):
    with open(os.path.join(dir, 'text'), 'w', encoding='utf-8') as out_f:
        for line in open(os.path.join(dir, 'text.orig'), encoding='utf-8'):
            key, sent = line.strip().split(None, 1)

            print("{} {}".format(key, " ".join(w.lower().split("*")[0].strip(".?") for w in sent.split())), file=out_f)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('dir')
    parser.add_argument('lexicon')

    args = parser.parse_args()

    main(args.dir)
