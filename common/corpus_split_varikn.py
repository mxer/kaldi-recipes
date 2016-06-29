#!/usr/bin/env python3
import argparse
import lzma
import random


def main(inp_f, target_lines, of1, of2):

    l = sum(1 for _ in lzma.open(inp_f, 'rt', encoding='utf-8'))
    print("{} lines".format(l))
    p = target_lines / l
    p *= 1.05
    print("using {} as percentage".format(p))

    c = 0
    for line in lzma.open(inp_f, 'rt', encoding='utf-8'):
        line = line.strip()

        if random.random() < p and c < target_lines:
            print(line, file=of1)
            c += 1
        else:
            print(line, file=of2)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='')
    parser.add_argument('infile')
    parser.add_argument('lines', type=int)
    parser.add_argument('out1', type=argparse.FileType('w', encoding='utf-8'))
    parser.add_argument('out2', type=argparse.FileType('w', encoding='utf-8'))

    args = parser.parse_args()

    main(args.infile, args.lines, args.out1, args.out2)

