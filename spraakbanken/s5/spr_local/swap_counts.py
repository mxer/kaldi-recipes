#!/usr/bin/env python

from __future__ import print_function

import fileinput

for line in fileinput.input():
    parts = line.strip().split()
    print("{} {}".format(" ".join(parts[1:]), parts[0]))

