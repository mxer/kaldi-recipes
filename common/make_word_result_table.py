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
        
test_size = range(50,850,50)
small_order = 3
big_order = 5
for s in test_size:
    try:
        nscontexts = count_contexts("data/lm/word/srilm/{}k_{}g/arpa.xz".format(s, small_order))
        nbcontexts = count_contexts("data/lm/word/srilm/{}k_{}g/arpa.xz".format(s, big_order))
    
        sfstsize = os.stat("data/recog_langs/word_s_{}k_{}gram/G.fst".format(s,small_order)).st_size
        bfstsize = os.stat("data/recog_langs/word_s_{}k_{}gram/G.fst".format(s,big_order)).st_size
        sresult = bresult = 0
        try: 
            sresult = float(subprocess.run("grep WER exp/tri4a/decode_word_s_{}k_{}gram/wer_* | utils/best_wer.sh".format(s,small_order), shell=True, stdout=subprocess.PIPE).stdout.split()[1])
        except:
            pass
        try:
            bresult = float(subprocess.run("grep WER exp/tri4a/decode_word_s_{}k_{}gram_rs_word_s_{}k_{}gram/wer_* | utils/best_wer.sh".format(s,small_order,s,big_order), shell=True, stdout=subprocess.PIPE).stdout.split()[1])
        except:
            pass

        print("{}k & {} & {} & {:.1f}M & {:.1f}M & {:.0f}Mb & {:.0f}Mb\\\\".format(s,sresult,bresult,nscontexts/1000000,nbcontexts/1000000,sfstsize/1000000,bfstsize/1000000))
    except Exception as e:
        print("Error for {}, {}".format(s, e))
