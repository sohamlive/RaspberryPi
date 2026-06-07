#!/bin/bash
# ============================================================
# Raspberry Pi Home Lab — Bootstrap Setup Script
# Run this once on a fresh Pi OS install to get everything up.
# Usage: chmod +x setup.sh && sudo ./setup.sh
# ============================================================

set -e  # Exit on any error

STATIC_IP="192.168.1.2"
ROUTER_IP="192.168.1.1"
FALLBACK_DNS="1.1.1.1"
# Pi uses its own Pi-hole (127.0.0.1) for DNS, with Cloudflare as fallback.
# Do NOT set this to 192.168.1.1 — that bypasses Pi-hole entirely.

echo "============================================"
echo "  Pi Home Lab — Setup Starting"
echo "============================================"

# ------------------------------------------------------------
# STEP 1: Set static local IP (Pi OS Bookworm+ uses NetworkManager)
# dhcpcd.conf is no longer used on Pi OS 12 (Bookworm) and later.
# The correct tool is nmcli.
# ------------------------------------------------------------
echo ""
echo "[1/6] Setting static local IP to $STATIC_IP via NetworkManager..."

# Detect the active ethernet interface and its connection name
INTERFACE=$(ip route | grep default | awk '{print $5}')
echo "      Detected network interface: $INTERFACE"

# Get the NetworkManager connection name for this interface
# Usually "Wired connection 1" on a fresh Pi OS install
CONN_NAME=$(nmcli -t -f NAME,DEVICE con show --active | grep ":$INTERFACE" | cut -d: -f1)

if [ -z "$CONN_NAME" ]; then
  echo "      ERROR: Could not find an active NetworkManager connection for $INTERFACE"
  echo "      Run 'nmcli device status' to check your connection name and set it manually."
  exit 1
fi

echo "      Found connection: \"$CONN_NAME\""

# Apply static IP settings
nmcli con mod "$CONN_NAME" ipv4.addresses "$STATIC_IP/24"
nmcli con mod "$CONN_NAME" ipv4.gateway "$ROUTER_IP"
nmcli con mod "$CONN_NAME" ipv4.dns "127.0.0.1 $FALLBACK_DNS"
nmcli con mod "$CONN_NAME" ipv4.method manual

echo "      Static IP configured. Restarting connection..."
echo "      NOTE: If you are connected via SSH, your session will drop here."
echo "      Reconnect to $STATIC_IP after a few seconds."

# Bring connection down and up to apply — SSH will drop here if remote
nmcli con down "$CONN_NAME" && nmcli con up "$CONN_NAME" || true

echo "      Network restarted with static IP $STATIC_IP"

# ------------------------------------------------------------
# STEP 2: Update system
# ------------------------------------------------------------
echo ""
echo "[2/6] Updating system packages..."
apt-get update -qq && apt-get upgrade -y -qq
echo "      Done."

# ------------------------------------------------------------
# STEP 3: Install Docker (skip if already installed)
# ------------------------------------------------------------
echo ""
echo "[3/6] Checking Docker installation..."

if ! command -v docker &> /dev/null; then
  echo "      Docker not found. Installing..."
  curl -fsSL https://get.docker.com | sh
  usermod -aG docker $SUDO_USER
  echo "      Docker installed. Note: log out and back in for group changes to take effect."
else
  echo "      Docker already installed. Skipping."
fi

# Install docker compose plugin if not present
if ! docker compose version &> /dev/null; then
  echo "      Installing Docker Compose plugin..."
  apt-get install -y docker-compose-plugin
else
  echo "      Docker Compose already available."
fi

# ------------------------------------------------------------
# STEP 4: Create config directories
# ------------------------------------------------------------
echo ""
echo "[4/6] Creating config directories..."

mkdir -p ./nginx/data
mkdir -p ./nginx/letsencrypt
mkdir -p ./homepage/config

# Create a minimal homepage config if not present
if [ ! -f ./homepage/config/services.yaml ]; then
cat > ./homepage/config/services.yaml <<EOF
- Home Lab:
    - Pi-hole:
        href: http://pihole.lab/admin
        description: DNS & Ad Blocking
        icon: pi-hole.png
    - Portainer:
        href: http://portainer.lab
        description: Docker Management
        icon: portainer.png
    - Uptime Kuma:
        href: http://uptime.lab
        description: Uptime Monitoring
        icon: uptime-kuma.png
    - Dozzle:
        href: http://logs.lab
        description: Container Logs
        icon: docker.png
    - Netdata:
        href: http://stats.lab
        description: System Stats
        icon: netdata.png
EOF
echo "      Created default homepage/config/services.yaml"
fi

if [ ! -f ./homepage/config/settings.yaml ]; then
cat > ./homepage/config/settings.yaml <<EOF
title: Home Lab
theme: dark
color: slate
EOF
echo "      Created default homepage/config/settings.yaml"
fi

# ------------------------------------------------------------
# STEP 5: Pull all images and start services
# ------------------------------------------------------------
echo ""
echo "[5/6] Pulling Docker images and starting services..."
docker compose pull
docker compose up -d
echo "      All services started."

# ------------------------------------------------------------
# STEP 6: Set up auto-start on boot (Docker already handles
# this via restart: unless-stopped, but confirm service is on)
# ------------------------------------------------------------
echo ""
echo "[6/6] Ensuring Docker starts on boot..."
systemctl enable docker
echo "      Docker enabled on boot."

# ------------------------------------------------------------
# Done
# ------------------------------------------------------------
echo ""
echo "============================================"
echo "  Setup Complete!"
echo "============================================"
echo ""
echo "  Services running at:"
echo "    http://$STATIC_IP:81     → Nginx Proxy Manager admin (set up *.lab routes here)"
echo "    http://$STATIC_IP:8053   → Pi-hole (before proxy is configured)"
echo "    http://$STATIC_IP:9000   → Portainer"
echo "    http://$STATIC_IP:3000   → Homepage"
echo "    http://$STATIC_IP:3001   → Uptime Kuma"
echo "    http://$STATIC_IP:8080   → Dozzle"
echo "    http://$STATIC_IP:19999  → Netdata"
echo ""
echo "  Next steps:"
echo "    1. Visit http://$STATIC_IP:81 and configure *.lab reverse proxy routes"
echo "    2. Log into your ISP router (192.168.1.1) → DHCP settings → set DNS to 192.168.1.2"
echo "    3. Install Tailscale for remote access: curl -fsSL https://tailscale.com/install.sh | sh"
echo "       Then run: sudo tailscale up"
echo "       Then run: tailscale ip   (note this IP — use it to SSH from anywhere)"
echo ""
echo "  Pi-hole web password: changeme  ← Change this in docker-compose.yml before deploying!"
echo ""
