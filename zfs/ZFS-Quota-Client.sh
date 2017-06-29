#!/bin/bash
# ZFS Quota Client

servers[0]="/mt/home"

echo "";
echo -e " Quota Report for $USER"
echo -e " Mount\t\t\t\tUsed\t\tTotal\t\tLast Checked"

for i in "${servers[@]}"; do
	zquota=$(cat $i/quota.zfs | grep $USER);
	if [[ ! -z "$zquota" ]]; then
		zused=$(echo $zquota | awk -F'::' '{print $2}' | numfmt --to=iec);
		ztotal=$(echo $zquota | awk -F'::' '{print $3}');
		if [[ $ztotal -ne "none" ]]; then 
			ztotal=$(echo $ztotal | numfmt --to=iec);
		fi
		zuperc=$(echo $zquota | awk -F'::' '{print $4}');
		zage=$(date +"%c" -d @$(stat -c %Z $i/quota.zfs))
		echo -e " $i\t\t\t$zused ($zuperc)\t$ztotal\t\t$zage"
	fi
done;
echo "";
exit 0;