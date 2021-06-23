#!/bin/bash
################################################################################
# Squid SNMP to Graphite
#
# Notes:
#   Assumes TCP Graphite.
#
# Written by:
#   Adam Boutcher         (IPPP, Durham University, UK) 2020
#
################################################################################


GRAPHITE="172.16.0.1"
GPORT="2003"
PREFIX="prefix."

SQUIDS=(
  "172.32.0.1:3401"
)

# Function to check that a binary exists
function check_bin() {
  which $1 1>/dev/null 2>&1
  if [[ $? -ne 0 ]]; then
    echo "$1 cannot be found. Please install it or add it to the path. Exiting."
    exit 1
  fi
}

check_bin which
check_bin date
check_bin hostname
check_bin echo
check_bin snmpget
check_bin xargs
check_bin nc

stamp=`date +"%s"`

for SQUID in ${SQUIDS[@]}; do
  UsedMem=$(snmpget -Oqv -c public $SQUID -v 2c .1.3.6.1.4.1.3495.1.1.1.0 | xargs)
  UsedDir=$(snmpget -Oqv -c public $SQUID -v 2c .1.3.6.1.4.1.3495.1.1.2.0 | xargs)
  MaxMem=$(snmpget -Oqv -c public $SQUID -v 2c .1.3.6.1.4.1.3495.1.2.5.1.0 | xargs)
  MaxDir=$(snmpget -Oqv -c public $SQUID -v 2c .1.3.6.1.4.1.3495.1.2.5.2.0 | xargs)
  HTTPREQ=$(snmpget -Oqv -c public $SQUID -v 2c .1.3.6.1.4.1.3495.1.3.2.1.1.0 | xargs)
  HTTPHIT=$(snmpget -Oqv -c public $SQUID -v 2c .1.3.6.1.4.1.3495.1.3.2.1.2.0 | xargs)
  HTTPERR=$(snmpget -Oqv -c public $SQUID -v 2c .1.3.6.1.4.1.3495.1.3.2.1.3.0 | xargs)
  CLIENTS=$(snmpget -Oqv -c public $SQUID -v 2c .1.3.6.1.4.1.3495.1.3.2.1.15.0 | xargs)
  SNAME=$(echo $SQUID | sed 's/\./_/g' | awk -F ":" '{print $1}')

  nc -z $GRAPHITE $GPORT 1>/dev/null 2>&1
  if [[ $? -eq 0 ]]; then
    if [[ ! -z "$UsedMem" ]]; then echo "${PREFIX}squid.$SNAME.used.mem $UsedMem $stamp" | nc -w 3 $GRAPHITE $GPORT; fi
    if [[ ! -z "$UsedDir" ]]; then echo "${PREFIX}squid.$SNAME.used.dir $UsedDir $stamp" | nc -w 3 $GRAPHITE $GPORT; fi
    if [[ ! -z "$MaxMem" ]]; then echo "${PREFIX}squid.$SNAME.max.mem $MaxMem $stamp" | nc -w 3 $GRAPHITE $GPORT; fi
    if [[ ! -z "$MaxDir" ]]; then echo "${PREFIX}squid.$SNAME.max.dir $MaxDir $stamp" | nc -w 3 $GRAPHITE $GPORT; fi
    if [[ ! -z "$HTTPREQ" ]]; then echo "${PREFIX}squid.$SNAME.stats.httprequests $HTTPREQ $stamp" | nc -w 3 $GRAPHITE $GPORT; fi
    if [[ ! -z "$HTTPHIT" ]]; then echo "${PREFIX}squid.$SNAME.stats.httphits $HTTPHIT $stamp" | nc -w 3 $GRAPHITE $GPORT; fi
    if [[ ! -z "$HTTPERR" ]]; then echo "${PREFIX}squid.$SNAME.stats.httperrors $HTTPERR $stamp" | nc -w 3 $GRAPHITE $GPORT; fi
    if [[ ! -z "$CLIENTS" ]]; then echo "${PREFIX}squid.$SNAME.stats.clients $CLIENTS $stamp" | nc -w 3 $GRAPHITE $GPORT; fi
  fi
done;

exit 0;
