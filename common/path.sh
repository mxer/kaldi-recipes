#!/bin/bash

export PYTHONIOENCODING='utf-8'
export PATH="$PWD/utils:$PWD:$PATH"

module load kaldi/2016.12.06-d41af22-GCC-4.9.3-mkl phonetisaurus/2016.05.26-09651ed anaconda3 srilm mitlm Morfessor openfst sph2pipe variKN m2m-aligner anaconda2 MorfessorJoint et-g2p

module list

