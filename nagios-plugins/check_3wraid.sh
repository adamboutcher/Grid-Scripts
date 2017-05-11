#!/bin/bash
# Nagios Plugin Wrapper for checking 3ware raid status
# requires 3ware TW_CLI http://www.avagotech.com/support/download-search/

CONT=0
CHK="OK"
if [[ -z "$1" ]]; then
    echo No Arguments Supplied
    exit 1
elif [ $1 = "-h" ] || [ $1 = "-u" ] || [ $1 = "--help" ] || [ $1 = "--usage" ]; then
        echo "check_3wraid a simple Nagios plugin to check the raid status on 3wraid cards."
    echo "Usage:"
    echo "-c --cont              Controller ID"
    echo "-h --help              Same as -u --usage"
    echo "-u --usage             This screen"
    exit 0
else
    while [[ $# -gt 1 ]]
    do
        key="$1"

        case $key in
            -c|--cont)
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
    TEST=$(/opt/TW_CLI/x86_64/tw_cli /c${CONT} show  2> /dev/null)
    if [[ "$?" -eq "0" ]]; then
        for i in `/opt/TW_CLI/x86_64/tw_cli /c${CONT} show | grep "^u[0-9]" | cut -c17-30`;
        do
            if [[ "$i" != *"OK"* ]] && [[ "$i" != *"VERIFY"* ]]; then
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
       echo "WARNING - Unknown Controller ID";
       exit 2
   fi
fi
