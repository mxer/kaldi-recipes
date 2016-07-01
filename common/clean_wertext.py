#!/usr/bin/env python3
import sys

for line in sys.stdin:
    key, val = line.split(None, 1)

    print("{} {}".format(key, val.lower().replace("+ +","").replace(" +", "").replace("+ ", ""), end=""))
