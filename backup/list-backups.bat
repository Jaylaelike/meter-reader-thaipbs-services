@echo off
REM List all available database backups - Windows Version

echo ========================================
echo Available Database Backups
echo ========================================
echo.

if not exist "db_snapshots" (
    echo No backups found. Directory db_snapshots does not exist.
    pause
    exit /b 1
)

REM List all backup files with details
for /f "delims=" %%i in ('dir /s /b /o-d db_snapshots\*.sql.gz 2^>nul') do (
    echo %%i
    for %%A in ("%%i") do echo   Size: %%~zA bytes
    echo.
)

echo ========================================
echo Total backup files:
dir /s /-c db_snapshots\*.sql.gz 2>nul | find "File(s)"
echo ========================================

pause
