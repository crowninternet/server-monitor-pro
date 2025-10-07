#!/bin/bash

# Uptime Monitor Pro - Restore Script for Proxmox + Debian
# Usage: sudo ./restore.sh <backup-file>

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
INSTALL_DIR="/opt/uptime-monitor"
SERVICE_NAME="uptime-monitor"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"
USER_NAME="uptime-monitor"
CONTAINER_ID=$(hostname)
TEMP_DIR="/tmp/uptime-monitor-restore-$(date +%Y%m%d-%H%M%S)"

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${PURPLE}================================${NC}"
    echo -e "${PURPLE}  Uptime Monitor Pro Restore${NC}"
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

# Function to validate backup file
validate_backup_file() {
    local backup_file="$1"
    
    if [ -z "$backup_file" ]; then
        print_error "No backup file specified"
        show_help
        exit 1
    fi
    
    if [ ! -f "$backup_file" ]; then
        print_error "Backup file not found: $backup_file"
        exit 1
    fi
    
    if [[ "$backup_file" != *.tar.gz ]]; then
        print_error "Backup file must be a .tar.gz archive"
        exit 1
    fi
    
    # Test archive integrity
    if ! tar -tzf "$backup_file" >/dev/null 2>&1; then
        print_error "Backup file is corrupted or invalid"
        exit 1
    fi
    
    print_status "Backup file validated: $backup_file"
}

# Function to extract backup
extract_backup() {
    local backup_file="$1"
    
    print_status "Extracting backup file..."
    
    # Create temporary directory
    mkdir -p "$TEMP_DIR"
    
    # Extract backup
    tar -xzf "$backup_file" -C "$TEMP_DIR"
    
    # Find the backup directory
    BACKUP_CONTENT=$(find "$TEMP_DIR" -name "uptime-monitor-*" -type d | head -1)
    
    if [ -z "$BACKUP_CONTENT" ]; then
        print_error "Invalid backup file format - no uptime-monitor directory found"
        cleanup_temp
        exit 1
    fi
    
    print_status "Backup extracted to: $BACKUP_CONTENT"
    echo "$BACKUP_CONTENT"
}

# Function to stop service
stop_service() {
    print_status "Stopping Uptime Monitor service..."
    
    if systemctl is-active --quiet "$SERVICE_NAME"; then
        systemctl stop "$SERVICE_NAME"
        sleep 2
        
        if systemctl is-active --quiet "$SERVICE_NAME"; then
            print_warning "Service is still running, forcing stop..."
            systemctl kill "$SERVICE_NAME" 2>/dev/null || true
            sleep 2
        fi
        
        print_status "Service stopped"
    else
        print_status "Service was not running"
    fi
}

# Function to backup current installation
backup_current_installation() {
    print_status "Creating backup of current installation..."
    
    CURRENT_BACKUP_DIR="/tmp/uptime-monitor-current-backup-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$CURRENT_BACKUP_DIR"
    
    # Backup current installation if it exists
    if [ -d "$INSTALL_DIR" ]; then
        cp -r "$INSTALL_DIR" "$CURRENT_BACKUP_DIR/"
        print_status "Current installation backed up to: $CURRENT_BACKUP_DIR"
    fi
    
    # Backup current service file if it exists
    if [ -f "$SERVICE_FILE" ]; then
        cp "$SERVICE_FILE" "$CURRENT_BACKUP_DIR/"
        print_status "Current service file backed up"
    fi
    
    echo "$CURRENT_BACKUP_DIR"
}

# Function to restore application files
restore_application_files() {
    local backup_content="$1"
    
    print_status "Restoring application files..."
    
    # Remove current installation
    if [ -d "$INSTALL_DIR" ]; then
        rm -rf "$INSTALL_DIR"
        print_status "Removed current installation"
    fi
    
    # Restore application files
    if [ -d "$backup_content/uptime-monitor" ]; then
        mv "$backup_content/uptime-monitor" "$INSTALL_DIR"
        print_status "Application files restored"
    else
        print_error "Application files not found in backup"
        return 1
    fi
    
    # Set proper permissions
    chown -R "$USER_NAME:$USER_NAME" "$INSTALL_DIR"
    chmod 755 "$INSTALL_DIR"
    chmod 644 "$INSTALL_DIR"/*.json "$INSTALL_DIR"/*.js "$INSTALL_DIR"/*.html 2>/dev/null || true
    
    print_status "Permissions set correctly"
}

# Function to restore service configuration
restore_service_config() {
    local backup_content="$1"
    
    print_status "Restoring service configuration..."
    
    # Restore service file
    if [ -f "$backup_content/uptime-monitor.service" ]; then
        cp "$backup_content/uptime-monitor.service" "$SERVICE_FILE"
        print_status "Service file restored"
    else
        print_warning "Service file not found in backup, using default"
        # Create default service file
        create_default_service_file
    fi
    
    # Reload systemd
    systemctl daemon-reload
    systemctl enable "$SERVICE_NAME"
    
    print_status "Service configuration restored"
}

# Function to create default service file
create_default_service_file() {
    print_status "Creating default service file..."
    
    cat > "$SERVICE_FILE" << EOF
[Unit]
Description=Uptime Monitor Pro
Documentation=https://github.com/crowninternet/uptime-monitor
After=network.target
Wants=network-online.target

[Service]
Type=simple
User=$USER_NAME
Group=$USER_NAME
WorkingDirectory=$INSTALL_DIR
ExecStart=/usr/bin/node $INSTALL_DIR/uptime-monitor-api.js
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=uptime-monitor

# Container-specific resource limits
MemoryMax=512M
CPUQuota=50%
LimitNOFILE=4096
LimitNPROC=2048

# Security settings for container environment
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=$INSTALL_DIR
ProtectKernelTunables=true
ProtectKernelModules=true
ProtectControlGroups=true
RestrictRealtime=true
RestrictSUIDSGID=true
RestrictNamespaces=true

# Environment variables
Environment=NODE_ENV=production
Environment=PORT=3000
Environment=CONTAINER_MODE=true

[Install]
WantedBy=multi-user.target
EOF
}

# Function to restore data files
restore_data_files() {
    local backup_content="$1"
    
    print_status "Restoring data files..."
    
    # Restore secure-data directory
    if [ -d "$backup_content/secure-data" ]; then
        if [ -d "$INSTALL_DIR/secure-data" ]; then
            rm -rf "$INSTALL_DIR/secure-data"
        fi
        mv "$backup_content/secure-data" "$INSTALL_DIR/"
        print_status "Secure data restored"
    fi
    
    # Restore logs directory
    if [ -d "$backup_content/logs" ]; then
        if [ -d "$INSTALL_DIR/logs" ]; then
            rm -rf "$INSTALL_DIR/logs"
        fi
        mv "$backup_content/logs" "$INSTALL_DIR/"
        print_status "Logs restored"
    fi
    
    # Restore container configuration
    if [ -f "$backup_content/container-config.json" ]; then
        cp "$backup_content/container-config.json" "$INSTALL_DIR/"
        print_status "Container configuration restored"
    fi
    
    # Set proper permissions for data files
    chown -R "$USER_NAME:$USER_NAME" "$INSTALL_DIR"
}

# Function to reinstall dependencies
reinstall_dependencies() {
    print_status "Reinstalling Node.js dependencies..."
    
    cd "$INSTALL_DIR"
    
    # Check if package.json exists
    if [ ! -f "package.json" ]; then
        print_error "package.json not found, cannot reinstall dependencies"
        return 1
    fi
    
    # Install dependencies
    sudo -u "$USER_NAME" npm install --production
    
    print_status "Dependencies reinstalled successfully"
}

# Function to start service
start_service() {
    print_status "Starting Uptime Monitor service..."
    
    systemctl start "$SERVICE_NAME"
    sleep 3
    
    if systemctl is-active --quiet "$SERVICE_NAME"; then
        print_status "Service started successfully"
        
        # Test API
        sleep 2
        if curl -s http://localhost:3000/api/health > /dev/null 2>&1; then
            print_status "API is responding"
        else
            print_warning "API may still be starting up..."
        fi
    else
        print_error "Failed to start service"
        print_status "Check logs: journalctl -u $SERVICE_NAME"
        return 1
    fi
}

# Function to cleanup temporary files
cleanup_temp() {
    print_status "Cleaning up temporary files..."
    
    if [ -d "$TEMP_DIR" ]; then
        rm -rf "$TEMP_DIR"
        print_status "Temporary files cleaned up"
    fi
}

# Function to show restore information
show_restore_info() {
    local backup_file="$1"
    local backup_content="$2"
    
    print_status "Restore Information:"
    echo ""
    echo "Backup File: $backup_file"
    echo "Container ID: $CONTAINER_ID"
    echo "Install Directory: $INSTALL_DIR"
    echo "Service Name: $SERVICE_NAME"
    echo ""
    
    # Show backup contents
    if [ -n "$backup_content" ] && [ -d "$backup_content" ]; then
        echo "Backup Contents:"
        ls -la "$backup_content"
        echo ""
        
        # Show system info from backup if available
        if [ -f "$backup_content/system-info.txt" ]; then
            echo "Original System Information:"
            head -10 "$backup_content/system-info.txt"
            echo ""
        fi
    fi
}

# Function to show help
show_help() {
    print_header
    echo "Usage: sudo $0 <backup-file>"
    echo ""
    echo "Arguments:"
    echo "  backup-file         Path to the backup .tar.gz file"
    echo ""
    echo "Options:"
    echo "  --help, -h         Show this help message"
    echo ""
    echo "Examples:"
    echo "  sudo $0 /tmp/uptime-monitor-backup-20240101-120000.tar.gz"
    echo "  sudo $0 /home/backups/uptime-monitor-20240101-120000.tar.gz"
    echo ""
    echo "Notes:"
    echo "  - This script will stop the current service before restoring"
    echo "  - A backup of the current installation will be created"
    echo "  - The service will be restarted after successful restore"
    echo "  - Dependencies will be reinstalled from package.json"
    echo ""
}

# Main function
main() {
    print_header
    
    # Check if running as root
    check_root
    
    # Handle command line arguments
    case "$1" in
        --help|-h)
            show_help
            exit 0
            ;;
        "")
            print_error "No backup file specified"
            show_help
            exit 1
            ;;
        *)
            BACKUP_FILE="$1"
            ;;
    esac
    
    print_status "Starting restore process..."
    echo ""
    
    # Validate backup file
    validate_backup_file "$BACKUP_FILE"
    
    # Show restore information
    show_restore_info "$BACKUP_FILE" ""
    
    # Confirm restore
    print_warning "This will replace the current installation with the backup"
    print_warning "The current service will be stopped and restarted"
    echo ""
    read -p "Are you sure you want to continue? (y/N): " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Restore cancelled"
        exit 0
    fi
    
    # Restore steps
    BACKUP_CONTENT=$(extract_backup "$BACKUP_FILE")
    CURRENT_BACKUP_DIR=$(backup_current_installation)
    stop_service
    restore_application_files "$BACKUP_CONTENT"
    restore_service_config "$BACKUP_CONTENT"
    restore_data_files "$BACKUP_CONTENT"
    reinstall_dependencies
    start_service
    cleanup_temp
    
    echo ""
    print_status "Restore completed successfully!"
    
    print_status "Current installation backed up to: $CURRENT_BACKUP_DIR"
    print_status "Service is running and API is accessible at: http://localhost:3000"
    
    print_status "To verify the restore:"
    echo "sudo systemctl status $SERVICE_NAME"
    echo "curl http://localhost:3000/api/health"
}

# Run main function
main "$@"
