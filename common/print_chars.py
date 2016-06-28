#!/usr/bin/env python3

import collections
import sys
import unicodedata


counter = collections.Counter()
for line in sys.stdin:
    for c in line.strip():
        counter[c] += 1

for c, count in counter.most_common():
    print("{} {} {} {}".format(c,count,unicodedata.name(c, "WHOKNOWS"), unicodedata.category(c)))
    
