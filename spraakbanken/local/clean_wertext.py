#!/usr/bin/env python
import sys

for line in sys.stdin:
    print(line.lower().replace("+ +","").replace(" +", "").replace("+ ", ""), end="")
