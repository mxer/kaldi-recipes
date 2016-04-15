import gzip
import os

import sys

SPECIAL_TIERS = ("BACKGROUND", "COMMENT", "UNKNOWN")


class TextGridShort(object):
    def __init__(self, filename):
        self._streams = {}
        self.key = os.path.basename(filename)[1:8]
        self._parse(filename)

    def _parse(self, filename):
        lines = [l.strip() for l in gzip.open(filename, 'rt', encoding='iso-8859-1')]
        assert lines[0] == 'File type = "ooTextFile short"'
        assert lines[1] == '"TextGrid"'
        assert lines[2] == ""

        num_tiers = int(lines[6])
        i = 7
        for _ in range(num_tiers):
            assert lines[i] == '"IntervalTier"'

            tier_name = lines[i+1][1:-1]
            tier = []
            num_intervals = int(lines[i+4])
            i += 5

            for _ in range(num_intervals):
                start_time = float(lines[i])
                end_time = float(lines[i+1])
                transcript = lines[i+2].strip('"')
                tier.append((start_time, end_time, transcript))
                i += 3

            self._streams[tier_name] = tier

    def records(self):
        speakers = set(self._streams.keys()) - set(SPECIAL_TIERS)

        for speaker in speakers:
            for i, record in enumerate(self._streams[speaker]):
                text = record[2].strip()

                # if text == ".":
                #     continue
                #
                # if "*" in text:
                #     continue
                #
                # if "ggg" in text:
                #     continue
                #
                # if "xxx" in text:
                #     continue
                #
                # if "Xxx" in text:
                #     continue

                if len(text) == 0:
                    continue

                # text = text+" "
                # text = re.sub(r"(?<=\S)\...\s", " |... ", text)
                # text = re.sub(r"(?<=\S)\?\s", " |? ", text)
                # text = re.sub(r"(?<!\s|[|.])\.\s", " |. ", text)

                yield "{}-{}-{:04d}".format(speaker, self.key, i), record[0], record[1], text.strip()


if __name__ == "__main__":
    s = TextGridShort(sys.argv[1])
    print(sys.argv[1], " ".join(str(len(s._streams[k])) for k in sorted(s._streams.keys())))
