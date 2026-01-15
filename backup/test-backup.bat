@echo off
REM Test MySQL Backup Script - Windows Version

echo ========================================
echo Testing MySQL Backup Script
echo ========================================
echo.

echo Running backup script manually...
docker exec power_mysql_backup /usr/local/bin/mysql-backup.sh

if %errorlevel% equ 0 (
    echo.
    echo ========================================
    echo Test completed successfully!
    echo ========================================
    echo.
    echo Latest backup:
    dir /b /o-d db_snapshots\*\*\*.sql.gz 2>nul | findstr /n "^" | findstr "^1:"
) else (
    echo.
    echo ========================================
    echo Test failed! Check the error above.
    echo ========================================
)

pause
