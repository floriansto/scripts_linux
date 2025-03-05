#!/bin/bash

DEVBASE=$1
DEVICE="/dev/${DEVBASE}"

# See if this drive is already mounted
MOUNT_POINT=$(/bin/mount | /bin/grep ${DEVICE} | /usr/bin/awk '{ print $3 }')
SCRIPT_DIR="$( cd "$(dirname "$0")" ; pwd -P )"

if [[ -n ${MOUNT_POINT} ]]; then
    # Already mounted, exit
    exit 1
fi

# Get info for this drive: $ID_FS_LABEL, $ID_FS_UUID, and $ID_FS_TYPE
eval $(/sbin/blkid -o udev ${DEVICE})

# Allow automount only for specific drive labels
LABEL=${ID_FS_LABEL}
if [[ ${LABEL} != borg_backup[0-9+] ]]; then
    exit 1
fi

MOUNT_POINT="/mnt/borg_backup"

/bin/mkdir -p ${MOUNT_POINT}

# Global mount options
OPTS="rw,relatime"

# File system type specific mount options
if [[ ${ID_FS_TYPE} == "vfat" ]]; then
    OPTS+=",users,gid=100,umask=000,shortname=mixed,utf8=1,flush"
fi

if ! /bin/mount -o ${OPTS} ${DEVICE} ${MOUNT_POINT}; then
    # Error during mount process: cleanup mountpoint
    /bin/rmdir ${MOUNT_POINT}
    exit 1
fi

${SCRIPT_DIR}/startBackup.sh -a -p ${SCRIPT_DIR}/borg_passphrase_ext_dell-t20.txt -n $(hostname) -r ${MOUNT_POINT}/borg_repos/dell-t20 /etc /root /var/spool
${SCRIPT_DIR}/startBackup.sh -a -p ${SCRIPT_DIR}/borg_passphrase_ext_flo-data.txt -n flo-data -r ${MOUNT_POINT}/borg_repos/flo-data /tank/subvol-100-nas-flo
success=$?

if [[ $success -ne 0 ]]; then
  echo "Backup failed"
else
  echo "Backup succeeded"
fi

if [[ -n ${MOUNT_POINT} ]]; then
    /bin/umount -l ${DEVICE}
fi

exit $success

