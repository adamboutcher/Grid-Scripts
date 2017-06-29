## Sample Usage:

This is aimed at network envrionments where end users require some form of quota output.

Put the server script into cron:
```bash
echo "*/2 * * * * root ZFS-Quota-Server.sh homes/home >/mnt/home/quota.zfs 2>&1" >> /etc/cron.d/zfs-quota
```

the quota.zfs output should look similar to this:
```
aboutcher::1307875224::161061273600::1%
root::56580187648::64424509440::88%
```

Add the list of ZFS Servers to the array in the client script and the correct mountpoint, you could then alias quota with this script is required.

The sample output should look like this
```

 Quota Report for aboutcher
 Mount				Used		Total		Last Checked
 /mnt/home			1.3G (1%)	150G		Wed 28 Jun 2017 16:21:44 BST

```
