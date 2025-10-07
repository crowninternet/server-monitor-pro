#!/bin/bash

# Uptime Monitor Pro - Update Script for Proxmox Host
# This script runs from the Proxmox HOST and updates the container
# Usage: ./update-from-git.sh [container-id]

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
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
    echo -e "${PURPLE}========================================${NC}"
    echo -e "${PURPLE}  Uptime Monitor Pro - Git Update${NC}"
    echo -e "${PURPLE}  ⚠️  RUN FROM PROXMOX HOST (NOT CONTAINER)${NC}"
    echo -e "${PURPLE}========================================${NC}"
    echo ""
}

# Check if running on Proxmox host
check_proxmox_host() {
    if ! command -v pct &> /dev/null; then
        print_error "This script must be run from a Proxmox host (pct command not found)"
        exit 1
    fi
}

# Find container ID
find_container() {
    print_info "Looking for Uptime Monitor container..."
    
    # Try to find container with uptime-monitor in the name
    FOUND_CONTAINERS=$(pct list | grep -i "uptime" | awk '{print $1}')
    
    if [ -z "$FOUND_CONTAINERS" ]; then
        print_warning "No container found with 'uptime' in the name"
        echo ""
        print_info "Available containers:"
        pct list
        echo ""
        return 1
    fi
    
    # If multiple containers found, list them
    CONTAINER_COUNT=$(echo "$FOUND_CONTAINERS" | wc -l)
    if [ $CONTAINER_COUNT -gt 1 ]; then
        print_warning "Multiple containers found:"
        pct list | grep -i "uptime"
        echo ""
        return 1
    fi
    
    CONTAINER_ID=$FOUND_CONTAINERS
    return 0
}

# Check if container is running
check_container_running() {
    local container_id=$1
    STATUS=$(pct status $container_id 2>/dev/null)
    
    if [ $? -ne 0 ]; then
        print_error "Container $container_id not found"
        return 1
    fi
    
    if [[ ! $STATUS =~ "running" ]]; then
        print_error "Container $container_id is not running"
        print_info "Start it with: pct start $container_id"
        return 1
    fi
    
    return 0
}

# Execute command in container
exec_in_container() {
    local container_id=$1
    local command=$2
    pct exec $container_id -- bash -c "$command"
}

# Main update function
update_container() {
    local container_id=$1
    
    print_header
    
    print_info "Container ID: $container_id"
    print_info "Updating Uptime Monitor from git..."
    echo ""
    
    # Check container is running
    if ! check_container_running $container_id; then
        exit 1
    fi
    
    print_success "Container is running"
    echo ""
    
    # Create backup
    print_info "Step 1/5: Creating backup..."
    exec_in_container $container_id "cd /opt/uptime-monitor && cp uptime-monitor-api.js uptime-monitor-api.js.backup-\$(date +%Y%m%d-%H%M%S)"
    if [ $? -eq 0 ]; then
        print_success "Backup created"
    else
        print_error "Failed to create backup"
        exit 1
    fi
    echo ""
    
    # Pull from git
    print_info "Step 2/5: Pulling latest changes from git..."
    exec_in_container $container_id "cd /opt/uptime-monitor && sudo -u uptime-monitor git pull origin master"
    if [ $? -eq 0 ]; then
        print_success "Git pull successful"
    else
        print_error "Git pull failed"
        print_info "You may need to reset the repository first"
        exit 1
    fi
    echo ""
    
    # Restart service
    print_info "Step 3/5: Restarting service..."
    exec_in_container $container_id "systemctl restart uptime-monitor"
    sleep 3
    if [ $? -eq 0 ]; then
        print_success "Service restarted"
    else
        print_error "Failed to restart service"
        exit 1
    fi
    echo ""
    
    # Check service status
    print_info "Step 4/5: Checking service status..."
    SERVICE_STATUS=$(exec_in_container $container_id "systemctl is-active uptime-monitor")
    if [[ "$SERVICE_STATUS" == *"active"* ]]; then
        print_success "Service is running"
    else
        print_error "Service is not running"
        print_info "Check logs: pct exec $container_id -- journalctl -u uptime-monitor -n 50"
        exit 1
    fi
    echo ""
    
    # Show monitoring status
    print_info "Step 5/5: Checking monitoring engine..."
    echo ""
    
    # Wait a moment for monitoring to initialize
    sleep 2
    
    # Show recent logs with monitoring activity
    print_info "Recent logs:"
    echo "----------------------------------------"
    exec_in_container $container_id "journalctl -u uptime-monitor -n 30 | grep -E 'MONITORING|Starting monitoring|Check complete|activeMonitors' || journalctl -u uptime-monitor -n 15"
    echo "----------------------------------------"
    echo ""
    
    # Check monitoring API
    print_info "Monitoring API status:"
    API_STATUS=$(exec_in_container $container_id "curl -s http://localhost:3000/api/monitoring/status 2>/dev/null")
    if [ $? -eq 0 ] && [ ! -z "$API_STATUS" ]; then
        echo "$API_STATUS" | python3 -m json.tool 2>/dev/null || echo "$API_STATUS"
    else
        print_warning "Could not get monitoring status (API may still be starting)"
    fi
    echo ""
    
    # Final success message
    print_success "Update completed successfully!"
    echo ""
    print_info "Server-side monitoring is now active!"
    print_info "Checks will run automatically even when browser is closed."
    echo ""
    print_info "Useful commands:"
    echo "  View live logs:          pct exec $container_id -- journalctl -u uptime-monitor -f"
    echo "  Check service status:    pct exec $container_id -- systemctl status uptime-monitor"
    echo "  Check monitoring API:    pct exec $container_id -- curl http://localhost:3000/api/monitoring/status"
    echo "  Restart service:         pct exec $container_id -- systemctl restart uptime-monitor"
    echo ""
}

# Show help
show_help() {
    print_header
    echo "Usage: $0 [container-id]"
    echo ""
    echo "Updates Uptime Monitor from git repository."
    echo ""
    echo "Options:"
    echo "  container-id    LXC container ID (optional - will auto-detect if not provided)"
    echo ""
    echo "Examples:"
    echo "  $0              # Auto-detect container"
    echo "  $0 100          # Update container 100"
    echo ""
    echo "This script:"
    echo "  1. Creates a backup of the current file"
    echo "  2. Pulls latest changes from git"
    echo "  3. Restarts the uptime-monitor service"
    echo "  4. Verifies monitoring is active"
    echo ""
}

# Main script
main() {
    # Check if running on Proxmox
    check_proxmox_host
    
    # Parse arguments
    if [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
        show_help
        exit 0
    fi
    
    # Get container ID
    if [ -n "$1" ]; then
        CONTAINER_ID=$1
        print_info "Using specified container ID: $CONTAINER_ID"
    else
        if ! find_container; then
            print_error "Could not auto-detect container"
            echo ""
            print_info "Please specify container ID manually:"
            echo "  $0 CONTAINER_ID"
            echo ""
            print_info "Available containers:"
            pct list
            exit 1
        fi
        print_success "Found container: $CONTAINER_ID"
    fi
    
    echo ""
    
    # Confirm before proceeding
    read -p "Update container $CONTAINER_ID? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Update cancelled"
        exit 0
    fi
    
    # Run update
    update_container $CONTAINER_ID
}

# Run main
main "$@"

