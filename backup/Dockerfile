FROM mysql:8.0

# Install cron (mysql:8.0 uses Oracle Linux with microdnf)
RUN microdnf install -y cronie && microdnf clean all

# Copy backup script
COPY mysql-backup.sh /usr/local/bin/mysql-backup.sh
RUN chmod +x /usr/local/bin/mysql-backup.sh

# Copy cron configuration
COPY crontab /etc/cron.d/mysql-backup
RUN chmod 0644 /etc/cron.d/mysql-backup

# Create backup directory
RUN mkdir -p /backups

# Copy entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
