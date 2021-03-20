#!/bin/bash

backupDir="$HOME/.pacman_backup"
backupName="pacman_packages"
timeStamp=$(date +%Y-%m-%d_%H.%M.%S)
maxBackups=50

if [[ ! -d $backupDir ]]; then
    mkdir $backupDir
else
    existingBackups=$(ls -d $backupDir/* | grep $backupName)
    numBackups=$(echo $existingBackups | wc -w)
    if [[ $numBackups -ge $maxBackups ]]; then
        numToDel=$((numBackups-maxBackups+1))
        toDel=$(echo $existingBackups | cut -f-$numToDel -d " ")
        rm $toDel
    fi
fi

pacman -Qeq > ${backupDir}/${backupName}_${timeStamp}
