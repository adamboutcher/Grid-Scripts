#!/bin/bash
# Nagios Plugin Wrapper for checking megaraid raid status
# requires MegaRaid megaCLI http://www.avagotech.com/support/download-search/

RAID=0

if [[ -z "$1" ]]; then
    echo No Arguments Supplied
    exit 1
elif [ $1 = "-h" ] || [ $1 = "-u" ] || [ $1 = "--help" ] || [ $1 = "--usage" ]; then
	echo "check_megaraid         a simple Nagios plugin to check the raid status on MegaRAID cards."
    echo "Usage:"
    echo "-r --raid              Logical Drive or Raid ID"
    echo "-h --help              Same as -u --usage"
    echo "-u --usage             This screen"
    exit 0
else
    while [[ $# -gt 1 ]]
    do
        key="$1"   

        case $key in
            -r|--raid)
            RAID="$2"
            shift
            ;;
            *)
            echo "Wrong Arguments Supplied."
            echo "Check --usage for usaged details."
            exit 1
            ;;
        esac
        shift
    done

    DIFF=$(/opt/MegaRAID/MegaCli/MegaCli64 -LDInfo -L${RAID} -aALL | grep "State" | cut -c23-)

    if [[ "$DIFF" -eq "Optimal" ]]; then
    	echo "OK - ${DIFF}";
    	exit 0;
    else
    	echo "CRITICAL - ${DIFF}";
    	exit 2;
    fi

fi