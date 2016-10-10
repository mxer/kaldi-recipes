#!/usr/bin/env python

import argparse
import sys

from math import log

EPS = b"<eps>"
PY3 = True if sys.version_info[0] == 3 else False


class WriteFst:
    def __init__(self, file_obj=sys.stdin.buffer if PY3 else sys.stdin):
        self.out = file_obj
        self.started_final_states = False

    def add_trans(self, from_state, to_state, ilabel=EPS, olabel=EPS, cost=0.0):
        if self.started_final_states: raise Exception("Don't print transisitons after final states!")
        self.out.write(b"%d %d %s %s" % (from_state, to_state,ilabel, olabel))
        if abs(cost) > sys.float_info.epsilon:
            self.out.write(b" %f" % cost)
        self.out.write(b"\n")

    def add_final_state(self, state, cost=0.0):
        self.started_final_states = True
        self.out.write(b"%d" % state)
        if abs(cost) > sys.float_info.epsilon:
            self.out.write(b" %f" % cost)
        self.out.write(b"\n")


def mbytes(arg):
    if type(arg) == bytes:
        return arg
    else:
        return arg.encode()

parser = argparse.ArgumentParser(description='')
parser.add_argument('lexicon', type=argparse.FileType('rb'), default=sys.stdin.buffer if PY3 else sys.stdin)
parser.add_argument('silphone', type=mbytes if PY3 else str, default=b'SIL')
parser.add_argument('noisephone', type=mbytes if PY3 else str, default=b'NSN')
parser.add_argument('sildisambig', type=mbytes if PY3 else str, default=EPS)
parser.add_argument('noisedisambig', type=mbytes if PY3 else str, default=EPS)
parser.add_argument('silprob', type=float, default=0.4)
parser.add_argument('noiseprob', type=float, default=0.2)
parser.add_argument('fst', nargs='?', type=argparse.FileType('wb'), default=sys.stdout.buffer if PY3 else sys.stdout)


args = parser.parse_args()
fst = WriteFst(args.fst)

start_state = 0
loop_state = 1
afterword_state = 2
tonsn_state = 3
fromnsn_state = 4

fst.add_trans(start_state, loop_state)
fst.add_trans(afterword_state, loop_state, cost=-log(1.0-args.silprob-args.noiseprob))
fst.add_trans(afterword_state, loop_state, args.silphone, args.sildisambig, -log(args.silprob))

nsilprob = args.silprob / (1.0 - args.noiseprob)
fst.add_trans(afterword_state, tonsn_state, cost=-log((1.0-nsilprob) * args.noiseprob))
fst.add_trans(afterword_state, tonsn_state, args.silphone, args.sildisambig, cost=-log(nsilprob * args.noiseprob))

fst.add_trans(tonsn_state, fromnsn_state, args.noisephone, args.noisedisambig)

fst.add_trans(fromnsn_state, loop_state, cost=-log(1.0-nsilprob))
fst.add_trans(fromnsn_state, loop_state, args.silphone, args.sildisambig, cost=-log(nsilprob))

next_state_num = 5

for line in args.lexicon:
    parts = line.split()
    word = parts[0]
    cost = -log(float(parts[1]))
    phones = parts[2:]
    from_state = loop_state

    first = True
    while len(phones) > 0:
        phone = phones.pop(0)
        if len(phones) > 0:
            next_state = next_state_num
            next_state_num += 1
        else:
            next_state = afterword_state

        fst.add_trans(from_state, next_state, phone, word, cost)

        if first: #No cost or output label after first transisiton
            cost = 0.0
            word = EPS
        from_state = next_state

fst.add_final_state(loop_state)