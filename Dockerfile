FROM alpine:latest
ENV ARCHIVE_NAME=
ENV BACKUP_FOLDER=
ENV DB_NAME=
ENV MYSQL_HOST=
ENV MYSQL_USER=
ENV MYSQL_PASSWD_FILE=
ENV DATE_DIR_FILE=

RUN apk add mariadb-client

COPY mariaDBbackup.sh /
RUN chmod 700 mariaDBbackup.sh

WORKDIR /

# The double quotes around $@ ensure that a parameter containing a space is transfered as a single parameter to mariaDBbackup.sh
ENTRYPOINT ["/bin/ash", "-c", "$0 \"$@\"", "./mariaDBbackup.sh"]
