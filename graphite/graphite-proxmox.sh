#!/bin/bash
################################################################################
# PROXMOX Status to Graphite
#
# Notes:
#   Assumes TCP Graphite.
#
# Written by:
#   Adam Boutcher         (IPPP, Durham University, UK) 2020
#   Paul Clark            (IPPP, Durham University, UK) 2020
#
################################################################################

# Graphite details
GRAPHITE="172.16.0.1"
GPORT="2003"
PREFIX="prefix."
PVECLUTER="pve"

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
check_bin date
check_bin awk
check_bin /usr/bin/nc
check_bin /usr/bin/pvesh

PVENODES=$(/usr/bin/pvesh get /nodes/ --noborder --human-readable=0 --noheader)
stamp=$(date +%s)

TMPIFS=$IFS
IFS=$'\n'

for node in $(echo "$PVENODES"); do
  name=$(echo "$node" | awk '{print $1}')
  status=$(echo "$node" | awk '{print $2}')
  cpu=$(echo "$node" | awk '{print $3}') #percent as float
  maxcpu=$(echo "$node" | awk '{print $4}')
  maxmem=$(echo "$node" | awk '{print $5}')
  mem=$(echo "$node" | awk '{print $6}')
  uptime=$(echo "$node" | awk '{print $8}')

  nc -z $GRAPHITE $GPORT 1>/dev/null 2>&1
  if [[ $? -eq 0 ]]; then
    if [[ ! -z "$cpu" ]]; then echo "${PREFIX}proxmox.$PVECLUTER.$(hostname -s).$name.cpu $cpu $stamp" | /usr/bin/nc -w 3 $GRAPHITE $GPORT & fi
    if [[ ! -z "$maxcpu" ]]; then echo "${PREFIX}proxmox.$PVECLUTER.$(hostname -s).$name.maxcpu $maxcpu $stamp" | /usr/bin/nc -w 3 $GRAPHITE $GPORT & fi
    if [[ ! -z "$maxmem" ]]; then echo "${PREFIX}proxmox.$PVECLUTER.$(hostname -s).$name.maxmem $maxmem $stamp" | /usr/bin/nc -w 3 $GRAPHITE $GPORT & fi
    if [[ ! -z "$mem" ]]; then echo "${PREFIX}proxmox.$PVECLUTER.$(hostname -s).$name.mem $mem $stamp" | /usr/bin/nc -w 3 $GRAPHITE $GPORT & fi
    if [[ ! -z "$uptime" ]]; then echo "${PREFIX}proxmox.$PVECLUTER.$(hostname -s).$name.uptime $uptime $stamp" | /usr/bin/nc -w 3 $GRAPHITE $GPORT & fi
  fi

done

IFS=$TMPIFS
