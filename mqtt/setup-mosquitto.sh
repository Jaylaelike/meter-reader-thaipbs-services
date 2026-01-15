#!/bin/bash

# Create necessary directories
mkdir -p data log

# Stop the container if running
docker-compose down

# Create password file with admin:public credentials
docker run --rm -v $(pwd)/config/mosquitto:/mosquitto/config eclipse-mosquitto:latest mosquitto_passwd -c -b /mosquitto/config/password.txt admin public

# Start the container
docker-compose up -d

echo ""
echo "Mosquitto setup complete!"
echo "Username: admin"
echo "Password: public"
echo "MQTT Port: 1883"
echo "WebSocket Port: 8083"
