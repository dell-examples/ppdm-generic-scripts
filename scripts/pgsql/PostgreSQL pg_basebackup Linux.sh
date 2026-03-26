#!/bin/bash

#
# Copyright (c) 2024 Dell Inc. or its subsidiaries. All Rights Reserved.
#
# This software contains the intellectual property of Dell Inc.
# or is licensed to Dell Inc. from third parties. Use of this
# software and the intellectual property contained therein is
# expressly limited to the terms and conditions of the License
# Agreement under which it is provided by or on behalf of Dell
# Inc. or its subsidiaries.
#

# $PG_BASEBACKUP_PATH is the path of the pg_basebackup utility
PG_BASEBACKUP_PATH="/usr/bin/pg_basebackup"
if [ -z "$PG_BASEBACKUP_PATH" ]; then
    echo "pg_basebackup path not provided. Exiting."
    exit 1
elif [ ! -f "$PG_BASEBACKUP_PATH" ]; then
    echo "Invalid pg_basebackup path. Exiting."
    exit 1
fi

echo "pg_basebackup found in the path at $PG_BASEBACKUP_PATH"

# DD_TARGET_DIRECTORY is an exported value of the Destination path by the agent
BASE_BACKUP_DIR=${DD_TARGET_DIRECTORY}

# Process command line options
while getopts ":p:w:" opt; do
  case $opt in
    # $PORT_NAME is the name of the database port to connect
    p)
      PORT_NAME="$OPTARG"
      ;;
    # $WAL_PATH is the path to the write ahead log (WAL) directory
    w)
      WAL_PATH="$OPTARG"
      ;;
    # Invalid option
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
  esac
done

echo "entering Backup phase"
if [ -z $BASE_BACKUP_DIR ]; then
    echo "Not provided the backup directory for BASE_BACKUP_DIR"
    exit 1
fi
if [ -z $BACKUP_LEVEL ]; then
    echo "Not provided the backup level for BACKUP_LEVEL"
    exit 1
fi
if [ ! -z "$PORT_NAME" ]; then
    PORT_OPTION="-p ${PORT_NAME}"
else
    PORT_OPTION=""
fi
if [ -z "$WAL_PATH" ]; then
    WAL_PATH="/var/lib/pgsql/data/pg_wal"
fi


# Perform a full backup
if [[ "$BACKUP_LEVEL" == "FULL" ]]; then
    output=$($PG_BASEBACKUP_PATH -D "${BASE_BACKUP_DIR}" ${PORT_OPTION} -Xs -Ft -P --checkpoint=fast)
    exit_status=$?
    echo "$output"
    if [ $exit_status -ne 0 ]; then
       echo "Unable to perform FULL backup"
       exit 1
    fi
    echo "Backup Completed Successfully"
    exit 0

# Perform a log backup
elif [[ "$BACKUP_LEVEL" == "LOG" ]]; then
    # write the Wal files list into a temp file to delete after the backup is successful
    # if the files are not decided to be delete another approach is to  copy only the fils created afer the last backup time
    find  "${WAL_PATH}" -type f > "${LOG_FILE_LIST_FILE}"
    tar_file="wal_backup_`date +%Y%m%d-%H%M%S`.tar"
    tar -cf "${BASE_BACKUP_DIR}/${tar_file}" -C "${WAL_PATH}" .
    exit_status=$?

    if [ $exit_status -ne 0 ]; then
        echo "Unable to perform LOG backup"
        exit 1
    fi
    echo "LOG Backup Completed Successfully"
    exit 0
else
    echo "Invalid backup level. Please specify 'FULL' or 'LOG'."
    exit 1
fi
