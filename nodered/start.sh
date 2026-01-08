#!/bin/bash

echo "=== Starting Node-RED Power Monitor Gateway ==="

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker first."
    exit 1
fi

# Load environment variables
if [ -f .env ]; then
    echo "📋 Loading environment variables from .env"
    export $(cat .env | grep -v '^#' | xargs)
else
    echo "⚠️  No .env file found, using defaults"
fi

# Stop existing containers
echo "🛑 Stopping existing containers..."
docker-compose down 2>/dev/null

# Build and start services
echo "🚀 Building and starting Node-RED server..."
docker-compose up -d --build

# Wait for services to be ready
echo "⏳ Waiting for Node-RED to start..."
sleep 10

# Check service status
echo "📊 Service Status:"
docker-compose ps

# Show logs
echo ""
echo "📝 Recent logs:"
docker-compose logs --tail 20

echo ""
echo "✅ Node-RED Power Monitor Gateway is running!"
echo ""
echo "🌐 Access Points:"
echo "   Node-RED Editor: http://localhost:1880/admin"
echo "   Dashboard:       http://localhost:1880/ui"
echo "   API:            http://localhost:1880/api"
echo ""
echo "🔐 Default Login:"
echo "   Username: admin"
echo "   Password: admin123"
echo ""
echo "📋 To view logs: docker-compose logs -f"
echo "🛑 To stop:      docker-compose down"