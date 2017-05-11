#!/bin/bash
# Nagios Plugin Wrapper for checking megaraid raid status
# requires MegaRaid TW_CLI http://www.avagotech.com/support/download-search/

CONT=0
CHK="OK"
if [[ $1 = "-h" ]] || [[ $1 = "-u" ]] || [[ $1 = "--help" ]] || [[ $1 = "--usage" ]]; then
        echo "check_megaraid_global  a simple Nagios plugin to check the raid status on MegaRAID cards."
    echo "Usage:"
    echo "-h --help              Same as -u --usage"
    echo "-u --usage             This screen"
    exit 0
else
    TEST=$(/opt/MegaRAID/MegaCli/MegaCli64 -LDInfo -LALL -aALL  2> /dev/null)
    if [[ "$?" -eq "0" ]]; then
        for i in `/opt/MegaRAID/MegaCli/MegaCli64 -LDInfo -LALL -aALL | grep "State" | cut -c23-`;
        do
            if [[ "$i" != *"Optimal"* ]]; then
                    echo "CRITICAL - $i"
                    CHK="EXIT"
                    exit 3
                    break
                fi
        done;
    if [[ "$CHK" -eq "OK" ]]; then
            echo "OK"
            exit 0
        fi
    else
       echo "WARNING - Unknown Error with MegaCLI";
       exit 2
   fi
fi