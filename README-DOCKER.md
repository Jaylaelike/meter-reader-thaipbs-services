# Docker Deployment Files - Power Monitor Project

This document describes all Docker-related files created for the Power Monitor project.

## 📁 Files Overview

### Core Docker Files

#### 1. `docker-compose-release.yml`
**Purpose**: Production-ready Docker Compose configuration for the full stack.

**Services Included**:
- **MySQL 8.0**: Database server with health checks
- **Backend**: Node.js application for MQTT data processing
- **Frontend**: PHP/Apache web server for dashboard
- **phpMyAdmin**: Database management interface (optional)

**Features**:
- Environment variable support via `.env` file
- Health checks for service dependencies
- Persistent data volumes
- Log rotation
- Automatic restart policies
- Custom network isolation

**Usage**:
```bash
docker-compose -f docker-compose-release.yml up -d
```

---

#### 2. `backend/Dockerfile`
**Purpose**: Containerizes the Node.js MQTT processor.

**Base Image**: `node:18-alpine`

**What it does**:
- Installs Node.js dependencies
- Copies application code
- Starts the MQTT-to-database worker processes

**Build**:
```bash
cd backend
docker build -t power_monitor_backend .
```

---

#### 3. `frontend/Dockerfile`
**Purpose**: Containerizes the PHP web dashboard.

**Base Image**: `php:8.1-apache`

**What it does**:
- Installs PDO MySQL extensions
- Configures Apache web server
- Copies frontend files to web root
- Sets proper permissions

**Build**:
```bash
cd frontend
docker build -t power_monitor_frontend .
```

---

#### 4. `backend/.dockerignore`
**Purpose**: Excludes unnecessary files from Docker build context.

**Excludes**:
- `node_modules` (will be installed fresh)
- `.git` and `.gitignore`
- Documentation files
- Environment files
- Dockerfile itself

---

### Configuration Files

#### 5. `.env.example`
**Purpose**: Template for environment configuration.

**Contains**:
- Database credentials
- MQTT broker connection details
- Port mappings
- Application settings

**Setup**:
```bash
cp .env.example .env
# Edit .env with your values
```

**Key Variables**:
```env
MYSQL_ROOT_PASSWORD=thaipbs
MYSQL_DATABASE=power_monitor
MQTT_HOST=172.16.202.63
MQTT_USER=admin
MQTT_PASSWORD=public
FRONTEND_PORT=80
PHPMYADMIN_PORT=8080
```

---

### Deployment Scripts

#### 6. `start-release.sh` (Linux/Mac)
**Purpose**: Automated deployment script with interactive prompts.

**Features**:
- Pre-flight checks (Docker, Docker Compose)
- Environment file validation
- Service health monitoring
- Colored output and progress indicators
- Access information display
- Useful command suggestions

**Commands**:
```bash
./start-release.sh deploy   # Full deployment
./start-release.sh start    # Start services
./start-release.sh stop     # Stop services
./start-release.sh restart  # Restart services
./start-release.sh status   # Show status
./start-release.sh logs     # View logs
./start-release.sh clean    # Complete cleanup
```

**Permissions**:
```bash
chmod +x start-release.sh
```

---

#### 7. `start-release.ps1` (Windows)
**Purpose**: PowerShell version of deployment script for Windows users.

**Features**:
- Same functionality as bash version
- Windows-compatible commands
- Docker Desktop integration
- Color-coded output
- Interactive confirmations

**Usage**:
```powershell
.\start-release.ps1 deploy
```

---

### Documentation Files

#### 8. `DOCKER_DEPLOYMENT.md`
**Purpose**: Comprehensive deployment documentation.

**Contents**:
- Detailed setup instructions
- Service configuration guides
- Troubleshooting section
- Security recommendations
- Backup and maintenance procedures
- Production deployment checklist
- Command reference

**Sections**:
- Quick Start
- Service Details
- Configuration
- Database Initialization
- Common Commands
- Troubleshooting
- Production Deployment
- Scaling
- Updates and Maintenance

---

#### 9. `QUICKSTART.md`
**Purpose**: Quick reference guide for fast deployment.

**Contents**:
- 5-minute setup guide
- Essential commands
- Common troubleshooting
- Verification checklist

**Ideal for**:
- First-time users
- Quick reference
- Testing deployments

---

#### 10. `README-DOCKER.md` (This File)
**Purpose**: Overview of all Docker-related files and their purposes.

---

## 🚀 Quick Deployment Guide

### Method 1: Automated (Recommended)

**Linux/Mac**:
```bash
./start-release.sh deploy
```

**Windows**:
```powershell
.\start-release.ps1 deploy
```

### Method 2: Manual

```bash
# 1. Setup environment
cp .env.example .env

# 2. Start services
docker-compose -f docker-compose-release.yml up -d

# 3. Check status
docker-compose -f docker-compose-release.yml ps
```

---

## 📊 Architecture

```
┌─────────────────────────────────────────────────┐
│                 Docker Network                  │
│                 (app_network)                   │
│                                                 │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐    │
│  │  MySQL   │  │ Backend  │  │ Frontend │    │
│  │  :3306   │◄─┤ Node.js  │  │ PHP/Apache│   │
│  │          │  │          │  │   :80     │    │
│  └────┬─────┘  └────▲─────┘  └────┬──────┘   │
│       │             │               │          │
│       │        ┌────┴──────┐        │          │
│       │        │   MQTT    │        │          │
│       │        │  Broker   │        │          │
│       │        └───────────┘        │          │
│       │                              │          │
│  ┌────▼─────────────────────────────▼──────┐  │
│  │          phpMyAdmin :8080               │  │
│  └─────────────────────────────────────────┘  │
└─────────────────────────────────────────────────┘
         │                          │
    MySQL Data                  External
    (Volume)                    Access
```

---

## 🔧 Configuration Requirements

### Before Deployment

You need to update database host references in the code:

#### Backend Files
- `backend/mqtt-to-db.js` line 33:
  ```javascript
  // Change from:
  host: 'localhost',
  // To:
  host: 'mysql',
  ```

#### Frontend Files
- `frontend/Dashboard.php` line 8:
  ```php
  // Change from:
  $conn = new PDO("mysql:host=127.0.0.1;...");
  // To:
  $conn = new PDO("mysql:host=mysql;...");
  ```

- `frontend/MonthlyCost.php` line 8:
  ```php
  // Change from:
  $host = "127.0.0.1";
  // To:
  $host = "mysql";
  ```

---

## 🔐 Security Considerations

### For Production:

1. **Change Default Passwords**:
   - Edit `.env` file
   - Set strong passwords for MySQL

2. **Remove phpMyAdmin**:
   - Comment out or remove phpMyAdmin service from `docker-compose-release.yml`

3. **Restrict MySQL Access**:
   - Remove external port mapping for MySQL:
     ```yaml
     # ports:
     #   - "3306:3306"
     ```

4. **Use Secrets**:
   - Use Docker secrets instead of environment variables
   - Don't commit `.env` to version control

5. **Add SSL/TLS**:
   - Use nginx reverse proxy with Let's Encrypt
   - Redirect HTTP to HTTPS

6. **Network Isolation**:
   - Use separate networks for different service tiers
   - Restrict inter-service communication

---

## 📦 Docker Images

| Service | Base Image | Size (approx) |
|---------|-----------|---------------|
| MySQL | mysql:8.0 | ~500 MB |
| Backend | node:18-alpine | ~150 MB |
| Frontend | php:8.1-apache | ~450 MB |
| phpMyAdmin | phpmyadmin:latest | ~130 MB |

**Total**: ~1.2 GB

---

## 💾 Data Persistence

### Volumes

- **mysql_data**: Stores all database data
  - Location: `/var/lib/docker/volumes/mysql_data`
  - Persists across container restarts
  - Survives `docker-compose down`
  - Removed only with `docker-compose down -v`

### Backup

```bash
# Database backup
docker exec power_monitor_mysql mysqldump -u root -pthaipbs power_monitor > backup.sql

# Volume backup
docker run --rm -v mysql_data:/data -v $(pwd):/backup alpine tar czf /backup/mysql_backup.tar.gz /data
```

### Restore

```bash
# Database restore
docker exec -i power_monitor_mysql mysql -u root -pthaipbs power_monitor < backup.sql
```

---

## 🔄 Update Process

### Application Updates

```bash
# 1. Pull latest code
git pull

# 2. Rebuild images
docker-compose -f docker-compose-release.yml build

# 3. Recreate containers
docker-compose -f docker-compose-release.yml up -d
```

### Base Image Updates

```bash
# 1. Pull latest base images
docker-compose -f docker-compose-release.yml pull

# 2. Rebuild
docker-compose -f docker-compose-release.yml up -d --build
```

---

## 🐛 Troubleshooting Quick Reference

| Issue | Solution |
|-------|----------|
| Port conflict | Change ports in `.env` |
| Container won't start | Check logs: `docker-compose -f docker-compose-release.yml logs [service]` |
| Database connection error | Verify host is `mysql` not `localhost` |
| MQTT not connecting | Check MQTT_HOST in `.env` |
| Permission denied | Run with sudo or add user to docker group |
| Out of disk space | Prune: `docker system prune -a` |

---

## 📚 Related Files

- `docker-compose.yml`: Development setup (MySQL + phpMyAdmin only)
- `init_database.sh`: Database initialization script
- `README.md`: Main project documentation

---

## 🎯 Best Practices

1. **Always use `.env` file** for configuration
2. **Don't hardcode** database hosts (use service names)
3. **Monitor logs** regularly
4. **Backup database** before major changes
5. **Use health checks** for critical services
6. **Set resource limits** in production
7. **Keep images updated** for security patches
8. **Use specific versions** (not `latest`) in production

---

## 📞 Support

For issues with Docker deployment:
1. Check the logs first
2. Review `DOCKER_DEPLOYMENT.md` for detailed troubleshooting
3. Verify Docker and Docker Compose versions
4. Ensure all prerequisites are met

---

## ✅ Deployment Checklist

- [ ] Docker and Docker Compose installed
- [ ] `.env` file created and configured
- [ ] Database hosts updated to `mysql` in code
- [ ] MQTT broker accessible
- [ ] Required ports available (80, 3306, 8080)
- [ ] Sufficient disk space (5GB+)
- [ ] Sufficient RAM (2GB+)
- [ ] Firewall rules configured
- [ ] Passwords changed from defaults (production)
- [ ] Backup strategy implemented (production)

---

## 📝 Summary

This Docker setup provides:
- ✅ Complete containerization of backend and frontend
- ✅ Easy one-command deployment
- ✅ Environment-based configuration
- ✅ Automated health checks
- ✅ Data persistence
- ✅ Production-ready defaults
- ✅ Comprehensive documentation
- ✅ Cross-platform support (Linux/Mac/Windows)

**Get started**: Run `./start-release.sh deploy` or see `QUICKSTART.md`
