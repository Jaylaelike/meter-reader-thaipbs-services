# Node-RED Power Monitor Gateway

This Node-RED server acts as a gateway between Modbus TCP power meters and MQTT broker.

## Features

- **Modbus TCP Client**: Reads data from power meters
- **MQTT Publisher**: Publishes formatted data to MQTT broker
- **Real-time Processing**: 5-second data collection interval
- **Web Dashboard**: Node-RED editor and dashboard UI
- **Docker Support**: Containerized deployment

## Configuration

### Environment Variables (.env)
```bash
# Modbus Configuration
MODBUS_HOST=10.6.1.226
MODBUS_PORT=502
MODBUS_UNIT_ID=2

# MQTT Configuration  
MQTT_BROKER=172.16.202.63
MQTT_PORT=1883
MQTT_USERNAME=admin
MQTT_PASSWORD=public
MQTT_TOPIC=sensor/3phase10
```

### Data Flow

1. **Modbus Read**: Reads voltage, current, frequency, and power factor
2. **Data Processing**: Converts raw Modbus data to engineering units
3. **MQTT Publish**: Publishes JSON payload every 5 seconds

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
  },
  "timestamp": "2026-01-08T04:15:30.123Z"
}
```

## Deployment

### Docker Compose
```bash
cd nodered
docker-compose up -d --build
```

### Access Points
- **Node-RED Editor**: http://localhost:1880/admin
- **Dashboard**: http://localhost:1880/ui
- **API**: http://localhost:1880/api

### Default Credentials
- **Username**: admin
- **Password**: admin123

## Modbus Register Map

| Register | Address | Quantity | Description | Scale |
|----------|---------|----------|-------------|-------|
| 0x5B02   | 23298   | 20       | Voltage + Current | 0.1 / 0.01 |
| 0x5B32   | 23346   | 1        | Frequency | 0.01 |
| 0x5B40   | 23360   | 4        | Power Factor | 0.001 |

## Troubleshooting

### Check Logs
```bash
docker-compose logs -f node-red
```

### Modbus Connection Issues
1. Verify Modbus TCP host IP and port
2. Check unit ID configuration
3. Ensure network connectivity

### MQTT Connection Issues
1. Verify MQTT broker IP and port
2. Check credentials (username/password)
3. Test with MQTT client tools

## Development

### Local Development
```bash
npm install
npm run dev
```

### Flow Export/Import
Flows are stored in `flows.json` and automatically loaded on startup.