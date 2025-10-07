#!/bin/bash

# Recover Data Script for Container 104
# Run from Proxmox HOST
# Finds and migrates old data files to new location

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
echo "  Recover Data for Container 104"
echo "  Run from Proxmox HOST"
echo "========================================"
echo ""

print_info "Searching for old data files..."
echo ""

# Check various possible locations for old data
OLD_LOCATIONS=(
    "/opt/uptime-monitor/servers.json"
    "/opt/uptime-monitor/config.json"
    "/opt/secure-data/servers.json"
    "/opt/secure-data/config.json"
    "/root/secure-data/servers.json"
    "/root/secure-data/config.json"
)

NEW_DATA_DIR="/opt/uptime-monitor/data"

print_info "Stopping service..."
pct exec $CONTAINER_ID -- systemctl stop uptime-monitor
sleep 2
print_success "Service stopped"
echo ""

print_info "Creating new data directory..."
pct exec $CONTAINER_ID -- mkdir -p $NEW_DATA_DIR
pct exec $CONTAINER_ID -- chown uptime-monitor:uptime-monitor $NEW_DATA_DIR
print_success "Data directory ready"
echo ""

print_info "Searching for data files in container..."
echo ""

# Find servers.json
FOUND_SERVERS=""
for location in "${OLD_LOCATIONS[@]}"; do
    if pct exec $CONTAINER_ID -- test -f "$location" 2>/dev/null; then
        if [[ "$location" == *"servers.json" ]]; then
            print_success "Found servers.json at: $location"
            FOUND_SERVERS="$location"
            
            # Show preview
            print_info "Preview of servers.json:"
            pct exec $CONTAINER_ID -- head -20 "$location"
            echo ""
            break
        fi
    fi
done

# Find config.json
FOUND_CONFIG=""
for location in "${OLD_LOCATIONS[@]}"; do
    if pct exec $CONTAINER_ID -- test -f "$location" 2>/dev/null; then
        if [[ "$location" == *"config.json" ]]; then
            print_success "Found config.json at: $location"
            FOUND_CONFIG="$location"
            break
        fi
    fi
done

echo ""

# Copy files if found
if [ -n "$FOUND_SERVERS" ]; then
    print_info "Copying servers.json to new location..."
    pct exec $CONTAINER_ID -- cp "$FOUND_SERVERS" "$NEW_DATA_DIR/servers.json"
    pct exec $CONTAINER_ID -- chown uptime-monitor:uptime-monitor "$NEW_DATA_DIR/servers.json"
    print_success "Servers data recovered!"
else
    print_warning "No servers.json found - creating empty file"
    pct exec $CONTAINER_ID -- bash -c "echo '[]' > $NEW_DATA_DIR/servers.json"
    pct exec $CONTAINER_ID -- chown uptime-monitor:uptime-monitor "$NEW_DATA_DIR/servers.json"
fi

if [ -n "$FOUND_CONFIG" ]; then
    print_info "Copying config.json to new location..."
    pct exec $CONTAINER_ID -- cp "$FOUND_CONFIG" "$NEW_DATA_DIR/config.json"
    pct exec $CONTAINER_ID -- chown uptime-monitor:uptime-monitor "$NEW_DATA_DIR/config.json"
    print_success "Configuration recovered!"
else
    print_warning "No config.json found - creating empty file"
    pct exec $CONTAINER_ID -- bash -c "echo '{}' > $NEW_DATA_DIR/config.json"
    pct exec $CONTAINER_ID -- chown uptime-monitor:uptime-monitor "$NEW_DATA_DIR/config.json"
fi

echo ""
print_info "Verifying recovered data..."
echo ""

# Show what was recovered
print_info "Servers in new location:"
SERVER_COUNT=$(pct exec $CONTAINER_ID -- cat $NEW_DATA_DIR/servers.json | grep -o '"id"' | wc -l)
print_info "Found $SERVER_COUNT server(s)"
echo ""

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

print_success "Data recovery completed!"
echo ""
print_info "Summary:"
echo "  Servers recovered: $SERVER_COUNT"
echo "  Data location: $NEW_DATA_DIR"
echo ""
print_info "Open the web interface to verify your servers are back:"
echo "  http://YOUR_PROXMOX_IP:3000"
echo ""

