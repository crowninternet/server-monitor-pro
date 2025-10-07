#!/bin/bash

# Verify Server-Side Monitoring is Working
# Run this script to check if the monitoring engine is active

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }
print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }

if [ -z "$1" ]; then
    print_error "Please provide SSH connection details"
    echo ""
    echo "Usage: $0 <user@host>"
    echo "Example: $0 root@192.168.1.100"
    exit 1
fi

SSH_HOST="$1"

echo "========================================"
echo "  Monitoring Verification"
echo "========================================"
echo ""

# Test SSH
print_info "Testing SSH connection..."
if ! ssh -o ConnectTimeout=5 "$SSH_HOST" "echo 'OK'" > /dev/null 2>&1; then
    print_error "Cannot connect to $SSH_HOST"
    exit 1
fi
print_success "SSH connected"
echo ""

# Check service status
print_info "Checking service status..."
if ssh "$SSH_HOST" "systemctl is-active uptime-monitor" > /dev/null 2>&1; then
    print_success "Service is running"
else
    print_error "Service is NOT running"
    exit 1
fi
echo ""

# Check API health
print_info "Checking API health..."
API_RESPONSE=$(ssh "$SSH_HOST" "curl -s http://localhost:3000/api/health")
if [ $? -eq 0 ]; then
    print_success "API is responding"
    echo "Response: $API_RESPONSE"
else
    print_error "API is not responding"
fi
echo ""

# Check monitoring status
print_info "Checking monitoring status..."
MONITORING_STATUS=$(ssh "$SSH_HOST" "curl -s http://localhost:3000/api/monitoring/status")
if [ $? -eq 0 ]; then
    print_success "Monitoring API is responding"
    echo "$MONITORING_STATUS" | python3 -m json.tool 2>/dev/null || echo "$MONITORING_STATUS"
else
    print_warning "Cannot check monitoring status"
fi
echo ""

# Show recent monitoring logs
print_info "Recent monitoring activity (last 30 lines with monitoring keywords):"
echo "----------------------------------------"
ssh "$SSH_HOST" "journalctl -u uptime-monitor --no-pager -n 50 | grep -i -E 'monitoring|checking|check complete|server.*up|server.*down'"
echo "----------------------------------------"
echo ""

# Get server count
print_info "Getting server list..."
SERVERS=$(ssh "$SSH_HOST" "curl -s http://localhost:3000/api/servers")
if [ $? -eq 0 ]; then
    SERVER_COUNT=$(echo "$SERVERS" | python3 -c "import sys, json; print(len(json.load(sys.stdin)['servers']))" 2>/dev/null || echo "?")
    print_success "Found $SERVER_COUNT servers configured"
else
    print_warning "Cannot retrieve server list"
fi
echo ""

# Final summary
echo "========================================"
echo "  Summary"
echo "========================================"
print_info "To view live monitoring logs:"
echo "  ssh $SSH_HOST 'sudo journalctl -u uptime-monitor -f'"
echo ""
print_info "To manually restart monitoring:"
echo "  ssh $SSH_HOST 'sudo systemctl restart uptime-monitor'"
echo ""
print_info "Web interface:"
echo "  http://[YOUR_PROXMOX_IP]:3000"
echo ""

print_success "Verification complete!"

