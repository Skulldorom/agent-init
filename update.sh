#!/bin/bash

# Exit on any error
set -e

echo "======================================"
echo "TechToday Agent Update Script"
echo "======================================"

PROJECT_DIR="/opt/techtoday-agent"
REPO_URL="https://github.com/Skulldorom/agent-init"
REPO_BRANCH="main"
UPDATE_SCRIPT_PATH="/usr/local/bin/update"

# Check if project directory exists
if [ ! -d "$PROJECT_DIR" ]; then
    echo "✗ ERROR: Project directory $PROJECT_DIR not found"
    echo "Please run the init.sh script first to set up the project"
    exit 1
fi

# Self-update check
echo ""
echo "[0/5] Checking for update script updates..."
TEMP_DIR=$(mktemp -d)
if curl -fsSL "${REPO_URL}/archive/refs/heads/${REPO_BRANCH}.tar.gz" | tar -xz -C "$TEMP_DIR" --strip-components=1; then
    if [ -f "$TEMP_DIR/update.sh" ]; then
        # Compare the downloaded update.sh with the current one
        if ! cmp -s "$TEMP_DIR/update.sh" "$UPDATE_SCRIPT_PATH"; then
            echo "✓ New version of update script found"
            echo "  Updating update script..."
            cp "$TEMP_DIR/update.sh" "$UPDATE_SCRIPT_PATH"
            chmod +x "$UPDATE_SCRIPT_PATH"
            echo "✓ Update script has been updated"
            rm -rf "$TEMP_DIR"
            echo "  Re-running updated script..."
            echo ""
            exec "$UPDATE_SCRIPT_PATH" "$@"
        else
            echo "✓ Update script is already up to date"
        fi
    fi
else
    echo "✗ Warning: Could not check for update script updates"
    echo "  Continuing with current version..."
fi

echo ""
echo "[1/5] Stopping Docker services..."
cd "$PROJECT_DIR"
docker compose down
echo "✓ Docker services stopped"

echo ""
echo "[2/5] Downloading latest configuration files..."

# Note: TEMP_DIR needs to be recreated here because if self-update occurred above,
# it was removed and this is a fresh process execution
if [ ! -d "$TEMP_DIR" ] || [ -z "$TEMP_DIR" ]; then
    TEMP_DIR=$(mktemp -d)
    if ! curl -fsSL "${REPO_URL}/archive/refs/heads/${REPO_BRANCH}.tar.gz" | tar -xz -C "$TEMP_DIR" --strip-components=1; then
        echo "✗ Error: Could not download repository from $REPO_URL"
        rm -rf "$TEMP_DIR"
        exit 1
    fi
fi

if [ -d "$TEMP_DIR" ]; then
    # Copy necessary files to project directory
    if [ -f "$TEMP_DIR/docker-compose.yml" ]; then
        cp "$TEMP_DIR/docker-compose.yml" "$PROJECT_DIR/"
        echo "✓ docker-compose.yml updated"
    else
        echo "✗ Error: docker-compose.yml not found in repository"
        rm -rf "$TEMP_DIR"
        exit 1
    fi
    
    if [ -f "$TEMP_DIR/nginx.conf" ]; then
        cp "$TEMP_DIR/nginx.conf" "$PROJECT_DIR/"
        echo "✓ nginx.conf updated"
    else
        echo "✗ Error: nginx.conf not found in repository"
        rm -rf "$TEMP_DIR"
        exit 1
    fi
    
    # Clean up temp directory
    rm -rf "$TEMP_DIR"
else
    echo "✗ Error: Could not download repository files"
    rm -rf "$TEMP_DIR"
    exit 1
fi

echo ""
echo "[3/5] Pulling latest Docker images..."
docker compose pull
echo "✓ Docker images updated"

echo ""
echo "[4/5] Cleaning up old Docker images..."
# Remove dangling images (untagged images)
PRUNE_OUTPUT=$(docker image prune -f 2>&1)
if echo "$PRUNE_OUTPUT" | grep -q "Total reclaimed space"; then
    SPACE=$(echo "$PRUNE_OUTPUT" | awk -F': ' '/Total reclaimed space/ {print $2}')
    echo "✓ Dangling images removed: $SPACE reclaimed"
else
    echo "✓ No dangling images to remove"
fi

# Remove unused images that are not associated with any container
# Using -a to remove all unused images, not just dangling ones
PRUNE_ALL_OUTPUT=$(docker image prune -a -f --filter "until=24h" 2>&1)
if echo "$PRUNE_ALL_OUTPUT" | grep -q "Total reclaimed space"; then
    SPACE_ALL=$(echo "$PRUNE_ALL_OUTPUT" | awk -F': ' '/Total reclaimed space/ {print $2}')
    echo "✓ Old unused images cleaned up: $SPACE_ALL reclaimed"
else
    echo "✓ No old images to clean up"
fi

echo ""
echo "[5/5] Starting Docker services..."
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
