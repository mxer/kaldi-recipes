#!/usr/bin/env python3

import argparse

import morfessor

def main(model, infile, outfile):

    io = morfessor.MorfessorIO()
    m = io.read_any_model(model)
    with open(outfile, 'w', encoding='utf-8') as out_f:
        for line in open(infile, encoding='utf-8'):
            parts = line.split()
            np = []

            for p in parts:
                if p in {".","?","!",";",",",":","\""}:
                    continue
                if any(c in "<>." for c in p):
                    np.append(p)
                else:
                    np.append("+ +".join(m.viterbi_segment(p)[0]))
            result = " ".join(a.lower() for a in np)

            print(result, file=out_f)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Segment corpus, but not tokens with punctuation')
    parser.add_argument('model')
    parser.add_argument('infile')
    parser.add_argument('outfile')

    args = parser.parse_args()

    main(args.model, args.infile, args.outfile)
