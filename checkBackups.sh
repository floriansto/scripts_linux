#!/usr/bin/env bash

function usage() {
  echo "Usage $0 OPTIONS"
  echo ""
  echo "Wrapper script to backup your system using borgbackup"
  echo "A file called env has to be in the same directory"
  echo ""
  echo "Required arguments"
  echo " -n,--name   Name of the backup (usually the hostname)"
  echo " -r,--repo   Path to the borg repository"
  echo ""
  echo "Optional arguments"
  echo " -e,--exclude     Path to the excludefile (optional):"
  echo " -p,--passphrase  Passphrase file containing the passphrase of your repo (optional):"
  echo ""
  echo "The name has to be the first argument and is required"
  echo "The paths are a space separated list of directories that you"
  echo "want to backup"
}

SCRIPTDIR=$(dirname $0)
ENV="$SCRIPTDIR/./env"

if [[ ! -e $ENV ]]; then
  echo "Env file at $ENV cannot be found!"
  echo "Use the following template to create it:"
  echo ""
  echo "# Shell file to export sensitive configuration data"
  echo "# for gotify notifications"
  echo "export GOTIFY_URL=''"
  echo "export GOTIFY_TOKEN=''"
  echo "export EXCLUDE_FILE=''"
  echo ""
  usage
  exit 1
fi

source $ENV
GOTIFY_CALL="$GOTIFY_URL/message?token=$GOTIFY_TOKEN"

if [ -z ${GOTIFY_URL+x} ]; then echo "\$GOTIFY_URL is unset";fi
if [ -z ${GOTIFY_TOKEN+x} ]; then echo "\$GOTIFY_TOKEN is unset";fi
if [ -z ${GOTIFY_URL+x} ] || [ -z ${GOTIFY_TOKEN+x} ]; then exit 1;fi

EXCLUDE_STR=""
if [ ! -z ${EXCLUDE_FILE+x} ]; then
  if [ -f ${EXCLUDE_FILE} ]; then
    EXCLUDE_STR="--exclude-from $EXCLUDE_FILE"
  fi
fi

repo_provided=false
password_file=""
while [[ ! -z "$1" ]]; do
  if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    usage
    exit 0
  elif [[ "$1" == "-r" || "$1" == "--repo" ]]; then
    REPO="$2"
    repo_provided=true
    shift
    shift
  elif [[ "$1" == "-p" || "$1" == "--passphrase" ]]; then
    password_file=$2
    shift
    shift
  else
    if [[ $repo_provided == true ]]; then
      break
    fi
    usage
    exit 1
  fi
done

if [[ $repo_provided == false ]]; then
  echo "please provide the path to the borg repo"
  usage
  exit 1
fi

# Setting this, so the repo does not need to be given on the commandline:
export BORG_REPO=$REPO

# See the section "Passphrase notes" for more infos.
if [[ $password_file != "" ]]; then
    export BORG_PASSCOMMAND="/usr/bin/cat ${password_file}"
else
    export BORG_PASSPHRASE=""
fi


# some helpers and error handling:
info() { printf "\n%s %s\n\n" "$( date )" "$*" >&2; }
trap 'echo $( date ) Backup interrupted >&2; exit 2' INT TERM

info "Checking backup at location $REPO"

borg check
check_exit=$?

if [ ${check_exit} -eq 0 ]; then
    STATE="successfully"
else
    STATE="with exit code $check_exit"
fi

# Use jq to get the size of the repo
SIZE=""
if [ $(command -v jq) ]; then
    DEDUP_SIZE=$(printf "%.2f GB" "$(($(borg info --json | jq .cache.stats.unique_csize)))e-9")
    SIZE="Size on disk: $DEDUP_SIZE"
fi

MESSAGE="Backup check finished $STATE"
info "$MESSAGE"

num_backups=$(borg list | wc -l)
NUM_BACKUPS="Number of backups: $num_backups"

last_backup=$(borg list --last 1 | column -t -H 1,5)
LAST_BACKUP="Last backup: $last_backup"

# Notify gotify when the backup was not successful
GOTIFY_MESSAGE=$(echo "Repo: $REPO\n$NUM_BACKUPS\n$LAST_BACKUP\n$SIZE" | sed 's/\\n/%0A/g' | sed 's/ /%20/g')
GOTIFY_TITLE=$(echo "borg check finished $STATE" | sed 's/\\n/%0A/g' | sed 's/ /%20/g')
curl --silent --show-error -X POST "$GOTIFY_CALL&message=$GOTIFY_MESSAGE&title=$GOTIFY_TITLE" > /dev/null

exit ${check_exit}

