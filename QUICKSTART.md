# Quick Start Guide - Power Monitor Docker Deployment

Get up and running with Power Monitor in under 5 minutes!

## Prerequisites

- **Docker Desktop** (Windows/Mac) or **Docker Engine** (Linux)
- **Docker Compose** 1.29 or higher
- **2GB RAM** minimum
- **5GB disk space** for Docker images and volumes

## 🚀 Quick Deployment

### Option 1: Using the Automated Script (Recommended)

#### Linux/Mac:
```bash
cd project-meter-thaipbs
./start-release.sh deploy
```

#### Windows PowerShell:
```powershell
cd project-meter-thaipbs
.\start-release.ps1 deploy
```

### Option 2: Manual Deployment

```bash
cd project-meter-thaipbs

# Copy environment file (optional)
cp .env.example .env

# Start all services
docker-compose -f docker-compose-release.yml up -d

# Check status
docker-compose -f docker-compose-release.yml ps
```

## 📱 Access the Application

Once deployed, access:

- **Dashboard**: http://localhost
- **phpMyAdmin**: http://localhost:8080
  - Username: `root`
  - Password: `thaipbs`

## ⚙️ Configuration

### Before First Run

1. **Copy environment file**:
   ```bash
   cp .env.example .env
   ```

2. **Edit `.env` file** to customize:
   ```env
   # Database
   MYSQL_ROOT_PASSWORD=thaipbs
   MYSQL_DATABASE=power_monitor
   
   # MQTT Broker
   MQTT_HOST=172.16.202.63
   MQTT_USER=admin
   MQTT_PASSWORD=public
   
   # Ports
   FRONTEND_PORT=80
   PHPMYADMIN_PORT=8080
   MYSQL_PORT=3306
   ```

3. **Important**: Update the database host in PHP files:
   - `frontend/Dashboard.php`: Change `127.0.0.1` to `mysql`
   - `frontend/MonthlyCost.php`: Change `127.0.0.1` to `mysql`
   - `backend/mqtt-to-db.js`: Change `localhost` to `mysql`

## 🔧 Common Commands

### View Logs
```bash
# All services
docker-compose -f docker-compose-release.yml logs -f

# Specific service
docker-compose -f docker-compose-release.yml logs -f backend
docker-compose -f docker-compose-release.yml logs -f frontend
```

### Stop Services
```bash
docker-compose -f docker-compose-release.yml down
```

### Restart Services
```bash
docker-compose -f docker-compose-release.yml restart
```

### Rebuild After Changes
```bash
docker-compose -f docker-compose-release.yml up -d --build
```

## 🐛 Troubleshooting

### Port Already in Use
If port 80 or 8080 is already in use, edit `.env`:
```env
FRONTEND_PORT=8000
PHPMYADMIN_PORT=8081
```

### Database Connection Error
1. Ensure MySQL is healthy:
   ```bash
   docker-compose -f docker-compose-release.yml ps
   ```
2. Check MySQL logs:
   ```bash
   docker-compose -f docker-compose-release.yml logs mysql
   ```
3. Verify database host is set to `mysql` (not `localhost`)

### Backend Not Processing Data
1. Check MQTT broker is accessible
2. Verify MQTT credentials in `.env`
3. Check backend logs:
   ```bash
   docker-compose -f docker-compose-release.yml logs backend
   ```

### Container Won't Start
```bash
# Remove and recreate
docker-compose -f docker-compose-release.yml down -v
docker-compose -f docker-compose-release.yml up -d --build
```

## 📊 Verify Installation

1. **Check all containers are running**:
   ```bash
   docker-compose -f docker-compose-release.yml ps
   ```
   Should show:
   - `power_monitor_mysql` - healthy
   - `power_monitor_backend` - up
   - `power_monitor_frontend` - up
   - `power_monitor_phpmyadmin` - up

2. **Access Dashboard**: http://localhost
   - Should display the energy dashboard

3. **Check phpMyAdmin**: http://localhost:8080
   - Login and verify `power_monitor` database exists

4. **Verify Backend**: Check logs for MQTT connection
   ```bash
   docker-compose -f docker-compose-release.yml logs backend | grep -i connect
   ```

## 🛑 Stop and Clean Up

### Stop All Services
```bash
docker-compose -f docker-compose-release.yml down
```

### Complete Cleanup (Removes Data)
```bash
docker-compose -f docker-compose-release.yml down -v
```

## 🔄 Update Application

```bash
# Pull latest code
git pull

# Rebuild and restart
docker-compose -f docker-compose-release.yml up -d --build
```

## 📦 What Gets Installed?

| Service | Container Name | Port | Purpose |
|---------|---------------|------|---------|
| MySQL | power_monitor_mysql | 3306 | Database |
| Backend | power_monitor_backend | - | MQTT processor |
| Frontend | power_monitor_frontend | 80 | Web dashboard |
| phpMyAdmin | power_monitor_phpmyadmin | 8080 | DB management |

## 💾 Data Persistence

All database data is stored in Docker volume `mysql_data`:
```bash
# List volumes
docker volume ls | grep mysql_data

# Backup database
docker exec power_monitor_mysql mysqldump -u root -pthaipbs power_monitor > backup.sql

# Restore database
docker exec -i power_monitor_mysql mysql -u root -pthaipbs power_monitor < backup.sql
```

## 🔐 Security Notes

For **production** deployment:

1. Change default passwords in `.env`
2. Remove phpMyAdmin service from `docker-compose-release.yml`
3. Don't expose MySQL port externally (remove port mapping)
4. Use environment secrets instead of `.env` file
5. Set up SSL/TLS with reverse proxy (nginx)

## 📚 More Information

- **Full Documentation**: See `DOCKER_DEPLOYMENT.md`
- **Project Structure**: See main `README.md`
- **Issues**: Check logs with `docker-compose -f docker-compose-release.yml logs`

## 🎉 Success!

If everything is working:
- ✅ Dashboard shows at http://localhost
- ✅ Real-time power data is displayed
- ✅ Backend is processing MQTT messages
- ✅ Database is storing historical data

**Next Steps**:
1. Configure your MQTT broker details
2. Set up device groups in `backend/device-groups.js`
3. Customize dashboard settings
4. Set up automated backups

## Need Help?

1. Check the logs: `docker-compose -f docker-compose-release.yml logs`
2. Review `DOCKER_DEPLOYMENT.md` for detailed troubleshooting
3. Ensure Docker Desktop is running (Windows/Mac)
4. Verify firewall allows Docker network access