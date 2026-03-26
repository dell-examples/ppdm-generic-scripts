 #!/bin/bash
#
# Copyright (c) 2025 Dell Inc., or its subsidiaries. All Rights Reserved.
#
# Licensed under the MIT License. See LICENSE file in the project root for
# full license information.
#
# Configuration
ASSET_USERNAME_USER=$ASSET_USERNAME
ASSET_PASSWORD=$ASSET_PASSWORD
MYSQL_HOST="localhost" # can be changed.
BACKUP_DIR=$DD_TARGET_DIRECTORY
DATE=$(date +%s)
LASTBACKUPTIME=$LAST_BACKUP_TIME
# Function to perform a full backup
full_backup() {
    echo "Starting full backup..."
    output=$(mysqlbackup --user=$ASSET_USERNAME --password=$ASSET_PASSWORD -host=$MYSQL_HOST \
                         --backup-dir=$DD_TARGET_DIRECTORY  backup-and-apply-log 2>&1)
    if [ $? -eq 0 ]; then
        echo "Full backup completed successfully!"
        echo "$output"
    else
        echo "Error: Full backup failed."
        echo "$output"
        exit 1
    fi
 }
  
# Function to perform an incremental backup using LSN
 incremental_backup() {
    echo "Starting incremental backup..."
    output=$(mysqlbackup --defaults-file=/etc/my.cnf --incremental --startlsn=$LAST_BACKUP_TIME \
                         --incremental-backup-dir=$DD_TARGET_DIRECTORY \
                         --user=$ASSET_USERNAME --password=$ASSET_PASSWORD  backup 2>&1)
    if [ $? -eq 0 ]; then
        echo "Incremental backup completed successfully!"
        echo "$output"
    else
        echo "Error: Incremental backup failed."
        echo "$output"
        exit 1
    fi
 }
  
# Check the backup level and perform the appropriate backup
 if [ "$BACKUP_LEVEL" == "FULL" ]; then
    full_backup
 elif [ "$BACKUP_LEVEL" == "LOG" ]; then
    incremental_backup
 else
    echo "Invalid backup level. Please specify 'full' or 'log'."
    exit 1
 fi