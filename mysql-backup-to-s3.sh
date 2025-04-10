#!/bin/bash

################################################################################
# Author: Sowmyadevi Telidevara
# Version: v1.1
#
# Description:
# This script backs up a MySQL DB from AWS RDS, compresses it,
# uploads to S3, and optionally removes old backups if any exist.
################################################################################

DB_HOST="mysql-db.c030qy8mgi7w.us-east-1.rds.amazonaws.com"
DB_USER="admin"
DB_PASSWORD="Sowmyadevi"
DB_NAME="devopsdb"
S3_BUCKET="mysql-db-backup-to-s3"
RETENTION_DAYS=3

DATE=$(date +"%F_%H-%M")
BACKUP_DIR="$HOME/mysql/tmp/db_backups"
BACKUP_FILE="$BACKUP_DIR/${DB_NAME}_backup_$DATE.sql"

# Step 1: Ensure backup directory exists
mkdir -p "$BACKUP_DIR"

# Step 2: Take MySQL backup quietly and cleanly
echo "Saving DB content to backup file..."
mysqldump -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASSWORD" \
  --single-transaction --set-gtid-purged=OFF "$DB_NAME" > "$BACKUP_FILE"

# Step 3: Compress the backup
echo "Compressing backup..."
tar -czf "$BACKUP_FILE.tar.gz" -C "$(dirname "$BACKUP_FILE")" "$(basename "$BACKUP_FILE")"
rm -f "$BACKUP_FILE"

# Step 4: Upload to S3
echo "Uploading backup to S3: s3://$S3_BUCKET/db_backups/"
aws s3 cp "$BACKUP_FILE.tar.gz" "s3://$S3_BUCKET/db_backups/"

# Step 5: Local cleanup (only if old files exist)
OLD_LOCAL_FILES=$(find "$BACKUP_DIR" -type f -name "*.tar.gz" -mtime +$RETENTION_DAYS)
if [[ -n "$OLD_LOCAL_FILES" ]]; then
  echo "Cleaning up local backups older than $RETENTION_DAYS days..."
  find "$BACKUP_DIR" -type f -name "*.tar.gz" -mtime +$RETENTION_DAYS -exec rm -f {} \;
fi

# Step 6: S3 cleanup (only if old backups exist)
THRESHOLD_DATE=$(date -d "-$RETENTION_DAYS days" +%Y-%m-%dT%H:%M:%S)
OLD_S3_BACKUPS=$(aws s3api list-objects-v2 --bucket "$S3_BUCKET" --prefix "db_backups/" \
  --query "Contents[?LastModified<='${THRESHOLD_DATE}'].[Key]" --output text)

if [[ -n "$OLD_S3_BACKUPS" ]]; then
  echo "Cleaning up old backups in s3://$S3_BUCKET/db_backups/ older than $RETENTION_DAYS days..."
  while read -r KEY; do
    [[ "$KEY" == *.tar.gz ]] && aws s3 rm "s3://$S3_BUCKET/$KEY"
  done <<< "$OLD_S3_BACKUPS"
fi

echo "Backup complete!"
