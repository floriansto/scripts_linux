#!/usr/bin/env bash

USER=$(whoami)
SOURCE="${HOME}/Bilder/Wallpaper/"
DEST="/mnt/data/$USER/Bilder/Wallpaper"

SSH_PORT=5176
HOST="nas"

rsync -avz -e "ssh -p $SSH_PORT" $SOURCE $USER@$HOST:$DEST
