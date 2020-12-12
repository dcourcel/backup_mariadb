#!/bin/ash

set -o pipefail

function cleanup()
{
    # Kill the background task if it exists before removing the backup file
    kill %1 2> /dev/null
    if [ -f "$BACKUP_FILE" ]; then
        rm -f "$BACKUP_FILE"
    fi
    exit 3
}

trap 'cleanup' SIGINT
trap 'cleanup' SIGTERM

# Read parameters from command line if there is at least one parameter.
# Otherwise, the environment variables are assumed to be already defined.
if [ -n "$1" ]; then

    # Empty initialise environment variable in case it was defined outside.
    ADD_DROP_DATABASE=""
    while [ $# gt 0 -a "${1::2}" = "--" ]; do
        case $1 in
            --add-drop-database)
            ADD_DROP_DATABASE=--add-drop-database
            ;;

            *)
            echo "Unrecognized option $1"
            exit 2
            ;;
        esac
        shift
    done

    DB_NAME="$1"
    MYSQL_HOST="$2"
    MYSQL_USER="$3"
    MYSQL_PASSWD_FILE="$4"
    BACKUP_FOLDER="$5"
    ARCHIVE_NAME="$6"
    DATE_DIR_FILE="$7"
else
    if [ -n "$ADD_DROP_DATABASE" ]; then
        ADD_DROP_DATABASE=--add-drop-database
    fi
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

if [ -n "$DATE_DIR_FILE" ]; then
    if [ ! -f "$DATE_DIR_FILE" ]; then
        echo "\$DATE_DIR_FILE ($DATE_DIR_FILE) is not a file."
        ERR=1
    fi
    date_dir=$(head -n 1 $DATE_DIR_FILE)
    if [ -z "$date_dir" ]; then
        echo "The file $DATE_DIR_FILE is empty."
        ERR=1
    fi
else
    date_dir=$(date +%Y-%m-%d_%H-%M-%S)
fi;
if ! mkdir -p /media/backup/$BACKUP_FOLDER/$date_dir; then
    echo "Cannot create directory /media/backup/$BACKUP_FOLDER/$date_dir"
    ERR=1
fi

if [ $ERR = 1 ]; then
     exit 1
fi;

echo '----------------------------------------'
echo 'Begin Database backup.'

# Backup the databases specified
BACKUP_FILE=/media/backup/$BACKUP_FOLDER/$date_dir/$ARCHIVE_NAME.sql.bz2
mysqldump --databases $DB_NAME $ADD_DROP_DATABASE "-h$MYSQL_HOST" "-u$MYSQL_USER" "-p$(cat $MYSQL_PASSWD_FILE)" | bzip2 -cz9 > $BACKUP_FILE &
# The process is started in background and we wait for its completion. This allow the script to treat a signal
# immediatly instead of waiting for the end of the command.
wait $!

ERR_CODE="$?"
if [ $ERR_CODE -eq 0 ]; then
    echo 'Database backup completed.'
else
    echo "Database backup failed with error code $ERR_CODE"
fi
echo -e '----------------------------------------\n'
exit $ERR_CODE
