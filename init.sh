#!/bin/bash

# Exit on any error
set -e

# ====================================
# SECURITY TOKEN CHECK
# ====================================
EXPECTED_TOKEN="your-secret-token-here-change-this"

if [ "$1" != "$EXPECTED_TOKEN" ]; then
    echo "ERROR: Invalid or missing token"
    echo "Usage: curl -fsSL https://your-domain.com/setup.sh | bash -s YOUR_TOKEN"
    exit 1
fi

echo "======================================"
echo "Server Setup Script"
echo "======================================"

# ====================================
# CONFIGURATION - EDIT THESE
# ====================================
PUBLIC_KEY="ssh-rsa YOUR_PUBLIC_KEY_HERE user@hostname"

DOCKER_COMPOSE_CONTENT='version: "3.8"
services:
  app:
    image: nginx:latest
    ports:
      - "80:80"
    environment:
      - ENV_VAR_1=${ENV_VAR_1}
      - ENV_VAR_2=${ENV_VAR_2}
    restart: unless-stopped'

ENV_FILE_CONTENT='ENV_VAR_1=value1
ENV_VAR_2=value2'

PROJECT_DIR="$HOME/docker-app"

# ====================================
# 1. Install OpenSSH
# ====================================
echo ""
echo "[1/4] Installing OpenSSH..."

if command -v apt-get &> /dev/null; then
    # Debian/Ubuntu
    sudo apt-get update
    sudo apt-get install -y openssh-server
    sudo systemctl enable ssh
    sudo systemctl start ssh
elif command -v yum &> /dev/null; then
    # RHEL/CentOS
    sudo yum install -y openssh-server
    sudo systemctl enable sshd
    sudo systemctl start sshd
else
    echo "Unsupported package manager. Please install OpenSSH manually."
    exit 1
fi

echo "✓ OpenSSH installed and started"

# ====================================
# 2. Add Public Key
# ====================================
echo ""
echo "[2/4] Adding public key..."

mkdir -p ~/.ssh
chmod 700 ~/.ssh

if [ ! -f ~/.ssh/authorized_keys ]; then
    touch ~/.ssh/authorized_keys
fi

chmod 600 ~/.ssh/authorized_keys

# Add key if it doesn't already exist
if ! grep -q "$PUBLIC_KEY" ~/.ssh/authorized_keys 2>/dev/null; then
    echo "$PUBLIC_KEY" >> ~/.ssh/authorized_keys
    echo "✓ Public key added"
else
    echo "✓ Public key already exists"
fi

# ====================================
# 3. Install Docker
# ====================================
echo ""
echo "[3/4] Installing Docker..."

if command -v docker &> /dev/null; then
    echo "✓ Docker already installed ($(docker --version))"
else
    # Install Docker using official script
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    rm get-docker.sh
    
    # Add current user to docker group
    sudo usermod -aG docker $USER
    
    echo "✓ Docker installed"
fi

# Install Docker Compose plugin
if ! docker compose version &> /dev/null; then
    echo "Installing Docker Compose..."
    sudo apt-get update
    sudo apt-get install -y docker-compose-plugin
fi

echo "✓ Docker Compose ready ($(docker compose version))"

# ====================================
# 4. Setup Docker Compose
# ====================================
echo ""
echo "[4/4] Setting up Docker Compose..."

# Create project directory
mkdir -p "$PROJECT_DIR"

# Write docker-compose.yml
echo "$DOCKER_COMPOSE_CONTENT" > "$PROJECT_DIR/docker-compose.yml"
echo "✓ docker-compose.yml created"

# Write .env file
echo "$ENV_FILE_CONTENT" > "$PROJECT_DIR/.env"
echo "✓ .env file created"

# Start services
cd "$PROJECT_DIR"
docker compose up -d

echo "✓ Docker services started"

# ====================================
# Done
# ====================================
echo ""
echo "======================================"
echo "✓ Setup Complete!"
echo "======================================"
echo ""
echo "Next steps:"
echo "1. If this is your first time, log out and back in for Docker group changes to take effect"
echo "2. Your Docker services are running in: $PROJECT_DIR"
echo "3. Manage services with:"
echo "   - docker compose ps    (view status)"
echo "   - docker compose logs  (view logs)"
echo "   - docker compose down  (stop services)"
echo ""
