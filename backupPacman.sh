#!/bin/bash

backupDir="$HOME/Backup"
backupName="pacman_packages"
timeStamp=$(date +%Y-%m-%d_%H.%M.%S)
maxBackups=50

existingBackups=$(ls -d $backupDir/* | grep $backupName)
numBackups=$(echo $existingBackups | wc -w)
if [[ $numBackups -ge $maxBackups ]]; then
    numToDel=$((numBackups-maxBackups+1))
    toDel=$(echo $existingBackups | cut -f-$numToDel -d " ")
    rm $toDel
fi

pacman -Qeq > ${backupDir}/${backupName}_${timeStamp}
