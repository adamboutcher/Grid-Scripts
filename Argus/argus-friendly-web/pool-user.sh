#!/bin/bash

HN=$(getent ahosts $(hostname) | grep $(hostname) | awk '{print $1}');
echo "Pool Accounts on \"$HN\"" > /mt/admin/argus/userlist-$HN.txt

for i in `ls -li /etc/grid-security/gridmapdir/ | grep cn%3  | awk {'print $1'}`
do
  	user=`ls -li /etc/grid-security/gridmapdir/ | grep $i | awk {'print $10'}`
        count=`ls -li /etc/grid-security/gridmapdir/ | grep $i | wc -l`
        if [ $count -gt "1" ]; then
                IFS=', ' read -r -a user_array <<< ${user}
                decoded==$(printf '%b' "${user_array[0]//%/\\x}")
                echo ${user_array[1]} - ${decoded} >> /mt/admin/argus/userlist-$HN.txt
        fi

done