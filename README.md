# Docker image to backup mariaDB database
This image create bz2 archive from a mariaDB database dump. The archive is created in location /media/backup/$BACKUP_FOLDER with the name ${ARCHIVE\_NAME}\_$(date +%Y-%m-%d\_%H-%M-%S).sql.bz2 (e.g. myArchive\_2020-08-15\_17-32-45.sql.bz2). The location /media/backup must exists in order to make the backup. It means you must mount a volume at that location.


The information to specify to make the backup can be either with environment variables or with command line arguments. The parameters are the following:
| Position | Variable      | Description                                        |
|:---:| --------------     | -------------------------------------------------- |
| 1   | $DB_NAME           | The name of the database to backup. Only one database name can be specified. |
| 2   | $MYSQL_HOST        | The host address to communicate with.              |
| 3   | $MYSQL_USER        | The username used to connect to the database.      |
| 4   | $MYSQL_PASSWD_FILE | The path to the file containing the password to use to connect to the database. |
| 5   | $BACKUP_FOLDER     | The archive file will be put inside that folder. The folder will be created if it is missing. |
| 6   | $ARCHIVE_NAME      | The prefix that compose the archive file name      |

## Examples of execution
You can run the backup by specifying the parameters with environment variables.
> docker run --env DB_NAME=mysql --env MYSQL_HOST=mariadb --env MYSQL_USER=root --env MYSQL_PASSWD_FILE=/root/passwd.txt --env BACKUP_FOLDER=my_mariadb_backups --env ARCHIVE_NAME=my_database --network mariadb --mount type=volume,src=test_backup,dst=/media/backup --mount type=volume,src=mariadb_passwd,dst=/root local/backup_mariadb

You can also run the backup by specifying the parameters with command line parameters in the order DB_NAME, MYSQL_HOST, MYSQL_USER, MYSQL_PASSWD_FILE, BACKUP_FOLDER and ARCHIVE_NAME.
> docker run --network mariadb --mount type=volume,src=test_backup,dst=/media/backup --mount type=volume,src=mariadb_passwd,dst=/root local/backup_mariadb mysql mariadb root /root/passwd.txt my_mariadb_backups my_database
