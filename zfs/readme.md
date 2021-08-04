# Moved...

This work has been split into it's own repo found at [adamboutcher/zfs-quota](https://github.com/adamboutcher/zfs-quota). This code was pushed into v1 branch and will be maintained there.

## Sample Usage:

This is aimed at network envrionments where end users require some form of quota output.
We assume that the root of the ZFS mount point is the mount point for the users data, this may not be your use case, please change teh variable QLOC in the server script.

Put the server script into cron:
```bash
echo "*/2 * * * * root ZFS-Quota-Server.sh homes/home >/dev/null 2>&1" >> /etc/cron.d/zfs-quota
```

Touch the quota.zfs and set permissions for first run, change homes/home for your ZFS vol.
```bash
touch $(zfs get mountpoint homes/home -H | awk '{print $3}')/quota.zfs
chmod 744 $(zfs get mountpoint homes/home -H | awk '{print $3}')/quota.zfs
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
