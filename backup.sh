#!/bin/bash

MONGODB_USER=
MONGODB_PASSWORD=1
MONGODB_HOST=127.0.0.1:3001
S3_BUCKET=

# Get the directory the script is being run from
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
echo $DIR
# Store the current date in YYYY-mm-DD-HHMMSS
DATE=$(date -u "+%F-%H%M%S")
FILE_NAME="backup-$DATE"
ARCHIVE_NAME="$FILE_NAME.tar.gz"

# Lock the database
# Note there is a bug in mongo 2.2.0 where you must touch all the databases before you run mongodump
mongo --username "$MONGODB_USER" --password "$MONGODB_PASSWORD" --host "$MONGODB_HOST" admin --eval "var databaseNames = db.getMongo().getDBNames(); for (var i in databaseNames) { printjson(db.getSiblingDB(databaseNames[i]).getCollectionNames()) }; printjson(db.fsyncLock());"

# Dump the database
mongodump --username "$MONGODB_USER" --password "$MONGODB_PASSWORD" --host "$MONGODB_HOST" --oplog --out $DIR/backup/$FILE_NAME

# Unlock the database
mongo --username "$MONGODB_USER" --password "$MONGODB_PASSWORD" --host "$MONGODB_HOST" admin --eval "printjson(db.fsyncUnlock());"

# Tar Gzip the file
tar -C $DIR/backup/ -zcvf $DIR/backup/$ARCHIVE_NAME $FILE_NAME/

# Remove the backup directory
rm -r $DIR/backup/$FILE_NAME

# Send the file to the backup drive or S3
aws s3 cp $DIR/backup/$ARCHIVE_NAME s3://$S3_BUCKET/$ARCHIVE_NAME
