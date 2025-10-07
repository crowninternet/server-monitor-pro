#!/bin/bash

# Update Script - Run this directly on Proxmox host
# This script updates uptime-monitor-api.js with server-side monitoring

INSTALL_DIR="/opt/uptime-monitor"
SERVICE_NAME="uptime-monitor"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }
print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_header() {
    echo -e "${CYAN}================================${NC}"
    echo -e "${CYAN}  Update Server-Side Monitoring${NC}"
    echo -e "${CYAN}================================${NC}"
    echo ""
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    print_error "This script must be run as root (use sudo)"
    exit 1
fi

print_header

# Check if file exists in /tmp
if [ ! -f "/tmp/uptime-monitor-api.js" ]; then
    print_error "Updated file not found at /tmp/uptime-monitor-api.js"
    echo ""
    print_info "Please copy the file to /tmp first:"
    echo "  From your Mac: scp uptime-monitor-api.js root@PROXMOX_IP:/tmp/"
    echo ""
    exit 1
fi

# Check if install directory exists
if [ ! -d "$INSTALL_DIR" ]; then
    print_error "Install directory not found: $INSTALL_DIR"
    exit 1
fi

# Create backup
print_info "Creating backup..."
BACKUP_FILE="$INSTALL_DIR/uptime-monitor-api.js.backup-$(date +%Y%m%d-%H%M%S)"
cp "$INSTALL_DIR/uptime-monitor-api.js" "$BACKUP_FILE"
if [ $? -eq 0 ]; then
    print_success "Backup created: $BACKUP_FILE"
else
    print_error "Failed to create backup"
    exit 1
fi
echo ""

# Stop the service
print_info "Stopping service..."
systemctl stop "$SERVICE_NAME"
sleep 2
print_success "Service stopped"
echo ""

# Install new file
print_info "Installing updated file..."
mv /tmp/uptime-monitor-api.js "$INSTALL_DIR/uptime-monitor-api.js"
if [ $? -ne 0 ]; then
    print_error "Failed to install file"
    print_info "Restoring backup..."
    cp "$BACKUP_FILE" "$INSTALL_DIR/uptime-monitor-api.js"
    systemctl start "$SERVICE_NAME"
    exit 1
fi

# Set permissions
chown uptime-monitor:uptime-monitor "$INSTALL_DIR/uptime-monitor-api.js"
chmod 644 "$INSTALL_DIR/uptime-monitor-api.js"
print_success "File installed successfully"
echo ""

# Start the service
print_info "Starting service..."
systemctl start "$SERVICE_NAME"
sleep 3

# Check if service started
if systemctl is-active --quiet "$SERVICE_NAME"; then
    print_success "Service started successfully!"
else
    print_error "Service failed to start"
    print_info "Restoring backup..."
    cp "$BACKUP_FILE" "$INSTALL_DIR/uptime-monitor-api.js"
    systemctl start "$SERVICE_NAME"
    exit 1
fi
echo ""

# Show monitoring status
print_info "Checking monitoring status..."
sleep 2
echo ""

# Show recent logs
print_info "Recent logs:"
echo "----------------------------------------"
journalctl -u "$SERVICE_NAME" --no-pager -n 30 | grep -E "MONITORING|monitoring|Starting monitoring|Check complete"
echo "----------------------------------------"
echo ""

# Check API
print_info "Testing API..."
if curl -s http://localhost:3000/api/health > /dev/null 2>&1; then
    print_success "API is responding"
    
    # Check monitoring status
    MONITORING_STATUS=$(curl -s http://localhost:3000/api/monitoring/status)
    if [ $? -eq 0 ]; then
        print_success "Monitoring engine is active"
        echo ""
        echo "Monitoring Status:"
        echo "$MONITORING_STATUS" | python3 -m json.tool 2>/dev/null || echo "$MONITORING_STATUS"
    fi
else
    print_warning "API not responding yet (may still be starting)"
fi
echo ""

print_success "Update completed successfully!"
echo ""
print_info "Server-side monitoring is now active!"
print_info "Checks will run automatically even when browser is closed."
echo ""
print_info "To view live logs:"
echo "  sudo journalctl -u $SERVICE_NAME -f"
echo ""
print_info "To check monitoring status:"
echo "  curl http://localhost:3000/api/monitoring/status"
echo ""

