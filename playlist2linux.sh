#!/bin/bash

linuxDir="/mnt/samba/audio/Playlists/linux"

if [[ ! -d "$linuxDir" ]]; then
    mkdir -p $linuxDir
fi
cp $linuxDir/../*.m3u $linuxDir


sed -i 's=\\\\NAS\\audio=/mnt/samba/audio=g' $linuxDir/*.m3u
sed -i 's=\\=/=g' $linuxDir/*.m3u
