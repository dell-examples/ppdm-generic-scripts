#!/bin/bash
#
# Copyright (c) 2025 Dell Inc., or its subsidiaries. All Rights Reserved.
#
# Licensed under the MIT License. See LICENSE file in the project root for
# full license information.
#
# DD_TARGET_DIRECTORY, ASSET_USERNAME, ASSET_PASSWORD is an exported value by the agent
# BACKUP_LEVEL is an exported value having "FULL | LOG" values by the agent
# Configuration
SYBASE_HOME="/opt/sap"                             # change to your Sybase install directory
SYBASE_SERVER="SYBASE_SERVER"                      # change to your Sybase ASE server name (-S)
ISQL="${SYBASE_HOME}/OCS-16_0/bin/isql"            # change to your isql binary path (check OCS version)
INTERFACES="${SYBASE_HOME}/interfaces"             # path to interfaces file
BACKUP_DIR=$DD_TARGET_DIRECTORY
DATE=$(date +%Y%m%d_%H%M%S)

export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# parsing the arguments
while getopts ":d:" opt; do
  case $opt in
    d)
      DB_NAME="$OPTARG"
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
  esac
done

# Source Sybase environment
if [ -f "${SYBASE_HOME}/SYBASE.sh" ]; then
  . "${SYBASE_HOME}/SYBASE.sh"
fi

DUMP_FILE="${BACKUP_DIR}/${DB_NAME}_${BACKUP_LEVEL}_${DATE}.dmp"

# Function to perform a full backup
full_backup() {
    echo "Starting full backup of ${DB_NAME}..."
    output=$(echo "dump database ${DB_NAME} to '${DUMP_FILE}'
go" | "${ISQL}" -S "${SYBASE_SERVER}" -U "${ASSET_USERNAME}" -P "${ASSET_PASSWORD}" -I "${INTERFACES}" -w 999 2>&1)
    if [ $? -eq 0 ]; then
        echo "Full backup completed successfully!"
        echo "$output"
    else
        echo "Error: Full backup failed."
        echo "$output"
        exit 1
    fi
}

# Function to perform a transaction log backup
log_backup() {
    echo "Starting transaction log backup of ${DB_NAME}..."
    output=$(echo "dump transaction ${DB_NAME} to '${DUMP_FILE}'
go" | "${ISQL}" -S "${SYBASE_SERVER}" -U "${ASSET_USERNAME}" -P "${ASSET_PASSWORD}" -I "${INTERFACES}" -w 999 2>&1)
    if [ $? -eq 0 ]; then
        echo "Transaction log backup completed successfully!"
        echo "$output"
    else
        echo "Error: Transaction log backup failed."
        echo "$output"
        exit 1
    fi
}

# Check the backup level and perform the appropriate backup
if [ "$BACKUP_LEVEL" == "FULL" ]; then
    full_backup
elif [ "$BACKUP_LEVEL" == "LOG" ]; then
    log_backup
else
    echo "Invalid backup level. Please specify 'FULL' or 'LOG'."
    exit 1
fi
