#!/bin/bash

# Verify Server-Side Monitoring for Container 104
# Run from Proxmox HOST

CONTAINER_ID=104

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }
print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }

echo "========================================"
echo "  Verify Monitoring - Container 104"
echo "========================================"
echo ""

# 1. Check if server-side monitoring code exists in file
print_info "1. Checking if server-side monitoring code is in file..."
if pct exec $CONTAINER_ID -- grep -q "SERVER-SIDE MONITORING ENGINE" /opt/uptime-monitor/uptime-monitor-api.js; then
    print_success "Server-side monitoring code is present"
else
    print_error "Server-side monitoring code NOT FOUND!"
    echo ""
    print_warning "The file needs to be updated. Run ./patch-container-104.sh first"
    exit 1
fi
echo ""

# 2. Check if monitoring initialization message is in logs
print_info "2. Checking logs for monitoring initialization..."
if pct exec $CONTAINER_ID -- journalctl -u uptime-monitor --no-pager | grep -q "INITIALIZING SERVER-SIDE MONITORING"; then
    print_success "Monitoring initialization found in logs"
    pct exec $CONTAINER_ID -- journalctl -u uptime-monitor --no-pager | grep "MONITORING" | tail -5
else
    print_error "Monitoring initialization NOT found in logs"
    print_warning "Service may need to be restarted"
fi
echo ""

# 3. Check monitoring API endpoint
print_info "3. Checking monitoring API endpoint..."
MONITORING_STATUS=$(pct exec $CONTAINER_ID -- curl -s http://localhost:3000/api/monitoring/status 2>/dev/null)

if [ $? -eq 0 ] && [ ! -z "$MONITORING_STATUS" ]; then
    if echo "$MONITORING_STATUS" | grep -q '"enabled"'; then
        print_success "Monitoring API is responding"
        echo "$MONITORING_STATUS" | python3 -m json.tool 2>/dev/null || echo "$MONITORING_STATUS"
        
        # Check if there are active monitors
        ACTIVE_MONITORS=$(echo "$MONITORING_STATUS" | grep -o '"activeMonitors":[0-9]*' | grep -o '[0-9]*')
        if [ ! -z "$ACTIVE_MONITORS" ] && [ "$ACTIVE_MONITORS" -gt 0 ]; then
            print_success "Active monitors: $ACTIVE_MONITORS"
        else
            print_warning "No active monitors running (activeMonitors: 0)"
            print_info "You may need to add servers or they may all be stopped"
        fi
    else
        print_error "Monitoring API returned unexpected response"
        echo "$MONITORING_STATUS"
    fi
else
    print_error "Monitoring API is not responding"
    echo "Response: $MONITORING_STATUS"
fi
echo ""

# 4. Check for recent check activity
print_info "4. Looking for recent check activity in logs..."
RECENT_CHECKS=$(pct exec $CONTAINER_ID -- journalctl -u uptime-monitor --since "5 minutes ago" --no-pager | grep "Check complete" | tail -5)

if [ ! -z "$RECENT_CHECKS" ]; then
    print_success "Found recent checks in logs:"
    echo "$RECENT_CHECKS"
else
    print_warning "No recent checks found in logs"
    print_info "Checking if any checks have ever run..."
    
    ALL_CHECKS=$(pct exec $CONTAINER_ID -- journalctl -u uptime-monitor --no-pager | grep "Check complete" | tail -5)
    if [ ! -z "$ALL_CHECKS" ]; then
        print_info "Found older checks:"
        echo "$ALL_CHECKS"
    else
        print_error "No checks found in logs at all"
    fi
fi
echo ""

# 5. Check how many servers are configured
print_info "5. Checking configured servers..."
if pct exec $CONTAINER_ID -- test -f /opt/uptime-monitor/data/servers.json; then
    SERVER_COUNT=$(pct exec $CONTAINER_ID -- cat /opt/uptime-monitor/data/servers.json | grep -o '"id"' | wc -l | tr -d ' ')
    STOPPED_COUNT=$(pct exec $CONTAINER_ID -- cat /opt/uptime-monitor/data/servers.json | grep -o '"stopped":true' | wc -l | tr -d ' ')
    
    print_info "Total servers: $SERVER_COUNT"
    print_info "Stopped servers: $STOPPED_COUNT"
    
    if [ "$SERVER_COUNT" -gt 0 ]; then
        ACTIVE_SERVERS=$((SERVER_COUNT - STOPPED_COUNT))
        if [ "$ACTIVE_SERVERS" -gt 0 ]; then
            print_success "$ACTIVE_SERVERS active server(s) configured"
        else
            print_warning "All servers are stopped!"
        fi
    else
        print_warning "No servers configured"
    fi
else
    print_error "servers.json not found"
fi
echo ""

# Summary
echo "========================================"
echo "  SUMMARY"
echo "========================================"
echo ""

# Determine overall status
HAS_CODE=$(pct exec $CONTAINER_ID -- grep -q "SERVER-SIDE MONITORING ENGINE" /opt/uptime-monitor/uptime-monitor-api.js && echo "yes" || echo "no")
HAS_API=$(echo "$MONITORING_STATUS" | grep -q '"enabled"' && echo "yes" || echo "no")
HAS_CHECKS=$([ ! -z "$RECENT_CHECKS" ] && echo "yes" || echo "no")

if [ "$HAS_CODE" = "yes" ] && [ "$HAS_API" = "yes" ] && [ "$HAS_CHECKS" = "yes" ]; then
    print_success "Server-side monitoring is WORKING!"
    echo ""
    print_info "To test:"
    echo "  1. Close all browser windows"
    echo "  2. Wait 5 minutes"
    echo "  3. Run: pct exec 104 -- journalctl -u uptime-monitor --since '10 minutes ago' | grep 'Check complete'"
    echo ""
elif [ "$HAS_CODE" = "yes" ] && [ "$HAS_API" = "yes" ]; then
    print_warning "Monitoring code is present but no checks are running"
    echo ""
    print_info "Possible causes:"
    echo "  - No servers configured (add servers in web interface)"
    echo "  - All servers are stopped (check web interface)"
    echo "  - Service needs restart"
    echo ""
    print_info "Try restarting the service:"
    echo "  pct exec 104 -- systemctl restart uptime-monitor"
    echo "  pct exec 104 -- journalctl -u uptime-monitor -f"
    echo ""
elif [ "$HAS_CODE" = "no" ]; then
    print_error "Server-side monitoring code is NOT in the file"
    echo ""
    print_info "You need to update the file:"
    echo "  wget https://raw.githubusercontent.com/crowninternet/server-monitor-pro/master/proxmox/patch-container-104.sh"
    echo "  chmod +x patch-container-104.sh"
    echo "  ./patch-container-104.sh"
    echo ""
else
    print_error "Monitoring is not working properly"
    echo ""
    print_info "Check the logs for errors:"
    echo "  pct exec 104 -- journalctl -u uptime-monitor -n 50"
    echo ""
fi

