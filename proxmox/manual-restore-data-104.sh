#!/bin/bash

# Manual Restore Script for Container 104
# Run from Proxmox HOST
# Restores specific files you identify

CONTAINER_ID=104

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }
print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }

echo "========================================"
echo "  Manual Data Restore - Container 104"
echo "========================================"
echo ""

# Get file paths from user
read -p "Enter path to servers.json (or press Enter to skip): " SERVERS_PATH
read -p "Enter path to config.json (or press Enter to skip): " CONFIG_PATH

if [ -z "$SERVERS_PATH" ] && [ -z "$CONFIG_PATH" ]; then
    print_error "No files specified"
    exit 1
fi

print_info "Stopping service..."
pct exec $CONTAINER_ID -- systemctl stop uptime-monitor
sleep 2
print_success "Service stopped"
echo ""

NEW_DATA_DIR="/opt/uptime-monitor/data"

print_info "Ensuring data directory exists..."
pct exec $CONTAINER_ID -- mkdir -p $NEW_DATA_DIR
pct exec $CONTAINER_ID -- chown uptime-monitor:uptime-monitor $NEW_DATA_DIR
echo ""

# Restore servers.json
if [ -n "$SERVERS_PATH" ]; then
    print_info "Checking $SERVERS_PATH..."
    if pct exec $CONTAINER_ID -- test -f "$SERVERS_PATH"; then
        print_info "File exists, copying..."
        pct exec $CONTAINER_ID -- cp "$SERVERS_PATH" "$NEW_DATA_DIR/servers.json"
        pct exec $CONTAINER_ID -- chown uptime-monitor:uptime-monitor "$NEW_DATA_DIR/servers.json"
        
        SERVER_COUNT=$(pct exec $CONTAINER_ID -- cat "$NEW_DATA_DIR/servers.json" | grep -o '"id"' | wc -l)
        print_success "Restored servers.json - Found $SERVER_COUNT server(s)"
    else
        print_error "File not found: $SERVERS_PATH"
    fi
    echo ""
fi

# Restore config.json
if [ -n "$CONFIG_PATH" ]; then
    print_info "Checking $CONFIG_PATH..."
    if pct exec $CONTAINER_ID -- test -f "$CONFIG_PATH"; then
        print_info "File exists, copying..."
        pct exec $CONTAINER_ID -- cp "$CONFIG_PATH" "$NEW_DATA_DIR/config.json"
        pct exec $CONTAINER_ID -- chown uptime-monitor:uptime-monitor "$NEW_DATA_DIR/config.json"
        
        # Check for SendGrid config
        if pct exec $CONTAINER_ID -- grep -q "sendgridApiKey" "$NEW_DATA_DIR/config.json"; then
            print_success "Restored config.json - SendGrid configuration found!"
        else
            print_warning "Config restored but no SendGrid data found"
        fi
        
        # Check for Twilio config
        if pct exec $CONTAINER_ID -- grep -q "twilioSid" "$NEW_DATA_DIR/config.json"; then
            print_success "Twilio configuration found!"
        fi
    else
        print_error "File not found: $CONFIG_PATH"
    fi
    echo ""
fi

print_info "Starting service..."
pct exec $CONTAINER_ID -- systemctl start uptime-monitor
sleep 3

if pct exec $CONTAINER_ID -- systemctl is-active uptime-monitor > /dev/null 2>&1; then
    print_success "Service is running!"
else
    print_error "Service failed to start"
    pct exec $CONTAINER_ID -- journalctl -u uptime-monitor -n 20 --no-pager
    exit 1
fi
echo ""

print_success "Restore complete!"
echo ""
print_info "Open http://YOUR_PROXMOX_IP:3000 to verify"
echo ""

