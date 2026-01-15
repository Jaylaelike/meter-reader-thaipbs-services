#!/bin/bash
# MySQL Monthly Backup Script
# Creates timestamped database snapshots

set -e

# Configuration from environment
DB_HOST="${DB_HOST:-mysql}"
DB_USER="${DB_USER:-root}"
DB_PASSWORD="${DB_PASSWORD:-thaipbs}"
DB_NAME="${DB_NAME:-power_real_a_1}"
BACKUP_DIR="/backups"

# Create year/month directory structure
YEAR=$(date +%Y)
MONTH=$(date +%m)
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_PATH="${BACKUP_DIR}/${YEAR}/${MONTH}"

mkdir -p "${BACKUP_PATH}"

# Backup filename
BACKUP_FILE="${BACKUP_PATH}/${DB_NAME}_${TIMESTAMP}.sql.gz"

echo "[$(date)] Starting backup of database: ${DB_NAME}"

# Perform backup with compression
mysqldump -h "${DB_HOST}" -u "${DB_USER}" -p"${DB_PASSWORD}" \
    --single-transaction \
    --routines \
    --triggers \
    --databases "${DB_NAME}" | gzip > "${BACKUP_FILE}"

# Verify backup was created
if [ -f "${BACKUP_FILE}" ]; then
    SIZE=$(ls -lh "${BACKUP_FILE}" | awk '{print $5}')
    echo "[$(date)] Backup completed successfully: ${BACKUP_FILE} (${SIZE})"
else
    echo "[$(date)] ERROR: Backup failed!"
    exit 1
fi

# Optional: Remove backups older than 12 months
find "${BACKUP_DIR}" -name "*.sql.gz" -mtime +365 -delete 2>/dev/null || true

echo "[$(date)] Backup process finished"
