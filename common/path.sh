#!/bin/bash

export PYTHONIOENCODING='utf-8'
export PATH="$PWD/utils:$PWD:$PATH"

module load kaldi/2016.11.21-ac1f932-GCC-4.9.3-mkl phonetisaurus anaconda3 srilm mitlm Morfessor openfst sph2pipe variKN m2m-aligner anaconda2 MorfessorJoint

module list

