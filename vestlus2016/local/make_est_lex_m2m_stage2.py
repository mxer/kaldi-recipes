#!/usr/bin/env python3

import sys

lex = open(sys.argv[1], encoding='utf-8')
word_lex = open(sys.argv[3], encoding='utf-8')


lexicon = {}
word_lexicon = {}

for l in lex:
    parts = l.split()
    if parts[0] not in lexicon:
        lexicon[parts[0]] = set()
    lexicon[parts[0]].add(tuple(parts[1:]))

for l in word_lex:
    parts = l.split()
    if parts[0] not in word_lexicon:
        word_lexicon[parts[0]] = set()
    word_lexicon[parts[0]].add(tuple(parts[1:]))
new_lex = []
ls = -1
while ls != len(new_lex):
    print("round", file=sys.stderr)
    ls = len(new_lex)

    word_map = open(sys.argv[2], encoding='utf-8')
    for line in word_map:
        morphs = line.split()[1:]
        morphs_missing = 0
        missing = []
        for i, m in enumerate(morphs):
            if m not in lexicon:
                morphs_missing += 1
                missing.append(i)
        if morphs_missing == 1:
            missing = missing[0]
            word = "".join(morphs).replace("++", "")
            if not word in word_lexicon:
                continue
            for transcription in word_lexicon[word]:
                s = 0
                e = len(transcription)
                success = True
                for i in range(missing):
                    cur_s = s
                    for mt in lexicon[morphs[i]]:
                        if transcription[s:s+len(mt)] == mt:
                            s += len(mt)
                            break
                        success = False
                    if not success: break
                for i in reversed(range(missing+1,len(morphs))):
                    cur_e = e
                    for mt in lexicon[morphs[i]]:
                        if transcription[e-len(mt):e] == mt:
                            e -= len(mt)
                            break
                        success = False
                    if not success: break 
                if success:
                    
                    lexicon[morphs[missing]] = {transcription[s:e]}
                    new_lex.append((morphs[missing], transcription[s:e]))
            
for m, t in new_lex:
    print("{}\t{}".format(m, " ".join(t)))
