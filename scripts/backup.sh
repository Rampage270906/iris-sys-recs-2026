#!/bin/bash

# Backup script — runs on a 24h loop via Dockerfile.backup CMD
# Each run dumps MySQL and archives NFS shared storage into a single .tar.gz
# Retention policy keeps the last 5 backups to avoid filling disk

BACKUP_DIR="/backups"

# Read DB credentials from environment variables (set in docker-compose via .env)
# Avoids hardcoding secrets in the script itself
DB_HOST="${DATABASE_HOST}"
DB_USER="${DATABASE_USER}"
DB_PASSWORD="${DATABASE_PASSWORD}"
DB_NAME="appdb"

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/backup_$TIMESTAMP.tar.gz"
TEMP_DIR="/tmp/backup_$TIMESTAMP"

echo "[$(date)] Starting backup..."
mkdir -p $TEMP_DIR

# Dump MySQL
# --ssl-mode=DISABLED — MySQL 8 forces TLS by default, disabled here since
#   traffic stays inside the Docker network (no external exposure)
# --no-tablespaces — appuser doesn't have PROCESS privilege, this skips tablespace info
echo "[$(date)] Backing up MySQL database..."
mysqldump -h $DB_HOST -u $DB_USER -p$DB_PASSWORD \
    --ssl-mode=DISABLED \
    --no-tablespaces \
    $DB_NAME > $TEMP_DIR/database.sql

# Archive NFS shared storage if it exists
echo "[$(date)] Backing up NFS shared storage..."
if [ -d "/nfs_shared" ]; then
    tar -czf $TEMP_DIR/nfs_shared.tar.gz /nfs_shared
fi

# Bundle both dumps into a single timestamped archive
tar -czf $BACKUP_FILE -C /tmp backup_$TIMESTAMP/
rm -rf $TEMP_DIR

echo "[$(date)] Backup created: $BACKUP_FILE"

# Keep only the 5 most recent backups — delete anything older
# ls -t sorts newest first, tail -n +6 skips the first 5
echo "[$(date)] Cleaning old backups (keeping last 5)..."
cd $BACKUP_DIR
ls -t backup_*.tar.gz | tail -n +6 | xargs rm -f

echo "[$(date)] Backup complete!"