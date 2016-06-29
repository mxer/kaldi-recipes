#!/usr/bin/env python3

import argparse

import sys


def main(inf, outf, word_map):
    iw_backoff_outgoing = []
    iw_backoff_incoming = []
    iw_ending_nodes = set()
    
    max_node = 0

    backoff_node = None

    for line in inf:
        parts = line.split()
        if len(parts) < 3:
            print("\t".join(parts), file=outf)
            continue

        node_out = int(parts[0])
        node_in = int(parts[1])
        max_node = max(max_node, node_in, node_out)

        if backoff_node is None and word_map.get(parts[2],parts[2]) == word_map.get("#0", "#0"):
            backoff_node = int(parts[1])

        if node_out == backoff_node:
            word = word_map.get(parts[2],parts[2])
            if word.endswith('+'):
                iw_ending_nodes.add(node_in)
            if word.startswith('+'):
                iw_backoff_outgoing.append(parts)
                continue
        if node_in == backoff_node:
            if node_out in iw_ending_nodes:
                iw_backoff_incoming.append(parts)
                continue
        print("\t".join(parts), file=outf)

    iw_backoff_node = str(max_node + 1)
    print("Backoff node: {}".format(iw_backoff_node), file=sys.stderr)
    print("Incoming arcs iw-backoff: {}".format(len(iw_backoff_incoming)), file=sys.stderr)
    print("Outcoming arcs iw-backoff: {}".format(len(iw_backoff_outgoing)), file=sys.stderr)

    for parts in iw_backoff_outgoing:
        parts[0] = iw_backoff_node
        print("\t".join(parts), file=outf)
    for parts in iw_backoff_incoming:
        parts[1] = iw_backoff_node
        print("\t".join(parts), file=outf)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('infile', nargs='?', type=argparse.FileType('r'), default=sys.stdin)
    parser.add_argument('outfile', nargs='?', type=argparse.FileType('w'), default=sys.stdout)
    parser.add_argument('--symbols', type=argparse.FileType('r'), default=None)

    args = parser.parse_args()
    word_map = {}
    if args.symbols is not None:
        word_map = {l.split()[1]: l.split()[0] for l in args.symbols}

    main(args.infile, args.outfile, word_map)
