#!/usr/bin/env bash

BACKUP_HOST="backup"
BACKUP_USER="root"
SSH_PORT=$2
DEVICE=$1
DBT="/root/data-backup-tool"

# Start ssh server
systemctl start sshd.service

# Start rsnapshot from backup server
ssh -p $SSH_PORT $BACKUP_USER@$BACKUP_HOST "python3 $DBT/src/main.py $DBT/config/$1.yaml -s -u $BACKUP_USER -h $1 -p $SSH_PORT"

RET_VAL=$?
# Check exit status
if [[ $RET_VAL -eq 0 ]]; then
    MESSAGE="Backup finished successfully"
else
    MESSAGE="Error: Backup finished with code $RET_VAL please investigate"
fi

# Stop ssh server
systemctl stop sshd.service

