import subprocess

import sys


def get_result(dir):
    try:
#        print("grep WER {}/wer_* | utils/best_wer.sh".format(dir), file=sys.stderr)
        c = subprocess.run("grep WER {}/wer_* | utils/best_wer.sh".format(dir), shell=True, stderr=subprocess.PIPE,  stdout=subprocess.PIPE)
        result = float(c.stdout.split()[1])
        return result
    except:
        return None

def print_table(morph_format_string, word_format_string, title):
    print()
    print(title)
    print()
    for size in range(400, 2200, 400):

        word_result = get_result(word_format_string.format(size=size))

        morph_results = []

        for suffix in ("", "_pr", "_tc", "_pr_tc"):
            best_result = None
            best_alpha = None
            for alpha in range(1,9):
                result = get_result(morph_format_string.format(suffix=suffix, size=size, alpha=alpha))
                if result is not None and (best_result is None or result > best_result):
                    best_result = result
                    best_alpha = alpha

            if best_result is None:
                morph_results.append("")
            else:
                morph_results.append("{} / {}".format(best_result, best_alpha))

        print("{} & {} & {} \\\\".format(size, word_result, " & ".join(morph_results)))


print_table("exp/chain_cleaned/tdnna_sp_bi/decode_dev_short_morphjoin{suffix}_{size}_{alpha}_5M", "exp/chain_cleaned/tdnna_sp_bi/decode_dev_short_word_v_{size}k_5M", "NNET results")
print_table("exp/chain_cleaned/tdnna_sp_bi/decode_dev_short_morphjoin{suffix}_{size}_{alpha}_5M_ca_morphjoin{suffix}_{size}_{alpha}_50M", "exp/chain_cleaned/tdnna_sp_bi/decode_dev_short_word_v_{size}k_5M_ca_word_v_{size}k_50M", "NNET results rescored")
print_table("exp/tri3/decode_dev_short_morphjoin{suffix}_{size}_{alpha}_5M", "exp/tri3/decode_dev_short_word_v_{size}k_5M", "HMM results")
print_table("exp/tri3/decode_dev_short_morphjoin{suffix}_{size}_{alpha}_5M_ca_morphjoin{suffix}_{size}_{alpha}_50M", "exp/tri3/decode_dev_short_word_v_{size}k_5M_ca_word_v_{size}k_50M", "HMM results rescored")

# print_table("", "", "Nnet results")
# print_table("", "", "Nnet results rescored")
