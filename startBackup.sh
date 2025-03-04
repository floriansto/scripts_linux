#!/usr/bin/env bash

function usage() {
  echo "Usage $0 OPTIONS PATHS"
  echo ""
  echo "Wrapper script to backup your system using borgbackup"
  echo "A file called env has to be in the same directory"
  echo ""
  echo "Required arguments"
  echo " -n,--name   Name of the backup (usually the hostname)"
  echo " -r,--repo   Path to the borg repository"
  echo ""
  echo "Optional arguments"
  echo " -e,--exclude  Path to the excludefile (optional):"
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

name_provided=false
repo_provided=false
while [[ ! -z "$1" ]]; do
  echo "Begin loop with $1"
  if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    usage
    exit 0
  elif [[ "$1" == "-n" || "$1" == "--name" ]]; then
    echo $1
    HOSTNAME="$2"
    name_provided=true
    shift
    shift
  elif [[ "$1" == "-e" || "$1" == "--exclude" ]]; then
    EXCLUDE_STR="--exclude-from $2"
    echo $2
    shift
    shift
  elif [[ "$1" == "-r" || "$1" == "--repo" ]]; then
    REPO="$2"
    repo_provided=true
    shift
    shift
  else
    if [[ $name_provided == true || $repo_provided == true ]]; then
      break
    fi
    usage
    exit 1
  fi
done

if [[ $name_provided == false ]]; then
  echo "Please provide a backup name (ideally hostname)"
  usage
  exit 1
fi

if [[ $repo_provided == false ]]; then
  echo "please provide the path to the borg repo"
  usage
  exit 1
fi

# Setting this, so the repo does not need to be given on the commandline:
export BORG_REPO=$REPO

# See the section "Passphrase notes" for more infos.
export BORG_PASSPHRASE=''

# some helpers and error handling:
info() { printf "\n%s %s\n\n" "$( date )" "$*" >&2; }
trap 'echo $( date ) Backup interrupted >&2; exit 2' INT TERM

backup_name="$HOSTNAME-$(date +%FT%T)"
info "Starting backup $backup_name"

# Backup the most important directories into an archive named after
# the machine this script is currently running on:
attempts=1
while true; do
  borg_create=$(                        \
    borg create                         \
        --verbose                       \
        --filter AME                    \
        --list                          \
        --stats                         \
        --show-rc                       \
        --compression lz4               \
        --exclude-caches                \
        $EXCLUDE_STR                    \
                                        \
        ::"$backup_name"                \
        $*                              \
  2>&1)

  backup_exit=$?
  if [ ${backup_exit} -ne 0 ]; then
    info "Backup attempt $attempts failed with code $backup_exit ... retry"
  fi
  attempts=$(( attempts+1 ))
  [[ backup_exit -ne 0 && attempts -lt 11 ]] || break
  sleep 5
done

info "Pruning repository"

# Use the `prune` subcommand to maintain 7 daily, 4 weekly and 6 monthly
# archives of THIS machine. The '{hostname}-' prefix is very important to
# limit prune's operation to this machine's archives and not apply to
# other machines' archives also:

borg_prune=$(                         \
  borg prune                          \
      --list                          \
      --glob-archives '{hostname}-*'  \
      --show-rc                       \
      --keep-last     4               \
      --keep-hourly   8               \
      --keep-daily    7               \
      --keep-weekly   4               \
      --keep-monthly  12              \
2>&1)

prune_exit=$?

# actually free repo disk space by compacting segments

info "Compacting repository"

compact_exit=0
BORG_MINOR_VERSION=$(borg --version | cut -d '.' -f 2)
if [ $BORG_MINOR_VERSION -gt 1 ]; then
  borg_compact=$(borg compact 2>&1)
  compact_exit=$?
fi

info "Check last backup archive"
borg_check=$(borg check --archives-only --last 1 2>&1)
check_exit=$?

# use highest exit code as global exit code
global_exit=$(( backup_exit > prune_exit ? backup_exit : prune_exit ))
global_exit=$(( compact_exit > global_exit ? compact_exit : global_exit ))
global_exit=$(( check_exit > global_exit ? check_exit : global_exit ))

if [ ${global_exit} -eq 0 ]; then
    STATE="successfully"
elif [ ${global_exit} -eq 1 ]; then
    STATE="with warnings"
else
    STATE="with errors"
fi

# Use jq to get the size of the repo
SIZE=""
if [ $(command -v jq) ]; then
    DEDUP_SIZE=$(printf "%.2f GB" "$(($(borg info --json | jq .cache.stats.unique_csize)))e-9")
    SIZE="Size on disk: $DEDUP_SIZE"
fi

MESSAGE="Create, Prune, Compact and Check finished $STATE"
info "$MESSAGE"

if [ $backup_exit -ne 0 ]; then
  borg_create=$(echo "\n\nBorg create error:\n$borg_create" | tr "\n" ",")
fi
if [ $prune_exit -ne 0 ]; then
  borg_prune=$(echo "$error_message\n\nBorg prune error:\n$borg_prune" | tr "\n" ",")
fi
if [ $compact_exit -ne 0 ]; then
  borg_compact=$(echo "$error_message\n\nBorg compact error:\n$borg_compact" | tr "\n" ",")
fi
if [ $check_exit -ne 0 ]; then
  borg_check=$(echo "$error_message\n\nBorg check error:\n$borg_check" | tr "\n" ",")
fi
error_message=$borg_create$borg_prune$borg_compact$borg_check

# Notify gotify when the backup was not successful
if [ ${global_exit} -ne 0 ]; then
    EXIT_CODES="Create: $backup_exit, Prune: $prune_exit, Compact: $compact_exit, Check: $check_exit"
    GOTIFY_MESSAGE="Repo: $REPO\nExit codes: $EXIT_CODES\n$SIZE$error_message"
    GOTIFY_TITLE="borg create on $HOSTNAME finished $STATE"
    curl --silent --show-error "$GOTIFY_CALL" \
      -H  "accept: application/json" \
      -H  "Content-Type: application/json" \
      -d "{  \"message\": \"$GOTIFY_MESSAGE\", \"title\": \"$GOTIFY_TITLE\"}" > /dev/null
fi

exit ${global_exit}

