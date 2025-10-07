#!/bin/bash

# Direct Patch Script for Container 104
# Run from Proxmox HOST
# Fixes the data directory path directly in the file

CONTAINER_ID=104

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

echo "========================================"
echo "  Direct Patch for Container 104"
echo "  Run from Proxmox HOST"
echo "========================================"
echo ""

print_info "Stopping service..."
pct exec $CONTAINER_ID -- systemctl stop uptime-monitor
sleep 2
print_success "Service stopped"
echo ""

print_info "Backing up current file..."
pct exec $CONTAINER_ID -- cp /opt/uptime-monitor/uptime-monitor-api.js /opt/uptime-monitor/uptime-monitor-api.js.backup-patch
print_success "Backup created"
echo ""

print_info "Patching data directory path in file..."
pct exec $CONTAINER_ID -- sed -i "s|path.join(__dirname, '..', 'secure-data')|path.join(__dirname, 'data')|g" /opt/uptime-monitor/uptime-monitor-api.js
print_success "File patched"
echo ""

print_info "Creating data directory..."
pct exec $CONTAINER_ID -- bash -c "mkdir -p /opt/uptime-monitor/data && chown -R uptime-monitor:uptime-monitor /opt/uptime-monitor && chmod 755 /opt/uptime-monitor/data"
print_success "Data directory created"
echo ""

print_info "Verifying patch..."
if pct exec $CONTAINER_ID -- grep -q "path.join(__dirname, 'data')" /opt/uptime-monitor/uptime-monitor-api.js; then
    print_success "Patch verified - using correct data path"
else
    print_error "Patch verification failed"
    exit 1
fi
echo ""

print_info "Starting service..."
pct exec $CONTAINER_ID -- systemctl start uptime-monitor
sleep 3
print_success "Service started"
echo ""

print_info "Checking service status..."
if pct exec $CONTAINER_ID -- systemctl is-active uptime-monitor > /dev/null 2>&1; then
    print_success "Service is running!"
else
    print_error "Service failed to start"
    echo ""
    print_info "Error logs:"
    pct exec $CONTAINER_ID -- journalctl -u uptime-monitor -n 20 --no-pager
    exit 1
fi
echo ""

print_info "Waiting for initialization..."
sleep 5
echo ""

print_info "Recent logs:"
echo "----------------------------------------"
pct exec $CONTAINER_ID -- journalctl -u uptime-monitor -n 30 --no-pager | tail -20
echo "----------------------------------------"
echo ""

print_info "Checking for server-side monitoring..."
if pct exec $CONTAINER_ID -- journalctl -u uptime-monitor --no-pager | grep -q "INITIALIZING SERVER-SIDE MONITORING"; then
    print_success "Server-side monitoring detected in logs!"
else
    print_info "Monitoring initialization may not have logged yet, checking API..."
fi
echo ""

print_info "Checking monitoring API..."
MONITORING_STATUS=$(pct exec $CONTAINER_ID -- curl -s http://localhost:3000/api/monitoring/status 2>/dev/null)
if [ $? -eq 0 ] && [ ! -z "$MONITORING_STATUS" ]; then
    echo "$MONITORING_STATUS" | python3 -m json.tool 2>/dev/null || echo "$MONITORING_STATUS"
    echo ""
    if echo "$MONITORING_STATUS" | grep -q '"enabled"'; then
        print_success "Monitoring API is responding!"
        print_success "Server-side monitoring is now active!"
    fi
else
    print_info "API may still be starting up..."
fi
echo ""

print_success "Patch completed!"
echo ""
print_info "Monitor live logs with:"
echo "  pct exec 104 -- journalctl -u uptime-monitor -f"
echo ""
print_info "Check monitoring status:"
echo "  pct exec 104 -- curl http://localhost:3000/api/monitoring/status"
echo ""

