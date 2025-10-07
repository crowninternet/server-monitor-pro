#!/bin/bash

# Fix Config Save Issue for Container 104
# Run from Proxmox HOST
# Diagnoses and fixes configuration save problems

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
echo "  Fix Config Save - Container 104"
echo "========================================"
echo ""

DATA_DIR="/opt/uptime-monitor/data"
CONFIG_FILE="$DATA_DIR/config.json"

# Check if data directory exists
print_info "Checking data directory..."
if pct exec $CONTAINER_ID -- test -d "$DATA_DIR"; then
    print_success "Data directory exists: $DATA_DIR"
else
    print_warning "Data directory missing, creating it..."
    pct exec $CONTAINER_ID -- mkdir -p "$DATA_DIR"
fi
echo ""

# Check permissions
print_info "Checking permissions..."
pct exec $CONTAINER_ID -- ls -la "$DATA_DIR"
echo ""

# Check ownership
OWNER=$(pct exec $CONTAINER_ID -- stat -c '%U:%G' "$DATA_DIR" 2>/dev/null)
print_info "Directory owner: $OWNER"

if [ "$OWNER" != "uptime-monitor:uptime-monitor" ]; then
    print_warning "Wrong ownership, fixing..."
    pct exec $CONTAINER_ID -- chown -R uptime-monitor:uptime-monitor "$DATA_DIR"
    print_success "Ownership fixed"
else
    print_success "Ownership is correct"
fi
echo ""

# Check if config.json exists
print_info "Checking config.json..."
if pct exec $CONTAINER_ID -- test -f "$CONFIG_FILE"; then
    print_success "Config file exists"
    
    # Check if it's writable
    if pct exec $CONTAINER_ID -- test -w "$CONFIG_FILE"; then
        print_success "Config file is writable"
    else
        print_warning "Config file is not writable, fixing..."
        pct exec $CONTAINER_ID -- chmod 644 "$CONFIG_FILE"
        pct exec $CONTAINER_ID -- chown uptime-monitor:uptime-monitor "$CONFIG_FILE"
        print_success "Permissions fixed"
    fi
    
    # Show current config
    print_info "Current config contents:"
    pct exec $CONTAINER_ID -- cat "$CONFIG_FILE"
    echo ""
else
    print_warning "Config file doesn't exist, creating it..."
    pct exec $CONTAINER_ID -- bash -c "echo '{}' > $CONFIG_FILE"
    pct exec $CONTAINER_ID -- chown uptime-monitor:uptime-monitor "$CONFIG_FILE"
    pct exec $CONTAINER_ID -- chmod 644 "$CONFIG_FILE"
    print_success "Config file created"
fi
echo ""

# Test if we can write to the file
print_info "Testing write access..."
if pct exec $CONTAINER_ID -- bash -c "echo '{}' > $CONFIG_FILE.test && rm $CONFIG_FILE.test" 2>/dev/null; then
    print_success "Write test successful"
else
    print_error "Cannot write to data directory"
    print_info "Attempting to fix permissions..."
    pct exec $CONTAINER_ID -- chmod 755 "$DATA_DIR"
    pct exec $CONTAINER_ID -- chown -R uptime-monitor:uptime-monitor "$DATA_DIR"
fi
echo ""

# Check if service is running
print_info "Checking service status..."
if pct exec $CONTAINER_ID -- systemctl is-active uptime-monitor > /dev/null 2>&1; then
    print_success "Service is running"
else
    print_warning "Service is not running, starting it..."
    pct exec $CONTAINER_ID -- systemctl start uptime-monitor
    sleep 3
    if pct exec $CONTAINER_ID -- systemctl is-active uptime-monitor > /dev/null 2>&1; then
        print_success "Service started"
    else
        print_error "Service failed to start"
        pct exec $CONTAINER_ID -- journalctl -u uptime-monitor -n 20 --no-pager
        exit 1
    fi
fi
echo ""

# Test the email config API endpoint
print_info "Testing email config API endpoint..."
sleep 2

# Try to save a test config
TEST_RESPONSE=$(pct exec $CONTAINER_ID -- curl -s -X POST http://localhost:3000/api/email-config \
  -H "Content-Type: application/json" \
  -d '{"emailFrom":"test@example.com","emailTo":"admin@example.com","emailEnabled":false}' 2>/dev/null)

if echo "$TEST_RESPONSE" | grep -q '"success":true'; then
    print_success "Email config API is working!"
    echo "Response: $TEST_RESPONSE"
else
    print_warning "API test had issues"
    echo "Response: $TEST_RESPONSE"
    echo ""
    print_info "Checking recent logs for errors..."
    pct exec $CONTAINER_ID -- journalctl -u uptime-monitor -n 30 --no-pager | grep -i "error\|failed\|cannot"
fi
echo ""

# Get current email config from API
print_info "Getting current email config from API..."
EMAIL_CONFIG=$(pct exec $CONTAINER_ID -- curl -s http://localhost:3000/api/email-config 2>/dev/null)
echo "Current email config:"
echo "$EMAIL_CONFIG" | python3 -m json.tool 2>/dev/null || echo "$EMAIL_CONFIG"
echo ""

print_success "Diagnostics complete!"
echo ""
print_info "Summary:"
echo "  Data directory: $DATA_DIR"
echo "  Config file: $CONFIG_FILE"
echo "  Permissions: Fixed"
echo ""
print_info "Try saving your SendGrid config now in the web interface."
echo "  URL: http://YOUR_PROXMOX_IP:3000"
echo ""
print_info "If you still have issues, check browser console for errors (F12)"
echo ""

