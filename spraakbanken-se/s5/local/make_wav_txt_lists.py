import os
import sys


def main(in_dir, out_text, out_scp):
    wav_files = {}
    spl_files = {}

    for root, dirs, files in os.walk(in_dir):
        for f in files:
            if f.endswith(".wav"):
                wav_files[os.path.splitext(f)[0]] = os.path.join(root,f)

            if f.endswith(".spl"):
                spl_files[os.path.splitext(f)[0]] = os.path.join(root,f)

    pass

if __name__ == "__main__":
    if len(sys.argv) != 4:
        exit("3 required arguments: data directory, output text file, output scp file")

    in_dir, out_text, out_scp = sys.argv[1:4]
    main(in_dir, out_text, out_scp)
