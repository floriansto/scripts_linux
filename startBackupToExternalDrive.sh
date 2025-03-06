#!/bin/bash

function notify() {
  curl --silent --show-error "$1" \
    -H  "accept: application/json" \
    -H  "Content-Type: application/json" \
    -d "{  \"message\": \"$3\", \"title\": \"$2\"}" > /dev/null
}

DEVBASE=$1
DEVICE="/dev/${DEVBASE}"

# See if this drive is already mounted
MOUNT_POINT=$(/bin/mount | /bin/grep ${DEVICE} | /usr/bin/awk '{ print $3 }')
SCRIPT_DIR="$( cd "$(dirname "$0")" ; pwd -P )"
ENV="$SCRIPT_DIR/./env"

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

source $ENV
GOTIFY_CALL="$GOTIFY_URL/message?token=$GOTIFY_TOKEN"

mount_msg=$(/bin/mount -o ${OPTS} ${DEVICE} ${MOUNT_POINT} 2>&1)
mount_state=$?

if [[ $mount_state -ne 0 ]] ; then
    # Error during mount process: cleanup mountpoint
    mount_msg=$(echo $mount_msg | tr "\n" ",")
    /bin/rmdir ${MOUNT_POINT}
    echo "Mount ${DEVICE} failed"
    notify $GOTIFY_CALL "$(hostname): Mount ${DEVICE} failed" "Exit code: $mount_state\nMessage: $mount_msg"
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
    unmount_msg=$(/bin/umount -l ${DEVICE} 2>&1)
    unmount_state=$?
    if [[ $unmount_state -eq 0 ]]; then
      notify $GOTIFY_CALL "$(hostname): Unmount ${DEVICE} succeeded!" "You can remove it now"
      echo "Unmount ${DEVICE} succeeded"
    else
      unmount_msg=$(echo $unmount_msg | tr "\n" ",")
      notify $GOTIFY_CALL "$(hostname): Unmount ${DEVICE} failed!" "Exit code: $unmount_state\nMessage: $unmount_msg"
      echo "Unmount ${DEVICE} failed"
    fi
    success=$unmount_state
fi

exit $success

