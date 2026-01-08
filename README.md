# Power Monitor Thai PBS

![Meter Reader Dashboard](https://56fwnhyzti.ufs.sh/f/aK4w8mNL3AiPER8pfk9WON2pJKgdI63ReTV9fSa7PvqDr8An)

## Overview

Power Monitor Thai PBS is an IoT-based energy monitoring system that collects real-time power data from 3-phase meters via MQTT protocol and stores it in MySQL database for visualization and analysis.

![Systems Diagram](https://56fwnhyzti.ufs.sh/f/aK4w8mNL3AiPbirbh62pYTMgVenQFZajfRIEm9A73kXGlq6y)

## Features

- Real-time 3-phase power monitoring (Voltage, Current, Power Factor, Frequency)
- MQTT data collection from IoT sensors
- MySQL database storage with time-series optimization
- Web dashboard for energy visualization
- Carbon footprint calculation
- Node-RED integration for Modbus TCP gateway
- Docker containerized deployment

## Technology Stack

| Component | Technology |
|-----------|------------|
| Backend | Node.js + MQTT.js + MySQL2 |
| Frontend | PHP 8.1 + Apache + JavaScript |
| Database | MySQL 8.0 |
| MQTT Broker | External (172.16.202.63:1883) |
| Gateway | Node-RED (Modbus TCP → MQTT) |
| Container | Docker & Docker Compose |

## Prerequisites

- Docker 20.10+
- Docker Compose 2.0+
- Git

## Quick Start

```bash
# Clone repository
git clone https://github.com/Jaylaelike/meter-reader-thaipbs-services.git
cd meter-reader-thaipbs-services

# Start all services
docker-compose up -d --build

# Verify services
docker-compose ps
```

## Services

| Service | Container | URL | Port |
|---------|-----------|-----|------|
| Frontend Dashboard | power_frontend | http://localhost | 80 |
| phpMyAdmin | power_phpmyadmin | http://localhost:8080 | 8080 |
| MySQL Database | power_mysql | localhost:3306 | 3306 |
| Backend (MQTT→MySQL) | power_backend | - | - |
| Node-RED (Optional) | nodered_server | http://localhost:1880 | 1880 |

## Project Structure

```
project-meter-thaipbs/
├── backend/
│   ├── Dockerfile
│   ├── mqtt_to_mysql.js      # MQTT subscriber → MySQL
│   ├── package.json
│   └── .dockerignore
├── frontend/
│   ├── Dockerfile
│   ├── index.html            # Dashboard UI
│   ├── newdash.js            # Dashboard logic
│   ├── newdash.css           # Styles
│   ├── energy_daily.php      # Energy API
│   ├── kwh_daily_fast.php    # kWh calculation API
│   ├── db_ping.php           # Database health check
│   └── mqtt.min.js           # MQTT client library
├── nodered/
│   ├── Dockerfile
│   ├── docker-compose.yml
│   ├── flows.json            # Modbus → MQTT flow
│   └── settings.js
├── docker-compose.yml        # Main orchestration
├── init.sql                  # Database schema
├── .env                      # Environment config
└── README.md
```

## Configuration

### Environment Variables (.env)

```env
# Database
MYSQL_ROOT_PASSWORD=thaipbs
DB_NAME=power_real_a_1
DB_HOST=mysql
DB_USER=root
DB_PASSWORD=thaipbs

# MQTT Broker
MQTT_HOST=172.16.202.63
MQTT_PORT=1883
MQTT_USER=admin
MQTT_PASSWORD=public
MQTT_TOPICS=sensor/3phase10

# Ports
FRONTEND_PORT=80
PHPMYADMIN_PORT=8080
MYSQL_PORT=3306
```

### MQTT Payload Format

```json
{
  "load": {
    "voltage": [220.1, 221.2, 219.8],
    "voltage_3phase": [380.5, 381.2, 379.9],
    "current": [15.25, 14.87, 15.12],
    "frequency": 50.02,
    "pfT": 0.850,
    "pf": [0.845, 0.852, 0.848]
  }
}
```

## Database Schema

Database: `power_real_a_1`

| Table | Description |
|-------|-------------|
| full_history | Raw sensor data (voltage, current, PF, frequency) |
| summary_minute | Aggregated data per minute |
| summary_hourly | Aggregated data per hour |
| summary_daily | Aggregated data per day |
| summary_monthly | Aggregated data per month |
| summary_yearly | Aggregated data per year |
| event_timeline | Power events log |
| event_summary_* | Event aggregations |

## Database Backup & Restore

### Check Database Status

```bash
# List Docker volumes
docker volume ls | grep mysql_data

# Show all databases
docker exec power_mysql mysql -u root -pthaipbs -e "SHOW DATABASES;"

# Show tables in power_real_a_1
docker exec power_mysql mysql -u root -pthaipbs -e "USE power_real_a_1; SHOW TABLES;"

# Check row count
docker exec power_mysql mysql -u root -pthaipbs -e "SELECT COUNT(*) FROM power_real_a_1.full_history;"
```

### Backup Database

```bash
# Full database backup
docker exec power_mysql mysqldump -u root -pthaipbs power_real_a_1 > backup.sql

# Backup with timestamp
docker exec power_mysql mysqldump -u root -pthaipbs power_real_a_1 > backup_$(date +%Y%m%d_%H%M%S).sql

# Backup specific table
docker exec power_mysql mysqldump -u root -pthaipbs power_real_a_1 full_history > full_history_backup.sql

# Compressed backup
docker exec power_mysql mysqldump -u root -pthaipbs power_real_a_1 | gzip > backup_$(date +%Y%m%d).sql.gz
```

### Restore Database

```bash
# Restore from backup file
docker exec -i power_mysql mysql -u root -pthaipbs power_real_a_1 < backup.sql

# Restore from compressed backup
gunzip < backup_20260108.sql.gz | docker exec -i power_mysql mysql -u root -pthaipbs power_real_a_1

# Restore specific table
docker exec -i power_mysql mysql -u root -pthaipbs power_real_a_1 < full_history_backup.sql
```

### Automated Backup Script

Create `backup.sh`:

```bash
#!/bin/bash
BACKUP_DIR="./backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/power_real_a_1_$TIMESTAMP.sql.gz"

mkdir -p $BACKUP_DIR
docker exec power_mysql mysqldump -u root -pthaipbs power_real_a_1 | gzip > $BACKUP_FILE

# Keep only last 7 days
find $BACKUP_DIR -name "*.sql.gz" -mtime +7 -delete

echo "Backup completed: $BACKUP_FILE"
```

### Volume Backup

```bash
# Backup entire MySQL volume
docker run --rm -v project-meter-thaipbs_mysql_data:/data -v $(pwd):/backup alpine tar czf /backup/mysql_volume_backup.tar.gz /data

# Restore volume
docker run --rm -v project-meter-thaipbs_mysql_data:/data -v $(pwd):/backup alpine tar xzf /backup/mysql_volume_backup.tar.gz -C /
```

## Node-RED Gateway (Optional)

For Modbus TCP power meters, use Node-RED as gateway:

```bash
# Start Node-RED
docker-compose -f nodered/docker-compose.yml up -d --build

# Access Node-RED Editor
open http://localhost:1880/admin

# Default login: admin / admin123
```

Node-RED reads Modbus registers and publishes to MQTT topic `sensor/3phase10`.

## Commands Reference

### Service Management

```bash
# Start all services
docker-compose up -d --build

# Stop all services
docker-compose down

# View logs
docker-compose logs -f
docker-compose logs -f backend

# Restart specific service
docker-compose restart backend

# Check status
docker-compose ps
```

## Feed sensor-node simulator mqtt for Testing

For Modbus TCP power meters (simulator) for testing:

```bash
# Start shell script
./feed_test_sensor_mqtt.sh

```

### Database Access

```bash
# MySQL CLI
docker exec -it power_mysql mysql -u root -pthaipbs power_real_a_1

# phpMyAdmin
open http://localhost:8080
```

### Monitoring

```bash
# Backend logs
docker logs -f power_backend

# Check MQTT connection
docker logs power_backend | grep MQTT

# Check database inserts
docker logs power_backend | grep "Insert OK"
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Services won't start | `docker-compose down -v && docker-compose up -d --build` |
| Backend can't connect to MySQL | Wait for MySQL health check, verify credentials |
| MQTT connection failed | Check MQTT broker IP/port, verify credentials |
| No data in dashboard | Check backend logs, verify MQTT messages |
| Port already in use | Change port in `.env` or stop conflicting service |

### View Logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f backend
docker-compose logs -f mysql
docker-compose logs -f frontend
```

### Reset Everything

```bash
# Stop and remove all containers, volumes, networks
docker-compose down -v

# Rebuild from scratch
docker-compose up -d --build
```

## API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/energy_daily.php?device_id=sensor/3phase10` | GET | Daily energy consumption |
| `/kwh_daily_fast.php?device_id=sensor/3phase10` | GET | Fast kWh calculation |
| `/db_ping.php` | GET | Database health check |

## License

MIT License - see [LICENSE](LICENSE) file.

## Support

- **Issues**: [GitHub Issues](https://github.com/Jaylaelike/meter-reader-thaipbs-services/issues)
- **Email**: support@thaipbs.or.th

---

**Made with ❤️ by Thai PBS Development Team**
