#!/usr/bin/env python3

import sys

morf_model = sys.argv[1]
align_lex = sys.argv[2]

#morph_lex = sys.argv[3]
#word_misalign = sys.argv[4]
#word_hardalign = sys.argv[5]


morph_map = {}
for line in open(morf_model):
    if line.startswith("#"):
        continue

#    morphs = line.split()[1::2]

#    morph_map[''.join(morphs)] = tuple(morphs)
    parts = line.split()
    morph_map[parts[0]] = tuple(p.strip('+') for p in parts[1:])


align_map = {}
for line in open(align_lex):
    graphs,phones = line.split()
    graphs = tuple(tuple(g.split(":")) for g in graphs.split('|') if len(g) != 0)
    phones = tuple(tuple(p.split(":")) for p in phones.split('|') if len(p) != 0)

    word = ''.join(sum((list(b) for b in graphs), []))

    align_map[word] = (graphs, phones)
    assert len(graphs) == len(phones)

counter = 0
for word in morph_map.keys():
    if word not in align_map:
        counter += 1


#morph_lex = open(morph_lex, 'w', encoding='utf-8')
# word_misalign = open(word_misalign, 'w', encoding='utf-8')
# word_hardalign = open(word_hardalign, 'w', encoding='utf-8')

not_clean_counter = 0
for word, morphs in morph_map.items():
    if word not in align_map:
        # print(word, file=word_misalign)
        counter += 1
        continue
    
    grapheme_index = 0
    morph_index = 0
    inmorph_index = 0
    cur_phones = []

    for g, p in zip(*align_map[word]):
        assert ''.join(g) == word[grapheme_index:grapheme_index+len(g)]

        morph = morphs[morph_index]
        morph_length = len(morph)

        grapheme_index += len(g)

        if len(g) > (morph_length - inmorph_index):
            not_clean_counter += 1
            # print(word, file=word_hardalign)

            # print(word, file=sys.stderr)
            # print(' '.join(morph_map[word]), file=sys.stderr)
            # print(' '.join(''.join(a) for a in align_map[word][0]), file=sys.stderr)
            # print(' '.join(''.join(a) for a in align_map[word][1]), file=sys.stderr)
            # print(file=sys.stderr)
            # print(file=sys.stderr)
            # print(file=sys.stderr)
            start = morph_index == 0
            morph_index += 1
            end = morph_index == len(morphs)

            print("{}{}{}\t{}".format('' if start else '+', morph, '' if end else '+', ' '.join(cur_phones)))

            cur_phones = []
            cur_phones.extend(p)
            inmorph_index = len(g) - (morph_length - inmorph_index)

        elif len(g) == (morph_length - inmorph_index):
            cur_phones.extend(p)

            start = morph_index == 0
            morph_index += 1
            end = morph_index == len(morphs)

            print("{}{}{}\t{}".format('' if start else '+', morph, '' if end else '+', ' '.join(cur_phones)))

            inmorph_index = 0
            cur_phones = []
        else:
            cur_phones.extend(p)
            inmorph_index += len(g)
        
print("{} word were not in align_map".format(counter), file=sys.stderr)
print("{} alignments were difficult".format(not_clean_counter), file=sys.stderr)
            

     

