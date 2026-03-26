 #!/bin/bash
#
# Copyright (c) 2025 Dell Inc., or its subsidiaries. All Rights Reserved.
#
# Licensed under the MIT License. See LICENSE file in the project root for
# full license information.
#
# Function to perform a full backup

DD_TARGET_DIRECTORY=$DD_TARGET_DIRECTORY
BACKUP_LEVEL=$BACKUP_LEVEL
PORT_NAME=27017 # Default port, can be changed

while getopts ":p:" opt; do
  case $opt in
    p)
      PORT_NAME="$OPTARG"
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
  esac
 done
  
if [ ! -z "$PORT_NAME" ]; then
  PORT_NAME="--port $PORT_NAME"
 fi
  
full_backup() {
  output=$(mongodump -h localhost $PORT_NAME -o /"$DD_TARGET_DIRECTORY" 2>&1)
  if [ $? -eq 0 ]; then
    echo "Full backup completed successfully at $(date)!"
    echo "$output"
  else
    echo "Error: Full backup failed."
    echo "$output"
    exit 1
  fi
 }
  
# Check backup level and perform the appropriate backup
 if [ "$BACKUP_LEVEL" == "FULL" ]; then
  full_backup
 else
  echo "Invalid backup level. Use 'FULL'."
  exit 1
 fi