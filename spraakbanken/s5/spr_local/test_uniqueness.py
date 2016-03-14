import hashlib
import os
import sys

import spl

def main(path):
    d = {}
    type = {}

    seen = set()
    for root, dirs, files in os.walk(path):
        for f in files:
            if f.endswith(".spl"):
                h = hashlib.md5(open(os.path.join(root, f), 'rb').read()).hexdigest()
                if h in seen:
                    continue
                seen.add(h)
                for key, val, rec in spl.Spl(os.path.join(root, f)).key_records():
                    if key not in d:
                        d[key] = []
                        type[key] = []
                    d[key].append(rec[2])
                    type[key].append(rec[9])


    set_d = {k: set(v) for k,v in d.items()}

    for k in sorted(d.keys()):
        print("{: 4d} - {: 4d} / {: 4d}   -- {} ({}) -- {}".format(k, len(set_d[k]), len(d[k]), type[k][0], len(set(type[k])), d[k][0]))




if __name__ == "__main__":
    main(sys.argv[1])