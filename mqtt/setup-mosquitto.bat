@echo off

REM Create necessary directories
if not exist "data" mkdir data
if not exist "log" mkdir log

REM Stop the container if running
docker-compose down

REM Create password file with admin:public credentials
docker run --rm -v %cd%/config/mosquitto:/mosquitto/config eclipse-mosquitto:latest mosquitto_passwd -c -b /mosquitto/config/password.txt admin public

REM Start the container
docker-compose up -d

echo.
echo Mosquitto setup complete!
echo Username: admin
echo Password: public
echo MQTT Port: 1883
echo WebSocket Port: 8083
