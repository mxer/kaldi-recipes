#!/usr/bin/env python3

import argparse

import morfessor

def main(model, countfile, segmentedfile, vocab, lowercase):
    if vocab is not None:
        vocab = {v.strip() for v in open(vocab, encoding='utf-8')}
    min_size = 100
    max_size = 0

    io = morfessor.MorfessorIO()
    m = io.read_any_model(model)
    with open(segmentedfile, 'w', encoding='utf-8') as out_f:
        for line in open(countfile, encoding='utf-8'):
            if lowercase:
                line = line.lower()
            parts = line.split()

            if vocab is not None:
                if any(p not in vocab for p in parts[:-1]):
                    continue
                    
            result = []
            for p in parts[:-1]:
                result.extend(m.viterbi_segment(p)[0])

            if len(result) < min_size:
                min_size = len(result)

            if len(result) > max_size:
                max_size = len(result)

            result.append(parts[-1])
            print(" ".join(result), file=out_f)

    print("Min context: {}, max context: {}".format(min_size, max_size))

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Transform count file to segmented count file')
    parser.add_argument('--lowercase', dest='lowercase', default=False, action='store_true', help='Lowercase')
    parser.add_argument('--vocab', dest='vocab', default=None)
    parser.add_argument('model')
    parser.add_argument('countfile')
    parser.add_argument('segmentedfile')

    args = parser.parse_args()

    main(args.model, args.countfile, args.segmentedfile, args.vocab, args.lowercase)