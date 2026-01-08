FROM node:18-alpine

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm install --production

# Copy application files
COPY . .

# Set timezone
ENV TZ=Asia/Bangkok

# Start the MQTT to MySQL service
CMD ["node", "mqtt_to_mysql.js"]
