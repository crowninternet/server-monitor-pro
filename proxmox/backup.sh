#!/bin/bash

# Uptime Monitor Pro - Backup Script for Proxmox + Debian
# Usage: sudo ./backup.sh [backup-directory]

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
DEFAULT_BACKUP_DIR="/tmp/uptime-monitor-backups"
BACKUP_DIR="${1:-$DEFAULT_BACKUP_DIR}"

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
    echo -e "${PURPLE}  Uptime Monitor Pro Backup${NC}"
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

# Function to create backup directory
create_backup_directory() {
    print_status "Creating backup directory: $BACKUP_DIR"
    mkdir -p "$BACKUP_DIR"
    chmod 755 "$BACKUP_DIR"
}

# Function to backup application files
backup_application_files() {
    print_status "Backing up application files..."
    
    if [ -d "$INSTALL_DIR" ]; then
        BACKUP_NAME="uptime-monitor-$(date +%Y%m%d-%H%M%S)"
        BACKUP_PATH="$BACKUP_DIR/$BACKUP_NAME"
        
        # Create backup directory
        mkdir -p "$BACKUP_PATH"
        
        # Copy application files
        cp -r "$INSTALL_DIR" "$BACKUP_PATH/"
        
        # Remove node_modules to reduce backup size
        if [ -d "$BACKUP_PATH/uptime-monitor/node_modules" ]; then
            print_status "Removing node_modules from backup (will be reinstalled)"
            rm -rf "$BACKUP_PATH/uptime-monitor/node_modules"
        fi
        
        # Create package.json backup for dependency restoration
        if [ -f "$BACKUP_PATH/uptime-monitor/package.json" ]; then
            print_status "Package.json included for dependency restoration"
        fi
        
        print_status "Application files backed up to: $BACKUP_PATH/uptime-monitor"
        echo "$BACKUP_PATH" > "$BACKUP_DIR/latest-backup-path.txt"
    else
        print_warning "Installation directory not found: $INSTALL_DIR"
    fi
}

# Function to backup service configuration
backup_service_config() {
    print_status "Backing up service configuration..."
    
    BACKUP_PATH=$(cat "$BACKUP_DIR/latest-backup-path.txt" 2>/dev/null || echo "")
    
    if [ -n "$BACKUP_PATH" ] && [ -d "$BACKUP_PATH" ]; then
        # Backup service file
        if [ -f "$SERVICE_FILE" ]; then
            cp "$SERVICE_FILE" "$BACKUP_PATH/uptime-monitor.service"
            print_status "Service file backed up"
        fi
        
        # Backup systemd logs
        if command -v journalctl >/dev/null 2>&1; then
            journalctl -u "$SERVICE_NAME" --no-pager > "$BACKUP_PATH/service-logs.txt" 2>/dev/null || true
            print_status "Service logs backed up"
        fi
        
        # Backup system information
        cat > "$BACKUP_PATH/system-info.txt" << EOF
Uptime Monitor Pro Backup Information
====================================
Backup Date: $(date)
Container ID: $CONTAINER_ID
Install Directory: $INSTALL_DIR
Service Name: $SERVICE_NAME
System User: $USER_NAME

System Information:
$(uname -a)

Debian Version:
$(cat /etc/os-release 2>/dev/null || echo "Not available")

Node.js Version:
$(node --version 2>/dev/null || echo "Not available")

NPM Version:
$(npm --version 2>/dev/null || echo "Not available")

Memory Information:
$(free -h 2>/dev/null || echo "Not available")

Disk Usage:
$(df -h "$INSTALL_DIR" 2>/dev/null || echo "Not available")
EOF
        print_status "System information backed up"
    fi
}

# Function to backup data files
backup_data_files() {
    print_status "Backing up data files..."
    
    BACKUP_PATH=$(cat "$BACKUP_DIR/latest-backup-path.txt" 2>/dev/null || echo "")
    
    if [ -n "$BACKUP_PATH" ] && [ -d "$BACKUP_PATH" ]; then
        # Backup secure-data directory
        if [ -d "$INSTALL_DIR/secure-data" ]; then
            cp -r "$INSTALL_DIR/secure-data" "$BACKUP_PATH/"
            print_status "Secure data backed up"
        fi
        
        # Backup logs directory
        if [ -d "$INSTALL_DIR/logs" ]; then
            cp -r "$INSTALL_DIR/logs" "$BACKUP_PATH/"
            print_status "Logs backed up"
        fi
        
        # Backup container configuration
        if [ -f "$INSTALL_DIR/container-config.json" ]; then
            cp "$INSTALL_DIR/container-config.json" "$BACKUP_PATH/"
            print_status "Container configuration backed up"
        fi
    fi
}

# Function to create backup archive
create_backup_archive() {
    print_status "Creating backup archive..."
    
    BACKUP_PATH=$(cat "$BACKUP_DIR/latest-backup-path.txt" 2>/dev/null || echo "")
    
    if [ -n "$BACKUP_PATH" ] && [ -d "$BACKUP_PATH" ]; then
        BACKUP_NAME=$(basename "$BACKUP_PATH")
        ARCHIVE_NAME="${BACKUP_NAME}.tar.gz"
        ARCHIVE_PATH="$BACKUP_DIR/$ARCHIVE_NAME"
        
        # Create archive
        tar -czf "$ARCHIVE_PATH" -C "$BACKUP_DIR" "$BACKUP_NAME"
        
        # Remove uncompressed backup
        rm -rf "$BACKUP_PATH"
        rm -f "$BACKUP_DIR/latest-backup-path.txt"
        
        # Set permissions
        chmod 644 "$ARCHIVE_PATH"
        
        # Get archive size
        ARCHIVE_SIZE=$(du -h "$ARCHIVE_PATH" | cut -f1)
        
        print_status "Backup archive created: $ARCHIVE_PATH"
        print_status "Archive size: $ARCHIVE_SIZE"
        
        # Create backup manifest
        cat > "$BACKUP_DIR/backup-manifest.txt" << EOF
Uptime Monitor Pro Backup Manifest
==================================
Backup Date: $(date)
Archive: $ARCHIVE_NAME
Size: $ARCHIVE_SIZE
Container: $CONTAINER_ID

Contents:
- Application files (without node_modules)
- Service configuration
- System information
- Data files (secure-data, logs)
- Container configuration
- Service logs

Restore Command:
sudo /opt/uptime-monitor/manage-uptime-monitor.sh restore $ARCHIVE_PATH
EOF
        print_status "Backup manifest created"
    fi
}

# Function to cleanup old backups
cleanup_old_backups() {
    print_status "Cleaning up old backups..."
    
    # Keep only the last 5 backups
    BACKUP_COUNT=$(ls -1 "$BACKUP_DIR"/*.tar.gz 2>/dev/null | wc -l)
    
    if [ "$BACKUP_COUNT" -gt 5 ]; then
        print_status "Found $BACKUP_COUNT backups, keeping only the last 5"
        
        # Sort by modification time and remove oldest
        ls -1t "$BACKUP_DIR"/*.tar.gz 2>/dev/null | tail -n +6 | xargs rm -f
        
        print_status "Old backups cleaned up"
    else
        print_status "Backup count ($BACKUP_COUNT) is within limits"
    fi
}

# Function to verify backup
verify_backup() {
    print_status "Verifying backup..."
    
    # Find the most recent backup
    LATEST_BACKUP=$(ls -1t "$BACKUP_DIR"/*.tar.gz 2>/dev/null | head -1)
    
    if [ -n "$LATEST_BACKUP" ]; then
        # Test archive integrity
        if tar -tzf "$LATEST_BACKUP" >/dev/null 2>&1; then
            print_status "Backup verification successful"
            
            # Show backup contents
            print_status "Backup contents:"
            tar -tzf "$LATEST_BACKUP" | head -10
            if [ $(tar -tzf "$LATEST_BACKUP" | wc -l) -gt 10 ]; then
                echo "... and $(($(tar -tzf "$LATEST_BACKUP" | wc -l) - 10)) more files"
            fi
        else
            print_error "Backup verification failed"
            exit 1
        fi
    else
        print_error "No backup found to verify"
        exit 1
    fi
}

# Function to show backup information
show_backup_info() {
    print_status "Backup Information:"
    echo ""
    echo "Backup Directory: $BACKUP_DIR"
    echo "Container ID: $CONTAINER_ID"
    echo "Install Directory: $INSTALL_DIR"
    echo "Service Name: $SERVICE_NAME"
    echo ""
    
    # Show available backups
    if ls "$BACKUP_DIR"/*.tar.gz >/dev/null 2>&1; then
        echo "Available Backups:"
        ls -lh "$BACKUP_DIR"/*.tar.gz | awk '{print $9, $5, $6, $7, $8}'
        echo ""
    else
        echo "No backups found"
        echo ""
    fi
    
    # Show disk usage
    if [ -d "$BACKUP_DIR" ]; then
        echo "Backup Directory Usage:"
        du -sh "$BACKUP_DIR"
        echo ""
    fi
}

# Function to show help
show_help() {
    print_header
    echo "Usage: sudo $0 [backup-directory]"
    echo ""
    echo "Arguments:"
    echo "  backup-directory    Directory to store backups (default: $DEFAULT_BACKUP_DIR)"
    echo ""
    echo "Options:"
    echo "  --info, -i         Show backup information"
    echo "  --help, -h         Show this help message"
    echo ""
    echo "Examples:"
    echo "  sudo $0                    # Create backup in default directory"
    echo "  sudo $0 /home/backups     # Create backup in custom directory"
    echo "  sudo $0 --info            # Show backup information"
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
        --info|-i)
            show_backup_info
            exit 0
            ;;
        "")
            # Use default backup directory
            ;;
        *)
            # Use custom backup directory
            BACKUP_DIR="$1"
            ;;
    esac
    
    print_status "Starting backup process..."
    echo ""
    
    # Backup steps
    create_backup_directory
    backup_application_files
    backup_service_config
    backup_data_files
    create_backup_archive
    cleanup_old_backups
    verify_backup
    
    echo ""
    print_status "Backup completed successfully!"
    
    # Show backup information
    show_backup_info
    
    print_status "To restore this backup, use:"
    LATEST_BACKUP=$(ls -1t "$BACKUP_DIR"/*.tar.gz 2>/dev/null | head -1)
    if [ -n "$LATEST_BACKUP" ]; then
        echo "sudo /opt/uptime-monitor/manage-uptime-monitor.sh restore $LATEST_BACKUP"
    fi
}

# Run main function
main "$@"
