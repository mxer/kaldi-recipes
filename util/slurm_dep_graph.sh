#!/bin/bash

mkdir log
LAST=""
declare -A jobmap

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

deparg=""
if [ ${#dep[@]} -gt 0 ]
then
    IFS=":"; depp=${dep[*]}
    deparg="--dependency=afterok:$depp"
fi

IFS=" "
ret=$(sbatch --job-name="${JOB_PREFIX}${name}" -e "log/${name}-%j.out" -o "log/${name}-%j.out" -t ${time}:00:00 --mem-per-cpu ${mem}G $deparg "${@}")

echo $ret
rid=$(echo $ret | awk '{print $4;}')
LAST=$rid

jobmap["$name"]=$rid

echo ${#jobmap[@]}
echo "${!jobmap[@]}"

echo
echo
echo
}