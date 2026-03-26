#!/bin/bash
#
# Copyright (c) 2025 Dell Inc., or its subsidiaries. All Rights Reserved.
#
# Licensed under the MIT License. See LICENSE file in the project root for
# full license information.
#
# update the username details if necessary for -u
 
BASE_BACKUP_DIR=${DD_TARGET_DIRECTORY}
echo "entering ... dump.sh ..."
 
echo "starting mariadb-dump for all databases"
mariadb-dump -u ${ASSET_USERNAME} -p${ASSET_PASSWORD} --all-databases > ${BASE_BACKUP_DIR}/all-databases-$(date +%Y%m%d-%H%M%S).sql
[ ! $? == 0 ] && echo "mariadb-dump of all databases failed" && exit 1
echo "mariadb-dump of all databases success"