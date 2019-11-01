#!/usr/bin/env bash

BACKUP_HOST="backup"
BACKUP_USER="root"
SSH_PORT="5176"

# Start rsnapshot from backup server
ssh -p $SSH_PORT $BACKUP_USER@$BACKUP_HOST '/root/rsnapshot/run_rsnapshot_no_cron.sh flo-desktop'

RET_VAL=$?
# Check exit status
if [[ $RET_VAL -eq 0 ]]; then
    MESSAGE="Backup finished successfully"
else
    MESSAGE="Error: Backup finished with code $RET_VAL please investigate"
fi
