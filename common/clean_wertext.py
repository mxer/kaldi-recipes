#!/usr/bin/env python3
import sys

for line in sys.stdin:
    try:
        key, val = line.strip().split(None, 1)
    except ValueError:
        key = line.strip
        val = ""

    print("{} {}".format(key, val.lower().replace("+ +","").replace(" +", "").replace("+ ", ""), end=""))

