#!/bin/bash

# Backup script - runs daily
# Backs up MySQL database and NFS shared storage

BACKUP_DIR="/backups"
DB_HOST="mysql"
DB_USER="appuser"
DB_PASSWORD="apppassword"
DB_NAME="appdb"
RETENTION_DAYS=5

# Create timestamp
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/backup_$TIMESTAMP.tar.gz"

echo "[$(date)] Starting backup..."

# Create temporary directory for backup files
TEMP_DIR="/tmp/backup_$TIMESTAMP"
mkdir -p $TEMP_DIR

# Backup MySQL database
echo "[$(date)] Backing up MySQL database..."
mysqldump -h $DB_HOST -u $DB_USER -p$DB_PASSWORD $DB_NAME > $TEMP_DIR/database.sql

# Backup NFS shared storage
echo "[$(date)] Backing up NFS shared storage..."
if [ -d "/nfs_shared" ]; then
    tar -czf $TEMP_DIR/nfs_shared.tar.gz /nfs_shared
fi

# Create final backup archive
tar -czf $BACKUP_FILE -C /tmp backup_$TIMESTAMP/

# Cleanup temp directory
rm -rf $TEMP_DIR

echo "[$(date)] Backup created: $BACKUP_FILE"

# Retention policy - keep only last 5 backups
echo "[$(date)] Cleaning old backups (keeping last 5)..."
cd $BACKUP_DIR
ls -t backup_*.tar.gz | tail -n +6 | xargs rm -f

echo "[$(date)] Backup complete!"
