#!/usr/bin/env bash

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

# $1: pg_dumpbackup path
# $2: base backup directory
# $3: port name
# $4: database name
# $5: backup level

# Function: pg_dumpbackup
#
# Perform a pg_dump of the specified database and save it to the base backup directory.
#
# Args:
#   - pg_dumpbackup_path (string): The path of the pg_dump utility.
#   - base_backup_dir (string): The directory where the backup will be stored.
#   - port_name (string, optional): The port name.
#   - database_name (string): The database name.
#   - backup_level (string): The backup level.

pg_dumpbackup() {
    local pg_dumpbackup_path="$1"
    local base_backup_dir="$2"
    local port_name="$3"
    local database_name="$4"
    local backup_level="$5"

    # Check if the pg_dumpbackup path is provided
    if [ -z "$pg_dumpbackup_path" ]; then
        echo "pg_dumpbackup path not provided. Exiting."
        return 1
    elif [ ! -f "$pg_dumpbackup_path" ]; then
        echo "Invalid pg_dumpbackup path. Exiting."
        return 1
    fi

    echo "pg_dumpbackup found in the path at $pg_dumpbackup_path"

    # Check if the base backup directory is provided
    if [ -z "$base_backup_dir" ]; then
        echo "Base backup directory not provided. Exiting."
        return 1
    fi

    # Check if the port name is provided
    if [ ! -z "$port_name" ]; then
        port_option="-p $port_name"
    else
        port_option=""
    fi

    # Check if the backup level is provided
    if [ -z "$backup_level" ]; then
        echo "Backup level not provided. Exiting."
        return 1
    fi

    # Check if the backup level is full
    if [ "$backup_level" != "FULL" ]; then
        echo "Backup level must be FULL. Exiting."
        return 1
    fi

    # Check if the database name is provided
    if [ -z "$database_name" ]; then
        echo "Database name not provided. Exiting."
        return 1
    fi


    if [ ! -z "${ASSET_PASSWORD}" ]; then
        export PGPASSWORD="${ASSET_PASSWORD}"
    fi
     if [ ! -z "${ASSET_USERNAME}" ]; then
        username="-U ${ASSET_USERNAME}"
    fi
    # get the list of databases provided in -d option
    IFS=',' read -r -a DB_NAME_LIST <<< "$database_name"

    for db in "${DB_NAME_LIST[@]}"
    do
        echo "Starting pg_dump for database $db PG_DUMPBACKUP_PATH: $PG_DUMPBACKUP_PATH"
        output=$("${PG_DUMPBACKUP_PATH}" "${port_option}" -F t -f "${base_backup_dir}/${db}-$(date +%Y%m%d-%H%M%S).tar" ${username} "${db}")

        exit_status=$?
        echo "$output"

        if [ $exit_status -ne 0 ]; then
            echo "Unable to perform FULL backup"
            exit 1
        else
			echo "pgrep -f $(date +%Y%m%d-%H%M%S).tar"
            # Check if the backup is still running
            psql_pid="$(pgrep -f "$(date +%Y%m%d-%H%M%S).tar")"
            if [ -n "$psql_pid" ]; then
                echo "Backup is still running (PID: $psql_pid)"
                sleep 1m
            else
                echo "Backup has completed for database ${db}"
                continue
            fi
        fi
    done

    return 0
}


# Check if the backup level is FULL
if [ "$BACKUP_LEVEL" != "FULL" ]; then
    echo "Backup level must be FULL. Exiting."
    if [ "$BACKUP_LEVEL" == "LOG" ]; then
        echo "pgdump does not support log backup. skipping the backup."
        exit 0
    fi
    exit 1
fi




# $BASE_BACKUP_DIR is the directory where the backup will be stored
BASE_BACKUP_DIR=${DD_TARGET_DIRECTORY}

PG_DUMPBACKUP_PATH="/usr/bin/pg_dump"

# Process command line options
while getopts ":p:d:" opt; do
    case $opt in
        p)
            PORT_NAME="$OPTARG"
            ;;
        d)
            DB_NAME="$OPTARG"
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            exit 1
            ;;
    esac
done

# Call the pg_dumpbackup function
pg_dumpbackup "$PG_DUMPBACKUP_PATH" "$BASE_BACKUP_DIR" "$PORT_NAME" "$DB_NAME" "$BACKUP_LEVEL"
exit_status=$?
if [ $exit_status -ne 0 ]; then
        echo "Unable to perform Full pg_dump backup"
        exit 1
fi
exit 0
