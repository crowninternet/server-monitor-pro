#!/bin/bash

# Uptime Monitor Pro - Management Script for Proxmox + Debian
# Usage: sudo ./manage-uptime-monitor.sh {start|stop|restart|status|logs|uninstall}

INSTALL_DIR="/opt/uptime-monitor"
SERVICE_NAME="uptime-monitor"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"
USER_NAME="uptime-monitor"
CONTAINER_ID=$(hostname)

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
    echo -e "${PURPLE}================================${NC}"
    echo -e "${PURPLE}  Uptime Monitor Pro Manager${NC}"
    echo -e "${PURPLE}  Proxmox + Debian Edition${NC}"
    echo -e "${PURPLE}================================${NC}"
    echo ""
}

# Function to check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root (use sudo)"
        exit 1
    fi
}

# Function to show system information
show_system_info() {
    print_header
    echo "System Information:"
    echo "==================="
    echo "Container ID: $CONTAINER_ID"
    echo "Install Directory: $INSTALL_DIR"
    echo "Service Name: $SERVICE_NAME"
    echo "System User: $USER_NAME"
    echo ""
    
    # Show resource usage
    if command -v free >/dev/null 2>&1; then
        echo "Memory Usage:"
        free -h
        echo ""
    fi
    
    if command -v df >/dev/null 2>&1; then
        echo "Disk Usage:"
        df -h "$INSTALL_DIR"
        echo ""
    fi
    
    # Show container-specific info
    if [ -f /proc/1/environ ] && grep -q "container=lxc" /proc/1/environ 2>/dev/null; then
        echo "Container Information:"
        echo "Type: Proxmox LXC"
        if [ -f /proc/version ]; then
            echo "Kernel: $(cat /proc/version | cut -d' ' -f3)"
        fi
        echo ""
    fi
}

# Function to show service status
show_status() {
    print_header
    echo "Checking Uptime Monitor status..."
    echo ""
    
    if systemctl is-active --quiet "$SERVICE_NAME"; then
        print_success "Service is running"
        
        # Show service details
        echo "Service Details:"
        systemctl show "$SERVICE_NAME" --property=ActiveState,SubState,MainPID,MemoryCurrent,CPUUsageNSec --no-pager
        echo ""
        
        # Show resource usage
        if systemctl show "$SERVICE_NAME" --property=MemoryCurrent --value >/dev/null 2>&1; then
            MEMORY_USAGE=$(systemctl show "$SERVICE_NAME" --property=MemoryCurrent --value)
            if [ "$MEMORY_USAGE" != "0" ] && [ "$MEMORY_USAGE" != "" ]; then
                MEMORY_MB=$((MEMORY_USAGE / 1024 / 1024))
                echo "Memory Usage: ${MEMORY_MB}MB"
            fi
        fi
        
        echo ""
        if curl -s http://localhost:3000/api/health > /dev/null 2>&1; then
            print_success "API is responding at http://localhost:3000"
            print_info "Web interface: http://localhost:3000"
            
            # Show API response
            echo ""
            echo "API Health Check:"
            curl -s http://localhost:3000/api/health | python3 -m json.tool 2>/dev/null || curl -s http://localhost:3000/api/health
        else
            print_warning "API is not responding (may still be starting up)"
        fi
    else
        print_error "Service is not running"
        print_info "Run 'sudo $0 start' to start the service"
    fi
}

# Function to show help
show_help() {
    print_header
    echo "Usage: sudo $0 {command}"
    echo ""
    echo "Commands:"
    echo "  start     - Start the Uptime Monitor service"
    echo "  stop      - Stop the Uptime Monitor service"
    echo "  restart   - Restart the Uptime Monitor service"
    echo "  status    - Check if the service is running"
    echo "  logs      - Show recent log entries"
    echo "  logs-tail - Follow log entries in real-time"
    echo "  test      - Test API connectivity"
    echo "  info      - Show system information"
    echo "  backup    - Create backup of configuration and data"
    echo "  restore   - Restore from backup"
    echo "  update    - Update the application"
    echo "  uninstall - Remove Uptime Monitor completely"
    echo "  help      - Show this help message"
    echo ""
    echo "Configuration:"
    echo "  Install Directory: $INSTALL_DIR"
    echo "  Service Name: $SERVICE_NAME"
    echo "  Service File: $SERVICE_FILE"
    echo "  System User: $USER_NAME"
    echo "  Container ID: $CONTAINER_ID"
    echo ""
    echo "Examples:"
    echo "  sudo $0 start      # Start the service"
    echo "  sudo $0 status     # Check service status"
    echo "  sudo $0 logs       # View recent logs"
    echo "  sudo $0 backup     # Create backup"
    echo ""
}

# Function to create backup
create_backup() {
    print_info "Creating backup of Uptime Monitor..."
    
    BACKUP_DIR="/tmp/uptime-monitor-backup-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    
    # Backup application files
    if [ -d "$INSTALL_DIR" ]; then
        cp -r "$INSTALL_DIR" "$BACKUP_DIR/"
        print_info "Application files backed up"
    fi
    
    # Backup service file
    if [ -f "$SERVICE_FILE" ]; then
        cp "$SERVICE_FILE" "$BACKUP_DIR/"
        print_info "Service file backed up"
    fi
    
    # Backup systemd logs
    if command -v journalctl >/dev/null 2>&1; then
        journalctl -u "$SERVICE_NAME" --no-pager > "$BACKUP_DIR/service-logs.txt" 2>/dev/null || true
        print_info "Service logs backed up"
    fi
    
    # Create backup archive
    tar -czf "${BACKUP_DIR}.tar.gz" -C /tmp "$(basename "$BACKUP_DIR")"
    rm -rf "$BACKUP_DIR"
    
    print_success "Backup created: ${BACKUP_DIR}.tar.gz"
    print_info "Backup size: $(du -h "${BACKUP_DIR}.tar.gz" | cut -f1)"
}

# Function to restore from backup
restore_backup() {
    if [ -z "$2" ]; then
        print_error "Please specify backup file path"
        print_info "Usage: sudo $0 restore /path/to/backup.tar.gz"
        exit 1
    fi
    
    BACKUP_FILE="$2"
    
    if [ ! -f "$BACKUP_FILE" ]; then
        print_error "Backup file not found: $BACKUP_FILE"
        exit 1
    fi
    
    print_warning "This will restore Uptime Monitor from backup"
    print_warning "Current installation will be replaced!"
    echo ""
    read -p "Are you sure you want to continue? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_info "Stopping service..."
        systemctl stop "$SERVICE_NAME" 2>/dev/null || true
        
        print_info "Extracting backup..."
        TEMP_DIR="/tmp/uptime-monitor-restore-$(date +%Y%m%d-%H%M%S)"
        mkdir -p "$TEMP_DIR"
        tar -xzf "$BACKUP_FILE" -C "$TEMP_DIR"
        
        # Find the backup directory
        BACKUP_CONTENT=$(find "$TEMP_DIR" -name "uptime-monitor-backup-*" -type d | head -1)
        
        if [ -n "$BACKUP_CONTENT" ]; then
            print_info "Restoring application files..."
            if [ -d "$BACKUP_CONTENT/uptime-monitor" ]; then
                rm -rf "$INSTALL_DIR"
                mv "$BACKUP_CONTENT/uptime-monitor" "$INSTALL_DIR"
                chown -R "$USER_NAME:$USER_NAME" "$INSTALL_DIR"
            fi
            
            print_info "Restoring service file..."
            if [ -f "$BACKUP_CONTENT/uptime-monitor.service" ]; then
                cp "$BACKUP_CONTENT/uptime-monitor.service" "$SERVICE_FILE"
                systemctl daemon-reload
            fi
            
            print_info "Cleaning up..."
            rm -rf "$TEMP_DIR"
            
            print_info "Starting service..."
            systemctl start "$SERVICE_NAME"
            
            print_success "Restore completed successfully!"
        else
            print_error "Invalid backup file format"
            rm -rf "$TEMP_DIR"
            exit 1
        fi
    else
        print_info "Restore cancelled"
    fi
}

# Function to update application
update_application() {
    print_info "Updating Uptime Monitor Pro..."
    
    # Create backup before update
    create_backup
    
    print_info "Stopping service..."
    systemctl stop "$SERVICE_NAME"
    
    # Download updated files
    GITHUB_REPO="crowninternet/uptime-monitor"
    GITHUB_BRANCH="main"
    GITHUB_BASE_URL="https://raw.githubusercontent.com/${GITHUB_REPO}/${GITHUB_BRANCH}"
    
    print_info "Downloading updated files..."
    curl -fsSL "${GITHUB_BASE_URL}/uptime-monitor-api.js" -o "$INSTALL_DIR/uptime-monitor-api.js"
    curl -fsSL "${GITHUB_BASE_URL}/index.html" -o "$INSTALL_DIR/index.html"
    curl -fsSL "${GITHUB_BASE_URL}/recovery.html" -o "$INSTALL_DIR/recovery.html"
    curl -fsSL "${GITHUB_BASE_URL}/package.json" -o "$INSTALL_DIR/package.json"
    
    # Update dependencies
    print_info "Updating dependencies..."
    cd "$INSTALL_DIR"
    sudo -u "$USER_NAME" npm install --production
    
    # Set permissions
    chown -R "$USER_NAME:$USER_NAME" "$INSTALL_DIR"
    chmod 644 "$INSTALL_DIR"/*.json "$INSTALL_DIR"/*.js "$INSTALL_DIR"/*.html
    
    print_info "Starting service..."
    systemctl start "$SERVICE_NAME"
    
    print_success "Update completed successfully!"
}

case "$1" in
    start)
        check_root
        print_header
        echo "Starting Uptime Monitor..."
        systemctl start "$SERVICE_NAME"
        sleep 2
        if systemctl is-active --quiet "$SERVICE_NAME"; then
            print_success "Uptime Monitor started successfully!"
            print_info "Web interface: http://localhost:3000"
        else
            print_error "Failed to start Uptime Monitor"
            print_info "Check the logs: sudo $0 logs"
            exit 1
        fi
        ;;
        
    stop)
        check_root
        print_header
        echo "Stopping Uptime Monitor..."
        systemctl stop "$SERVICE_NAME"
        sleep 2
        if ! systemctl is-active --quiet "$SERVICE_NAME"; then
            print_success "Uptime Monitor stopped successfully!"
        else
            print_warning "Service may still be stopping..."
        fi
        ;;
        
    restart)
        check_root
        print_header
        echo "Restarting Uptime Monitor..."
        systemctl restart "$SERVICE_NAME"
        sleep 3
        if systemctl is-active --quiet "$SERVICE_NAME"; then
            print_success "Uptime Monitor restarted successfully!"
            print_info "Web interface: http://localhost:3000"
        else
            print_error "Failed to restart Uptime Monitor"
            print_info "Check the logs: sudo $0 logs"
            exit 1
        fi
        ;;
        
    status)
        show_status
        ;;
        
    logs)
        print_header
        echo "Recent log entries:"
        echo ""
        journalctl -u "$SERVICE_NAME" --no-pager -n 20
        ;;
        
    logs-tail)
        print_header
        echo "Following logs in real-time (Press Ctrl+C to stop)..."
        echo ""
        journalctl -u "$SERVICE_NAME" --no-pager -f
        ;;
        
    test)
        print_header
        echo "Testing API connectivity..."
        echo ""
        if curl -s http://localhost:3000/api/health > /dev/null 2>&1; then
            print_success "API is responding"
            echo "API Health Check:"
            curl -s http://localhost:3000/api/health | python3 -m json.tool 2>/dev/null || curl -s http://localhost:3000/api/health
        else
            print_error "API is not responding"
            print_info "Make sure the service is running: sudo $0 status"
        fi
        ;;
        
    info)
        show_system_info
        ;;
        
    backup)
        check_root
        create_backup
        ;;
        
    restore)
        check_root
        restore_backup "$@"
        ;;
        
    update)
        check_root
        update_application
        ;;
        
    uninstall)
        check_root
        print_header
        echo "Uninstalling Uptime Monitor Pro..."
        echo ""
        print_warning "This will permanently remove all files and data!"
        echo ""
        read -p "Are you sure you want to continue? (y/N): " -n 1 -r
        echo
        
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "Stopping service..."
            systemctl stop "$SERVICE_NAME" 2>/dev/null || true
            
            echo "Disabling service..."
            systemctl disable "$SERVICE_NAME" 2>/dev/null || true
            
            echo "Removing service file..."
            rm -f "$SERVICE_FILE"
            
            echo "Removing installation directory..."
            rm -rf "$INSTALL_DIR"
            
            echo "Removing system user..."
            userdel "$USER_NAME" 2>/dev/null || true
            
            echo "Reloading systemd..."
            systemctl daemon-reload
            
            print_success "Uptime Monitor Pro has been completely removed"
        else
            print_info "Uninstall cancelled"
        fi
        ;;
        
    help|--help|-h)
        show_help
        ;;
        
    *)
        print_error "Unknown command: $1"
        echo ""
        show_help
        exit 1
        ;;
esac
