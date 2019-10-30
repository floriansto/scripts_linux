#!/usr/bin/env bash

# Input parameter:
# Gitea data folder where the remote repositories are stored

# Root dir of gitea repositories
DIR=$1

for i in $(ls); do
    if [[ -d $i ]]; then
        d=$i/hooks
        cp pre-receive.hook $d/pre-receive.d/gitea
        cp post-receive.hook $d/post-receive.d/gitea
        cp update.hook $d/update.d/gitea
    fi
done

