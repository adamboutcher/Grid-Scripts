#!/bin/bash
# Nagios Plugin Wrapper for checking DPM
# Adam Boutcher - May 2017 - GPLv3
#   I would suggest reading this script and implementing your own version of it.
#   Put your host certificate & key in /etc/nagios/ and 400 it to nagios.
#   Add a Grid Map for this host certiciate to your DPM Test PATH on your DPM Server.
#   requires dpm-tester.py

if [[ -z "$1" ]]; then
    echo "No Arguments Supplied"
    echo "Check --usage for usaged details."
    exit 1
elif [ $1 = "-u" ] || [ $1 = "--help" ] || [ $1 = "--usage" ]; then
    echo "check_dpm              Super Simple DPM tester for Nagios - I personally wouldn't use it."
    echo "Usage:"
    echo "-h --host              Hostname"
    echo "-t --test              Test [davs, root, gsiftp, combined]"
    echo "-p --path              Path to test"
    echo "   --help              Same as -u --usage"
    echo "-u --usage             This screen"
    exit 0
else
    while [[ $# -gt 1 ]]
    do
        key="$1"   

        case $key in
            -h|--host)
            DHOST="$2"
            shift
            ;;
            -t|--test)
            DTEST="$2"
            shift
            ;;
            -p|--path)
            DPATH="$2"
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
    # Get a Proxy from host cert - chmod 400 these files and own it by your nagios user.
    # Only renew if it's expired
    export X509_USER_CERT=/etc/nagios/hostcert.pem 
    export X509_USER_KEY=/etc/nagios/hostkey.pem
    SECPROX=$(arcproxy -i validityEnd)
    SECNOW=$(date +%s --date "30 seconds")
    if [ $SECPROX -le $SECNOW ]; then
        arcproxy >/dev/null 2>&1
    fi

    DIFF=$(dpm-tester.py --host ${DHOST} --path ${DPATH} --tests ${DTEST} --cleanup | grep -i FAIL | wc -l)
    rm -f /tmp/dpm-tests-tempfile

    # Test for the number of FAIL lines counted OR segfault Exit code (dpm-tester.py hasn't got exit codes implemented)
    if [[ "$DIFF" > "0"  || "$?" > "0" ]]; then
        OUTPUT=$(dpm-tester.py --host ${DHOST} --path ${DPATH} --tests ${DTEST} --cleanup | tail -n1)
        echo "CRITICAL - DPM ${DTEST} - ${OUTPUT}";
	rm -f /tmp/dpm-tests-tempfile
        exit 2;
    else
        echo "OK - DPM ${DTEST}";
        exit 0;
    fi
fi
