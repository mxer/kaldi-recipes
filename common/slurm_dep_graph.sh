#!/bin/bash

mkdir -p log
LAST=""
declare -A jobmap
ORIG_IFS=$IFS

function join { local IFS="$1"; shift; echo "$*"; }

function job {
name=$1
mem=$2
time=$3
after=$4

shift 4

declare -a dep

case $after in
"NONE")
;;
"LAST")
  if [ -n "$LAST" ]; then
      dep+=($LAST)
  fi
;;
*)
IFS=',' read -r -a names <<< "$after"
for n in ${names[@]}; do
    if [ -n "${jobmap[$n]}" ]; then
        dep+=(${jobmap["$n"]})
    else
        echo "Warning, did not find job '${n}' for dependency"
    fi
done
;;
esac

if [ -n "$DEP_LIST" ]; then
IFS=',' read -r -a ids <<< "$DEP_LIST"
for i in ${ids[@]}; do
    dep+=($i)
done
fi

deparg=""
if [ ${#dep[@]} -gt 0 ]
then
    depp=$(join : "${dep[@]}")
    deparg="--dependency=afterok:$depp"
fi

ret=$(sbatch -p batch-ivb,batch-wsm,batch-hsw,coin --job-name="${JOB_PREFIX^^}${name}" -e "log/${name}-%j.out" -o "log/${name}-%j.out" -t ${time}:00:00 ${SLURM_EXTRA_ARGS} --mem-per-cpu ${mem}G $deparg "${@}")

echo $ret
rid=$(echo $ret | awk '{print $4;}')
LAST=$rid

jobmap["$name"]=$rid

echo $rid >> log/slurm_ids
IFS=$ORIG_IFS
}
