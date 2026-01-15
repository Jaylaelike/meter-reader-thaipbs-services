#!/bin/bash
# Entrypoint for backup container

# Export environment variables for cron
printenv | grep -E '^(DB_|MYSQL_)' >> /etc/environment

# Create log file
touch /var/log/mysql-backup.log

echo "[$(date)] Backup service started"
echo "[$(date)] Schedule: Monthly on 1st at 02:00 AM"

# Start crond in foreground (Oracle Linux uses crond, not cron)
crond -n
