#!/bin/bash

# Exit on any error
set -e

echo "======================================"
echo "TechToday Agent Update Script"
echo "======================================"

PROJECT_DIR="/opt/techtoday-agent"
DOCKER_COMPOSE_URL="https://raw.githubusercontent.com/Skulldorom/agent-init/refs/heads/main/docker-compose.yml"
NGINX_CONF_URL="https://raw.githubusercontent.com/Skulldorom/agent-init/refs/heads/main/nginx.conf"

# Check if project directory exists
if [ ! -d "$PROJECT_DIR" ]; then
    echo "✗ ERROR: Project directory $PROJECT_DIR not found"
    echo "Please run the init.sh script first to set up the project"
    exit 1
fi

echo ""
echo "[1/4] Stopping Docker services..."
cd "$PROJECT_DIR"
docker compose down
echo "✓ Docker services stopped"

echo ""
echo "[2/4] Downloading latest configuration files..."

# Download docker-compose.yml
echo "Downloading docker-compose.yml..."
if curl -fsSL "$DOCKER_COMPOSE_URL" -o "$PROJECT_DIR/docker-compose.yml"; then
    echo "✓ docker-compose.yml updated"
else
    echo "✗ Error: Could not download docker-compose.yml"
    exit 1
fi

# Download nginx.conf
echo "Downloading nginx.conf..."
if curl -fsSL "$NGINX_CONF_URL" -o "$PROJECT_DIR/nginx.conf"; then
    echo "✓ nginx.conf updated"
else
    echo "✗ Error: Could not download nginx.conf"
    exit 1
fi

echo ""
echo "[3/4] Pulling latest Docker images..."
docker compose pull
echo "✓ Docker images updated"

echo ""
echo "[4/4] Starting Docker services..."
docker compose up -d
echo "✓ Docker services started"

echo ""
echo "======================================"
echo "✓ Update Complete!"
echo "======================================"
echo ""
echo "Services have been updated and restarted"
echo ""
echo "Check status with:"
echo "   docker compose ps -a"
echo ""
echo "View logs with:"
echo "   docker compose logs -f"
echo ""
