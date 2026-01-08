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

    Write-Host ""
    Write-Header "Deployment Complete!"

    Show-Status
    Show-AccessInfo
    Show-Commands

    Write-Success "🎉 Power Monitor is now running!"
}

# Main script logic
param(
    [Parameter(Position=0)]
    [ValidateSet("deploy", "start", "stop", "restart", "status", "logs", "clean")]
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
    default {
        Write-Host "Usage: .\start-release.ps1 [deploy|start|stop|restart|status|logs|clean]"
        Write-Host ""
        Write-Host "Commands:"
        Write-Host "  deploy  - Full deployment (default)"
        Write-Host "  start   - Start services"
        Write-Host "  stop    - Stop services"
        Write-Host "  restart - Restart services"
        Write-Host "  status  - Show service status"
        Write-Host "  logs    - Show and follow logs"
        Write-Host "  clean   - Remove containers and volumes"
    }
}
