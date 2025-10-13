#!/bin/bash
# Setup backup system for Fleio

echo "Setting up backup system..."

# Create backup directory
mkdir -p /var/backups/fleio/{database,settings,uploads}

# Create backup script using official fleio backup command
cat > /opt/fleio-custom/scripts/backup-fleio.sh << 'EOF'
#!/bin/bash
# Fleio backup script using official fleio backup now command

BACKUP_DIR="/var/backups/fleio"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="fleio_backup_${DATE}"

# Create backup directory
mkdir -p "${BACKUP_DIR}"

# Use official fleio backup command
echo "Creating Fleio database backup using 'fleio backup now'..."
cd /opt/fleio
python manage.py backup --output="${BACKUP_DIR}/database/${BACKUP_NAME}.sql"

# Backup settings directory from Docker volumes
echo "Backing up settings directory..."
tar -czf "${BACKUP_DIR}/settings/${BACKUP_NAME}.tar.gz" /var/lib/docker/volumes/fleio_settings/

# Encrypt database backup if encryption key is provided
if [ -n "$FLEIO_BACKUP_ENCRYPTION_KEY" ]; then
    echo "Encrypting database backup..."
    gpg --symmetric --cipher-algo AES256 --passphrase "$FLEIO_BACKUP_ENCRYPTION_KEY" \
        --output "${BACKUP_DIR}/database/${BACKUP_NAME}.sql.gpg" \
        "${BACKUP_DIR}/database/${BACKUP_NAME}.sql"
    rm "${BACKUP_DIR}/database/${BACKUP_NAME}.sql"
    
    echo "Encrypting settings backup..."
    gpg --symmetric --cipher-algo AES256 --passphrase "$FLEIO_BACKUP_ENCRYPTION_KEY" \
        --output "${BACKUP_DIR}/settings/${BACKUP_NAME}.tar.gz.gpg" \
        "${BACKUP_DIR}/settings/${BACKUP_NAME}.tar.gz"
    rm "${BACKUP_DIR}/settings/${BACKUP_NAME}.tar.gz"
fi

# Create combined backup archive
echo "Creating combined backup archive..."
if [ -n "$FLEIO_BACKUP_ENCRYPTION_KEY" ]; then
    tar -czf "${BACKUP_DIR}/${BACKUP_NAME}.tar.gz" \
        "${BACKUP_DIR}/database/${BACKUP_NAME}.sql.gpg" \
        "${BACKUP_DIR}/settings/${BACKUP_NAME}.tar.gz.gpg"
else
    tar -czf "${BACKUP_DIR}/${BACKUP_NAME}.tar.gz" \
        "${BACKUP_DIR}/database/${BACKUP_NAME}.sql" \
        "${BACKUP_DIR}/settings/${BACKUP_NAME}.tar.gz"
fi

# Upload to S3 if configured
if [ -n "$FLEIO_S3_BUCKET" ] && [ -n "$FLEIO_S3_ACCESS_KEY" ]; then
    echo "Uploading encrypted backup to S3..."
    S3_ENDPOINT_FLAG=""
    if [ -n "$FLEIO_S3_ENDPOINT_URL" ]; then
        S3_ENDPOINT_FLAG="--endpoint-url $FLEIO_S3_ENDPOINT_URL"
    fi
    aws s3 cp "${BACKUP_DIR}/${BACKUP_NAME}.tar.gz" \
        "s3://${FLEIO_S3_BUCKET}/fleio-backups/${BACKUP_NAME}.tar.gz" \
        --region "${FLEIO_S3_REGION}" \
        $S3_ENDPOINT_FLAG \
        --storage-class STANDARD_IA
fi

# Cleanup old local backups
echo "Cleaning up old local backups..."
find "${BACKUP_DIR}" -name "fleio_backup_*.tar.gz" -mtime +${FLEIO_BACKUP_RETENTION_DAYS:-30} -delete
find "${BACKUP_DIR}/database" -name "*.sql*" -mtime +${FLEIO_BACKUP_RETENTION_DAYS:-30} -delete
find "${BACKUP_DIR}/settings" -name "*.tar.gz*" -mtime +${FLEIO_BACKUP_RETENTION_DAYS:-30} -delete

echo "Backup completed: ${BACKUP_NAME}.tar.gz"
EOF

chmod +x /opt/fleio-custom/scripts/backup-fleio.sh

# Create backup cron script
cat > /opt/fleio-custom/scripts/backup-cron.sh << 'EOF'
#!/bin/bash
# Backup cron script

# Load configuration
if [ -f "/opt/fleio-custom/config/fleio-custom.conf" ]; then
    source /opt/fleio-custom/scripts/load-config.sh
fi

# Run backup based on frequency
case "${FLEIO_BACKUP_FREQUENCY:-daily}" in
    "hourly")
        /opt/fleio-custom/scripts/backup-fleio.sh
        ;;
    "daily")
        # Run daily at 2 AM
        if [ $(date +%H) -eq 2 ]; then
            /opt/fleio-custom/scripts/backup-fleio.sh
        fi
        ;;
    "weekly")
        # Run weekly on Sunday at 2 AM
        if [ $(date +%u) -eq 7 ] && [ $(date +%H) -eq 2 ]; then
            /opt/fleio-custom/scripts/backup-fleio.sh
        fi
        ;;
esac
EOF

chmod +x /opt/fleio-custom/scripts/backup-cron.sh

# Create restore script
cat > /opt/fleio-custom/scripts/restore-fleio.sh << 'EOF'
#!/bin/bash
# Fleio restore script

if [ -z "$1" ]; then
    echo "Usage: $0 <backup_file>"
    exit 1
fi

BACKUP_FILE="$1"
RESTORE_DIR="/tmp/fleio_restore_$(date +%s)"

echo "Restoring from backup: $BACKUP_FILE"

# Extract backup
mkdir -p "$RESTORE_DIR"
tar -xzf "$BACKUP_FILE" -C "$RESTORE_DIR"

# Restore database
if [ -f "$RESTORE_DIR/fleio_backup_*.sql" ]; then
    echo "Restoring database..."
    psql -h db -U fleio -d fleio < "$RESTORE_DIR/fleio_backup_*.sql"
fi

# Restore settings
if [ -f "$RESTORE_DIR/fleio_backup_*.tar.gz" ]; then
    echo "Restoring settings..."
    tar -xzf "$RESTORE_DIR/fleio_backup_*.tar.gz" -C /
fi

# Restore uploads
if [ -f "$RESTORE_DIR/fleio_backup_*.tar.gz" ]; then
    echo "Restoring uploads..."
    tar -xzf "$RESTORE_DIR/fleio_backup_*.tar.gz" -C /
fi

# Cleanup
rm -rf "$RESTORE_DIR"

echo "Restore completed"
EOF

chmod +x /opt/fleio-custom/scripts/restore-fleio.sh

# Setup cron job
echo "Setting up backup cron job..."
cat > /etc/cron.d/fleio-backup << EOF
# Fleio backup cron job
*/5 * * * * root /opt/fleio-custom/scripts/backup-cron.sh >> /var/log/fleio-backup.log 2>&1
EOF

echo "Backup system setup complete"
