#!/usr/bin/env python3

import argparse

import itertools
import morfessor

def read_lex(inf):
    lex = {}
    for line in inf:
        word, trans = line.split(None, 1)
        if word not in lex:
            lex[word] = []

        lex[word].append(tuple(trans.strip().split()))

    return lex

def main(model, toplist, origlex,jointlex, wordmap):
    io = morfessor.MorfessorIO()
    model = io.read_binary_model_file(model)
    jointlex = read_lex(jointlex)
    origlex = read_lex(origlex)

    new_lex = {}

    tof = open('tmpout', 'w', encoding='utf-8')
    counts = [0]*100
    for k,v in origlex.items():
        counts[len(v)] += 1

        if len(v) == 2:
            print(k, file=tof)
    tof.close()

    for i,c in enumerate(counts):
        print("{} times {} transcriptions".format(c,i))

    jcounts = [0]*100
    for k,v in jointlex.items():
        jcounts[len(v)] += 1

    for i,c in enumerate(jcounts):
        print("{} times {} morphtranscriptions".format(c,i))

    words_todo = []

    for word in toplist:
        word = word.strip().split()[0]

        segm = model.viterbi_segment(word)[0]
        if any(p not in jointlex for p in segm):
            print("{}\tUNK".format(word), file=wordmap)
            continue

        if word not in origlex:
            words_todo.append(word)
            continue

        target_trans = origlex[word]

        if len(target_trans) > 1:
            words_todo.append(word)
            continue

        target_idx = None
        for idx in itertools.product(*[list(range(len(jointlex[p]))) for p in segm]):
            trans = []
            for p, i in zip(segm, idx):
                trans.extend(jointlex[p][i])

            if tuple(trans) == target_trans[0]:
                target_idx = idx
                break

        if target_idx is not None:
            nsegm = ["{}#{}".format(p,i) for p,i in zip(segm,target_idx)]
            print("{}\t{}".format(word, "+ +".join(nsegm)),file=wordmap)
        else:
            words_todo.append(word)

    print("Still to do {} words".format(len(words_todo)))

    words = words_todo
    words_todo = []
    for word in words:
        word_done = False
        if word not in origlex:
            words_todo.append(word)
            continue

        for segme in model.viterbi_nbest(word, 10):
            segm = segme[0]
            if any(p not in jointlex for p in segm):
                continue
            target_trans = origlex[word]

            trans_left = list(target_trans)

            target_idxs = []
            for idx in itertools.product(*[list(range(len(jointlex[p]))) for p in segm]):
                trans = []
                for p, i in zip(segm, idx):
                    trans.extend(jointlex[p][i])

                for ti in range(len(trans_left)):
                    if tuple(trans) == trans_left[ti]:
                        target_idxs.append(idx)
                        del trans_left[ti]
                        break

            if len(target_idxs) > 0:
                if len(target_idxs) != len(target_trans):
                    print("WARNING: {} has less phone transcriptions then expected".format(word))
                    continue
                target_idx = [{*k} for k in zip(*target_idxs)]
                nsegm = ["{}#{}".format(p, ",".join(str(a) for a in sorted(i))) for p, i in zip(segm, target_idx)]
                print("{}\t{}".format(word, "+ +".join(nsegm)), file=wordmap)
                word_done=True
                break
        if not word_done:
            words_todo.append(word)

    print("Still to do {} words".format(len(words_todo)))

    for word in words_todo:
        segm = model.viterbi_segment(word)[0]
        print("{}\t{}".format(word, "+ +".join(segm)), file=wordmap)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('morfessor_model')
    parser.add_argument('toplist', type=argparse.FileType('r', encoding='utf-8'))
    parser.add_argument('origlex', type=argparse.FileType('r', encoding='utf-8'))
    parser.add_argument('jointlex', type=argparse.FileType('r', encoding='utf-8'))
    parser.add_argument('wordmap', type=argparse.FileType('w', encoding='utf-8'))

    args = parser.parse_args()

    main(args.morfessor_model, args.toplist, args.origlex, args.jointlex, args.wordmap)
