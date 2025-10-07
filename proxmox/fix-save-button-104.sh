#!/bin/bash

# Fix Save Button for Container 104
# Run from Proxmox HOST
# Downloads latest index.html with fixes

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
echo "  Fix Save Button - Container 104"
echo "========================================"
echo ""

print_info "Stopping service..."
pct exec $CONTAINER_ID -- systemctl stop uptime-monitor
sleep 2
print_success "Service stopped"
echo ""

print_info "Backing up current index.html..."
pct exec $CONTAINER_ID -- cp /opt/uptime-monitor/index.html /opt/uptime-monitor/index.html.backup-savefix
print_success "Backup created"
echo ""

print_info "Downloading latest index.html from GitHub..."
pct exec $CONTAINER_ID -- bash -c "curl -fsSL https://raw.githubusercontent.com/crowninternet/server-monitor-pro/master/index.html -o /opt/uptime-monitor/index.html.new && mv /opt/uptime-monitor/index.html.new /opt/uptime-monitor/index.html"

if [ $? -eq 0 ]; then
    print_success "index.html updated"
else
    print_error "Failed to download index.html"
    print_info "Restoring backup..."
    pct exec $CONTAINER_ID -- cp /opt/uptime-monitor/index.html.backup-savefix /opt/uptime-monitor/index.html
    exit 1
fi
echo ""

print_info "Fixing ownership..."
pct exec $CONTAINER_ID -- chown uptime-monitor:uptime-monitor /opt/uptime-monitor/index.html
print_success "Ownership fixed"
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

print_success "Update complete!"
echo ""
print_info "Please refresh your browser (Ctrl+F5 or Cmd+Shift+R)"
print_info "Then try saving SendGrid configuration again"
echo ""
print_info "If button still doesn't work:"
echo "  1. Open browser console (F12)"
echo "  2. Click save button"
echo "  3. Look for error messages in console"
echo ""

