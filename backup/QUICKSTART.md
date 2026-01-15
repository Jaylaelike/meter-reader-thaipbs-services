# MySQL Backup Service - Quick Start

## Overview
Automated monthly database snapshots with organized storage and manual backup support.

## Directory Structure
```
backup/
├── Dockerfile           # Backup service container
├── mysql-backup.sh      # Backup execution script
├── crontab             # Schedule: 1st of month at 2:00 AM
├── entrypoint.sh       # Container startup script
└── QUICKSTART.md       # This file

db_snapshots/           # Backup storage (auto-created)
└── YYYY/MM/            # Year/Month organization
    └── power_real_a_1_YYYYMMDD_HHMMSS.sql.gz
```

## Features
- ✅ Automatic monthly backup (1st day at 2:00 AM Bangkok time)
- ✅ Compressed `.sql.gz` format (saves disk space)
- ✅ Year/Month folder organization
- ✅ Auto-cleanup of backups older than 12 months
- ✅ Manual backup on-demand

## Quick Start

### 1. Deploy Backup Service
```bash
docker-compose up -d --build
```

### 2. Verify Service is Running
```bash
docker ps | grep power_mysql_backup
docker logs power_mysql_backup
```

### 3. Manual Backup (Optional)
**Linux/macOS:**
```bash
./backup-now.sh
```

**Windows:**
```cmd
backup-now.bat
```

## Backup Schedule
- **Frequency:** Monthly
- **Day:** 1st of each month
- **Time:** 2:00 AM (Asia/Bangkok timezone)

## Restore from Backup

**Linux/macOS:**
```bash
# List available backups
ls -lh db_snapshots/

# Restore specific backup
gunzip < db_snapshots/2026/01/power_real_a_1_20260115_020000.sql.gz | \
  docker exec -i power_mysql mysql -uroot -pthaipbs
```

**Windows:**
```cmd
REM List available backups
backup\list-backups.bat

REM Restore specific backup
backup\restore-backup.bat "db_snapshots\2026\01\power_real_a_1_20260115_020000.sql.gz"
```

## Configuration
Edit environment variables in `.env` or `docker-compose.yml`:
- `DB_NAME` - Database name to backup
- `MYSQL_ROOT_PASSWORD` - MySQL root password
- `TZ` - Timezone (default: Asia/Bangkok)

## Troubleshooting

### Check backup service status
**Linux/macOS:**
```bash
docker logs power_mysql_backup
docker exec power_mysql_backup cat /var/log/mysql-backup.log
```

**Windows:**
```cmd
backup\check-backup-service.bat
```

### Test backup script manually
**Linux/macOS:**
```bash
docker exec power_mysql_backup /usr/local/bin/mysql-backup.sh
```

**Windows:**
```cmd
backup\test-backup.bat
```

### Verify cron schedule
```bash
docker exec power_mysql_backup crontab -l
```

## Storage Management
- Backups older than 12 months are automatically deleted
- Each backup is compressed (typically 10-20% of original size)
- Monitor disk usage: `du -sh db_snapshots/`