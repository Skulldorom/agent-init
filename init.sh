#!/bin/bash

# Exit on any error
set -e


echo "======================================"
echo "Server Setup Script"
echo "======================================"

# ====================================
# LOAD ENVIRONMENT VARIABLES 
# ====================================
PROJECT_DIR="/docker-app"
ENV_FILE="$PROJECT_DIR/.env"

if [ ! -f "$ENV_FILE" ]; then
    echo ""
    echo "✗ ERROR: .env file not found at $ENV_FILE"
    echo ""
    echo "Please create your .env file first with all required variables:"
    echo "  mkdir -p $PROJECT_DIR"
    echo "  nano $ENV_FILE"
    echo ""
    echo "Required variables:"
    echo "  PUBLIC_KEY=ssh-rsa AAAA... user@host"
    echo "  DOCKER_COMPOSE_URL=https://raw.githubusercontent.com/..."
    echo "  GITHUB_PAT=ghp_your_token_here"
    echo "  GITHUB_USERNAME=your_username"
    echo ""
    echo "Add any other environment variables your app needs."
    echo ""
    exit 1
fi

echo "Loading environment variables from $ENV_FILE..."

# Load environment variables from .env
set -a  # automatically export all variables
source "$ENV_FILE"
set +a

echo "✓ Environment variables loaded"

# Verify required variables
if [ -z "$PUBLIC_KEY" ]; then
    echo "✗ ERROR: PUBLIC_KEY must be set in .env file"
    exit 1
fi

if [ -z "$DOCKER_COMPOSE_URL" ]; then
    echo "✗ ERROR: DOCKER_COMPOSE_URL must be set in .env file"
    exit 1
fi

if [ -z "$GITHUB_PAT" ] || [ -z "$GITHUB_USERNAME" ]; then
    echo "✗ ERROR: GITHUB_PAT and GITHUB_USERNAME must be set in .env file"
    exit 1
fi

# Set proper permissions on .env
chmod 600 "$ENV_FILE"

# ====================================
# 1. Install OpenSSH
# ====================================
echo ""
echo "[1/4] Installing OpenSSH..."

if command -v apt-get &> /dev/null; then
    # Debian/Ubuntu
    apt-get update
    apt-get install -y openssh-server
    systemctl enable ssh
    systemctl start ssh
elif command -v yum &> /dev/null; then
    # RHEL/CentOS
    yum install -y openssh-server
    systemctl enable sshd
    systemctl start sshd
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
    sh get-docker.sh
    rm get-docker.sh
    
    # Add current user to docker group
    usermod -aG docker $USER
    
    echo "✓ Docker installed"
fi

# Install Docker Compose plugin
if ! docker compose version &> /dev/null; then
    echo "Installing Docker Compose..."
    apt-get update
    apt-get install -y docker-compose-plugin
fi

echo "✓ Docker Compose ready ($(docker compose version))"

# ====================================
# 4. Login to GitHub Container Registry
# ====================================
echo ""
echo "[4/4] Logging into GitHub Container Registry..."

echo "$GITHUB_PAT" | docker login ghcr.io -u "$GITHUB_USERNAME" --password-stdin
echo "✓ Logged into ghcr.io as $GITHUB_USERNAME"

# Also login to docker.pkg.github.com (legacy GitHub Packages)
echo "$GITHUB_PAT" | docker login docker.pkg.github.com -u "$GITHUB_USERNAME" --password-stdin
echo "✓ Logged into docker.pkg.github.com"

# ====================================
# 5. Setup Docker Compose
# ====================================
echo ""
echo "[5/5] Setting up Docker Compose..."

# Download docker-compose.yml
echo "Downloading docker-compose.yml..."
if curl -fsSL "$DOCKER_COMPOSE_URL" -o "$PROJECT_DIR/docker-compose.yml"; then
    echo "✓ docker-compose.yml downloaded"
else
    echo "✗ Error: Could not download docker-compose.yml from $DOCKER_COMPOSE_URL"
    exit 1
fi

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
echo "Your Docker services are running in: $PROJECT_DIR"
echo ""
echo "Manage services with:"
echo "   - docker compose ps      (view status)"
echo "   - docker compose logs    (view logs)"
echo "   - docker compose down    (stop services)"
echo "   - docker compose pull    (update images)"
echo "   - docker compose restart (restart services)"
echo ""
echo "NOTE: If Docker was just installed, log out and back in for group changes to take effect"
echo ""
