#!/bin/ash

set -o pipefail

function cleanup()
{
    # Kill the background task if it exists before removing the backup file
    kill %1 2> /dev/null
    if [ -f $BACKUP_FILE ]; then
        rm -f $BACKUP_FILE
    fi
    exit 2
}

trap 'cleanup' SIGINT
trap 'cleanup' SIGTERM

# Read parameters from command line if there are at least one parameters.
# Otherwise, the environment variables are assumed to be already defined.
if [ -n "$1" ]; then
    DB_NAME="$1"
    MYSQL_HOST="$2"
    MYSQL_USER="$3"
    MYSQL_PASSWD_FILE="$4"
    BACKUP_FOLDER="$5"
    ARCHIVE_NAME="$6"
fi

# Verify if arguments exist
ERR=0
if [ -z "$DB_NAME" ]; then
    echo 'Error. No Database name specified.'
    ERR=1
fi
if [ -z "$MYSQL_HOST" ]; then
    echo 'Error. No host specified.'
    ERR=1
fi
if [ -z "$MYSQL_USER" ]; then
    echo 'Error. No user specified.'
    ERR=1
fi
if [ ! -f "$MYSQL_PASSWD_FILE" ]; then
    echo 'Error. No password file specified or the file doesn'\''t exist.'
    ERR=1
fi
if [ -z "$BACKUP_FOLDER" ]; then
    echo 'Error. No backup folder specified.'
    ERR=1
fi
if [ -z "$ARCHIVE_NAME" ]; then
    echo 'Error. No archive name specified.'
    ERR=1
fi

# Verify if backup volume exist.
if [ ! -d /media/backup ]; then
    echo 'Error: /media/backup is not a directory. A volume should be mounted at that location.'
    ERR=1
fi

if [ $ERR = 1 ]; then
     exit 3
fi;

echo '----------------------------------------'
echo 'Begin Database backup.'

# Create directory if it doesn't exist.
mkdir -p /media/backup/$BACKUP_FOLDER
# Backup the databases specified
BACKUP_FILE=/media/backup/$BACKUP_FOLDER/${ARCHIVE_NAME}_$(date +%Y-%m-%d_%H-%M-%S).sql.bz2
mysqldump $DB_NAME "-h$MYSQL_HOST" "-u$MYSQL_USER" "-p$(cat $MYSQL_PASSWD_FILE)" | bzip2 -cz9 > $BACKUP_FILE &
# The process is started in background and we wait for its completion. This allow the script to treat a signal
# immediatly instead of waiting for the end of the command.
wait $!

ERR_CODE="$?"
if [ "$ERR_CODE" != 0 ]; then
    echo "Database backup failed with error code $ERR_CODE"
else
    echo 'Database backup completed.'
fi
echo -e '----------------------------------------\n'