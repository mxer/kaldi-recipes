#!/bin/bash
#SBATCH -p coin,short-ivb,short-wsm,short-hsw,batch-hsw,batch-wsm,batch-ivb
#SBATCH -t 2:00:00
#SBATCH -n 12
#SBATCH -N 1
#SBATCH --mem-per-cpu=4G



echo "Hello there"
