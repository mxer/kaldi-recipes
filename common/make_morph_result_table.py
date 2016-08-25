#!/usr/bin/env python3
import lzma
import os
import subprocess

def count_contexts(arpaxz):
    c = 0
    for line in lzma.open(arpaxz, "rt", encoding='utf-8'):
        if len(line.strip()) == 0:
            continue
        if line.strip().startswith("\\data\\"):
            continue
        if line.startswith("ngram"):
            c+= int(line.strip().rsplit('=',1)[1])
            continue
        break
    return c
        
test_size = [0.5,1,1.5,2,3,4]
small_order = 4
small_d = 0.05
big_order = 12
big_d = 0.01

for alpha in test_size:

    s = int(subprocess.run("wc -l data/segmentation/morpha_{}/vocab".format(alpha),shell=True, stdout=subprocess.PIPE).stdout.split()[0])
    v = int(subprocess.run("wc -l data/dicts/morpha_{}/lexicon.txt".format(alpha),shell=True, stdout=subprocess.PIPE).stdout.split()[0])
    try:
        nscontexts = nbcontexts = sfstsize = bfstsize = 0
        try:
            nscontexts = count_contexts("data/lm/morpha_{}/vk/{}_{}g/arpa.xz".format(alpha,small_d, small_order))
    
            sfstsize = os.stat("data/recog_langs/morpha_{}_fix1_backoff_v_{}_{}gram/G.fst".format(alpha,small_d, small_order)).st_size
        except:
            pass
        try:

            bfstsize = os.stat("data/recog_langs/morpha_{}_fix1_backoff_v_{}_{}gram/G.fst".format(alpha,big_d, big_order)).st_size
            nbcontexts = count_contexts("data/lm/morpha_{}/vk/{}_{}g/arpa.xz".format(alpha,big_d, big_order))
        except:
            pass
        sresult = bresult = 0
        try:
            sresult = float(subprocess.run("grep WER exp/tri4a/decode_morpha_{}_fix1_backoff_v_{}_{}gram/wer_* | utils/best_wer.sh".format(alpha, small_d, small_order), shell=True, stdout=subprocess.PIPE).stdout.split()[1])
        except:
            pass
        try:
            bresult = float(subprocess.run("grep WER exp/tri4a/decode_morpha_{}_fix1_backoff_v_{}_{}gram_rs_morpha_{}_fix1_backoff_v_{}_{}gram/wer_* | utils/best_wer.sh".format(alpha, small_d, small_order, alpha, big_d, big_order), shell=True, stdout=subprocess.PIPE).stdout.split()[1])
        except:
            pass

        print("{} & {:.0f}k  & {:.0f}k & {} & {} & {:.1f}M & {:.1f}M & {:.0f}Mb & {:.0f}Mb\\\\".format(alpha, s/1000, v/1000,sresult,bresult,nscontexts/1000000,nbcontexts/1000000,sfstsize/1000000,bfstsize/1000000))
    except:
        print("Error for {}".format(alpha))
