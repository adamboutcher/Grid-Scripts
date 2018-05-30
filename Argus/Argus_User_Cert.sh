#!/bin/bash
if [ -z "$1" ]; then
        echo "No Username supplied."
        exit 1
fi
GRIDUSER=$1
GRIDMAPDIR="/etc/grid-security/gridmapdir/"
ARGUSUSER=`ls -li $GRIDMAPDIR | grep $GRIDUSER | awk '{ print $1; }'`
ARGUSCOUNT=`echo "$ARGUSUSER" | wc -l`
if [ -z "$ARGUSUSER" ]; then
        echo "User not found."
        exit 2
fi
if [ $ARGUSCOUNT -gt 1 ]; then
        echo "Too many matches, please use exact username."
        exit 3
fi
CERT=`ls -li $GRIDMAPDIR | grep $ARGUSUSER | awk '{ print $10; }'`
if [ -z "$CERT" ];	then
        echo "Certificate not found"
        exit 4
else
    	echo "User $1 Certificate Details:"
        echo $CERT
        exit 0
fi