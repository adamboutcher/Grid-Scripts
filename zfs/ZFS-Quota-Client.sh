#!/bin/bash
# ZFS Quota Client

servers[0]="/mnt/home"

echo "";
echo -e " Quota Report for $USER"
echo -e " Mount\t\t\t\tUsed\t\tTotal\t\tLast Checked"

for i in "${servers[@]}"; do
	zquota=$(cat $i/quota.zfs | grep $USER);
	if [[ ! -z "$zquota" ]]; then
		zused=$(echo $zquota | awk -F'::' '{print $2}' | numfmt --to=iec);
		ztotal=$(echo $zquota | awk -F'::' '{print $3}' | numfmt --to=iec);
		zuperc=$(echo $zquota | awk -F'::' '{print $4}');
		zage=$(stat -c %Y $i/quota.zfs | date +%c)
		echo -e " $i\t\t\t$zused ($zuperc)\t$ztotal\t\t$zage"
	fi
done;
echo "";
exit 0;