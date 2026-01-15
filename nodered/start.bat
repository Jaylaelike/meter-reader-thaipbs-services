@echo off
REM Node-RED Power Monitor Gateway - Windows Startup Script

echo ========================================
echo Starting Node-RED Power Monitor Gateway
echo ========================================
echo.

REM Check if Docker is running
docker info >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Docker is not running. Please start Docker Desktop first.
    pause
    exit /b 1
)

REM Load environment variables from .env if exists
if exist .env (
    echo [INFO] Loading environment variables from .env
    for /f "usebackq tokens=1,* delims==" %%a in (".env") do (
        if not "%%a"=="" if not "%%a:~0,1%"=="#" set "%%a=%%b"
    )
) else (
    echo [WARN] No .env file found, using defaults
)

REM Stop existing containers
echo [INFO] Stopping existing containers...
docker-compose down 2>nul

REM Build and start services
echo [INFO] Building and starting Node-RED server...
docker-compose up -d --build

REM Wait for services to be ready
echo [INFO] Waiting for Node-RED to start...
timeout /t 10 /nobreak >nul

REM Check service status
echo.
echo ========================================
echo Service Status:
echo ========================================
docker-compose ps

REM Show logs
echo.
echo ========================================
echo Recent Logs:
echo ========================================
docker-compose logs --tail 20

echo.
echo ========================================
echo Node-RED Power Monitor Gateway is running!
echo ========================================
echo.
echo Access Points:
echo   Node-RED Editor: http://localhost:1880/admin
echo   Dashboard:       http://localhost:1880/ui
echo   API:             http://localhost:1880/api
echo.
echo Default Login:
echo   Username: admin
echo   Password: password
echo.
echo Commands:
echo   View logs: docker-compose logs -f
echo   Stop:      docker-compose down
echo ========================================

pause
