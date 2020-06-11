#!/usr/bin/env bash

USER=$(whoami)
SOURCE="${HOME}/Bilder/Wallpaper/"
DEST="/mnt/data/$USER/Bilder/Wallpaper"

SSH_PORT=5176
HOST="nas"

ISONLINE=$(ncat -z $HOST $SSH_PORT)
if [[ $? -eq 0 ]]; then
    rsync -av -zz -e "ssh -p $SSH_PORT" $SOURCE $USER@$HOST:$DEST
fi
