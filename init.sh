#!/bin/bash

# Exit on any error
set -e


echo "======================================"
echo "Server Setup Script"
echo "======================================"

# ====================================
# CONFIGURATION - EDIT THESE
# ====================================
PUBLIC_KEY="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCqdgq9pd9cBQzihSwgk5rZZuDhSUnTY9XUp6eLS80egtd5la2nOEnk+gpkfFasIJn0DIOXdpIV3r5V2555YRTZcEBdJrtIcv6b+vqlZumhSuvAWVHqNvtCYbr+zQku00E8dRHj+k8KpEdBm/oNh2+fMWKYd/SR5xV/Mpz/7buCKH0yDC6n+nSjPwKWpoLLpK6UdAgACIZGbHB0D+pC1DlWSujSX/480TfGZSA6ObaOGGyKIYCS/ovfhWnk4U9kF5L/5SqWlH1OY6tCklgJy+WQpq5th7jZkKCpsQjCY9KSoh0+Lm7tULlkVyZrlOTeB/rdWGVedeqUKLEQJFd3UB6wGRXs7z8ag8I7hLOmDyg9cXKIj3Wf2PUFdB36uzCNv7cusftsf451cJxrslz462JZtt8id9bC+NQ3Qfbp1CLXqovdJITyMO2F6/UaF0PhyHnIhwmY2BoWtAhHtzWVDf4dQH1XK0emTTKNcdAZYvX1WTH1sheCR+tUBZci7Dp0DoU= mijac@DESKTOP-CCGG6EQ"

# URL to your docker-compose.yml file
DOCKER_COMPOSE_URL="https://github.com/Skulldorom/agent-init/blob/main/docker-compose.yml"

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

# Download docker-compose.yml
echo "Downloading docker-compose.yml..."
if curl -fsSL "$DOCKER_COMPOSE_URL" -o "$PROJECT_DIR/docker-compose.yml"; then
    echo "✓ docker-compose.yml downloaded"
else
    echo "✗ Error: Could not download docker-compose.yml from $DOCKER_COMPOSE_URL"
    exit 1
fi

# Create .env file interactively
echo ""
echo "======================================"
echo "Environment Variables Setup"
echo "======================================"
echo "Please enter your environment variables."
echo "Press Ctrl+D when finished or Ctrl+C to skip."
echo ""

ENV_FILE="$PROJECT_DIR/.env"

# Check if .env already exists
if [ -f "$ENV_FILE" ]; then
    echo "⚠ .env file already exists at $ENV_FILE"
    read -p "Do you want to overwrite it? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Keeping existing .env file"
    else
        rm "$ENV_FILE"
        echo "Enter variables in KEY=VALUE format (one per line):"
        cat > "$ENV_FILE"
        echo "✓ .env file created"
    fi
else
    echo "Enter variables in KEY=VALUE format (one per line):"
    cat > "$ENV_FILE"
    echo "✓ .env file created"
fi

# Set proper permissions on .env
chmod 600 "$ENV_FILE"

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
echo "3. View your .env file: cat $PROJECT_DIR/.env"
echo "4. Edit .env anytime: nano $PROJECT_DIR/.env"
echo "5. After editing .env, restart services: cd $PROJECT_DIR && docker compose restart"
echo "6. Manage services with:"
echo "   - docker compose ps    (view status)"
echo "   - docker compose logs  (view logs)"
echo "   - docker compose down  (stop services)"
echo ""
