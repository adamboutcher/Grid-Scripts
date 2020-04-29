#!/bin/bash
#/usr/local/sbin/graphite-zfs.sh
#
# ZFS on Linux Graphite Metrics
# This is by no means fully featured and is very poorly tested.
# 2020 - Adam Boutcher - Durham University (UKI-SCOTGRID-DURHAM).
#

GRAPHITE="172.16.0.1"
GPORT="2003"
PREFIX="prefix."
ZPOOL="/usr/sbin/zpool"

# Function to check that a binary exists
function check_bin() {
  which $1 1>/dev/null 2>&1
  if [[ $? -ne 0 ]]; then
    echo "$1 cannot be found. Please install it or add it to the path. Exiting."
    exit 1
  fi
}

function state_to_id() {
  case $1 in
    "ONLINE"|"online")
      echo 0
    ;;
    "DEGRADED"|"degraded")
      echo 1
    ;;
    "FAULTED"|"faulted")
      echo 2
    ;;
    "OFFLINE"|"offline")
      echo 3
    ;;
    "UNAVAIL"|"unavail")
      echo 4
    ;;
    "REMOVED"|"removed")
      echo 5
    ;;
    *)
      echo 6
    ;;
  esac
}

check_bin which
check_bin $ZPOOL
check_bin hostname
check_bin echo
check_bin nc
check_bin awk
check_bin cat
check_bin tail

HOST=$(hostname -s)
POOLS=$($ZPOOL list -Ho name)

stamp=$(date +"%s")

for POOL in $POOLS; do
  DATA=$(cat /proc/spl/kstat/zfs/$POOL/io)

  nread=$(echo "$DATA"    | tail -n1 | awk '{print $1}')
  nwritten=$(echo "$DATA" | tail -n1 | awk '{print $2}')
  reads=$(echo "$DATA"    | tail -n1 | awk '{print $3}')
  writes=$(echo "$DATA"   | tail -n1 | awk '{print $4}')
  wtime=$(echo "$DATA"    | tail -n1 | awk '{print $5}')
  wlentime=$(echo "$DATA" | tail -n1 | awk '{print $6}')
  wupdate=$(echo "$DATA"  | tail -n1 | awk '{print $7}')
  rtime=$(echo "$DATA"    | tail -n1 | awk '{print $8}')
  rlentime=$(echo "$DATA" | tail -n1 | awk '{print $9}')
  rupdate=$(echo "$DATA"  | tail -n1 | awk '{print $10}')
  wcnt=$(echo "$DATA"     | tail -n1 | awk '{print $11}')
  rcnt=$(echo "$DATA"     | tail -n1 | awk '{print $12}')

  total=$($ZPOOL get -Hp size $POOL | awk '{print $3}')
  used=$($ZPOOL get -Hp alloc $POOL | awk '{print $3}')
  free=$($ZPOOL get -Hp free $POOL | awk '{print $3}')
  zpst=$(state_to_id $($ZPOOL get -Hp health $POOL | awk '{print $3}'))
  zpfrag=$($ZPOOL get -Hp frag $POOL | awk '{print $3}')
  zpcap=$($ZPOOL get -Hp cap $POOL | awk '{print $3}')

  if [[ ! -z "$nread" ]]; then    echo "$PREFIX.zfs.$HOST.$POOL.stats.nread $nread $stamp"       | nc -w 3 $GRAPHITE $GPORT; fi
  if [[ ! -z "$nwritten" ]]; then echo "$PREFIX.zfs.$HOST.$POOL.stats.nwritten $nwritten $stamp" | nc -w 3 $GRAPHITE $GPORT; fi
  if [[ ! -z "$reads" ]]; then    echo "$PREFIX.zfs.$HOST.$POOL.stats.reads $reads $stamp"       | nc -w 3 $GRAPHITE $GPORT; fi
  if [[ ! -z "$writes" ]]; then   echo "$PREFIX.zfs.$HOST.$POOL.stats.writes $writes $stamp"     | nc -w 3 $GRAPHITE $GPORT; fi
  if [[ ! -z "$wtime" ]]; then    echo "$PREFIX.zfs.$HOST.$POOL.stats.wtime $wtime $stamp"       | nc -w 3 $GRAPHITE $GPORT; fi
  if [[ ! -z "$wlentime" ]]; then echo "$PREFIX.zfs.$HOST.$POOL.stats.wlentime $wlentime $stamp" | nc -w 3 $GRAPHITE $GPORT; fi
  if [[ ! -z "$wupdate" ]]; then  echo "$PREFIX.zfs.$HOST.$POOL.stats.wupdate $wupdate $stamp"   | nc -w 3 $GRAPHITE $GPORT; fi
  if [[ ! -z "$rtime" ]]; then    echo "$PREFIX.zfs.$HOST.$POOL.stats.rtime $rtime $stamp"       | nc -w 3 $GRAPHITE $GPORT; fi
  if [[ ! -z "$rlentime" ]]; then echo "$PREFIX.zfs.$HOST.$POOL.stats.rlentime $rlentime $stamp" | nc -w 3 $GRAPHITE $GPORT; fi
  if [[ ! -z "$wcnt" ]]; then     echo "$PREFIX.zfs.$HOST.$POOL.stats.wcnt $wcnt $stamp"         | nc -w 3 $GRAPHITE $GPORT; fi
  if [[ ! -z "$rcnt" ]]; then     echo "$PREFIX.zfs.$HOST.$POOL.stats.rcnt $rcnt $stamp"         | nc -w 3 $GRAPHITE $GPORT; fi

  if [[ ! -z "$total" ]]; then    echo "$PREFIX.zfs.$HOST.$POOL.pool.total $total $stamp"        | nc -w 3 $GRAPHITE $GPORT; fi
  if [[ ! -z "$used" ]]; then     echo "$PREFIX.zfs.$HOST.$POOL.pool.used $used $stamp"          | nc -w 3 $GRAPHITE $GPORT; fi
  if [[ ! -z "$free" ]]; then     echo "$PREFIX.zfs.$HOST.$POOL.pool.free $free $stamp"          | nc -w 3 $GRAPHITE $GPORT; fi
  if [[ ! -z "$zpst" ]]; then     echo "$PREFIX.zfs.$HOST.$POOL.pool.state $zpst $stamp"         | nc -w 3 $GRAPHITE $GPORT; fi
  if [[ ! -z "$zpfrag" ]]; then   echo "$PREFIX.zfs.$HOST.$POOL.pool.fragperc $zpfrag $stamp"    | nc -w 3 $GRAPHITE $GPORT; fi
  if [[ ! -z "$zpcap" ]]; then    echo "$PREFIX.zfs.$HOST.$POOL.pool.usedperc $zpcap $stamp"     | nc -w 3 $GRAPHITE $GPORT; fi
done;
