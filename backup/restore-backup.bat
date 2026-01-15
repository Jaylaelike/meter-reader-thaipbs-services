@echo off
REM Restore MySQL Database from Backup - Windows Version

echo ========================================
echo MySQL Database Restore Tool
echo ========================================
echo.

REM Check if backup file path is provided
if "%~1"=="" (
    echo Usage: restore-backup.bat "path\to\backup.sql.gz"
    echo.
    echo Example:
    echo   restore-backup.bat "db_snapshots\2026\01\power_real_a_1_20260115_020000.sql.gz"
    echo.
    echo Available backups:
    dir /s /b db_snapshots\*.sql.gz 2>nul
    pause
    exit /b 1
)

set BACKUP_FILE=%~1

REM Check if file exists
if not exist "%BACKUP_FILE%" (
    echo ERROR: Backup file not found: %BACKUP_FILE%
    pause
    exit /b 1
)

echo Backup file: %BACKUP_FILE%
echo.
echo WARNING: This will restore the database from the backup.
echo Current data may be overwritten!
echo.
set /p CONFIRM="Are you sure you want to continue? (yes/no): "

if /i not "%CONFIRM%"=="yes" (
    echo Restore cancelled.
    pause
    exit /b 0
)

echo.
echo Restoring database...

REM Decompress and restore
docker run --rm -i ^
    --network project-meter-thaipbs_power_network ^
    -v "%cd%\%BACKUP_FILE%:/backup.sql.gz:ro" ^
    mysql:8.0 ^
    sh -c "gunzip < /backup.sql.gz | mysql -h mysql -uroot -pthaipbs"

if %errorlevel% equ 0 (
    echo.
    echo ========================================
    echo Restore completed successfully!
    echo ========================================
) else (
    echo.
    echo ========================================
    echo Restore failed! Check Docker logs.
    echo ========================================
    exit /b 1
)

pause
