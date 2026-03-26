 #!/bin/sh -x
#
# Copyright (c) 2025 Dell Inc., or its subsidiaries. All Rights Reserved.
#
# Licensed under the MIT License. See LICENSE file in the project root for
# full license information.
#
# This script will use the AWS stored procedure to dump the database to an S3 bucket
# It will then use AWS CLI copy the contents to DD
# Tool information
 
 
# Tool paths
 
SQL_TOOLS_PATH="/opt/mssql-tools18/bin"
SQLCMD=$SQL_TOOLS_PATH/sqlcmd
SQLOPT="-N o -h 1 -W -k1 -h -1 -C"
 
 
# Process command line options
 
while getopts ":s:d:b:e:r:" opt; do
case $opt in
s) SQLSRV="$OPTARG" ;;
d) SQLDB="$OPTARG" ;;
b) BUCKET="$OPTARG" ;;
e) ENDPOINT_URL="$OPTARG" ;;
r) RETAIN_OBJECT="$OPTARG" ;; # yes or no
\?) echo "Invalid option: -$OPTARG" >&2; exit 1 ;;
esac
 done
 
 
# backup directory settings (Defaults_
 BASE_BACKUP_DIR=${DD_TARGET_DIRECTORY}
 ENDPOINT_URL=${ENDPOINT_URL:-"https://bucket.vpce-08d4c175d1318826b-3r1szqif.s3.uswest-2.vpce.amazonaws.com"}
 RETAIN_OBJECT=${RETAIN_OBJECT:-"no"}
 OBJECT_NAME="${SQLDB}_$(date +%s).bak"
 
 
 
#
 #   Contact the database and execute the stored procedure
 #
 
TASKID=`$SQLCMD ${SQLOPT} -s ',' -U "${ASSET_USERNAME}" -P "${ASSET_PASSWORD}" -S $SQLSRV -Q "exec msdb.dbo.rds_backup_database
    @source_db_name='${SQLDB}',
    @s3_arn_to_backup_to='arn:aws:s3:::${BUCKET}/${OBJECT_NAME}',
    @overwrite_s3_backup_file=1,
    @type='FULL';" | head -1 | cut -d ',' -f 1`
 
# Poll for completion
 
sleep 30
 
while true
 do
 
TASK_STATUS=$($SQLCMD ${SQLOPT} -s ',' -U "${ASSET_USERNAME}" -P "${ASSET_PASSWORD}" -S $SQLSRV -Q "exec msdb.dbo.rds_task_status
    @db_name='${SQLDB}',
    @task_id=${TASKID};" | head -1)
 
  LIFECYCLE=$(echo "$TASK_STATUS" | cut -d, -f6)
  PROG=$(echo "$TASK_STATUS" | cut -d, -f4)
 
  echo "Progress: $PROG, Lifecycle: $LIFECYCLE"
 
  if ["$LIFECYCLE" == "SUCCESS"] && "[$PROG" -eq 100]; then
    echo "RDS Backup completed successfully"
    break
  fi
 
sleep 30
 
done
 
# Dynamically calculate expected size in GB
 OBJECT_SIZE_BYTES=$(aws s3api head-object --bucket "$BUCKET" --key "$OBJECT_NAME" --endpoint-url "$ENDPOINT_URL" --query 'ContentLength' --output text)
 
EXPECTED_SIZE_GB=$(echo "($OBJECT_SIZE_BYTES + 1073741823)/1073741824" | bc)
 
# Copy from S3 using expected size boostfs mountpoint
 #
 
if aws s3 cp "s3://$BUCKET/$OBJECT_NAME"  "$BASE_BACKUP_DIR"  --endpoint-url "$ENDPOINT_URL" --expected-size ${EXPECTED_SIZE_GB}GB  --no-progress;
 then
 
echo " S3 copy succeeded Proceeding to delete the object.."
 
#Delete the object from S3 after successful copy
 
if [ "$RETAIN_OBJECT" != "yes" ]; then
 echo "Deleting object from S3..."
 aws s3 rm "s3://$BUCKET/$OBJECT_NAME" --endpoint-url "$ENDPOINT_URL"
 echo "S3 object deleted successfully"
 else
 echo "Retaining object on S3 as per user request."
 fi
 else
 echo " s3 copy failed.Skipping deletion to preserve the backup file"
 fi
 exit 0