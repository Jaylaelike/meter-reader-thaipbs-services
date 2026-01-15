FROM debian:bullseye-slim

# Install mysql-client and cron
RUN apt-get update && apt-get install -y \
    default-mysql-client \
    cron \
    && rm -rf /var/lib/apt/lists/*

# Copy backup script
COPY mysql-backup.sh /usr/local/bin/mysql-backup.sh
RUN chmod +x /usr/local/bin/mysql-backup.sh

# Copy cron configuration (cron.d files are read automatically, no crontab command needed)
COPY crontab /etc/cron.d/mysql-backup
RUN chmod 0644 /etc/cron.d/mysql-backup

# Create backup directory
RUN mkdir -p /backups

# Copy entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
