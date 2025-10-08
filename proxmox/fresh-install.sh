#!/bin/bash

################################################################################
# Uptime Monitor Pro - Fresh Installation Script for Proxmox
# Run this script from the Proxmox HOST (not in a container)
# 
# This script will:
# 1. Create a new LXC container
# 2. Install Node.js and dependencies
# 3. Install Uptime Monitor with server-side monitoring
# 4. Configure systemd service
# 5. Start monitoring automatically
#
# Usage: ./fresh-install.sh
################################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }
print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_header() { echo -e "${PURPLE}================================${NC}"; echo -e "${PURPLE}$1${NC}"; echo -e "${PURPLE}================================${NC}"; }

# Check if running on Proxmox host
if ! command -v pct &> /dev/null; then
    print_error "This script must be run from a Proxmox host"
    exit 1
fi

print_header "Uptime Monitor Pro - Fresh Install"
echo ""

# Configuration
CONTAINER_NAME="uptime-monitor"
INSTALL_DIR="/opt/uptime-monitor"
SERVICE_NAME="uptime-monitor"
APP_USER="uptime-monitor"

# Ask for container configuration
read -p "Enter container ID (e.g., 100): " CONTAINER_ID
read -p "Enter hostname [uptime-monitor]: " HOSTNAME
HOSTNAME=${HOSTNAME:-uptime-monitor}
read -p "Enter disk size in GB [8]: " DISK_SIZE
DISK_SIZE=${DISK_SIZE:-8}
read -p "Enter RAM in MB [512]: " RAM
RAM=${RAM:-512}
read -p "Enter storage pool [local-lxc]: " STORAGE
STORAGE=${STORAGE:-local-lxc}

echo ""
print_warning "This will create container $CONTAINER_ID with:"
echo "  Hostname: $HOSTNAME"
echo "  Disk: ${DISK_SIZE}GB"
echo "  RAM: ${RAM}MB"
echo "  Storage: $STORAGE"
echo ""
read -p "Continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_info "Installation cancelled"
    exit 0
fi

echo ""
print_header "Step 1: Creating LXC Container"
echo ""

# Find latest Debian 12 template
print_info "Finding Debian 12 template..."
DEBIAN_TEMPLATE=$(pveam list local | grep "debian-12-standard" | awk '{print $1}' | head -1)

if [ -z "$DEBIAN_TEMPLATE" ]; then
    print_error "No Debian 12 template found in local storage"
    print_info "Download one with: pveam download local debian-12-standard"
    exit 1
fi

print_info "Using template: $DEBIAN_TEMPLATE"

# Create container
print_info "Creating Debian 12 container..."
pct create $CONTAINER_ID \
    $DEBIAN_TEMPLATE \
    --hostname $HOSTNAME \
    --memory $RAM \
    --rootfs $STORAGE:$DISK_SIZE \
    --cores 2 \
    --net0 name=eth0,bridge=vmbr0,ip=dhcp \
    --features nesting=1 \
    --unprivileged 1 \
    --onboot 1

print_success "Container created with ID: $CONTAINER_ID"
echo ""

print_info "Starting container..."
pct start $CONTAINER_ID
sleep 5
print_success "Container started"
echo ""

print_header "Step 2: Installing Base System"
echo ""

print_info "Updating package list..."
pct exec $CONTAINER_ID -- apt-get update -qq

print_info "Installing base packages..."
pct exec $CONTAINER_ID -- apt-get install -y curl wget ca-certificates gnupg

print_success "Base system updated"
echo ""

print_header "Step 3: Installing Node.js"
echo ""

print_info "Adding NodeSource repository..."
pct exec $CONTAINER_ID -- bash -c "curl -fsSL https://deb.nodesource.com/setup_20.x | bash -"

print_info "Installing Node.js..."
pct exec $CONTAINER_ID -- apt-get install -y nodejs

NODE_VERSION=$(pct exec $CONTAINER_ID -- node --version)
print_success "Node.js installed: $NODE_VERSION"
echo ""

print_header "Step 4: Creating Application User"
echo ""

print_info "Creating $APP_USER user..."
pct exec $CONTAINER_ID -- useradd -r -m -s /bin/bash $APP_USER
print_success "User created"
echo ""

print_header "Step 5: Installing Uptime Monitor"
echo ""

print_info "Creating application directory..."
pct exec $CONTAINER_ID -- mkdir -p $INSTALL_DIR
pct exec $CONTAINER_ID -- mkdir -p $INSTALL_DIR/data

print_info "Downloading application files..."
pct exec $CONTAINER_ID -- bash -c "cd $INSTALL_DIR && curl -fsSL https://raw.githubusercontent.com/crowninternet/server-monitor-pro/master/uptime-monitor-api.js -o uptime-monitor-api.js"
pct exec $CONTAINER_ID -- bash -c "cd $INSTALL_DIR && curl -fsSL https://raw.githubusercontent.com/crowninternet/server-monitor-pro/master/index.html -o index.html"
pct exec $CONTAINER_ID -- bash -c "cd $INSTALL_DIR && curl -fsSL https://raw.githubusercontent.com/crowninternet/server-monitor-pro/master/recovery.html -o recovery.html"
pct exec $CONTAINER_ID -- bash -c "cd $INSTALL_DIR && curl -fsSL https://raw.githubusercontent.com/crowninternet/server-monitor-pro/master/package.json -o package.json"

print_success "Files downloaded"
echo ""

print_info "Installing Node.js dependencies..."
pct exec $CONTAINER_ID -- bash -c "cd $INSTALL_DIR && npm install --production"
print_success "Dependencies installed"
echo ""

print_info "Setting up data directory..."
pct exec $CONTAINER_ID -- bash -c "echo '[]' > $INSTALL_DIR/data/servers.json"
pct exec $CONTAINER_ID -- bash -c "echo '{}' > $INSTALL_DIR/data/config.json"

print_info "Setting permissions..."
pct exec $CONTAINER_ID -- chown -R $APP_USER:$APP_USER $INSTALL_DIR
pct exec $CONTAINER_ID -- chmod 755 $INSTALL_DIR
pct exec $CONTAINER_ID -- chmod 755 $INSTALL_DIR/data
pct exec $CONTAINER_ID -- chmod 644 $INSTALL_DIR/*.js $INSTALL_DIR/*.html $INSTALL_DIR/*.json
pct exec $CONTAINER_ID -- chmod 644 $INSTALL_DIR/data/*.json

print_success "Permissions set"
echo ""

print_header "Step 6: Installing systemd Service"
echo ""

print_info "Creating service file..."
pct exec $CONTAINER_ID -- bash -c "cat > /etc/systemd/system/$SERVICE_NAME.service << 'EOF'
[Unit]
Description=Uptime Monitor Pro
Documentation=https://github.com/crowninternet/uptime-monitor
After=network.target
Wants=network-online.target

[Service]
Type=simple
User=$APP_USER
Group=$APP_USER
WorkingDirectory=$INSTALL_DIR
ExecStart=/usr/bin/node $INSTALL_DIR/uptime-monitor-api.js
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=$SERVICE_NAME

# Resource limits
MemoryMax=512M
CPUQuota=50%
LimitNOFILE=4096
LimitNPROC=2048

# Security settings
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=$INSTALL_DIR
ProtectKernelTunables=true
ProtectKernelModules=true
ProtectControlGroups=true
RestrictRealtime=true
RestrictSUIDSGID=true
RestrictNamespaces=true

# Environment
Environment=NODE_ENV=production
Environment=PORT=3000

[Install]
WantedBy=multi-user.target
EOF"

print_info "Reloading systemd..."
pct exec $CONTAINER_ID -- systemctl daemon-reload

print_info "Enabling service..."
pct exec $CONTAINER_ID -- systemctl enable $SERVICE_NAME

print_success "Service installed"
echo ""

print_header "Step 7: Starting Service"
echo ""

print_info "Starting $SERVICE_NAME..."
pct exec $CONTAINER_ID -- systemctl start $SERVICE_NAME
sleep 3

if pct exec $CONTAINER_ID -- systemctl is-active $SERVICE_NAME > /dev/null 2>&1; then
    print_success "Service is running!"
else
    print_error "Service failed to start"
    print_info "Checking logs..."
    pct exec $CONTAINER_ID -- journalctl -u $SERVICE_NAME -n 20 --no-pager
    exit 1
fi
echo ""

print_header "Step 8: Verifying Installation"
echo ""

print_info "Waiting for service to initialize..."
sleep 5

print_info "Checking API health..."
if pct exec $CONTAINER_ID -- curl -s http://localhost:3000/api/health > /dev/null 2>&1; then
    print_success "API is responding"
else
    print_warning "API not responding yet (may still be starting)"
fi

print_info "Checking server-side monitoring..."
MONITORING_STATUS=$(pct exec $CONTAINER_ID -- curl -s http://localhost:3000/api/monitoring/status 2>/dev/null)
if echo "$MONITORING_STATUS" | grep -q '"enabled"'; then
    print_success "Server-side monitoring is active!"
    echo "$MONITORING_STATUS" | python3 -m json.tool 2>/dev/null || echo "$MONITORING_STATUS"
else
    print_warning "Monitoring API not responding yet"
fi
echo ""

# Get container IP
print_info "Getting container IP address..."
CONTAINER_IP=$(pct exec $CONTAINER_ID -- hostname -I | awk '{print $1}')
print_success "Container IP: $CONTAINER_IP"
echo ""

print_header "Installation Complete!"
echo ""

print_success "Uptime Monitor Pro is now running!"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  📊 Access Information"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  Container ID:     $CONTAINER_ID"
echo "  Hostname:         $HOSTNAME"
echo "  IP Address:       $CONTAINER_IP"
echo "  Web Interface:    http://$CONTAINER_IP:3000"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  📝 Management Commands"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  Start:            pct exec $CONTAINER_ID -- systemctl start $SERVICE_NAME"
echo "  Stop:             pct exec $CONTAINER_ID -- systemctl stop $SERVICE_NAME"
echo "  Restart:          pct exec $CONTAINER_ID -- systemctl restart $SERVICE_NAME"
echo "  Status:           pct exec $CONTAINER_ID -- systemctl status $SERVICE_NAME"
echo "  Logs:             pct exec $CONTAINER_ID -- journalctl -u $SERVICE_NAME -f"
echo "  Enter Container:  pct enter $CONTAINER_ID"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ✨ Features Enabled"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  ✅ Server-side monitoring (24/7)"
echo "  ✅ Automatic SMS alerts (configure in web UI)"
echo "  ✅ Automatic email alerts (configure in web UI)"
echo "  ✅ FTP public page upload (configure in web UI)"
echo "  ✅ Auto-restart on failure"
echo "  ✅ Survives container reboots"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🚀 Next Steps"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  1. Open http://$CONTAINER_IP:3000 in your browser"
echo "  2. Add your servers to monitor"
echo "  3. Configure SMS alerts (optional)"
echo "  4. Configure email alerts (optional)"
echo "  5. Configure FTP upload (optional)"
echo ""
print_info "Monitoring will run 24/7 in the background!"
echo ""

