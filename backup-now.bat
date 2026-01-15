@echo off
REM Manual Database Backup Script for Windows
REM Run this to create an immediate backup

echo Starting manual database backup...
docker exec power_mysql_backup /usr/local/bin/mysql-backup.sh
if %errorlevel% equ 0 (
    echo Backup complete! Check .\db_snapshots\ for the backup file.
) else (
    echo Backup failed! Check if the container is running.
    exit /b 1
)
pause
