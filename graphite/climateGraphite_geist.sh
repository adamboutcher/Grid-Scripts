#!/bin/bash
#climateGraphite_geist.sh
IP="x.x.x.x"
COMMUNITY="public"
GRAPHITE="x.x.x.x"
GPORT="2013"

stamp=`date +"%s"`

# Main Unit
NAME=`snmpget -v1 -O v -c $COMMUNITY $IP .1.3.6.1.4.1.21239.2.2.1.3.1 | sed -e 's/STRING: \(.*\)/\1/' | tr \  _ | tr -d '()'\"`
TEMP=`snmpget -v1 -O v -c $COMMUNITY $IP .1.3.6.1.4.1.21239.2.2.1.5.1 | sed -e 's/INTEGER: \(.*\)/\1/'`
HUMD=`snmpget -v1 -O v -c $COMMUNITY $IP .1.3.6.1.4.1.21239.2.2.1.6.1 | sed -e 's/INTEGER: \(.*\)/\1/'`
AIRF=`snmpget -v1 -O v -c $COMMUNITY $IP .1.3.6.1.4.1.21239.2.2.1.7.1 | sed -e 's/INTEGER: \(.*\)/\1/'`
LIGH=`snmpget -v1 -O v -c $COMMUNITY $IP .1.3.6.1.4.1.21239.2.2.1.8.1 | sed -e 's/INTEGER: \(.*\)/\1/'`
SOND=`snmpget -v1 -O v -c $COMMUNITY $IP .1.3.6.1.4.1.21239.2.2.1.9.1 | sed -e 's/INTEGER: \(.*\)/\1/'`

#Analogue Sensor (Door)
AIO1=`snmpget -v1 -O v -c $COMMUNITY $IP .1.3.6.1.4.1.21239.2.2.1.11.1 | sed -e 's/INTEGER: \(.*\)/\1/'`
AIO2=`snmpget -v1 -O v -c $COMMUNITY $IP .1.3.6.1.4.1.21239.2.2.1.12.1 | sed -e 's/INTEGER: \(.*\)/\1/'`
AIO3=`snmpget -v1 -O v -c $COMMUNITY $IP .1.3.6.1.4.1.21239.2.2.1.13.1 | sed -e 's/INTEGER: \(.*\)/\1/'`

echo "climate.$NAME.temp $TEMP $stamp" | nc $GRAPHITE $GPORT
echo "climate.$NAME.humid $HUMD $stamp" | nc $GRAPHITE $GPORT
echo "climate.$NAME.airflow $AIRF $stamp" | nc $GRAPHITE $GPORT
echo "climate.$NAME.light $LIGH $stamp" | nc $GRAPHITE $GPORT
echo "climate.$NAME.sound $SOND $stamp" | nc $GRAPHITE $GPORT
echo "climate.$NAME.AIO1 $AIO1 $stamp" | nc $GRAPHITE $GPORT
echo "climate.$NAME.AIO2 $AIO2 $stamp" | nc $GRAPHITE $GPORT
echo "climate.$NAME.AIO3 $AIO3 $stamp" | nc $GRAPHITE $GPORT

#Added Sensors
NUM_TEMP=`snmpget -v1 -O v -c $COMMUNITY $IP .1.3.6.1.4.1.21239.2.1.8.1.4.0 | sed -e "s/INTEGER: \(.*\)/\1/"`
for i in `seq 1 $NUM_TEMP`; do
	NAME=`snmpget -v1 -O v -c $COMMUNITY $IP .1.3.6.1.4.1.21239.2.4.1.3.$i | sed -e 's/STRING: \(.*\)/\1/' | tr \  _ | tr -d '()'\"`
	TEMP=`snmpget -v1 -O v -c $COMMUNITY $IP .1.3.6.1.4.1.21239.2.4.1.5.$i | sed -e "s/INTEGER: \(.*\)/\1/"`
	echo "climate.$NAME.temp $TEMP $stamp" | nc $GRAPHITE $GPORT
done