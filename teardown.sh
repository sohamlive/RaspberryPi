#!/bin/bash
# ============================================================
# Raspberry Pi Home Lab — Teardown Script
#
# What this removes:
#   - All running containers from the homelab stack
#   - All Docker images pulled for the stack
#   - All named Docker volumes (Pi-hole data, Portainer data, etc)
#   - All homelab config directories (nginx/, homepage/)
#   - The Docker bridge network created by compose
#
# What this KEEPS:
#   - Docker and Docker Compose
#   - Tailscale
#   - Your static IP config (nmcli)
#   - The docker-compose.yml and setup.sh files themselves
#   - The Pi OS and all system packages
#
# Usage:
#   chmod +x teardown.sh
#   sudo ./teardown.sh
#
# Run from the homelab directory (same place as docker-compose.yml)
# ============================================================

set -e

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No colour

echo ""
echo -e "${RED}============================================${NC}"
echo -e "${RED}  Pi Home Lab — Teardown Script${NC}"
echo -e "${RED}============================================${NC}"
echo ""
echo -e "${YELLOW}  This will remove all homelab containers, images,${NC}"
echo -e "${YELLOW}  volumes, and config directories.${NC}"
echo -e "${YELLOW}  Docker, Tailscale, and your OS are untouched.${NC}"
echo ""
read -p "  Are you sure you want to continue? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
  echo ""
  echo "  Aborted. Nothing was changed."
  echo ""
  exit 0
fi

echo ""

# ------------------------------------------------------------
# STEP 1: Stop and remove all containers defined in compose
# ------------------------------------------------------------
echo "[1/5] Stopping and removing containers..."

if [ -f docker-compose.yml ]; then
  docker compose down --remove-orphans
  echo "      Done."
else
  echo "      docker-compose.yml not found in current directory."
  echo "      Skipping compose down — run this script from your homelab folder."
fi

# ------------------------------------------------------------
# STEP 2: Remove named volumes
# ------------------------------------------------------------
echo ""
echo "[2/5] Removing named Docker volumes..."

VOLUMES=(
  "homelab_pihole_data"
  "homelab_pihole_dnsmasq"
  "homelab_portainer_data"
  "homelab_uptime_kuma_data"
  "homelab_netdata_config"
  "homelab_netdata_lib"
  "homelab_netdata_cache"
  "homelab_filebrowser_data"
)

for VOL in "${VOLUMES[@]}"; do
  if docker volume inspect "$VOL" > /dev/null 2>&1; then
    docker volume rm "$VOL"
    echo "      Removed: $VOL"
  else
    echo "      Not found (skipping): $VOL"
  fi
done

# Also prune any dangling volumes not caught above
echo "      Pruning any remaining dangling volumes..."
docker volume prune -f
echo "      Done."

# ------------------------------------------------------------
# STEP 3: Remove Docker images
# ------------------------------------------------------------
echo ""
echo "[3/5] Removing Docker images..."

IMAGES=(
  "pihole/pihole"
  "portainer/portainer-ce"
  "jc21/nginx-proxy-manager"
  "ghcr.io/gethomepage/homepage"
  "louislam/uptime-kuma"
  "amir20/dozzle"
  "netdata/netdata"
  "filebrowser/filebrowser"
)

for IMG in "${IMAGES[@]}"; do
  if docker images --format "{{.Repository}}" | grep -q "^${IMG}$"; then
    docker rmi $(docker images --format "{{.Repository}}:{{.Tag}}" | grep "^${IMG}:") 2>/dev/null || true
    echo "      Removed: $IMG"
  else
    echo "      Not found (skipping): $IMG"
  fi
done

# Prune any dangling image layers
echo "      Pruning dangling image layers..."
docker image prune -f
echo "      Done."

# ------------------------------------------------------------
# STEP 4: Remove the Docker network
# ------------------------------------------------------------
echo ""
echo "[4/5] Removing Docker network..."

if docker network inspect homelab_homelab > /dev/null 2>&1; then
  docker network rm homelab_homelab
  echo "      Removed: homelab_homelab"
else
  echo "      Network not found (skipping)."
fi

# ------------------------------------------------------------
# STEP 5: Remove config directories
# ------------------------------------------------------------
echo ""
echo "[5/5] Removing config directories..."

DIRS=(
  "./nginx"
  "./homepage/config"
  "./filebrowser"
)

for DIR in "${DIRS[@]}"; do
  if [ -d "$DIR" ]; then
    rm -rf "$DIR"
    echo "      Removed: $DIR"
  else
    echo "      Not found (skipping): $DIR"
  fi
done

# Remove homepage dir if now empty
if [ -d "./homepage" ] && [ -z "$(ls -A ./homepage)" ]; then
  rm -rf ./homepage
  echo "      Removed: ./homepage (was empty)"
fi

# ------------------------------------------------------------
# Done
# ------------------------------------------------------------
echo ""
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}  Teardown Complete!${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""
echo "  What was removed:"
echo "    - All homelab containers"
echo "    - All homelab Docker volumes and data"
echo "    - All homelab Docker images"
echo "    - homelab Docker bridge network"
echo "    - nginx/ and homepage/config/ directories"
echo ""
echo "  What was kept:"
echo "    - Docker and Docker Compose"
echo "    - Tailscale"
echo "    - Static IP configuration"
echo "    - docker-compose.yml and setup.sh"
echo ""
echo "  To redeploy from scratch, run:"
echo "    sudo ./setup.sh"
echo ""
