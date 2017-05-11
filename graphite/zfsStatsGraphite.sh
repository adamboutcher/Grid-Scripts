#!/bin/bash
#zfsStatsGraphite.sh
HOST=$(hostname)
POOL="ZFS-POOL"
GRAPHITE="x.x.x.x"
GPORT="2003"

stamp=`date +"%s"`

nread=`cat /proc/spl/kstat/zfs/$POOL/io | tail -n1 | cut -d ' ' -f 1`
nwritten=`cat /proc/spl/kstat/zfs/$POOL/io | tail -n1 | cut -d ' ' -f 2`
reads=`cat /proc/spl/kstat/zfs/$POOL/io | tail -n1 | cut -d ' ' -f 3`
writes=`cat /proc/spl/kstat/zfs/$POOL/io | tail -n1 | cut -d ' ' -f 4`
wtime=`cat /proc/spl/kstat/zfs/$POOL/io | tail -n1 | cut -d ' ' -f 5`
wlentime=`cat /proc/spl/kstat/zfs/$POOL/io | tail -n1 | cut -d ' ' -f 6`
wupdate=`cat /proc/spl/kstat/zfs/$POOL/io | tail -n1 | cut -d ' ' -f 7`
rtime=`cat /proc/spl/kstat/zfs/$POOL/io | tail -n1 | cut -d ' ' -f 8`
rlentime=`cat /proc/spl/kstat/zfs/$POOL/io | tail -n1 | cut -d ' ' -f 9`
rupdate=`cat /proc/spl/kstat/zfs/$POOL/io | tail -n1 | cut -d ' ' -f 10`
wcnt=`cat /proc/spl/kstat/zfs/$POOL/io | tail -n1 | cut -d ' ' -f 11`
rcnt=`cat /proc/spl/kstat/zfs/$POOL/io | tail -n1 | cut -d ' ' -f 12`


echo "$HOST.zfs.$POOL.stats.nread $nread $stamp" | nc $GRAPHITE $GPORT
echo "$HOST.zfs.$POOL.stats.nwritten $nwritten $stamp" | nc $GRAPHITE $GPORT
echo "$HOST.zfs.$POOL.stats.reads $reads $stamp" | nc $GRAPHITE $GPORT
echo "$HOST.zfs.$POOL.stats.writes $writes $stamp" | nc $GRAPHITE $GPORT
echo "$HOST.zfs.$POOL.stats.wtime $wtime $stamp" | nc $GRAPHITE $GPORT
echo "$HOST.zfs.$POOL.stats.wlentime $wlentime $stamp" | nc $GRAPHITE $GPORT
echo "$HOST.zfs.$POOL.stats.wupdate $wupdate $stamp" | nc $GRAPHITE $GPORT
echo "$HOST.zfs.$POOL.stats.rtime $rtime $stamp" | nc $GRAPHITE $GPORT
echo "$HOST.zfs.$POOL.stats.rlentime $rlentime $stamp" | nc $GRAPHITE $GPORT
echo "$HOST.zfs.$POOL.stats.wcnt $wcnt $stamp" | nc $GRAPHITE $GPORT
echo "$HOST.zfs.$POOL.stats.rcnt $rcnt $stamp" | nc $GRAPHITE $GPORT