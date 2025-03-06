#!/usr/bin/env bash

SCRIPTDIR=$(dirname $0)
USER=$1

$SCRIPTDIR/startBackup.sh -p $SCRIPTDIR/borg_passphrase_backup_box1_dell-t20.txt -n $(hostname) -r ssh://$USER-sub1@$USER.your-storagebox.de:23/home/dell-t20 /etc /root /var/spool
$SCRIPTDIR/startBackup.sh -p $SCRIPTDIR/borg_passphrase_backup_box1_flo-data.txt -n flo-data -r ssh://$USER-sub1@$USER.your-storagebox.de:23/home/flo-data /tank/subvol-100-nas-flo

$SCRIPTDIR/checkBackups.sh -p $SCRIPTDIR/borg_passphrase_backup_box1_dell-t20.txt -r ssh://$USER-sub1@$USER.your-storagebox.de:23/home/dell-t20
$SCRIPTDIR/checkBackups.sh -p $SCRIPTDIR/borg_passphrase_backup_box1_flo-data.txt -r ssh://$USER-sub1@$USER.your-storagebox.de:23/home/flo-data

