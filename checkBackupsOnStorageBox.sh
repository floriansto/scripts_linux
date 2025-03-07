#!/usr/bin/env bash

SCRIPTDIR=$(dirname $0)
USER=$1

$SCRIPTDIR/checkBackups.sh -p $SCRIPTDIR/borg_passphrase_backup_box1_dell-t20.txt -r ssh://$USER-sub1@$USER.your-storagebox.de:23/home/dell-t20
$SCRIPTDIR/checkBackups.sh -p $SCRIPTDIR/borg_passphrase_backup_box1_flo-data.txt -r ssh://$USER-sub1@$USER.your-storagebox.de:23/home/flo-data
