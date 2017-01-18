#!/usr/bin/env python3
import string
import sys

for line in sys.stdin:
    parts = line.split()
    word = parts[0]
    if len(word) == 1:
        continue
    if len(word) == 2 and len(parts[1:]) < 2:
        continue
    if word != word.lower():
        continue


    print(line.strip())
