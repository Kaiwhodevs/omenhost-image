#!/bin/bash
# Fleio backup and S3 upload script with S3 retention logic

# Load configuration - prefer config loader if available
if [ -f "/opt/fleio-custom/scripts/load-config.sh" ]; then
    source /opt/fleio-custom/scripts/load-config.sh
fi

BACKUP_DIR="/var/backups/fleio"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="fleio_backup_${DATE}"
RETENTION_DAYS="${FLEIO_BACKUP_RETENTION_DAYS:-30}"

set -e

# Create backup directories
mkdir -p "$BACKUP_DIR/database" "$BACKUP_DIR/settings" "$BACKUP_DIR/uploads"

# Backup database using Fleio command
echo "[fleio-backup] Creating Fleio database backup..."
cd /opt/fleio || exit 1
if python manage.py backup --output="$BACKUP_DIR/database/${BACKUP_NAME}.sql"; then
    echo "[fleio-backup] Database backup succeeded."
else
    echo "[fleio-backup] ERROR: Database backup failed!" >&2
    exit 1
fi

# Backup settings directory
echo "[fleio-backup] Archiving settings directory..."
tar -czf "$BACKUP_DIR/settings/${BACKUP_NAME}.tar.gz" /var/lib/docker/volumes/fleio_settings/

# Encrypt backups if key provided
if [ -n "$FLEIO_BACKUP_ENCRYPTION_KEY" ]; then
    echo "[fleio-backup] Encrypting backups (AES256)..."
    gpg --batch --yes --symmetric --cipher-algo AES256 --passphrase "$FLEIO_BACKUP_ENCRYPTION_KEY" \
        --output "$BACKUP_DIR/database/${BACKUP_NAME}.sql.gpg" \
        "$BACKUP_DIR/database/${BACKUP_NAME}.sql" && rm "$BACKUP_DIR/database/${BACKUP_NAME}.sql"
    gpg --batch --yes --symmetric --cipher-algo AES256 --passphrase "$FLEIO_BACKUP_ENCRYPTION_KEY" \
        --output "$BACKUP_DIR/settings/${BACKUP_NAME}.tar.gz.gpg" \
        "$BACKUP_DIR/settings/${BACKUP_NAME}.tar.gz" && rm "$BACKUP_DIR/settings/${BACKUP_NAME}.tar.gz"
    ARCHIVE_DB="$BACKUP_DIR/database/${BACKUP_NAME}.sql.gpg"
    ARCHIVE_SETTINGS="$BACKUP_DIR/settings/${BACKUP_NAME}.tar.gz.gpg"
else
    ARCHIVE_DB="$BACKUP_DIR/database/${BACKUP_NAME}.sql"
    ARCHIVE_SETTINGS="$BACKUP_DIR/settings/${BACKUP_NAME}.tar.gz"
fi

# Create combined archive
echo "[fleio-backup] Creating combined backup archive..."
tar -czf "$BACKUP_DIR/${BACKUP_NAME}.tar.gz" "$ARCHIVE_DB" "$ARCHIVE_SETTINGS"

# Upload backup to S3 if configured
if [ -n "$FLEIO_S3_BUCKET" ] && [ -n "$FLEIO_S3_ACCESS_KEY" ] && [ -n "$FLEIO_S3_SECRET_KEY" ]; then
    echo "[fleio-backup] Uploading backup to S3 bucket $FLEIO_S3_BUCKET..."
    S3_ENDPOINT_FLAG=""
    if [ -n "$FLEIO_S3_ENDPOINT_URL" ]; then
        S3_ENDPOINT_FLAG="--endpoint-url $FLEIO_S3_ENDPOINT_URL"
    fi
    export AWS_ACCESS_KEY_ID="$FLEIO_S3_ACCESS_KEY"
    export AWS_SECRET_ACCESS_KEY="$FLEIO_S3_SECRET_KEY"
    aws s3 cp "$BACKUP_DIR/${BACKUP_NAME}.tar.gz" \
        "s3://${FLEIO_S3_BUCKET}/fleio-backups/${BACKUP_NAME}.tar.gz" \
        --region "${FLEIO_S3_REGION:-us-east-1}" \
        $S3_ENDPOINT_FLAG \
        --storage-class STANDARD_IA || echo "[fleio-backup] ERROR: S3 upload failed!" >&2

    # S3 retention: delete remote backups older than $RETENTION_DAYS
    if aws s3 ls "s3://${FLEIO_S3_BUCKET}/fleio-backups/" $S3_ENDPOINT_FLAG > /dev/null 2>&1; then
        echo "[fleio-backup] Applying S3 backup retention (older than $RETENTION_DAYS days)..."
        aws s3 ls "s3://${FLEIO_S3_BUCKET}/fleio-backups/" $S3_ENDPOINT_FLAG |
            awk '{print $4" "$1" "$2}' | while read -r filename filedate filetime; do
                # filedate is yyyy-mm-dd, filetime is hh:mm:ss
                # S3 backup files contain date in their name: fleio_backup_YYYYMMDD_HHMMSS.tar.gz
                backup_date=$(echo "$filename" | grep -oE '[0-9]{8}' | head -1)
                if [[ -n "$backup_date" ]]; then
                    bdate=$(date -d "$backup_date" +%s 2>/dev/null || true)
                    now=$(date +%s)
                    if [[ -n "$bdate" ]] && (( (now - bdate) / 86400 > RETENTION_DAYS )); then
                        echo "[fleio-backup] Deleting old S3 backup: $filename"
                        aws s3 rm "s3://${FLEIO_S3_BUCKET}/fleio-backups/$filename" $S3_ENDPOINT_FLAG
                    fi
                fi
            done
    fi
fi

# Cleanup old local backups
echo "[fleio-backup] Cleaning up old local backups (older than $RETENTION_DAYS days)..."
find "$BACKUP_DIR" -name "fleio_backup_*.tar.gz" -mtime +$RETENTION_DAYS -delete
find "$BACKUP_DIR/database" -name "*.sql*" -mtime +$RETENTION_DAYS -delete
find "$BACKUP_DIR/settings" -name "*.tar.gz*" -mtime +$RETENTION_DAYS -delete

echo "[fleio-backup] Backup completed: ${BACKUP_NAME}.tar.gz"
