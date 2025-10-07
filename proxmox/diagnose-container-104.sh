#!/bin/bash

# Diagnostic Script for Container 104
# Run from Proxmox HOST

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
print_section() { echo -e "${CYAN}=== $1 ===${NC}"; }

echo "========================================"
echo "  Diagnostic: Container 104"
echo "  Run from Proxmox HOST"
echo "========================================"
echo ""

# Check container status
print_section "Container Status"
pct status $CONTAINER_ID
echo ""

# Check if service is running
print_section "Service Status"
pct exec $CONTAINER_ID -- systemctl status uptime-monitor --no-pager
echo ""

# Check for monitoring initialization
print_section "Looking for Monitoring Initialization"
pct exec $CONTAINER_ID -- journalctl -u uptime-monitor --no-pager | grep -i "MONITORING" | tail -20
echo ""

# Check recent logs
print_section "Recent Logs (last 30 lines)"
pct exec $CONTAINER_ID -- journalctl -u uptime-monitor -n 30 --no-pager
echo ""

# Check if monitoring API responds
print_section "Monitoring API Status"
pct exec $CONTAINER_ID -- curl -s http://localhost:3000/api/monitoring/status 2>/dev/null
echo ""
echo ""

# Check the actual file for server-side monitoring code
print_section "Checking for Server-Side Monitoring Code"
if pct exec $CONTAINER_ID -- grep -q "SERVER-SIDE MONITORING ENGINE" /opt/uptime-monitor/uptime-monitor-api.js; then
    print_success "Server-side monitoring code is present in file"
else
    print_error "Server-side monitoring code NOT FOUND in file"
    echo "The file needs to be updated!"
fi
echo ""

# Check git status
print_section "Git Repository Status"
pct exec $CONTAINER_ID -- bash -c "cd /opt/uptime-monitor && git log -1 --oneline"
echo ""
pct exec $CONTAINER_ID -- bash -c "cd /opt/uptime-monitor && git status"
echo ""

print_section "Summary"
echo "If monitoring code is NOT present, run: ./fix-container-104.sh"
echo "To view live logs: pct exec 104 -- journalctl -u uptime-monitor -f"

