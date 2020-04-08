#!/bin/bash
# Nordugrid ARC Graphite Metrics - Similar to GanliARC (nordugrid-arc-gangliarc).
# This is by no means fully featured and is very poorly tested.
# 2020 - Adam Boutcher - Durham University (UKI-SCOTGRID-DURHAM).

GRAPHITE="172.16.0.1"
GPORT="2003"
PREFIX="prefix."

which nc 1>/dev/null 2>&1
if [[ $? -ne 0 ]]; then
  echo "NetCat (nc) cannot be found. Please add it to the path."
  exit 1
fi

# Get ARC Variables
JOBLOG=$(cat /etc/arc.conf | grep "joblog" | awk -F "=" '{print $2}' | sed 's/\"//g');
CONTROLDIR=$(cat /etc/arc.conf | grep "controldir" | awk -F "=" '{print $2}' | sed 's/\"//g');
WORKDIR=$(cat /etc/arc.conf | grep "sessiondir" | awk -F "=" '{print $2}' | sed 's/\"//g');

# Reading a Log
LRMS_COUNT=$(cat $JOBLOG | grep "LRMS error" | grep $(date '+%Y-%m-%d' -d "-1 Minute") | grep $(date +%H:%M -d "-1 Minute") | wc -l);
FAIL_COUNT=$(cat $JOBLOG | grep -i "f" | grep -i "fail" | grep $(date '+%Y-%m-%d' -d "-1 Minute") | grep $(date +%H:%M -d "-1 Minute") | wc -l);

# Counting directories
PROCESSING=$(echo $(ls $CONTROLDIR/processing/*.status 2>/dev/null | wc -l)-2 | bc)
# TODO: gm-heartbeat
# heartbeat is gm-heatbeat modified time - (now-mtime)
ACCEPTED=$(grep "ACCEPTED" $CONTROLDIR/*/*.status | wc -l)
PREPARING=$(grep "PREPARING" $CONTROLDIR/*/*.status | wc -l)
SUBMIT=$(grep "SUBMIT" $CONTROLDIR/*/*.status | wc -l)
INLRMS=$(grep "INLRMS" $CONTROLDIR/*/*.status | wc -l)
FINISHING=$(grep "FINISHING" $CONTROLDIR/*/*.status | wc -l)
FINISHED=$(grep "FINISHED" $CONTROLDIR/finished/*.status | wc -l)
DELETED=$(grep "DELETED" $CONTROLDIR/*/*.status | wc -l)
CANCELLING=$(grep "CANCELLING" $CONTROLDIR/*/*.status | wc -l)
TOTAL=$(ls $CONTROLDIR/*/*.status | wc -l)

# Grabbing FS Info
CONTROLDIR_USED=$(df $CONTROLDIR | tail -n1 | awk '{print $3}')
CONTROLDIR_AVAIL=$(df $CONTROLDIR | tail -n1 | awk '{print $4}')
WORKDIR_USED=$(df $WORKDIR | tail -n1 | awk '{print $3}')
WORKDIR_AVAIL=$(df $WORKDIR | tail -n1 | awk '{print $4}')

stamp=$(date +%s);

# Send to Graphite
if [[ ! -z "$LRMS_COUNT" ]]; then echo "${PREFIX}arc.$(hostname -s).stats.lrms_error $LRMS_COUNT $stamp" | nc -w 3 $GRAPHITE $GPORT; fi
if [[ ! -z "$FAIL_COUNT" ]]; then echo "${PREFIX}arc.$(hostname -s).stats.failed $FAIL_COUNT $stamp" | nc -w 3 $GRAPHITE $GPORT; fi
if [[ ! -z "$PROCESSING" ]]; then echo "${PREFIX}arc.$(hostname -s).stats.processing $PROCESSING $stamp" | nc -w 3 $GRAPHITE $GPORT; fi
if [[ ! -z "$ACCEPTED" ]]; then echo "${PREFIX}arc.$(hostname -s).stats.accepted $ACCEPTED $stamp" | nc -w 3 $GRAPHITE $GPORT; fi
if [[ ! -z "$PREPARING" ]]; then echo "${PREFIX}arc.$(hostname -s).stats.preparing $PREPARING $stamp" | nc -w 3 $GRAPHITE $GPORT; fi
if [[ ! -z "$SUBMIT" ]]; then echo "${PREFIX}arc.$(hostname -s).stats.sutmit $SUBMIT $stamp" | nc -w 3 $GRAPHITE $GPORT; fi
if [[ ! -z "$INLRMS" ]]; then echo "${PREFIX}arc.$(hostname -s).stats.inlrms $INLRMS $stamp" | nc -w 3 $GRAPHITE $GPORT; fi
if [[ ! -z "$FINISHING" ]]; then echo "${PREFIX}arc.$(hostname -s).stats.finishing $FINISHING $stamp" | nc -w 3 $GRAPHITE $GPORT; fi
if [[ ! -z "$FINISHED" ]]; then echo "${PREFIX}arc.$(hostname -s).stats.finished $FINISHED $stamp" | nc -w 3 $GRAPHITE $GPORT; fi
if [[ ! -z "$DELETED" ]]; then echo "${PREFIX}arc.$(hostname -s).stats.deleted $DELETED $stamp" | nc -w 3 $GRAPHITE $GPORT; fi
if [[ ! -z "$CANCELLING" ]]; then echo "${PREFIX}arc.$(hostname -s).stats.cancelling $CANCELLING $stamp" | nc -w 3 $GRAPHITE $GPORT; fi
if [[ ! -z "$TOTAL" ]]; then echo "${PREFIX}arc.$(hostname -s).stats.total $TOTAL $stamp" | nc -w 3 $GRAPHITE $GPORT; fi
if [[ ! -z "$CONTROLDIR_USED" ]]; then echo "${PREFIX}arc.$(hostname -s).stats.controldir_used $CONTROLDIR_USED $stamp" | nc -w 3 $GRAPHITE $GPORT; fi
if [[ ! -z "$CONTROLDIR_AVAIL" ]]; then echo "${PREFIX}arc.$(hostname -s).stats.controldir_avail $CONTROLDIR_AVAIL $stamp" | nc -w 3 $GRAPHITE $GPORT; fi
if [[ ! -z "$WORKDIR_USED" ]]; then echo "${PREFIX}arc.$(hostname -s).stats.workdir_used $WORKDIR_USED $stamp" | nc -w 3 $GRAPHITE $GPORT; fi
if [[ ! -z "$WORKDIR_AVAIL" ]]; then echo "${PREFIX}arc.$(hostname -s).stats.workdir_avail $WORKDIR_AVAIL $stamp" | nc -w 3 $GRAPHITE $GPORT; fi

