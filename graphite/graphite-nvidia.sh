#!/bin/bash
################################################################################
# NVIDIA GPU Status to Graphite
#
# Notes:
#   Assumes TCP Graphite.
#
# Written by:
#   Adam Boutcher         (IPPP, Durham University, UK) 2021
#
################################################################################

GRAPHITE="172.16.0.1"
GPORT="2003"
PREFIX="prefix."

# Function to check that a binary exists
function check_bin() {
  which $1 1>/dev/null 2>&1
  if [[ $? -ne 0 ]]; then
    echo "$1 cannot be found. Please install it or add it to the path. Exiting."
    exit 1
  fi
}
check_bin which
check_bin hostname
check_bin echo
check_bin nc
check_bin awk
check_bin nvidia-smi
check_bin grep
check_bin xargs
check_bin sed
check_bin wc
check_bin date

HOST=$(hostname -s)
stamp=$(date +"%s")
count=$(nvidia-smi --list-gpus 2>/dev/null | wc -l);
i=0
while [ $i -lt $count ]; do
  # GPU Status
  gpu_state=$(nvidia-smi --id=$i --query 2>/dev/null);
  # Power Draw
  gpu_name=$(echo "$gpu_state" | grep "Product Name" | awk -F ":" '{print $2}' | sed 's/ /_/g' | sed 's/_NVIDIA_//g' | xargs);
  # Power Draw
  gpu_power=$(echo "$gpu_state" | grep "Power Draw" | awk -F ":" '{print $2}' | sed 's/W//g' | xargs);
  # PID Count
  gpu_pid=$(echo "$gpu_state" | grep "Process ID" | wc -l);
  # GPU until
  gpu_gpuutil=$(echo "$gpu_state" | grep -A 2 "Utilization" | grep "Gpu" | awk -F ":" '{print $2}' | sed 's/%//g' | xargs);
  # Memory until
  gpu_memutil=$(echo "$gpu_state" | grep -A 2 "Utilization" | grep "Memory" | awk -F ":" '{print $2}' | sed 's/%//g' | xargs);
  # GPU Temp
  gpu_gputemp=$(echo "$gpu_state" | grep -A 5 "Temperature" | grep "GPU Current Temp" | awk -F ":" '{print $2}' | sed 's/C//g' | xargs);
  # Memory Temp
  gpu_memtemp=$(echo "$gpu_state" | grep -A 5 "Temperature" | grep "Memory Current Temp" | awk -F ":" '{print $2}' | sed 's/C//g' | xargs);

  nc -z $GRAPHITE $GPORT >/dev/null 2>&1
  if [ $? -eq 0 ]; then
    if [[ ! -z "$gpu_power" ]]; then    echo "${PREFIX}gpu.$HOST.$i.$gpu_name.POWER $gpu_power $stamp"      | nc -w 3 $GRAPHITE $GPORT 2>/dev/null; fi
    if [[ ! -z "$gpu_pid" ]]; then      echo "${PREFIX}gpu.$HOST.$i.$gpu_name.PID_COUNT $gpu_pid $stamp"    | nc -w 3 $GRAPHITE $GPORT 2>/dev/null; fi
    if [[ ! -z "$gpu_gpuutil" ]]; then  echo "${PREFIX}gpu.$HOST.$i.$gpu_name.GPU_UTIL $gpu_gpuutil $stamp" | nc -w 3 $GRAPHITE $GPORT 2>/dev/null; fi
    if [[ ! -z "$gpu_memutil" ]]; then  echo "${PREFIX}gpu.$HOST.$i.$gpu_name.MEM_UTIL $gpu_memutil $stamp" | nc -w 3 $GRAPHITE $GPORT 2>/dev/null; fi
    if [[ ! -z "$gpu_gputemp" ]]; then  echo "${PREFIX}gpu.$HOST.$i.$gpu_name.GPU_TEMP $gpu_gputemp $stamp" | nc -w 3 $GRAPHITE $GPORT 2>/dev/null; fi
    if [[ ! -z "$gpu_memtemp" ]]; then  echo "${PREFIX}gpu.$HOST.$i.$gpu_name.MEM_TEMP $gpu_memtemp $stamp" | nc -w 3 $GRAPHITE $GPORT 2>/dev/null; fi
  fi

  i=$(($i+1))
done
