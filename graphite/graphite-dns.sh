#!/bin/bash
# DNS Resolution Times - Adam Boutcher
# Requires dig with -u support (9.11.4 has it)
# Graphite host and prefix
GRAPHITE="192.168.186.100";
GPORT="2003";
PREFIX="ippp.";
# The Servers you resolve against
DNSRV=(   "129.234.186.101"
          "129.234.186.130"
          "10.255.0.1"
          "10.255.0.2"
);
# Names to Resolve - Probably best use use different domains/TLDs to test against different root forwarders.
TESTADR=( "gridui1.dur.scotgrid.ac.uk"
          "se01.dur.scotgrid.ac.uk"
          "login.phyip3.dur.ac.uk"
          "dur.ac.uk"
          "google.com"
          "bbc.co.uk"
          "cern.ch"
          "egi.eu"
);
# Timeout in Seconds
TIMEOUT=2;

which dig >/dev/null 2>&1;
if [ $? -ne 0 ]; then
  echo "DIG Not found.";
  exit 1;
fi

STAMP=$(date +"%s");
for SRV in ${DNSRV[@]}; do
  SRVCLN=$(echo $SRV | sed "s/\./\\-/g");
  for ADDR in ${TESTADR[@]}; do
    ADDRCLN=$(echo $ADDR | sed "s/\./\\-/g");
    RESULT=$(dig -u +time=$TIMEOUT @$SRV $ADDR 2>/dev/null);
    if [ $? -ne 0 ]; then
      echo $SRVCLN $ADDRCLN -1;
      echo "${PREFIX}dns.${SRVCLN}.${ADDRCLN} -1 $STAMP" | nc $GRAPHITE $GPORT;
    else
      TIME=$(echo "$RESULT" | grep "Query time:" | awk '{print $4}')
      echo $SRVCLN $ADDRCLN $TIME;
      echo "${PREFIX}dns.${SRVCLN}.${ADDRCLN} $TIME $STAMP" | nc $GRAPHITE $GPORT;
    fi
  done;
done;
exit 0;
