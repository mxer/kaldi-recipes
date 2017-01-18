#!/usr/bin/env python3

import sys

mapping = {}

def add_word(parts):
    if len(parts) == 0:
        return
    global mapping
    word = "".join(parts).replace("++", "")
    mapping[word] = parts
    

for line in sys.stdin:
    parts = line.split()[1:-1]
    cur_word = [] 
    i = 0
    while i < len(parts):
        cur_word.append(parts[i])
        if not cur_word[-1].endswith('+'):
            add_word(cur_word)
            cur_word = []
        i += 1
    add_word(cur_word) 
 

for word, morphs in sorted(mapping.items()):
    print("{}\t{}".format( word, " ".join(morphs)))
