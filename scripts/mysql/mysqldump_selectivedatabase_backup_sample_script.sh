 #!/bin/bash
#
# Copyright (c) 2025 Dell Inc., or its subsidiaries. All Rights Reserved.
#
# Licensed under the MIT License. See LICENSE file in the project root for
# full license information.
#
# DD_TARGET_DIRECTORY, DB_USER, DB_PASS is an exported value of the Destination path by the agent
# BACKUP_LEVEL is an exported value having "full | log" values by the agent
# update the username details if necessary for -u
# Compression should not be added to the MySQL.
BASE_BACKUP_DIR=${DD_TARGET_DIRECTORY}
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
 echo "entering ... dump.sh ..."
  
# Check if BACKUP_LEVEL is "full"
 if [[ "$BACKUP_LEVEL" != "FULL" ]]; then
  echo "Backup level is not 'FULL'. Exiting..."
  exit 1
 fi
  
if [[ ! -z "${ASSET_PASSWORD}" ]]; then
    PASSWORD_CHECK="MYSQL_PWD='${ASSET_PASSWORD}'"
 fi
  
echo "starting mysqldump for database ${DB_NAME}"
 mysqldump -u ${ASSET_USERNAME} -p${ASSET_PASSWORD} --databases ${DB_NAME} > ${BASE_BACKUP_DIR}/${DB_NAME}-$(date +%Y%m%d-%H%M%S).sql
 [ ! $? == 0 ] && echo "mysqldump of database ${DB_NAME} failed" && exit 1
 echo "mysqldump of database ${DB_NAME} success"