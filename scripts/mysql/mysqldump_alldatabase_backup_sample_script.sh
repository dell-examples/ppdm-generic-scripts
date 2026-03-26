!/bin/bash 
# update the username details if necessary for -u
 BASE_BACKUP_DIR=${DD_TARGET_DIRECTORY}
 echo "entering ... dump.sh ..."
  
# Check if BACKUP_LEVEL is "full"
 if [[ "$BACKUP_LEVEL" != "FULL" ]]; then
  echo "Backup level is not 'FULL'. Exiting..."
  exit 1
 fi
  
if [[ ! -z "${ASSET_PASSWORD}" ]]; then
    PASSWORD_CHECK="MYSQL_PWD='${ASSET_PASSWORD}'"
 fi
  
echo "starting mysqldump for all databases"
 mysqldump -u ${ASSET_USERNAME} -p${ASSET_PASSWORD} --all-databases > ${BASE_BACKUP_DIR}/
 all-databases-$(date +%Y%m%d-%H%M%S).sql
 [ ! $? == 0 ] && echo "mysqldump of all databases failed" && exit 1
 echo "mysqldump of all databases success