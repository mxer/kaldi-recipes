#!/bin/bash

mkdir -p log
LAST=""
declare -A jobmap
ORIG_IFS=$IFS
JOB_PREFIX=$(cat id)_

function join { local IFS="$1"; shift; echo "$*"; }

function job {
sdg_name=$1
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

extrashortpart=""
if [ ${time} -le 4 ]
then
    extrashortpart=",short-ivb,short-wsm,short-hsw"
fi

ret=$(sbatch -x pe63 -p batch-ivb,batch-wsm,batch-hsw,coin${extrashortpart} --job-name="${JOB_PREFIX^^}${sdg_name}" -e "log/${sdg_name}-%j.out" -o "log/${sdg_name}-%j.out" -t ${time}:00:00 ${SLURM_EXTRA_ARGS} --mem-per-cpu ${mem}G $deparg "${@}")

echo $ret
rid=$(echo $ret | awk '{print $4;}')
LAST=$rid

jobmap["$sdg_name"]=$rid

echo $rid >> log/slurm_ids
IFS=$ORIG_IFS
}


