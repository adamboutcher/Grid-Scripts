#!/bin/bash
################################################################################
# IBM (EATON) PDU to Graphite
#
# Notes:
#   Assumes TCP Graphite.
#   Uses OIDS so you dont need MIBS installed.
#
# Written by:
#   Adam Boutcher         (IPPP, Durham University, UK) 2021
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

  SNMP_tl=`snmpget -Oqv -c $PDU_COMM $PDU_ADDR -v 1 .1.3.6.1.4.1.534.6.6.2.1.3.2.7.1.49 2>/dev/null | xargs`
  SNMP_al=`snmpget -Oqv -c $PDU_COMM $PDU_ADDR -v 1 .1.3.6.1.4.1.534.6.6.2.1.3.2.7.1.13 2>/dev/null | xargs`
  SNMP_bl=`snmpget -Oqv -c $PDU_COMM $PDU_ADDR -v 1 .1.3.6.1.4.1.534.6.6.2.1.3.2.7.1.16 2>/dev/null | xargs`
  SNMP_cl=`snmpget -Oqv -c $PDU_COMM $PDU_ADDR -v 1 .1.3.6.1.4.1.534.6.6.2.1.3.2.7.1.19 2>/dev/null | xargs`

  nc -z $GRAPHITE $GPORT 1>/dev/null 2>&1
  if [[ $? -eq 0 ]]; then
    if [[ ! -z "$SNMP_tl" ]]; then echo "${PREFIX}pdu.$PDU_NAME.totalload $SNMP_tl $stamp" | nc -w 3 $GRAPHITE $GPORT; fi
    if [[ ! -z "$SNMP_al" ]]; then echo "${PREFIX}pdu.$PDU_NAME.bankaload $SNMP_al $stamp" | nc -w 3 $GRAPHITE $GPORT; fi
    if [[ ! -z "$SNMP_bl" ]]; then echo "${PREFIX}pdu.$PDU_NAME.bankbload $SNMP_bl $stamp" | nc -w 3 $GRAPHITE $GPORT; fi
    if [[ ! -z "$SNMP_cl" ]]; then echo "${PREFIX}pdu.$PDU_NAME.bankcload $SNMP_cl $stamp" | nc -w 3 $GRAPHITE $GPORT; fi
  fi
done;
exit 0;


