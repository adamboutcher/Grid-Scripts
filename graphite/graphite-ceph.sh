#!/bin/bash
################################################################################
# CEPH Status to Graphite
#
# Notes:
#   Assumes TCP Graphite.
#
# Written by:
#   Adam Boutcher         (IPPP, Durham University, UK) 2020
#   Paul Clark            (IPPP, Durham University, UK) 2020
#   Oliver Smith          (NetVirta, SG) 2021
#
################################################################################

# Graphite details
GRAPHITE="193.60.193.14"
GPORT="2003"
PREFIX="grid."
CEPHCLUTER="grid-pve"
CEPHBIN="/usr/bin/ceph"

#Function: Check that a binary exists
#Usage: check_bin command
function check_bin() {
  which $1 1>/dev/null 2>&1
  if [[ $? -ne 0 ]]; then
    echo "$1 cannot be found. Please install it or add it to the path. Exiting."
    exit 1
  fi
}

check_bin which
check_bin echo
check_bin date
check_bin bc
check_bin grep
check_bin tail
check_bin awk
check_bin xargs
check_bin cut
check_bin hostname
check_bin head
check_bin rev
check_bin kill
check_bin ps
check_bin sleep
check_bin nc
check_bin $CEPHBIN

# trying to make some of the units better.
function norm_to_b() {
  local VAL=$1
  local UNIT=$2
  case $UNIT in
    K|k)
      VAL=$(echo $VAL*1000 | bc )
      ;;
    M|m)
      VAL=$(echo $VAL*1000000 | bc )
      ;;
    G|g)
      VAL=$(echo $VAL*1000000000 | bc )
      ;;
    T|t)
      VAL=$(echo $VAL*1000000000000 | bc )
      ;;
    P|p)
      VAL=$(echo $VAL*1000000000000000 | bc )
      ;;
  esac
  echo $VAL
}

#Kill any previous scripts running
for opids in $(ps ax | grep $0 | grep -v grep | grep -v "/dev/null" | awk '{print $1}' | grep -v $$); do
  if [ $opids -ne 0 ]; then
    kill $opids >/dev/null 2>&1;
    if [ $? -eq 0 ]; then
      echo "Killed Previous script";
    fi
    sleep 1;
  fi
done;

# Check Graphite is alive
nc -z $GRAPHITE $GPORT 1>/dev/null 2>&1
if [[ $? -ne 0 ]]; then
  echo "Cannot connect to graphite on $GRAPHITE $GPORT"
  exit 1;
fi

# CEPH Commands
stamp=`date +"%s"`
CEPHSTATUS=$($CEPHBIN status)
CEPHPOOLS=$($CEPHBIN osd pool ls)
CEPHPOOLSTATS=$($CEPHBIN df)
CEPHOSDSTATS=$($CEPHBIN osd df)
TEMPIFS=$IFS
IFS=$'\n'

# CEPH Cluster STATUS
CEPHIOC=$(echo "$CEPHSTATUS" | grep -A1 io | tail -n1)
CEPHDOBJ=$(echo "$CEPHSTATUS" | grep -A2 data | tail -n1)
CEPHDUSE=$(echo "$CEPHSTATUS" | grep -A3 data | tail -n1)

# CEPH Cluster IOS
IORSP=$(echo "$CEPHIOC" | awk -F ":" '{print $2}' | awk -F "," '{print $1}' | xargs)
IOWSP=$(echo "$CEPHIOC" | awk -F ":" '{print $2}' | awk -F "," '{print $2}' | xargs)
IORIO=$(echo "$CEPHIOC" | awk -F ":" '{print $2}' | awk -F "," '{print $3}' | xargs)
IOWIO=$(echo "$CEPHIOC" | awk -F ":" '{print $2}' | awk -F "," '{print $4}' | xargs)
IORB=$(norm_to_b $(echo "$IORSP" | awk '{print $1}') $(echo "$IORSP" | awk '{print $2}' | cut -c -1))
IOWB=$(norm_to_b $(echo "$IOWSP" | awk '{print $1}') $(echo "$IOWSP" | awk '{print $2}' | cut -c -1))
IOR=$(echo "$IORIO" | awk '{print $1}')
IOW=$(echo "$IOWIO" | awk '{print $1}')
if [[ ! -z "$IORB" ]]; then echo "$PREFIX.ceph.$CEPHCLUTER.$(hostname -s).io.bytesread $IORB $stamp" | nc -w 3 $GRAPHITE $GPORT & fi
if [[ ! -z "$IOWB" ]]; then echo "$PREFIX.ceph.$CEPHCLUTER.$(hostname -s).io.byteswrite $IOWB $stamp" | nc -w 3 $GRAPHITE $GPORT & fi
if [[ ! -z "$IOR" ]]; then echo "$PREFIX.ceph.$CEPHCLUTER.$(hostname -s).io.read $IOR $stamp" | nc -w 3 $GRAPHITE $GPORT & fi
if [[ ! -z "$IOW" ]]; then echo "$PREFIX.ceph.$CEPHCLUTER.$(hostname -s).io.write $IOW $stamp" | nc -w 3 $GRAPHITE $GPORT & fi

#CEPH Cluster OBJECTS
OBJOBJ=$(echo "$CEPHDOBJ" | awk -F ":" '{print $2}' | awk -F "," '{print $1}' | xargs)
OBJSPC=$(echo "$CEPHDOBJ" | awk -F ":" '{print $2}' | awk -F "," '{print $2}' | xargs)
OBJO=$(norm_to_b $(echo "$OBJOBJ" | awk '{print $1}' | rev | cut -c 2- | rev) $(echo "$OBJOBJ" | awk '{print $1}' | rev | cut -c -1))
OBJU=$(norm_to_b $(echo "$OBJSPC" | awk '{print $1}') $(echo "$OBJSPC" | awk '{print $2}' | cut -c -1))
if [[ ! -z "$OBJO" ]]; then echo "$PREFIX.ceph.$CEPHCLUTER.$(hostname -s).data.objects $OBJO $stamp" | nc -w 3 $GRAPHITE $GPORT & fi
if [[ ! -z "$OBJU" ]]; then echo "$PREFIX.ceph.$CEPHCLUTER.$(hostname -s).data.space $OBJU $stamp" | nc -w 3 $GRAPHITE $GPORT & fi

#CEPH Cluster USAGE
USEUSE=$(echo "$CEPHDUSE" | awk -F ":" '{print $2}' | awk -F "," '{print $1}' | xargs)
USED=$(norm_to_b $(echo "$USEUSE" | awk '{print $1}') $(echo "$USEUSE" | awk '{print $2}' | cut -c -1))
if [[ ! -z "$USED" ]]; then echo "$PREFIX.ceph.$CEPHCLUTER.$(hostname -s).usage.usedspace $USED $stamp" | nc -w 3 $GRAPHITE $GPORT & fi

#CEPH Pool STATS
for pool in $(echo "$CEPHPOOLS"); do
  ## Individual Pools
  poolstats=$(echo "$CEPHPOOLSTATS" | grep "$pool" | tail -n 1)
  avail=$(norm_to_b $(echo "$poolstats" | awk '{print $9}') $(echo "$poolstats" | awk '{print $10}' | cut -c -1))
  used=$(norm_to_b $(echo "$poolstats" | awk '{print $6}') $(echo "$poolstats" | awk '{print $7}' | cut -c -1))
  stored=$(norm_to_b $(echo "$poolstats" | awk '{print $3}') $(echo "$poolstats" | awk '{print $4}' | cut -c -1))
  pctuse=$(echo "$poolstats" | awk '{print $10}')
  if [[ ! -z "$avail" ]]; then echo "$PREFIX.ceph.$CEPHCLUTER.$(hostname -s).pool.$pool.avail $avail $stamp" | nc -w 3 $GRAPHITE $GPORT & fi
  if [[ ! -z "$used" ]]; then echo "$PREFIX.ceph.$CEPHCLUTER.$(hostname -s).pool.$pool.used $used $stamp" | nc -w 3 $GRAPHITE $GPORT & fi
  if [[ ! -z "$stored" ]]; then echo "$PREFIX.ceph.$CEPHCLUTER.$(hostname -s).pool.$pool.stored $stored $stamp" | nc -w 3 $GRAPHITE $GPORT & fi
  if [[ ! -z "$pctuse" ]]; then echo "$PREFIX.ceph.$CEPHCLUTER.$(hostname -s).pool.$pool.pctuse $pctuse $stamp" | nc -w 3 $GRAPHITE $GPORT & fi
  unset avail
  unset used
  unset stored
  unset pctuse
  unset poolstats
done

#CEPH Class STATS
for class in {"ssd","hdd","nvme"}; do
  ## Individual Pools
  classstats=$(echo "$CEPHPOOLSTATS" | grep -i "$class" | head -n 1)
  avail=$(norm_to_b $(echo "$classstats" | awk '{print $4}') $(echo "$classstats" | awk '{print $5}' | cut -c -1))
  used=$(norm_to_b $(echo "$ckassstats" | awk '{print $8}') $(echo "$classstats" | awk '{print $9}' | cut -c -1))
  total=$(norm_to_b $(echo "$classstats" | awk '{print $2}') $(echo "$classstats" | awk '{print $3}' | cut -c -1))
  pctuse=$(echo "$poolstats" | awk '{print $10}')
  if [[ ! -z "$avail" ]]; then echo "$PREFIX.ceph.$CEPHCLUTER.$(hostname -s).class.$class.avail $avail $stamp" | nc -w 3 $GRAPHITE $GPORT & fi
  if [[ ! -z "$used" ]]; then echo "$PREFIX.ceph.$CEPHCLUTER.$(hostname -s).class.$class.used $used $stamp" | nc -w 3 $GRAPHITE $GPORT & fi
  if [[ ! -z "$total" ]]; then echo "$PREFIX.ceph.$CEPHCLUTER.$(hostname -s).class.$class.total $total $stamp" | nc -w 3 $GRAPHITE $GPORT & fi
  if [[ ! -z "$pctuse" ]]; then echo "$PREFIX.ceph.$CEPHCLUTER.$(hostname -s).class.$class.pctuse $pctuse $stamp" | nc -w 3 $GRAPHITE $GPORT & fi
  unset avail
  unset used
  unset stored
  unset pctuse
  unset classstats
done

# CEPH OSD STATS
for osd in $(echo "$CEPHOSDSTATS" | grep -i "ssd\|hdd\|nvme"); do
  id=$(echo "$osd" | awk '{print $1}')
  size=$(norm_to_b $(echo "$osd" | awk '{print $5}') $(echo "$osd" | awk '{print $6}' | cut -c -1))
  used=$(norm_to_b $(echo "$osd" | awk '{print $7}') $(echo "$osd" | awk '{print $8}' | cut -c -1))
  free=$(norm_to_b $(echo "$osd" | awk '{print $15}') $(echo "$osd" | awk '{print $16}' | cut -c -1))
  pctuse=$(echo "$osd" | awk '{print $17}')
  pgs=$(echo "$osd" | awk '{print $19}')
  if [[ ! -z "$size" ]]; then echo "$PREFIX.ceph.$CEPHCLUTER.$(hostname -s).osd.$id.size $size $stamp" | nc -w 3 $GRAPHITE $GPORT & fi
  if [[ ! -z "$used" ]]; then echo "$PREFIX.ceph.$CEPHCLUTER.$(hostname -s).osd.$id.used $used $stamp" | nc -w 3 $GRAPHITE $GPORT & fi
  if [[ ! -z "$free" ]]; then echo "$PREFIX.ceph.$CEPHCLUTER.$(hostname -s).osd.$id.free $free $stamp" | nc -w 3 $GRAPHITE $GPORT & fi
  if [[ ! -z "$pctuse" ]]; then echo "$PREFIX.ceph.$CEPHCLUTER.$(hostname -s).osd.$id.pctuse $pctuse $stamp" | nc -w 3 $GRAPHITE $GPORT & fi
  if [[ ! -z "$pgs" ]]; then echo "$PREFIX.ceph.$CEPHCLUTER.$(hostname -s).osd.$id.pgs $pgs $stamp" | nc -w 3 $GRAPHITE $GPORT & fi
  unset size
  unset used
  unset free
  unset pctuse
  unset pgs
  unset id
done

IFS=$TEMPIFS
exit 0;
