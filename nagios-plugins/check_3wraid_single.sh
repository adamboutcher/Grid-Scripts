#!/bin/bash
# Nagios Plugin Wrapper for checking 3ware raid status
# requires TW_CLI http://www.avagotech.com/support/download-search/

RAID=0
CONT=0

if [[ -z "$1" ]]; then
    echo No Arguments Supplied
    exit 1
elif [ $1 = "-h" ] || [ $1 = "-u" ] || [ $1 = "--help" ] || [ $1 = "--usage" ]; then
	echo "check_3wraid           a simple Nagios plugin to check the raid status on 3ware cards."
    echo "Usage:"
    echo "-c --ctl               Controller ID"
    echo "-u --unit              Unit/Raid ID"
    echo "-h --help              Same as -u --usage"
    echo "-u --usage             This screen"
    exit 0
else
    while [[ $# -gt 1 ]]
    do
        key="$1"   

        case $key in
            -u|--unit)
            RAID="$2"
            shift
            ;;
            -c|--ctl)
            CONT="$2"
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

    DIFF=$(tw_cli /c${CONT}/u${RAID} show | grep u${RAID} | head -1 | cut -c20-34)

    if [[ "$DIFF" -eq "OK" ]]; then
    	echo "OK - ${DIFF}";
    	exit 0;
    else
    	echo "CRITICAL - ${DIFF}";
    	exit 2;
    fi

fi