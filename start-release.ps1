# Power Monitor Project - Release Deployment Script (Windows)
# This script helps you deploy the full stack application on Windows

$ErrorActionPreference = "Stop"

# Colors for output
function Write-ColorMessage {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

function Write-Header {
    param([string]$Message)
    Write-Host ""
    Write-ColorMessage "==================================" "Cyan"
    Write-ColorMessage $Message "Cyan"
    Write-ColorMessage "==================================" "Cyan"
    Write-Host ""
}

function Write-Success {
    param([string]$Message)
    Write-ColorMessage "✓ $Message" "Green"
}

function Write-Error {
    param([string]$Message)
    Write-ColorMessage "✗ $Message" "Red"
}

function Write-Warning {
    param([string]$Message)
    Write-ColorMessage "⚠ $Message" "Yellow"
}

function Write-Info {
    param([string]$Message)
    Write-ColorMessage "ℹ $Message" "Cyan"
}

# Check if Docker is installed
function Test-Docker {
    try {
        $null = docker --version 2>$null
        Write-Success "Docker is installed"
        return $true
    }
    catch {
        Write-Error "Docker is not installed. Please install Docker Desktop first."
        Write-Info "Download from: https://www.docker.com/products/docker-desktop"
        return $false
    }
}

# Check if Docker Compose is available
function Test-DockerCompose {
    try {
        $null = docker-compose --version 2>$null
        Write-Success "Docker Compose is installed"
        return $true
    }
    catch {
        try {
            $null = docker compose version 2>$null
            Write-Success "Docker Compose (V2) is available"
            return $true
        }
        catch {
            Write-Error "Docker Compose is not available. Please install Docker Desktop or Docker Compose."
            return $false
        }
    }
}

# Check if .env file exists
function Test-EnvFile {
    if (-not (Test-Path ".env")) {
        Write-Warning ".env file not found. Creating from .env.example..."
        if (Test-Path ".env.example") {
            Copy-Item ".env.example" ".env"
            Write-Success "Created .env file from .env.example"
            Write-Info "Please review and update .env file with your configuration"
            $response = Read-Host "Press Enter to continue or Ctrl+C to exit and edit .env first"
        }
        else {
            Write-Warning "No .env.example found. Using default values."
        }
    }
    else {
        Write-Success ".env file exists"
    }
}

# Check if Docker is running
function Test-DockerRunning {
    try {
        $null = docker ps 2>$null
        Write-Success "Docker is running"
        return $true
    }
    catch {
        Write-Error "Docker is not running. Please start Docker Desktop."
        return $false
    }
}

# Stop and remove existing containers
function Stop-Services {
    Write-Header "Cleaning up existing containers"
    try {
        docker-compose -f docker-compose-release.yml down 2>$null
        Write-Success "Cleanup completed"
    }
    catch {
        Write-Info "No existing containers to clean up"
    }
}

# Build and start services
function Start-Services {
    Write-Header "Building and starting services"
    Write-Info "This may take a few minutes on first run..."

    try {
        docker-compose -f docker-compose-release.yml up -d --build
        Write-Success "Services started successfully"
        return $true
    }
    catch {
        Write-Error "Failed to start services: $_"
        return $false
    }
}

# Wait for services to be healthy
function Wait-ForServices {
    Write-Header "Waiting for services to be ready"
    Write-Info "Waiting for MySQL to be healthy..."

    $timeout = 60
    $counter = 0
    $healthy = $false

    while ($counter -lt $timeout) {
        try {
            $status = docker-compose -f docker-compose-release.yml ps mysql | Out-String
            if ($status -match "healthy") {
                Write-Success "MySQL is healthy"
                $healthy = $true
                break
            }
        }
        catch {
            # Continue waiting
        }

        Write-Host "." -NoNewline
        Start-Sleep -Seconds 2
        $counter += 2
    }

    Write-Host ""

    if (-not $healthy) {
        Write-Error "MySQL failed to become healthy within $timeout seconds"
        Write-Info "Check logs with: docker-compose -f docker-compose-release.yml logs mysql"
        return $false
    }

    Write-Info "Waiting for other services to start..."
    Start-Sleep -Seconds 5
    Write-Success "All services should be ready"
    return $true
}

# Show service status
function Show-Status {
    Write-Header "Service Status"
    docker-compose -f docker-compose-release.yml ps
}

# Show access information
function Show-AccessInfo {
    Write-Header "Access Information"

    # Get ports from environment or use defaults
    $frontendPort = if ($env:FRONTEND_PORT) { $env:FRONTEND_PORT } else { "80" }
    $phpmyadminPort = if ($env:PHPMYADMIN_PORT) { $env:PHPMYADMIN_PORT } else { "8080" }
    $mysqlPort = if ($env:MYSQL_PORT) { $env:MYSQL_PORT } else { "3306" }

    Write-Host ""
    Write-Success "Dashboard: http://localhost:$frontendPort"
    Write-Success "phpMyAdmin: http://localhost:$phpmyadminPort"
    Write-Info "MySQL Port: $mysqlPort"
    Write-Host ""

    Write-Info "Default MySQL Credentials:"
    Write-Host "  Username: root"
    Write-Host "  Password: thaipbs (change in .env file)"
    Write-Host "  Database: power_monitor"
    Write-Host ""
}

# Show useful commands
function Show-Commands {
    Write-Header "Useful Commands"

    Write-Host "View logs (all services):"
    Write-Host "  docker-compose -f docker-compose-release.yml logs -f"
    Write-Host ""
    Write-Host "View logs (specific service):"
    Write-Host "  docker-compose -f docker-compose-release.yml logs -f backend"
    Write-Host "  docker-compose -f docker-compose-release.yml logs -f frontend"
    Write-Host "  docker-compose -f docker-compose-release.yml logs -f mysql"
    Write-Host ""
    Write-Host "Stop all services:"
    Write-Host "  docker-compose -f docker-compose-release.yml down"
    Write-Host ""
    Write-Host "Restart a service:"
    Write-Host "  docker-compose -f docker-compose-release.yml restart backend"
    Write-Host ""
    Write-Host "Rebuild after code changes:"
    Write-Host "  docker-compose -f docker-compose-release.yml up -d --build"
    Write-Host ""
}

# Main deployment function
function Start-Deployment {
    Write-Header "Power Monitor - Release Deployment"

    # Pre-flight checks
    if (-not (Test-Docker)) { exit 1 }
    if (-not (Test-DockerCompose)) { exit 1 }
    if (-not (Test-DockerRunning)) { exit 1 }
    Test-EnvFile

    # Ask for confirmation
    Write-Host ""
    Write-Warning "This will stop any existing containers and start fresh."
    $response = Read-Host "Do you want to continue? (y/n)"

    if ($response -notmatch "^[Yy]$") {
        Write-Info "Deployment cancelled"
        exit 0
    }

    # Deploy
    Stop-Services
    if (-not (Start-Services)) { exit 1 }
    if (-not (Wait-ForServices)) { exit 1 }

    # Initialize database if needed
    Write-Info "Checking database initialization..."
    $databases = docker exec power_monitor_mysql mysql -uroot -pthaipbs -e "SHOW DATABASES;" 2>$null
    if ($databases -notmatch "power_real_a_1") {
        Write-Warning "Database 'power_real_a_1' not found. Initializing..."
        if (-not (Initialize-Database)) {
            Write-Warning "Database initialization had issues. You can retry with: .\start-release.ps1 initdb"
        }
    }
    else {
        Write-Success "Database 'power_real_a_1' exists"
    }

    Write-Host ""
    Write-Header "Deployment Complete!"

    Show-Status
    Show-AccessInfo
    Show-Commands

    Write-Success "🎉 Power Monitor is now running!"
}

# Initialize database manually
function Initialize-Database {
    Write-Header "Initializing Database"
    
    # Check if MySQL container is running
    try {
        $status = docker-compose -f docker-compose-release.yml ps mysql | Out-String
        if ($status -notmatch "Up|running") {
            Write-Error "MySQL container is not running. Please start services first."
            Write-Info "Run: .\start-release.ps1 deploy"
            return $false
        }
    }
    catch {
        Write-Error "Failed to check MySQL status: $_"
        return $false
    }

    # Wait for MySQL to be healthy
    Write-Info "Waiting for MySQL to be ready..."
    $timeout = 30
    $counter = 0
    $ready = $false

    while ($counter -lt $timeout) {
        try {
            $result = docker exec power_monitor_mysql mysqladmin ping -uroot -pthaipbs 2>$null
            if ($result -match "alive") {
                $ready = $true
                break
            }
        }
        catch {
            # Continue waiting
        }
        Write-Host "." -NoNewline
        Start-Sleep -Seconds 2
        $counter += 2
    }
    Write-Host ""

    if (-not $ready) {
        Write-Error "MySQL is not responding"
        return $false
    }

    Write-Success "MySQL is ready"

    # Check if database already exists
    Write-Info "Checking existing databases..."
    $databases = docker exec power_monitor_mysql mysql -uroot -pthaipbs -e "SHOW DATABASES;" 2>$null
    
    if ($databases -match "power_real_a_1") {
        Write-Warning "Database 'power_real_a_1' already exists"
        $response = Read-Host "Do you want to drop and recreate it? (y/n)"
        if ($response -match "^[Yy]$") {
            Write-Info "Dropping existing database..."
            docker exec power_monitor_mysql mysql -uroot -pthaipbs -e "DROP DATABASE power_real_a_1;" 2>$null
            Write-Success "Database dropped"
        }
        else {
            Write-Info "Keeping existing database"
            return $true
        }
    }

    # Run initialization SQL
    Write-Info "Creating database and tables..."
    
    try {
        # Copy init.sql to container and execute
        docker cp init.sql power_monitor_mysql:/tmp/init.sql
        docker exec power_monitor_mysql mysql -uroot -pthaipbs -e "source /tmp/init.sql;" 2>$null
        Write-Success "Database initialized from init.sql"
    }
    catch {
        Write-Warning "init.sql failed, trying inline initialization..."
        
        # Fallback: create database and basic structure inline
        $initSQL = @"
CREATE DATABASE IF NOT EXISTS power_real_a_1 CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE power_real_a_1;
CREATE TABLE IF NOT EXISTS full_history (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  device_id VARCHAR(64) NOT NULL,
  time_key TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  load_v_r DECIMAL(8,2) NULL,
  load_v_y DECIMAL(8,2) NULL,
  load_v_b DECIMAL(8,2) NULL,
  load_v3_r DECIMAL(8,2) NULL,
  load_v3_y DECIMAL(8,2) NULL,
  load_v3_b DECIMAL(8,2) NULL,
  load_i_r DECIMAL(10,2) NULL,
  load_i_y DECIMAL(10,2) NULL,
  load_i_b DECIMAL(10,2) NULL,
  load_freq DECIMAL(6,2) NULL,
  load_pf_t DECIMAL(6,3) NULL,
  load_pf_r DECIMAL(6,3) NULL,
  load_pf_y DECIMAL(6,3) NULL,
  load_pf_b DECIMAL(6,3) NULL,
  PRIMARY KEY (id),
  KEY idx_device_time (device_id, time_key),
  KEY idx_time_key (time_key)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE IF NOT EXISTS summary_minute (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  device_id VARCHAR(64) NOT NULL,
  time_key DATETIME NOT NULL,
  avg_kw DECIMAL(12,4) DEFAULT 0,
  total_kwh DECIMAL(12,6) DEFAULT 0,
  counter INT UNSIGNED DEFAULT 0,
  PRIMARY KEY (id),
  UNIQUE KEY uk_device_time (device_id, time_key),
  KEY idx_time_key (time_key)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE IF NOT EXISTS summary_hourly (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  device_id VARCHAR(64) NOT NULL,
  time_key DATETIME NOT NULL,
  avg_kw DECIMAL(12,4) DEFAULT 0,
  total_kwh DECIMAL(12,6) DEFAULT 0,
  counter INT UNSIGNED DEFAULT 0,
  PRIMARY KEY (id),
  UNIQUE KEY uk_device_time (device_id, time_key),
  KEY idx_time_key (time_key)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE IF NOT EXISTS summary_daily (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  device_id VARCHAR(64) NOT NULL,
  time_key DATE NOT NULL,
  avg_kw DECIMAL(12,4) DEFAULT 0,
  total_kwh DECIMAL(12,6) DEFAULT 0,
  counter INT UNSIGNED DEFAULT 0,
  PRIMARY KEY (id),
  UNIQUE KEY uk_device_time (device_id, time_key),
  KEY idx_time_key (time_key)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE IF NOT EXISTS summary_monthly (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  device_id VARCHAR(64) NOT NULL,
  time_key DATE NOT NULL,
  avg_kw DECIMAL(12,4) DEFAULT 0,
  total_kwh DECIMAL(12,6) DEFAULT 0,
  counter INT UNSIGNED DEFAULT 0,
  PRIMARY KEY (id),
  UNIQUE KEY uk_device_time (device_id, time_key),
  KEY idx_time_key (time_key)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE IF NOT EXISTS summary_yearly (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  device_id VARCHAR(64) NOT NULL,
  time_key DATE NOT NULL,
  avg_kw DECIMAL(12,4) DEFAULT 0,
  total_kwh DECIMAL(12,6) DEFAULT 0,
  counter INT UNSIGNED DEFAULT 0,
  PRIMARY KEY (id),
  UNIQUE KEY uk_device_time (device_id, time_key),
  KEY idx_time_key (time_key)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
"@
        docker exec power_monitor_mysql mysql -uroot -pthaipbs -e $initSQL 2>$null
    }

    # Verify database was created
    Write-Info "Verifying database..."
    $databases = docker exec power_monitor_mysql mysql -uroot -pthaipbs -e "SHOW DATABASES;" 2>$null
    
    if ($databases -match "power_real_a_1") {
        Write-Success "Database 'power_real_a_1' created successfully"
        
        # Show tables
        Write-Info "Tables created:"
        docker exec power_monitor_mysql mysql -uroot -pthaipbs power_real_a_1 -e "SHOW TABLES;" 2>$null
        return $true
    }
    else {
        Write-Error "Failed to create database"
        return $false
    }
}

# Main script logic
param(
    [Parameter(Position=0)]
    [ValidateSet("deploy", "start", "stop", "restart", "status", "logs", "clean", "initdb")]
    [string]$Command = "deploy"
)

switch ($Command) {
    "deploy" {
        Start-Deployment
    }
    "start" {
        Write-Header "Starting services"
        docker-compose -f docker-compose-release.yml up -d
        Write-Success "Services started"
    }
    "stop" {
        Write-Header "Stopping services"
        docker-compose -f docker-compose-release.yml down
        Write-Success "Services stopped"
    }
    "restart" {
        Write-Header "Restarting services"
        docker-compose -f docker-compose-release.yml restart
        Write-Success "Services restarted"
    }
    "status" {
        Show-Status
    }
    "logs" {
        docker-compose -f docker-compose-release.yml logs -f
    }
    "clean" {
        Write-Warning "This will remove all containers and volumes!"
        $response = Read-Host "Are you sure? (y/n)"
        if ($response -match "^[Yy]$") {
            docker-compose -f docker-compose-release.yml down -v
            Write-Success "Cleaned up containers and volumes"
        }
    }
    "initdb" {
        if (Initialize-Database) {
            Write-Success "Database initialization complete!"
        }
        else {
            Write-Error "Database initialization failed"
            exit 1
        }
    }
    default {
        Write-Host "Usage: .\start-release.ps1 [deploy|start|stop|restart|status|logs|clean|initdb]"
        Write-Host ""
        Write-Host "Commands:"
        Write-Host "  deploy  - Full deployment (default)"
        Write-Host "  start   - Start services"
        Write-Host "  stop    - Stop services"
        Write-Host "  restart - Restart services"
        Write-Host "  status  - Show service status"
        Write-Host "  logs    - Show and follow logs"
        Write-Host "  clean   - Remove containers and volumes"
        Write-Host "  initdb  - Initialize database manually"
    }
}
