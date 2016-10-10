#!/usr/bin/env python3
import argparse
import math
import sys
from collections import namedtuple


EPS = b"<eps>"
PY3 = True if sys.version_info[0] == 3 else False


def print_fst_line(from_state, to_state, ilabel=None, olabel=None, cost=0.0, file=sys.stdout.buffer if PY3 else sys.stdout):
    file.write(b"%d %d %s %s" % (from_state, to_state,ilabel if not None else EPS, olabel if not None else EPS))
    if abs(cost) > 0:
        file.write(b" %f" % cost)
    file.write(b"\n")


def print_fst_final_line(state, cost=0, file=sys.stdout.buffer if PY3 else sys.stdout):
    file.write(b"%d" % state)
    if abs(cost) > 0:
        file.write(b" %f" % cost)
    file.write(b"\n")


parser = argparse.ArgumentParser(description='')
parser.add_argument('lexicon', type=argparse.FileType('rb'), default=sys.stdin.buffer if PY3 else sys.stdin)
parser.add_argument('optphones', nargs='?', type=argparse.FileType('rb'), help="File with one optional phone", default=None)
parser.add_argument('fst', nargs='?', type=argparse.FileType('wb'), default=sys.stdout.buffer if PY3 else sys.stdout)

args = parser.parse_args()

OptPhone = namedtuple('OptPhone', ['prob', 'disambig'])

opt_phones = {}
if args.optphones is not None:
    for line in args.optphones:
        parts = line.split()
        if len(parts) == 0: continue
        elif len(parts) == 2:
            opt_phones[parts[0]] = OptPhone(float(parts[1]), EPS)
        elif len(parts) == 3:
            opt_phones[parts[0]] = OptPhone(float(parts[1]), parts[2])
        else:
            sys.exit("Invalid line in {}. Expected format 'phone probability [disambig symbol]".format(args.optphones.name))

opt_sum_prob = sum(x[0] for x in opt_phones.values())
if opt_sum_prob > 1.0:
    sys.exit("Sum of probabilities in {} can not exceed 1.0".format(args.optphones.name))

no_opt_prob = 1 - opt_sum_prob

start_state = 0
loop_state = 1
opt_state = 2
next_state = 2

if no_opt_prob > 0:
    print_fst_line(start_state, loop_state, EPS, EPS, math.log(no_opt_prob), file=args.fst)


if len(opt_phones) > 0:
    print_fst_line(start_state, opt_state, EPS, EPS, file=args.fst)

    for phone, data in opt_phones.items():
        print_fst_line(opt_state,loop_state, data.disambig, EPS, math.log(data.prob), file=args.fst)
    next_state += 1
else:
    opt_state = loop_state

for line in args.lexicon:
    parts = line.split()
    word = parts[0]
    prob = float(parts[1])
    cost = math.log(prob)

    phones = parts[2:]

    cur_state = loop_state
    while len(phones) > 0:
        phone = phones.pop(0)
        if len(phones) > 0:

            print_fst_line(cur_state, next_state, phone, word, cost, file=args.fst)
            cost = 1
            word = EPS
            cur_state = next_state
            next_state += 1
        else:
            print_fst_line(cur_state, opt_state, phone, word, cost, file=args.fst)

    print_fst_final_line(loop_state)






