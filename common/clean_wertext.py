#!/usr/bin/env python3
import re
import sys

for line in sys.stdin:
    try:
        key, val = line.strip().split(None, 1)
    except ValueError:
        key = line.strip
        val = ""

    val = val.lower().replace("+ +","").replace(" +", "").replace("+ ", "").replace(" |", "")

    val = re.sub("#[0-9,]+", "", val)

    print("{} {}".format(key, val, end=""))

