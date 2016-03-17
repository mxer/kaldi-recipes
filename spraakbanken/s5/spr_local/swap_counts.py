#!/usr/bin/env python3

import fileinput

for line in fileinput.input():
    parts = line.strip().split()
    print("{} {}".format(" ".join(parts[1:]), parts[0]))

