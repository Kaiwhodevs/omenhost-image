#!/bin/bash

# Discord-Style Authentication System - Production Startup Script

echo "🚀 Starting Discord-Style Authentication System (Production)..."

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker first."
    exit 1
fi

echo "📦 Building production image..."

# Build the production image
docker build -t discord-auth:latest .

echo "🐳 Starting production container..."

# Run the production container
docker run -d \
  --name discord-auth \
  -p 5000:5000 \
  -e SECRET_KEY="${SECRET_KEY:-your-secret-key-change-in-production}" \
  -e JWT_SECRET_KEY="${JWT_SECRET_KEY:-jwt-secret-key-change-in-production}" \
  -v discord-auth-data:/app/data \
  --restart unless-stopped \
  discord-auth:latest

echo "✅ Production service started successfully!"
echo ""
echo "🌐 Application: http://localhost:5000"
echo "📊 Health Check: http://localhost:5000/api/health"
echo ""
echo "To view logs: docker logs -f discord-auth"
echo "To stop: docker stop discord-auth"
echo "To remove: docker rm discord-auth"
