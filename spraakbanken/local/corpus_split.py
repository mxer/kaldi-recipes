#!/usr/bin/env python3

import sys
import random


def main(inp_f, lines, out1, out2):
    target_lines = int(lines)
    l = sum(1 for _ in open(inp_f, encoding='utf-8'))
    print("{} lines".format(l))
    p = target_lines / l
    p *= 1.05
    print("using {} as percentage".format(p))

    of1 = open(out1, 'w', encoding='utf-8')
    of2 = open(out2, 'w', encoding='utf-8')

    c = 0
    for line in open(inp_f, encoding='utf-8'):
        line = line.strip()

        if random.random() < p and c < target_lines:
            print(line, file=of1)
            c += 1
        else:
            print(line, file=of2)

    of1.close()
    of2.close()

if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4])
