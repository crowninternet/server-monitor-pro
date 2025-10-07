#!/bin/bash

# Fix Script for Container 104
# Run from Proxmox HOST
# Forces update to latest code with server-side monitoring

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
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }

echo "========================================"
echo "  Fix Container 104"
echo "  Run from Proxmox HOST"
echo "========================================"
echo ""

print_warning "This will force update container 104 with server-side monitoring"
read -p "Continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_info "Cancelled"
    exit 0
fi
echo ""

# Stop the service
print_info "Step 1/7: Stopping service..."
pct exec $CONTAINER_ID -- systemctl stop uptime-monitor
sleep 2
print_success "Service stopped"
echo ""

# Backup current file
print_info "Step 2/7: Creating backup..."
pct exec $CONTAINER_ID -- bash -c "cd /opt/uptime-monitor && cp uptime-monitor-api.js uptime-monitor-api.js.backup-\$(date +%Y%m%d-%H%M%S)"
print_success "Backup created"
echo ""

# Check if git is available
print_info "Step 3/7: Checking for git..."
if pct exec $CONTAINER_ID -- command -v git &> /dev/null; then
    print_info "Git found, using git pull..."
    pct exec $CONTAINER_ID -- bash -c "cd /opt/uptime-monitor && git fetch origin && git reset --hard origin/master"
    if [ $? -eq 0 ]; then
        print_success "Repository updated via git"
    else
        print_error "Git update failed"
        exit 1
    fi
else
    print_warning "Git not found, downloading file directly from GitHub..."
    pct exec $CONTAINER_ID -- bash -c "cd /opt/uptime-monitor && curl -fsSL https://raw.githubusercontent.com/crowninternet/server-monitor-pro/master/uptime-monitor-api.js -o uptime-monitor-api.js.new && mv uptime-monitor-api.js.new uptime-monitor-api.js"
    if [ $? -eq 0 ]; then
        print_success "File downloaded from GitHub"
    else
        print_error "Download failed"
        exit 1
    fi
fi
echo ""

# Fix ownership
print_info "Step 4/7: Fixing file ownership..."
pct exec $CONTAINER_ID -- chown -R uptime-monitor:uptime-monitor /opt/uptime-monitor
print_success "Ownership fixed"
echo ""

# Verify monitoring code is present
print_info "Step 5/7: Verifying server-side monitoring code..."
if pct exec $CONTAINER_ID -- grep -q "SERVER-SIDE MONITORING ENGINE" /opt/uptime-monitor/uptime-monitor-api.js; then
    print_success "Server-side monitoring code verified in file"
else
    print_error "Server-side monitoring code STILL NOT FOUND!"
    print_warning "There may be a problem with the repository"
    exit 1
fi
echo ""

# Start the service
print_info "Step 6/7: Starting service..."
pct exec $CONTAINER_ID -- systemctl start uptime-monitor
sleep 3
print_success "Service started"
echo ""

# Check service status
print_info "Step 7/7: Checking service status..."
if pct exec $CONTAINER_ID -- systemctl is-active uptime-monitor > /dev/null 2>&1; then
    print_success "Service is running"
else
    print_error "Service failed to start"
    echo ""
    print_info "Showing error logs:"
    pct exec $CONTAINER_ID -- journalctl -u uptime-monitor -n 30 --no-pager
    exit 1
fi
echo ""

# Show monitoring initialization
print_info "Waiting for monitoring to initialize..."
sleep 3
echo ""

print_info "Recent logs:"
echo "----------------------------------------"
pct exec $CONTAINER_ID -- journalctl -u uptime-monitor -n 40 --no-pager | grep -E "MONITORING|Starting monitoring|Check complete|Server-side" || pct exec $CONTAINER_ID -- journalctl -u uptime-monitor -n 20 --no-pager
echo "----------------------------------------"
echo ""

# Check monitoring API
print_info "Checking monitoring API..."
sleep 2
MONITORING_STATUS=$(pct exec $CONTAINER_ID -- curl -s http://localhost:3000/api/monitoring/status 2>/dev/null)
if [ $? -eq 0 ] && [ ! -z "$MONITORING_STATUS" ]; then
    echo "$MONITORING_STATUS" | python3 -m json.tool 2>/dev/null || echo "$MONITORING_STATUS"
    echo ""
    
    # Check if activeMonitors > 0
    if echo "$MONITORING_STATUS" | grep -q '"activeMonitors"'; then
        ACTIVE=$(echo "$MONITORING_STATUS" | grep -o '"activeMonitors":[0-9]*' | grep -o '[0-9]*')
        if [ "$ACTIVE" -gt 0 ]; then
            print_success "Server-side monitoring is ACTIVE with $ACTIVE monitors running!"
        else
            print_warning "Monitoring engine running but no active monitors"
            print_info "You may need to add servers or start monitoring via the web interface"
        fi
    fi
else
    print_warning "Could not get monitoring status (API may still be starting)"
fi
echo ""

print_success "Fix completed!"
echo ""
print_info "Server-side monitoring should now be running 24/7"
print_info "Checks will continue even when browser is closed"
echo ""
print_info "To watch live logs:"
echo "  pct exec 104 -- journalctl -u uptime-monitor -f"
echo ""
print_info "To check monitoring status:"
echo "  pct exec 104 -- curl http://localhost:3000/api/monitoring/status"
echo ""

