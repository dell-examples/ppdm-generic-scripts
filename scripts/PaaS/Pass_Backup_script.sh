 #!/bin/bash
 # RDS SQL Server Backup Script with Parallel S3 Copy to DDVE and Improved Logging
 
# Tool paths
 SQL_TOOLS_PATH="/opt/mssql-tools18/bin"
 SQLCMD=$SQL_TOOLS_PATH/sqlcmd
 SQLOPT="-N o -h 1 -W -k1 -h -1 -C"
 
# Process command line options
 while getopts ":s:d:u:p:b:e:r:" opt; do
  case $opt in
    s) SQLSRV="$OPTARG" ;;
    d) SQLDB="$OPTARG" ;;
    u) SQLUSER="$OPTARG" ;;
    p) SQLPASS="$OPTARG" ;;
    b) BUCKET="$OPTARG" ;;
    e) ENDPOINT_URL="$OPTARG" ;;
    r) RETAIN_OBJECT="$OPTARG" ;;  # yes or no
    \?) echo "Invalid option: -$OPTARG" >&2; exit 1 ;;
  esac
 done
 
# Backup directory settings
 BASE_BACKUP_DIR=${DD_TARGET_DIRECTORY}
 ENDPOINT_URL=${ENDPOINT_URL:-"https://bucket.vpce-08d4c175d1318826b-3r1szqif.s3.us
west-2.vpce.amazonaws.com"}
 RETAIN_OBJECT=${RETAIN_OBJECT:-"no"}
 OBJECT_NAME="${SQLDB}_$(date +%s)_*.bak"
 
# Contact the database and execute the stored procedure
 BACKUP_OUTPUT=$($SQLCMD ${SQLOPT} -s ',' -U "${ASSET_USERNAME}" -P "$
 {ASSET_PASSWORD}" -S "$SQLSRV" -Q "
 exec msdb.dbo.rds_backup_database
    @source_db_name='${SQLDB}',
    @s3_arn_to_backup_to='arn:aws:s3:::${BUCKET}/${OBJECT_NAME}',
    @overwrite_s3_backup_file=1,
    @type='FULL',
    @number_of_files=10;")
 
# Check for SQL error
 if echo "$BACKUP_OUTPUT" | grep -q "Msg "; then
  echo "Backup failed:"
  echo "$BACKUP_OUTPUT"
  exit 1
 fi
 
TASKID=$(echo "$BACKUP_OUTPUT" | head -1 | cut -d ',' -f 1)
 # Poll for completion
 sleep 30
 while true; do
  TASK_STATUS=$($SQLCMD ${SQLOPT} -s ',' -U "${ASSET_USERNAME}" -P 
"${ASSET_PASSWORD}" -S "$SQLSRV" -Q "
    exec msdb.dbo.rds_task_status
    @db_name='${SQLDB}',
    @task_id=${TASKID};" | head -1)
 
  LIFECYCLE=$(echo "$TASK_STATUS" | cut -d, -f6)
  PROG=$(echo "$TASK_STATUS" | cut -d, -f4)
 
  echo "Progress: $PROG, Lifecycle: $LIFECYCLE"
 
  if [[ "$LIFECYCLE" == "SUCCESS" && "$PROG" -eq 100 ]]; then
    echo "RDS Backup completed successfully"
    break
  fi
 
  sleep 30
 done
 
# Retry logic to detect all backup parts
 RETRIES=5
 for i in $(seq 1 $RETRIES); do
  OBJECT_NAMES=$(aws s3 ls "s3://$BUCKET/" --endpoint-url "$ENDPOINT_URL" 
| grep "${SQLDB}_" | awk '{print $4}')
  if [ -n "$OBJECT_NAMES" ]; then
    break
  fi
  echo "Waiting for S3 objects to appear... ($i/$RETRIES)"
  sleep 15
 done
 
if [ -z "$OBJECT_NAMES" ]; then
  echo "ERROR: Backup files not found in S3 after waiting."
  exit 1
 fi
 
echo "$(date '+%Y-%m-%d %H:%M:%S') - Backup parts detected:"
 echo "$OBJECT_NAMES"
 
# Start parallel copy for all parts
 echo "$(date '+%Y-%m-%d %H:%M:%S') - Starting parallel copy of 
all backup parts from S3 to DDVE..."
 
echo "$OBJECT_NAMES" | xargs -I {} -P 10 sh -c 'echo "$(date) - Copying {}"; aws s3 cp "s3://'"$BUCKET"'/{}" "'"$BASE_BACKUP_DIR"'/" --endpoint-url "'"$ENDPOINT_URL"'"  --no-progress || echo "Failed to copy {}"'
 
# Wait briefly to ensure file system sync
 sync
 sleep 5
 
# Check for any matching backup file
 if ls "$BASE_BACKUP_DIR/${SQLDB}_"*.bak 1> /dev/null 2>&1; then
  echo "$(date '+%Y-%m-%d %H:%M:%S') - Backup files successfully copied to DDVE."
 
  if [ "$RETAIN_OBJECT" != "yes" ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Deleting backup files from S3..."
    echo "$OBJECT_NAMES" | xargs -I {} -P 10 sh -c 'echo "$(date) - Deleting {}"; aws 
s3 rm "s3://'"$BUCKET"'/{}" --endpoint-url "'"$ENDPOINT_URL"'" --region "'"$REGION"'"'
    echo "$(date '+%Y-%m-%d %H:%M:%S') - S3 objects deleted successfully."
  else
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Retaining objects on S3 as per user request."
  fi
 else
  echo "$(date '+%Y-%m-%d %H:%M:%S') - ERROR: Backup files not found on DDVE after copy."
  exit 1
 fi
 
exit 0