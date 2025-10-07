#!/bin/bash

# Deploy updated Uptime Monitor to Proxmox
# This script copies the updated files and restarts the service

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_header() {
    echo -e "${CYAN}================================${NC}"
    echo -e "${CYAN}  Deploy to Proxmox Server${NC}"
    echo -e "${CYAN}================================${NC}"
    echo ""
}

print_header

# Check if SSH config is provided
if [ -z "$1" ]; then
    print_error "Please provide SSH connection details"
    echo ""
    echo "Usage: $0 <user@host> [install_dir]"
    echo ""
    echo "Examples:"
    echo "  $0 root@192.168.1.100"
    echo "  $0 root@proxmox.local"
    echo "  $0 root@192.168.1.100 /opt/uptime-monitor"
    echo ""
    exit 1
fi

SSH_HOST="$1"
INSTALL_DIR="${2:-/opt/uptime-monitor}"

print_info "SSH Host: $SSH_HOST"
print_info "Install Directory: $INSTALL_DIR"
echo ""

# Test SSH connection
print_info "Testing SSH connection..."
if ! ssh -o ConnectTimeout=5 "$SSH_HOST" "echo 'SSH connection OK'" > /dev/null 2>&1; then
    print_error "Cannot connect to $SSH_HOST"
    print_info "Please check your SSH configuration and try again"
    exit 1
fi
print_success "SSH connection OK"
echo ""

# Check if uptime-monitor-api.js exists locally
if [ ! -f "./uptime-monitor-api.js" ]; then
    print_error "uptime-monitor-api.js not found in current directory"
    print_info "Please run this script from the uptime-monitor directory"
    exit 1
fi

# Create backup on remote server
print_info "Creating backup on remote server..."
ssh "$SSH_HOST" "cd $INSTALL_DIR && sudo cp uptime-monitor-api.js uptime-monitor-api.js.backup-$(date +%Y%m%d-%H%M%S)" || true
print_success "Backup created"
echo ""

# Copy updated file to remote server
print_info "Copying updated uptime-monitor-api.js to remote server..."
scp ./uptime-monitor-api.js "$SSH_HOST:/tmp/uptime-monitor-api.js.new"
if [ $? -ne 0 ]; then
    print_error "Failed to copy file to remote server"
    exit 1
fi
print_success "File copied to remote server"
echo ""

# Move file to install directory and set permissions
print_info "Installing updated file..."
ssh "$SSH_HOST" "sudo mv /tmp/uptime-monitor-api.js.new $INSTALL_DIR/uptime-monitor-api.js && sudo chown uptime-monitor:uptime-monitor $INSTALL_DIR/uptime-monitor-api.js && sudo chmod 644 $INSTALL_DIR/uptime-monitor-api.js"
if [ $? -ne 0 ]; then
    print_error "Failed to install file"
    exit 1
fi
print_success "File installed successfully"
echo ""

# Restart the service
print_info "Restarting uptime-monitor service..."
ssh "$SSH_HOST" "sudo systemctl restart uptime-monitor"
if [ $? -ne 0 ]; then
    print_error "Failed to restart service"
    exit 1
fi
print_success "Service restarted"
echo ""

# Wait for service to start
print_info "Waiting for service to start..."
sleep 3

# Check service status
print_info "Checking service status..."
ssh "$SSH_HOST" "sudo systemctl is-active uptime-monitor" > /dev/null 2>&1
if [ $? -eq 0 ]; then
    print_success "Service is running!"
else
    print_warning "Service may not be running. Checking logs..."
    echo ""
    print_info "Recent log entries:"
    ssh "$SSH_HOST" "sudo journalctl -u uptime-monitor --no-pager -n 20"
    exit 1
fi
echo ""

# Show monitoring status
print_info "Checking monitoring status..."
sleep 2
echo ""
ssh "$SSH_HOST" "sudo journalctl -u uptime-monitor --no-pager -n 30 | grep -E 'MONITORING|monitoring|Starting monitoring'"
echo ""

print_success "Deployment completed successfully!"
echo ""
print_info "The server-side monitoring engine is now active."
print_info "Checks will run automatically even when the browser is closed."
echo ""
print_info "To view real-time logs:"
echo "  ssh $SSH_HOST 'sudo journalctl -u uptime-monitor -f'"
echo ""

