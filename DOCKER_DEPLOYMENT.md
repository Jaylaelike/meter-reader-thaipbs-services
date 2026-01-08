# Docker Deployment Guide

This guide explains how to deploy the Power Monitor project using Docker Compose.

## Prerequisites

- Docker Engine 20.10 or higher
- Docker Compose 1.29 or higher
- Access to MQTT broker (default: 172.16.202.63)

## Project Structure

```
project-meter-thaipbs/
├── backend/                    # Node.js MQTT-to-DB service
│   ├── Dockerfile
│   └── ...
├── frontend/                   # PHP web dashboard
│   ├── Dockerfile
│   └── ...
├── docker-compose.yml          # Development setup (MySQL + phpMyAdmin only)
├── docker-compose-release.yml  # Production setup (Full stack)
└── init_database.sh            # Database initialization script
```

## Quick Start

### 1. Clone and Navigate to Project

```bash
cd project-meter-thaipbs
```

### 2. Configure Environment Variables (Optional)

Copy the example environment file and modify as needed:

```bash
cp .env.example .env
```

Edit `.env` to customize:
- Database credentials
- MQTT broker connection details
- Port mappings

### 3. Start All Services

```bash
docker-compose -f docker-compose-release.yml up -d
```

This will start:
- **MySQL Database** (port 3306)
- **Backend Service** (Node.js MQTT processor)
- **Frontend Dashboard** (port 80)
- **phpMyAdmin** (port 8080)

### 4. Verify Services are Running

```bash
docker-compose -f docker-compose-release.yml ps
```

Expected output:
```
NAME                          STATUS
power_monitor_mysql           Up (healthy)
power_monitor_backend         Up
power_monitor_frontend        Up
power_monitor_phpmyadmin      Up
```

### 5. Access the Application

- **Dashboard**: http://localhost
- **phpMyAdmin**: http://localhost:8080
  - Username: `root`
  - Password: `thaipbs`

## Service Details

### MySQL Database
- **Container**: `power_monitor_mysql`
- **Port**: 3306
- **Database**: `power_monitor`
- **Root Password**: `thaipbs`
- **Data Persistence**: Volume `mysql_data`

### Backend Service
- **Container**: `power_monitor_backend`
- **Function**: Connects to MQTT broker and stores data in MySQL
- **Auto-restart**: Yes
- **Dependencies**: Waits for MySQL to be healthy

### Frontend Service
- **Container**: `power_monitor_frontend`
- **Port**: 80
- **Technology**: PHP 8.1 + Apache
- **Function**: Web dashboard for power monitoring

### phpMyAdmin
- **Container**: `power_monitor_phpmyadmin`
- **Port**: 8080
- **Function**: Database management interface

## Configuration

### Backend Configuration

The backend needs to connect to both MySQL and MQTT broker. Update these files if needed:

1. **Database Connection**: `backend/mqtt-to-db.js`
   - Default host: `localhost` → Change to `mysql` for Docker
   - Database: `power_monitor`

2. **MQTT Connection**: `backend/mqtt-to-db.js`
   - Default broker: `172.16.202.63`
   - Update in docker-compose-release.yml if different

### Frontend Configuration

The frontend PHP files connect to MySQL. Update these files if needed:

1. **Dashboard API**: `frontend/Dashboard.php`
   - Host: `127.0.0.1` → Change to `mysql` for Docker

2. **Monthly Cost API**: `frontend/MonthlyCost.php`
   - Host: `127.0.0.1` → Change to `mysql` for Docker

**Note**: To make the application work properly in Docker, you need to update the database host from `localhost`/`127.0.0.1` to `mysql` in both backend and frontend files.

## Database Initialization

The database schema will be automatically created when you run the `init_database.sh` script. If the database is not initialized:

```bash
# Enter MySQL container
docker exec -it power_monitor_mysql bash

# Run initialization script
mysql -u root -pthaipbs power_monitor < /docker-entrypoint-initdb.d/init_database.sh
```

Or connect via phpMyAdmin and import the schema manually.

## Common Commands

### Start Services
```bash
docker-compose -f docker-compose-release.yml up -d
```

### Stop Services
```bash
docker-compose -f docker-compose-release.yml down
```

### Stop and Remove Volumes (Clean Slate)
```bash
docker-compose -f docker-compose-release.yml down -v
```

### View Logs
```bash
# All services
docker-compose -f docker-compose-release.yml logs -f

# Specific service
docker-compose -f docker-compose-release.yml logs -f backend
docker-compose -f docker-compose-release.yml logs -f frontend
docker-compose -f docker-compose-release.yml logs -f mysql
```

### Restart a Service
```bash
docker-compose -f docker-compose-release.yml restart backend
```

### Rebuild After Code Changes
```bash
docker-compose -f docker-compose-release.yml up -d --build
```

### Execute Commands in Containers
```bash
# Backend (Node.js)
docker exec -it power_monitor_backend sh

# Frontend (PHP/Apache)
docker exec -it power_monitor_frontend bash

# MySQL
docker exec -it power_monitor_mysql mysql -u root -pthaipbs power_monitor
```

## Troubleshooting

### Backend Not Connecting to Database

1. Check if MySQL is healthy:
   ```bash
   docker-compose -f docker-compose-release.yml ps
   ```

2. View backend logs:
   ```bash
   docker-compose -f docker-compose-release.yml logs backend
   ```

3. Ensure database host is set to `mysql` (not `localhost`)

### Frontend Shows Database Connection Error

1. Update `frontend/Dashboard.php` and `frontend/MonthlyCost.php`:
   - Change host from `127.0.0.1` to `mysql`

2. Rebuild frontend:
   ```bash
   docker-compose -f docker-compose-release.yml up -d --build frontend
   ```

### MQTT Connection Issues

1. Check if MQTT broker is accessible from Docker network
2. Update MQTT_HOST in docker-compose-release.yml
3. Verify firewall rules allow connection to MQTT broker

### Port Already in Use

If ports 80, 3306, or 8080 are already in use:

1. Edit `docker-compose-release.yml`
2. Change port mappings:
   ```yaml
   ports:
     - "8000:80"  # Frontend on port 8000 instead of 80
   ```

### Database Data Persistence

Data is stored in Docker volume `mysql_data`. To backup:

```bash
docker exec power_monitor_mysql mysqldump -u root -pthaipbs power_monitor > backup.sql
```

To restore:
```bash
docker exec -i power_monitor_mysql mysql -u root -pthaipbs power_monitor < backup.sql
```

## Production Deployment

### Security Recommendations

1. **Change Default Passwords**:
   - Update MySQL root password
   - Update MQTT credentials
   - Use `.env` file for sensitive data

2. **Disable phpMyAdmin in Production**:
   ```bash
   # Edit docker-compose-release.yml and remove phpmyadmin service
   ```

3. **Use Secrets Management**:
   - Use Docker secrets for production
   - Don't commit `.env` file to version control

4. **Network Isolation**:
   - Remove port mapping for MySQL (3306) if not needed externally
   - Use reverse proxy (nginx) for SSL/TLS

5. **Resource Limits**:
   Add resource limits to services:
   ```yaml
   deploy:
     resources:
       limits:
         cpus: '0.5'
         memory: 512M
   ```

### Monitoring

Monitor container health and logs:

```bash
# Check container stats
docker stats

# Monitor logs in real-time
docker-compose -f docker-compose-release.yml logs -f --tail=100
```

## Scaling

To scale the backend service (if handling multiple device groups):

```bash
docker-compose -f docker-compose-release.yml up -d --scale backend=3
```

## Development vs Production

- **docker-compose.yml**: Development setup (database only)
- **docker-compose-release.yml**: Production setup (full stack)

Use development setup when running backend/frontend locally:
```bash
docker-compose up -d  # Only MySQL and phpMyAdmin
```

## Support

For issues or questions:
1. Check logs: `docker-compose -f docker-compose-release.yml logs`
2. Verify network connectivity between services
3. Ensure all environment variables are correctly set
4. Review the application code for hardcoded `localhost` references

## Updates and Maintenance

### Update Application Code

```bash
# Pull latest code
git pull

# Rebuild and restart
docker-compose -f docker-compose-release.yml up -d --build
```

### Update Docker Images

```bash
# Pull latest base images
docker-compose -f docker-compose-release.yml pull

# Rebuild with new base images
docker-compose -f docker-compose-release.yml up -d --build
```

### Backup Strategy

1. **Database Backup** (Daily):
   ```bash
   docker exec power_monitor_mysql mysqldump -u root -pthaipbs power_monitor | gzip > backup-$(date +%Y%m%d).sql.gz
   ```

2. **Configuration Backup**:
   - Backup `.env` file
   - Backup `docker-compose-release.yml`
   - Backup any custom configuration files

## License

Refer to project's main LICENSE file.