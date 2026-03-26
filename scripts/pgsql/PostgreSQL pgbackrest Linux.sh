#!/bin/bash
# Copyright (c) 2025 Dell Inc. or its subsidiaries. All Rights Reserved.
#
# This software contains the intellectual property of Dell Inc.
# or is licensed to Dell Inc. from third parties. Use of this
# software and the intellectual property contained therein is
# expressly limited to the terms and conditions of the License
# Agreement under which it is provided by or on behalf of Dell
# Inc. or its subsidiaries.
#

# Set the pgBackRest command path, stanza directory path and base backup directory
PG_BACKREST_CMD="/usr/bin/pgbackrest"
BASE_BACKUP_DIR=${DD_TARGET_DIRECTORY}

# Function to check for the existence of a full backup
check_full_backup() {
    echo "Checking for the existence of a full backup."
    if $PG_BACKREST_CMD --stanza=$STANZA_NAME info | grep -q "full backup"; then
        echo "Full backup exists."
        return 0
    else
        echo "Error: Cannot run incremental backup without a full backup. Please run a full backup first."
        return 1
    fi
}

# Function to retry a command twice before exiting
run_command() {
	eval "$2"
	if [[ $? -ne 0 ]]; then
		echo "First attempt failed for $2, retrying..."
		eval "$2"
		if [[ $? -ne 0 ]]; then
			echo "Second attempt failed for $2, exiting with status 1"
			if [[ $3 == FULL ]]; then
				echo "This is a FULL backup, deleting pg_data directory"
				eval "$3"
			fi
			exit 1
		fi
	fi
}

# Check latest_log backup for pg_data directory
check_latest_log_backup() {
	latest_dir=$(ls -lt $1 | grep '^d' | awk '{print $9}' | grep -E '^[0-9]{8}-[0-9]{6}F_[0-9]{8}-[0-9]{6}I$' | head -n 1)
	if [[ -z "$latest_dir" ]]; then
		echo "No previous incremental backup found."
		return 0
	fi
	echo "The last incremental backup label is: $latest_dir"
	if [[ -d "$1/$latest_dir/pg_data" ]]; then
		echo "pg_data directory exists in the last incremental backup."
		mkdir_directory="mkdir -p \"$BASE_BACKUP_DIR/backup/$STANZA_NAME/$latest_dir\""
		tar_pg_data="tar -C \"$1/$latest_dir\" --transform 's,^./pg_data,pg_data,' -cf \"$BASE_BACKUP_DIR/backup/$STANZA_NAME/$latest_dir/pg_data.tar\" pg_data"
		cp_manifest_files="cp \"$1/$latest_dir/backup.manifest\"{,.copy} \"$BASE_BACKUP_DIR/backup/$STANZA_NAME/$latest_dir/\""
		rm_pg_data="rm -rf \"$1/$latest_dir/pg_data\""

		run_command "LOG" "$mkdir_directory" "$rm_pg_data"
		run_command "LOG" "$tar_pg_data" "$rm_pg_data"
		run_command "LOG" "$cp_manifest_files" "$rm_pg_data"
		run_command "LOG" "$rm_pg_data" "$rm_pg_data"
	fi

}


# Check if pg_backrest s installed or not
if command -v $PG_BACKREST_CMD &> /dev/null
then
    echo "pgbackrest is installed."
else
    echo "pgbackrest is not installed."
    exit 1
fi

# Process command line options
while getopts ":s:p:" opt; do
  case $opt in
    # $STANZA_DIR is the path to the stanza(cluster) directory
    s)
      STANZA_NAME="$OPTARG"
      ;;
    # $STANZA_DIR is the path to the stanza(cluster) directory
    p)
      PGBACKREST_DIR="$OPTARG"
      ;;
    # Invalid option
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
  esac
done

echo "entering Backup phase"
if [[ -z $BASE_BACKUP_DIR ]]; then
    echo "Not provided the backup directory for BASE_BACKUP_DIR"
    exit 1
fi
if [[ -z $BACKUP_LEVEL ]]; then
    echo "Not provided the backup level for BACKUP_LEVEL"
    exit 1
fi
if [[ -z "$STANZA_NAME" ]]; then
    echo "Not provided the stanza name for STANZA_NAME"
    exit 1
fi
if [[ -z "$PGBACKREST_DIR" ]]; then
    echo "Not provided the path for PGBACKREST_DIR"
    exit 1
fi


# Perform a full backup
if [[ "$BACKUP_LEVEL" == "FULL" ]]; then
    echo "Starting Full backup with progress..."
    output=$($PG_BACKREST_CMD --stanza=$STANZA_NAME backup --type=full --log-level-console=info --compress-type=none)
    if [[ $? -eq 0 ]]; then
        echo $output
        echo "Full backup completed successfully!"
    else
        echo "Error: Full backup failed."
        echo $output
        exit 1
    fi
    new_backup_label=$(echo "$output" | grep -o "new backup label = [0-9]*-[0-9A-Z]*" | awk '{print $NF}')
    echo "The value of new backup label is: $new_backup_label"
	mkdir_all_directories="mkdir -p \"$BASE_BACKUP_DIR/backup/$STANZA_NAME/$new_backup_label\" \"$BASE_BACKUP_DIR/archive\""
	tar_pg_data="tar -C \"$PGBACKREST_DIR/backup/$STANZA_NAME/$new_backup_label\" --transform 's,^./pg_data,pg_data,' -cf \"$BASE_BACKUP_DIR/backup/$STANZA_NAME/$new_backup_label/pg_data.tar\" pg_data"
	tar_archive="tar -C \"$PGBACKREST_DIR/archive\" --transform 's,^./$STANZA_NAME,$STANZA_NAME,' -cf \"$BASE_BACKUP_DIR/archive/$STANZA_NAME.tar\" $STANZA_NAME"
	cp_manifest_files="cp \"$PGBACKREST_DIR/backup/$STANZA_NAME/$new_backup_label/backup.manifest\"{,.copy} \"$BASE_BACKUP_DIR/backup/$STANZA_NAME/$new_backup_label/\""
    cp_backup_info_files="cp \"$PGBACKREST_DIR/backup/$STANZA_NAME/backup.info\"{,.copy} \"$BASE_BACKUP_DIR/backup/$STANZA_NAME/\""
	rm_pg_data="rm -rf \"$PGBACKREST_DIR/backup/$STANZA_NAME/$new_backup_label/pg_data\""

	#running all the commands to move all data to Data Domain
	run_command "$BACKUP_LEVEL" "$mkdir_all_directories" "$rm_pg_data"
	run_command "$BACKUP_LEVEL" "$tar_pg_data" "$rm_pg_data"
	run_command "$BACKUP_LEVEL" "$tar_archive" "$rm_pg_data"
	run_command "$BACKUP_LEVEL" "$cp_manifest_files" "$rm_pg_data"
	run_command "$BACKUP_LEVEL" "$cp_backup_info_files" "$rm_pg_data"
	run_command "$BACKUP_LEVEL" "$rm_pg_data" "$rm_pg_data"
    exit 0
elif [[ "$BACKUP_LEVEL" == "LOG" ]]; then
    BACKUP_LVL="incr"
	check_latest_log_backup "$PGBACKREST_DIR/backup/$STANZA_NAME"

	#//check if the stanza/timetamp(latest) conatins folder pg_data then move ot first to DD
	#// thencontinue with the below
    if check_full_backup; then
        echo "Starting Incr backup with progress..."
        output=$($PG_BACKREST_CMD --stanza=$STANZA_NAME backup --type=incr --log-level-console=info --compress-type=none)
        if [[ $? -eq 0 ]]; then
            echo $output
            echo "Incr backup completed successfully!"
        else
            echo "Error: Incr backup failed."
            echo $output
            exit 1
        fi
        last_full_backup=$(echo "$output" | grep -o "new backup label = [0-9]*-[0-9A-Z]*" | awk '{print $NF}')
        # For label of incremental backup
        incr_backup_tag=$(echo "$output" | grep -oP '(?<=_)[0-9]{8}-[0-9]{6}[A-Z]' | tail -n 1)
        current_backup_label="${last_full_backup}_${incr_backup_tag}"
        echo "The value of new backup label is: $current_backup_label"
		mkdir_all_directories="mkdir -p \"$BASE_BACKUP_DIR/backup/$STANZA_NAME/$current_backup_label\" \"$BASE_BACKUP_DIR/archive\""
		tar_pg_data="tar -C \"$PGBACKREST_DIR/backup/$STANZA_NAME/$current_backup_label\" --transform 's,^./pg_data,pg_data,' -cf \"$BASE_BACKUP_DIR/backup/$STANZA_NAME/$current_backup_label/pg_data.tar\" pg_data"
		tar_archive="tar -C \"$PGBACKREST_DIR/archive\" --transform 's,^./$STANZA_NAME,$STANZA_NAME,' -cf \"$BASE_BACKUP_DIR/archive/$STANZA_NAME.tar\" $STANZA_NAME"
        cp_manifest_files="cp \"$PGBACKREST_DIR/backup/$STANZA_NAME/$current_backup_label/backup.manifest\"{,.copy} \"$BASE_BACKUP_DIR/backup/$STANZA_NAME/$current_backup_label/\""
		cp_backup_info_files="cp \"$PGBACKREST_DIR/backup/$STANZA_NAME/backup.info\"{,.copy} \"$BASE_BACKUP_DIR/backup/$STANZA_NAME/\""
		rm_pg_data="rm -rf \"$PGBACKREST_DIR/backup/$STANZA_NAME/$current_backup_label/pg_data\""

		#running all the commands to move all data to Data Domain
		run_command "$BACKUP_LEVEL" "$mkdir_all_directories" "$rm_pg_data"
		run_command "$BACKUP_LEVEL" "$tar_pg_data" "$rm_pg_data"
		run_command "$BACKUP_LEVEL" "$tar_archive" "$rm_pg_data"
		run_command "$BACKUP_LEVEL" "$cp_manifest_files" "$rm_pg_data"
		run_command "$BACKUP_LEVEL" "$cp_backup_info_files" "$rm_pg_data"
		run_command "$BACKUP_LEVEL" "$rm_pg_data" "$rm_pg_data"
        exit 0
    else
        exit 1
    fi
else
    echo "Invalid backup level. Please specify 'FULL' or 'LOG'."
    exit 1
fi
