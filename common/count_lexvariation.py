#!/usr/bin/env python3

import collections
import sys

lex = collections.Counter()

for line in sys.stdin:
    lex[line.split()[0]] += 1

lc = collections.Counter(lex.values())
for var,count in sorted(lc.items()):
    print("# of lex items with {} pronunc variants: {}".format(var,count))

