@echo off
REM Check MySQL Backup Service Status - Windows Version

echo ========================================
echo MySQL Backup Service Status
echo ========================================
echo.

echo [1] Container Status:
docker ps -a --filter "name=power_mysql_backup" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo.

echo [2] Recent Logs:
docker logs --tail 20 power_mysql_backup 2>nul
if %errorlevel% neq 0 (
    echo Container not running or not found!
    echo.
    echo To start the backup service:
    echo   docker-compose up -d mysql-backup
)
echo.

echo [3] Cron Schedule:
docker exec power_mysql_backup crontab -l 2>nul
echo.

echo [4] Backup Log:
docker exec power_mysql_backup cat /var/log/mysql-backup.log 2>nul
echo.

echo ========================================
pause
