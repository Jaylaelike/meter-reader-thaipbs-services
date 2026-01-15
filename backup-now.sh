#!/bin/bash
# Manual Database Backup Script
# Run this to create an immediate backup

echo "Starting manual database backup..."
docker exec power_mysql_backup /usr/local/bin/mysql-backup.sh
echo "Backup complete! Check ./db_snapshots/ for the backup file."
