#!/bin/bash
################################################################################
# iPOWER PDU to Graphite
#
# Notes:
#   Assumes TCP Graphite.
#   Uses OIDS so you dont need MIBS installed.
#
# Written by:
#   Adam Boutcher         (IPPP, Durham University, UK) 2020
#
################################################################################

GRAPHITE="172.16.0.1"
GPORT="2003"
PREFIX="prefix."

# MultiArray
# NAME:ADDR:SNMP_COMMUNITY
# THREE Phase
THREE=(

  "pdu-name-01:192.168.1.21:public"
  "pdu-name-02:192.168.1.22:public"
);

################################################################################

function check_bin() {
  which $1 1>/dev/null 2>&1
  if [[ $? -ne 0 ]]; then
    echo "$1 cannot be found. Please install it or add it to the path. Exiting."
    exit 1
  fi
}

check_bin which
check_bin date
check_bin echo
check_bin snmpget
check_bin nc
check_bin cut
check_bin xargs

stamp=`date +"%s"`

for PDU in ${THREE[@]}; do
  PDU_NAME=$(echo $PDU | cut -f1 -d:);
  PDU_ADDR=$(echo $PDU | cut -f2 -d:);
  PDU_COMM=$(echo $PDU | cut -f3 -d:);

  SNMP_1l=`snmpget -Oqv -c $PDU_COMM $PDU_ADDR -v 1 .1.3.6.1.4.1.38218.1.6.2.0 2>/dev/null | xargs`
  SNMP_2l=`snmpget -Oqv -c $PDU_COMM $PDU_ADDR -v 1 .1.3.6.1.4.1.38218.1.6.11.0 2>/dev/null | xargs`
  SNMP_3l=`snmpget -Oqv -c $PDU_COMM $PDU_ADDR -v 1 .1.3.6.1.4.1.38218.1.6.20.0 2>/dev/null | xargs`
  SNMP_tl=$(($SNMP_1l+$SNMP_2l+$SNMP_3l));

  nc -z $GRAPHITE $GPORT 1>/dev/null 2>&1
  if [[ $? -eq 0 ]]; then
    if [[ ! -z "$SNMP_tl" ]]; then echo "${PREFIX}pdu.$PDU_NAME.totalload $SNMP_tl $stamp" | nc -w 3 $GRAPHITE $GPORT; fi
    if [[ ! -z "$SNMP_1l" ]]; then echo "${PREFIX}pdu.$PDU_NAME.bank1load $SNMP_1l $stamp" | nc -w 3 $GRAPHITE $GPORT; fi
    if [[ ! -z "$SNMP_2l" ]]; then echo "${PREFIX}pdu.$PDU_NAME.bank2load $SNMP_2l $stamp" | nc -w 3 $GRAPHITE $GPORT; fi
    if [[ ! -z "$SNMP_3l" ]]; then echo "${PREFIX}pdu.$PDU_NAME.bank3load $SNMP_3l $stamp" | nc -w 3 $GRAPHITE $GPORT; fi
  fi
done;

exit 0;


