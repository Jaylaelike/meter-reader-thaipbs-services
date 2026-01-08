#!/bin/bash

# Power Monitor Project - Release Deployment Script
# This script helps you deploy the full stack application

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print colored message
print_message() {
    color=$1
    message=$2
    echo -e "${color}${message}${NC}"
}

print_header() {
    echo ""
    print_message "$BLUE" "=================================="
    print_message "$BLUE" "$1"
    print_message "$BLUE" "=================================="
    echo ""
}

print_success() {
    print_message "$GREEN" "✓ $1"
}

print_error() {
    print_message "$RED" "✗ $1"
}

print_warning() {
    print_message "$YELLOW" "⚠ $1"
}

print_info() {
    print_message "$BLUE" "ℹ $1"
}

# Check if Docker is installed
check_docker() {
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    print_success "Docker is installed"
}

# Check if Docker Compose is installed
check_docker_compose() {
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        print_error "Docker Compose is not installed. Please install Docker Compose first."
        exit 1
    fi
    print_success "Docker Compose is installed"
}

# Check if .env file exists
check_env_file() {
    if [ ! -f .env ]; then
        print_warning ".env file not found. Creating from .env.example..."
        if [ -f .env.example ]; then
            cp .env.example .env
            print_success "Created .env file from .env.example"
            print_info "Please review and update .env file with your configuration"
            read -p "Press Enter to continue or Ctrl+C to exit and edit .env first..."
        else
            print_warning "No .env.example found. Using default values."
        fi
    else
        print_success ".env file exists"
    fi
}

# Stop and remove existing containers
cleanup() {
    print_header "Cleaning up existing containers"
    docker-compose -f docker-compose-release.yml down 2>/dev/null || true
    print_success "Cleanup completed"
}

# Build and start services
start_services() {
    print_header "Building and starting services"

    print_info "This may take a few minutes on first run..."
    docker-compose -f docker-compose-release.yml up -d --build

    print_success "Services started successfully"
}

# Wait for services to be healthy
wait_for_services() {
    print_header "Waiting for services to be ready"

    print_info "Waiting for MySQL to be healthy..."
    timeout=60
    counter=0

    while [ $counter -lt $timeout ]; do
        if docker-compose -f docker-compose-release.yml ps mysql | grep -q "healthy"; then
            print_success "MySQL is healthy"
            break
        fi
        echo -n "."
        sleep 2
        counter=$((counter + 2))
    done

    if [ $counter -ge $timeout ]; then
        print_error "MySQL failed to become healthy within ${timeout} seconds"
        print_info "Check logs with: docker-compose -f docker-compose-release.yml logs mysql"
        exit 1
    fi

    echo ""
    print_info "Waiting for other services to start..."
    sleep 5
    print_success "All services should be ready"
}

# Show service status
show_status() {
    print_header "Service Status"
    docker-compose -f docker-compose-release.yml ps
}

# Show access information
show_access_info() {
    print_header "Access Information"

    # Get ports from .env or use defaults
    FRONTEND_PORT=${FRONTEND_PORT:-80}
    PHPMYADMIN_PORT=${PHPMYADMIN_PORT:-8080}
    MYSQL_PORT=${MYSQL_PORT:-3306}

    echo ""
    print_success "Dashboard: http://localhost:${FRONTEND_PORT}"
    print_success "phpMyAdmin: http://localhost:${PHPMYADMIN_PORT}"
    print_info "MySQL Port: ${MYSQL_PORT}"
    echo ""

    print_info "Default MySQL Credentials:"
    echo "  Username: root"
    echo "  Password: thaipbs (change in .env file)"
    echo "  Database: power_monitor"
    echo ""
}

# Show useful commands
show_commands() {
    print_header "Useful Commands"

    echo "View logs (all services):"
    echo "  docker-compose -f docker-compose-release.yml logs -f"
    echo ""
    echo "View logs (specific service):"
    echo "  docker-compose -f docker-compose-release.yml logs -f backend"
    echo "  docker-compose -f docker-compose-release.yml logs -f frontend"
    echo "  docker-compose -f docker-compose-release.yml logs -f mysql"
    echo ""
    echo "Stop all services:"
    echo "  docker-compose -f docker-compose-release.yml down"
    echo ""
    echo "Restart a service:"
    echo "  docker-compose -f docker-compose-release.yml restart backend"
    echo ""
    echo "Rebuild after code changes:"
    echo "  docker-compose -f docker-compose-release.yml up -d --build"
    echo ""
}

# Main deployment function
deploy() {
    print_header "Power Monitor - Release Deployment"

    # Pre-flight checks
    check_docker
    check_docker_compose
    check_env_file

    # Ask for confirmation
    echo ""
    print_warning "This will stop any existing containers and start fresh."
    read -p "Do you want to continue? (y/n) " -n 1 -r
    echo ""

    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Deployment cancelled"
        exit 0
    fi

    # Deploy
    cleanup
    start_services
    wait_for_services

    echo ""
    print_header "Deployment Complete!"

    show_status
    show_access_info
    show_commands

    print_success "🎉 Power Monitor is now running!"
}

# Handle script arguments
case "${1:-deploy}" in
    deploy)
        deploy
        ;;
    start)
        print_header "Starting services"
        docker-compose -f docker-compose-release.yml up -d
        print_success "Services started"
        ;;
    stop)
        print_header "Stopping services"
        docker-compose -f docker-compose-release.yml down
        print_success "Services stopped"
        ;;
    restart)
        print_header "Restarting services"
        docker-compose -f docker-compose-release.yml restart
        print_success "Services restarted"
        ;;
    status)
        show_status
        ;;
    logs)
        docker-compose -f docker-compose-release.yml logs -f
        ;;
    clean)
        print_warning "This will remove all containers and volumes!"
        read -p "Are you sure? (y/n) " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            docker-compose -f docker-compose-release.yml down -v
            print_success "Cleaned up containers and volumes"
        fi
        ;;
    *)
        echo "Usage: $0 {deploy|start|stop|restart|status|logs|clean}"
        echo ""
        echo "Commands:"
        echo "  deploy  - Full deployment (default)"
        echo "  start   - Start services"
        echo "  stop    - Stop services"
        echo "  restart - Restart services"
        echo "  status  - Show service status"
        echo "  logs    - Show and follow logs"
        echo "  clean   - Remove containers and volumes"
        exit 1
        ;;
esac
