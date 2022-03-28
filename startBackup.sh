#!/usr/bin/sh

ENV="./env"

if [[ ! -e $ENV ]]; then
  echo "Env file at $ENV cannot be found!"
  echo "Use the following template to create it:"
  echo ""
  echo "# Shell file to export sensitive configuration data"
  echo "# for gotify notifications"
  echo "export GOTIFY_URL=''"
  echo "export GOTIFY_TOKEN=''"
  echo "export EXCLUDE_FILE=''"
  exit 1
fi

source ./env
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

HOSTNAME=$(hostname)

# Setting this, so the repo does not need to be given on the commandline:
export BORG_REPO=ssh://root@backup:5176/mnt/backup/$HOSTNAME

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

  backup_exit=$?
  if [ ${backup_exit} -ne 0 ]; then
    info "Backup attempt $attempts failed... retry"
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

borg prune                          \
    --list                          \
    --prefix '{hostname}-'          \
    --show-rc                       \
    --keep-last     4               \
    --keep-hourly   8               \
    --keep-daily    7               \
    --keep-weekly   4               \
    --keep-monthly  12              \

prune_exit=$?

# actually free repo disk space by compacting segments

info "Compacting repository"

borg compact

compact_exit=$?

# use highest exit code as global exit code
global_exit=$(( backup_exit > prune_exit ? backup_exit : prune_exit ))
global_exit=$(( compact_exit > global_exit ? compact_exit : global_exit ))

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

MESSAGE="Backup, Prune, and Compact finished $STATE"
info "$MESSAGE"

# Notify gotify when the backup was not successful
if [ ${global_exit} -ne 0 ]; then
    EXIT_CODES="Backup: $backup_exit, Prune: $prune_exit, Compact: $compact_exit"
    GOTIFY_MESSAGE=$(echo "Exit codes:\n$EXIT_CODES\n$SIZE" | sed 's/\\n/%0A/g' | sed 's/ /%20/g')
    GOTIFY_TITLE=$(echo "$HOSTNAME finished $STATE" | sed 's/\\n/%0A/g' | sed 's/ /%20/g')
    curl --silent --show-error -X POST "$GOTIFY_CALL&message=$GOTIFY_MESSAGE&title=$GOTIFY_TITLE" > /dev/null
fi

exit ${global_exit}

