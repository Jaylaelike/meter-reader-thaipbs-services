#!/bin/bash

# MQTT Broker Configuration
BROKER_HOST="172.16.202.63"
BROKER_PORT="1883"
USERNAME="admin"
PASSWORD="public"
TOPIC="sensor/3phase10"

# Function to generate random float with decimal places
random_float() {
  local base=$1
  local range=$2
  local decimals=$3
  local result=$(echo "scale=$decimals; $base + ($RANDOM % $(echo "$range * (10^$decimals)" | bc)) / (10^$decimals)" | bc)
  # Ensure leading zero for values < 1
  if [[ $result == .* ]]; then
    result="0$result"
  fi
  echo "$result"
}

# Publish message to MQTT broker every 5 seconds
echo "Publishing to $TOPIC every 5 seconds. Press Ctrl+C to stop."
echo "Broker: $BROKER_HOST:$BROKER_PORT"
echo "-----------------------------------"

while true; do
  # Generate random voltage values (230-236V)
  V1=$(random_float 230 6 1)
  V2=$(random_float 233 3 1)
  V3=$(random_float 229 4 1)
  
  # Generate random 3-phase voltage values (398-407V)
  V3P1=$(random_float 403 5 1)
  V3P2=$(random_float 401 5 1)
  V3P3=$(random_float 396 5 1)
  
  # Generate random current values (59-75A)
  C1=$(random_float 70 6 2)
  C2=$(random_float 66 6 2)
  C3=$(random_float 58 6 2)
  
  # Generate random frequency (49.90-50.05Hz)
  FREQ=$(random_float 49.90 0.15 2)
  
  # Generate random power factor total (0.990-0.999)
  PFT=$(random_float 0.990 0.009 3)
  
  # Generate random power factor per phase (0.990-0.999)
  PF1=$(random_float 0.990 0.009 3)
  PF2=$(random_float 0.992 0.007 3)
  PF3=$(random_float 0.995 0.005 3)
  
  # Get current timestamp in ISO 8601 format
  TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")
  
  # Construct JSON message
  MESSAGE="{\"load\":{\"voltage\":[$V1,$V2,$V3],\"voltage_3phase\":[$V3P1,$V3P2,$V3P3],\"current\":[$C1,$C2,$C3],\"frequency\":$FREQ,\"pfT\":$PFT,\"pf\":[$PF1,$PF2,$PF3]},\"timestamp\":\"$TIMESTAMP\"}"
  
  # Publish to MQTT broker with authentication
  mosquitto_pub -h "$BROKER_HOST" -p "$BROKER_PORT" -u "$USERNAME" -P "$PASSWORD" -t "$TOPIC" -m "$MESSAGE"
  
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Published"
  echo "Data: $MESSAGE"
  echo ""
  
  sleep 5
done