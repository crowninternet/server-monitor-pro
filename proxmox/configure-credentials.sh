#!/bin/bash

# Uptime Monitor Pro - Secure Credentials Configuration Script
# Usage: ./configure-credentials.sh
# Run this script inside the container to securely configure credentials

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

INSTALL_DIR="/opt/uptime-monitor"
CONFIG_FILE="$INSTALL_DIR/secure-data/config.json"
ENV_FILE="$INSTALL_DIR/.env"

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
    echo -e "${PURPLE}  Uptime Monitor Pro${NC}"
    echo -e "${PURPLE}  Credentials Configuration${NC}"
    echo -e "${PURPLE}================================${NC}"
    echo ""
}

# Function to check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root"
        exit 1
    fi
}

# Function to read current config
read_current_config() {
    if [ -f "$CONFIG_FILE" ]; then
        cat "$CONFIG_FILE"
    else
        echo "{}"
    fi
}

# Function to configure Twilio (SMS)
configure_twilio() {
    echo ""
    echo -e "${CYAN}=== Twilio SMS Configuration ===${NC}"
    echo ""
    
    read -p "Do you want to configure Twilio SMS alerts? (y/n): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        read -p "Enter Twilio Account SID: " TWILIO_SID
        read -s -p "Enter Twilio Auth Token: " TWILIO_TOKEN
        echo
        read -p "Enter Twilio From Number (e.g., +1234567890): " TWILIO_FROM
        read -p "Enter Alert To Number (e.g., +1234567890): " TWILIO_TO
        
        # Add to .env file
        echo "TWILIO_ACCOUNT_SID=$TWILIO_SID" >> "$ENV_FILE"
        echo "TWILIO_AUTH_TOKEN=$TWILIO_TOKEN" >> "$ENV_FILE"
        echo "TWILIO_FROM_NUMBER=$TWILIO_FROM" >> "$ENV_FILE"
        echo "TWILIO_TO_NUMBER=$TWILIO_TO" >> "$ENV_FILE"
        
        print_status "Twilio configuration saved to .env file"
    else
        print_status "Skipping Twilio configuration"
    fi
}

# Function to configure SendGrid (Email)
configure_sendgrid() {
    echo ""
    echo -e "${CYAN}=== SendGrid Email Configuration ===${NC}"
    echo ""
    
    read -p "Do you want to configure SendGrid email alerts? (y/n): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        read -s -p "Enter SendGrid API Key: " SENDGRID_API_KEY
        echo
        read -p "Enter From Email Address (verified in SendGrid): " SENDGRID_FROM
        read -p "Enter To Email Address (for alerts): " SENDGRID_TO
        
        # Add to .env file
        echo "SENDGRID_API_KEY=$SENDGRID_API_KEY" >> "$ENV_FILE"
        echo "SENDGRID_FROM_EMAIL=$SENDGRID_FROM" >> "$ENV_FILE"
        echo "SENDGRID_TO_EMAIL=$SENDGRID_TO" >> "$ENV_FILE"
        
        print_status "SendGrid configuration saved to .env file"
    else
        print_status "Skipping SendGrid configuration"
    fi
}

# Function to configure FTP
configure_ftp() {
    echo ""
    echo -e "${CYAN}=== FTP Upload Configuration ===${NC}"
    echo ""
    
    read -p "Do you want to configure FTP upload? (y/n): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        read -p "Enter FTP Host: " FTP_HOST
        read -p "Enter FTP Username: " FTP_USER
        read -s -p "Enter FTP Password: " FTP_PASS
        echo
        read -p "Enter FTP Port (default: 21): " FTP_PORT
        FTP_PORT=${FTP_PORT:-21}
        read -p "Enter FTP Remote Path (default: index.html): " FTP_PATH
        FTP_PATH=${FTP_PATH:-index.html}
        
        # Add to .env file
        echo "FTP_HOST=$FTP_HOST" >> "$ENV_FILE"
        echo "FTP_USER=$FTP_USER" >> "$ENV_FILE"
        echo "FTP_PASSWORD=$FTP_PASS" >> "$ENV_FILE"
        echo "FTP_PORT=$FTP_PORT" >> "$ENV_FILE"
        echo "FTP_REMOTE_PATH=$FTP_PATH" >> "$ENV_FILE"
        
        print_status "FTP configuration saved to .env file"
    else
        print_status "Skipping FTP configuration"
    fi
}

# Function to set permissions
set_permissions() {
    print_status "Setting secure permissions..."
    
    # Set restrictive permissions on .env file
    if [ -f "$ENV_FILE" ]; then
        chown uptime-monitor:uptime-monitor "$ENV_FILE"
        chmod 600 "$ENV_FILE"
        print_status ".env file secured with 600 permissions"
    fi
    
    # Ensure secure-data directory permissions
    if [ -d "$INSTALL_DIR/secure-data" ]; then
        chown -R uptime-monitor:uptime-monitor "$INSTALL_DIR/secure-data"
        chmod 700 "$INSTALL_DIR/secure-data"
        print_status "secure-data directory secured with 700 permissions"
    fi
}

# Function to show configuration summary
show_summary() {
    echo ""
    echo -e "${GREEN}================================${NC}"
    echo -e "${GREEN}  Configuration Complete! ✅${NC}"
    echo -e "${GREEN}================================${NC}"
    echo ""
    echo -e "${YELLOW}Configuration Files:${NC}"
    echo -e "   📁 ${BLUE}$ENV_FILE${NC}"
    echo -e "   📁 ${BLUE}$CONFIG_FILE${NC}"
    echo ""
    echo -e "${YELLOW}Security:${NC}"
    echo -e "   🔒 ${GREEN}.env file permissions: 600 (read/write owner only)${NC}"
    echo -e "   🔒 ${GREEN}secure-data directory: 700 (owner only)${NC}"
    echo ""
    echo -e "${YELLOW}Next Steps:${NC}"
    echo -e "   1. Restart the service: ${BLUE}systemctl restart uptime-monitor${NC}"
    echo -e "   2. Check status: ${BLUE}systemctl status uptime-monitor${NC}"
    echo -e "   3. View logs: ${BLUE}journalctl -u uptime-monitor -f${NC}"
    echo -e "   4. Access web interface: ${BLUE}http://localhost:3000${NC}"
    echo ""
    echo -e "${YELLOW}Configuration can be updated:${NC}"
    echo -e "   • Through web interface at ${BLUE}http://localhost:3000${NC}"
    echo -e "   • By editing ${BLUE}$ENV_FILE${NC} (as root)"
    echo -e "   • By re-running this script: ${BLUE}$0${NC}"
    echo ""
}

# Function to backup existing config
backup_existing_config() {
    if [ -f "$ENV_FILE" ]; then
        BACKUP_FILE="$ENV_FILE.backup-$(date +%Y%m%d-%H%M%S)"
        cp "$ENV_FILE" "$BACKUP_FILE"
        print_status "Existing .env backed up to: $BACKUP_FILE"
    fi
}

# Main function
main() {
    print_header
    
    # Check if running as root
    check_root
    
    print_status "This script will help you securely configure credentials for:"
    echo "  • Twilio SMS alerts"
    echo "  • SendGrid email alerts"
    echo "  • FTP upload"
    echo ""
    print_warning "Credentials will be stored in $ENV_FILE with restricted permissions"
    echo ""
    
    read -p "Continue with configuration? (y/n): " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status "Configuration cancelled"
        exit 0
    fi
    
    # Backup existing config if it exists
    backup_existing_config
    
    # Create new .env file
    echo "# Uptime Monitor Pro - Environment Variables" > "$ENV_FILE"
    echo "# Generated on $(date)" >> "$ENV_FILE"
    echo "" >> "$ENV_FILE"
    
    # Configure services
    configure_twilio
    configure_sendgrid
    configure_ftp
    
    # Set secure permissions
    set_permissions
    
    # Show summary
    show_summary
    
    # Ask if user wants to restart service
    echo ""
    read -p "Restart the Uptime Monitor service now? (y/n): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_status "Restarting service..."
        systemctl restart uptime-monitor
        sleep 2
        
        if systemctl is-active --quiet uptime-monitor; then
            print_status "✅ Service restarted successfully"
        else
            print_error "Failed to restart service"
            print_status "Check logs: journalctl -u uptime-monitor -n 50"
        fi
    fi
}

# Run main function
main "$@"
