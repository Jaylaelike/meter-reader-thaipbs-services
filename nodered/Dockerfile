FROM nodered/node-red:latest

# Set timezone
ENV TZ=Asia/Bangkok

# Switch to root to install additional nodes
USER root

# Install additional Node-RED nodes
RUN npm install --unsafe-perm --no-update-notifier --no-fund --only=production \
    node-red-contrib-modbus \
    node-red-dashboard \
    node-red-contrib-ui-led \
    node-red-contrib-buffer-parser

# Switch back to node-red user
USER node-red

# Copy flows and settings
COPY --chown=node-red:node-red flows.json /data/flows.json
COPY --chown=node-red:node-red settings.js /data/settings.js

# Expose Node-RED port
EXPOSE 1880

# Start Node-RED
CMD ["npm", "start"]