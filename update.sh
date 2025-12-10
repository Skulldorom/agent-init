#!/bin/bash

# Exit on any error
set -e

echo "======================================"
echo "TechToday Agent Update Script"
echo "======================================"

PROJECT_DIR="/opt/techtoday-agent"
REPO_URL="https://github.com/Skulldorom/agent-init"
REPO_BRANCH="main"

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

# Download repository files
TEMP_DIR=$(mktemp -d)
if curl -fsSL "${REPO_URL}/archive/refs/heads/${REPO_BRANCH}.tar.gz" | tar -xz -C "$TEMP_DIR" --strip-components=1; then
    echo "✓ Repository files downloaded"
    
    # Copy necessary files to project directory
    cp "$TEMP_DIR/docker-compose.yml" "$PROJECT_DIR/"
    cp "$TEMP_DIR/nginx.conf" "$PROJECT_DIR/"
    
    # Clean up temp directory
    rm -rf "$TEMP_DIR"
else
    echo "✗ Error: Could not download repository from $REPO_URL"
    rm -rf "$TEMP_DIR"
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
