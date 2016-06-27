#!/usr/bin/env python3
import argparse
import os


def main(dir, lexicon):
    lexicon = {l.strip().split()[0] for l in open(lexicon, encoding='utf-8')}

    with open(os.path.join(dir, 'text'), 'w', encoding='utf-8') as out_f:
        for line in open(os.path.join(dir, 'text.orig'), encoding='utf-8'):
            key, raw = line.strip().split(None, 1)

            sent = []

            for w in raw.replace('\\', ' ').lower().split():
                if w in lexicon:
                    sent.append(w)
                else:
                    sent.append(w.strip(".,?()/"))

            print("{} {}".format(key, " ".join(sent), file=out_f))


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('dir')
    parser.add_argument('lexicon')

    args = parser.parse_args()

    main(args.dir, args.lexicon)
