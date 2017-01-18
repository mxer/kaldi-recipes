#!/usr/bin/env python3
import itertools
import sys

morf_model = sys.argv[1]

morf_lex = {}

for line in open(sys.argv[2], encoding='utf-8'):
    parts = line.split()
    word = parts[0]
    trans = parts[1:]
    
    if word not in morf_lex:
        morf_lex[word] = set()
    morf_lex[word].add(tuple(trans))

#print(morf_lex)
for line in open(sys.argv[1], encoding='utf-8'):
    if line.startswith("#"):
        continue
    parts = line.split()
    word = "".join(parts[1::2])
#    print(word)
    morphs = "+ +".join(parts[1::2]).split()
#    print(morphs) 
    try:
        if len(morphs) < 2:
            for p in morf_lex[morphs[0]]:
                print("{}\t{}".format(word, " ".join(p)))
            continue
        morph_sets = [morf_lex[m] for m in morphs]
        for p in itertools.product(*morph_sets):
            print("{}\t{}".format(word, " ".join(" ".join(x) for x in p)))
    except:
        print("Error for {}".format(word), file=sys.stderr)
        continue

#print(len(morf_lex))
