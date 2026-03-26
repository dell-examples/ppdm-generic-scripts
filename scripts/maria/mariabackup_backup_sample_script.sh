 #!/bin/bash
#
# Copyright (c) 2025 Dell Inc., or its subsidiaries. All Rights Reserved.
#
# Licensed under the MIT License. See LICENSE file in the project root for
# full license information.
#
# Exportable Variables
DATA_DIR="/var/lib/mysql" # change if necessary
BACKUP_DIR=$DD_TARGET_DIRECTORY
TODAY=$(date +%s)
BACKUP_LEVEL=$BACKUP_LEVEL
LASTBACKUPTIME=$LAST_BACKUP_TIME
  
# Function to perform full backup
full_backup() {
  echo "Starting Full backup with progress..."
  output=$(mariabackup --backup \
    --target-dir="${DD_TARGET_DIRECTORY}" \
    --datadir="${DATA_DIR}" \
    --user="${ASSET_USERNAME}" \
    --password="${ASSET_PASSWORD}")
  if [ $? -eq 0 ]; then
    echo "Full backup completed successfully at $(date)!"
    echo "$output"
  else
    echo "Error: Full backup failed."
    echo "$output"
    exit 1
  fi
 }
  
# Function to perform incremental backup
 incremental_backup() {
  echo "Starting Incremental backup with progress..."
  output=$(mariabackup --backup --incremental-lsn="${LAST_BACKUP_TIME}" \
    --target-dir="${DD_TARGET_DIRECTORY}" \
    --datadir="${DATA_DIR}" \
    --user="${ASSET_USERNAME}" \
    --password="${ASSET_PASSWORD}")
  if [ $? -eq 0 ]; then
    echo "Incremental backup completed successfully at $(date)!"
    echo "$output"
  else
    echo "Error: Incremental backup failed."
    echo "$output"
    exit 1
  fi
 }
  
# Check backup level and perform the appropriate backup
if [ "$BACKUP_LEVEL" == "FULL" ]; then
  full_backup
elif [ "$BACKUP_LEVEL" == "LOG" ]; then
  incremental_backup
else
  echo "Invalid backup level. Use 'FULL' or 'LOG'."
fi
PaaS_RDS_AWS_S3_DDV