#!/usr/bin/env python3

import sys
import string

def main(lexicon_file, vocab_file, desired_size, known_lex, oov_lex, real_vocab):
    lexicon_file = open(lexicon_file, encoding='utf-8')
    vocab_file = open(vocab_file, encoding='utf-8')
    known_lex = open(known_lex, 'w', encoding='utf-8')
    oov_lex = open(oov_lex, 'w', encoding='utf-8')
    real_vocab = open(real_vocab, 'w', encoding='utf-8')

    desired_size = int(desired_size)
    lexicon = {}

    for line in lexicon_file:
        word, trans = line.strip().split(None, 1)
        if word not in lexicon:
            lexicon[word] = set()
        lexicon[word].add(trans)

    lexicon["<s>"] = {"SIL",}
    lexicon["</s>"] = {"SIL",}
    
    print("<UNK>\tNSN", file=known_lex)

    punctuation = "\\/?.,!;:\"\'()-=+[]"
    for p in punctuation:
        lexicon[p] = {"SIL",}

    blacklist = "%§"

    count = 0
    for v in vocab_file:
        v = v.strip()
       
        if count >= desired_size:
            break
        if v == "<s>" or v == "</s>":
            print(v, file=real_vocab)
            continue
  
        if v in lexicon:
            for t in lexicon[v]:
                print("{}\t{}".format(v, t), file=known_lex)
            count += 1
            print(v, file=real_vocab)
            continue

        if any(x in blacklist for x in v):
            continue
        
        if any(x in string.digits for x in v):
            continue

        v2 = v.strip(punctuation)
        if len(v2) == 0:
            print("{}\tSIL".format(v), file=known_lex)
            count += 1
            print(v, file=real_vocab)
            continue

        if v2 in lexicon:
            for t in lexicon[v2]:
                print("{}\t{}".format(v, t), file=known_lex)
            count += 1
            print(v, file=real_vocab)
            continue

        v2 = v2.lower()  

        if v2 in lexicon:
            for t in lexicon[v2]:
                print("{}\t{}".format(v, t), file=known_lex)
            count += 1
            print(v, file=real_vocab)
            continue

        print(v, file=oov_lex)
        print(v, file=real_vocab)
        count += 1

if __name__ == "__main__":
    if len(sys.argv) != 7:
        exit("6 required arguments: lexicon, vocab, desired_vocab_size, known.lex, oov.lex, real_vocab")

    main(*sys.argv[1:])
