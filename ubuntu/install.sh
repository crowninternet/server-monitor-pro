#!/bin/bash

# Uptime Monitor Pro - One-Click Install Script for Ubuntu 24.04 Server
# Version 1.2.0 - Updated with Email Settings (SendGrid) Support
# Compatible with Ubuntu 24.04 LTS and later

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
MANAGEMENT_SCRIPT="$INSTALL_DIR/manage-uptime-monitor.sh"
USER_NAME="uptime-monitor"
GROUP_NAME="uptime-monitor"

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
    echo -e "${PURPLE}  Uptime Monitor Pro Installer${NC}"
    echo -e "${PURPLE}  Ubuntu 24.04 Server Edition${NC}"
    echo -e "${PURPLE}  Version 1.2.0 - Email Support${NC}"
    echo -e "${PURPLE}================================${NC}"
    echo ""
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root (use sudo)"
        print_info "Please run: sudo $0"
        exit 1
    fi
}

# Function to detect Ubuntu version
detect_ubuntu_version() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        if [[ "$ID" == "ubuntu" ]]; then
            echo "$VERSION_ID"
        else
            print_error "This script is designed for Ubuntu only"
            exit 1
        fi
    else
        print_error "Cannot detect Ubuntu version"
        exit 1
    fi
}

# Function to update system packages
update_system() {
    print_status "Updating system packages..."
    
    apt-get update -y
    apt-get upgrade -y
    
    print_status "System packages updated successfully"
}

# Function to install Node.js
install_nodejs() {
    print_status "Installing Node.js..."
    
    if command_exists node; then
        NODE_VERSION=$(node --version)
        print_status "Node.js is already installed: $NODE_VERSION"
        
        # Check if version is 18 or higher
        MAJOR_VERSION=$(echo $NODE_VERSION | cut -d'.' -f1 | sed 's/v//')
        if [ "$MAJOR_VERSION" -lt 18 ]; then
            print_warning "Node.js version $NODE_VERSION is outdated. Upgrading..."
            # Remove old version and install new one
            apt-get remove -y nodejs npm
            install_nodejs_from_repository
        else
            print_status "Node.js version is compatible"
            return 0
        fi
    else
        install_nodejs_from_repository
    fi
    
    print_status "Node.js installed successfully"
}

# Function to install Node.js from NodeSource repository
install_nodejs_from_repository() {
    print_status "Installing Node.js from NodeSource repository..."
    
    # Install curl if not present
    apt-get install -y curl
    
    # Add NodeSource repository
    curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
    
    # Install Node.js
    apt-get install -y nodejs
    
    # Verify installation
    node --version
    npm --version
}

# Function to create system user
create_system_user() {
    print_status "Creating system user: $USER_NAME"
    
    if id "$USER_NAME" &>/dev/null; then
        print_status "User $USER_NAME already exists"
    else
        useradd --system --shell /bin/false --home-dir "$INSTALL_DIR" --create-home "$USER_NAME"
        print_status "System user $USER_NAME created successfully"
    fi
}

# Function to create installation directory
create_install_directory() {
    print_status "Creating installation directory: $INSTALL_DIR"
    
    if [ -d "$INSTALL_DIR" ]; then
        print_warning "Directory $INSTALL_DIR already exists"
        read -p "Do you want to backup the existing installation? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            BACKUP_DIR="${INSTALL_DIR}-backup-$(date +%Y%m%d-%H%M%S)"
            print_status "Backing up to: $BACKUP_DIR"
            mv "$INSTALL_DIR" "$BACKUP_DIR"
        else
            print_warning "Proceeding with existing installation"
        fi
    fi
    
    mkdir -p "$INSTALL_DIR"
    chown "$USER_NAME:$GROUP_NAME" "$INSTALL_DIR"
    chmod 755 "$INSTALL_DIR"
}

# Function to copy project files
copy_project_files() {
    print_status "Copying project files..."
    
    # Get the directory where this script is located
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    
    # Copy all necessary files
    cp "$SCRIPT_DIR/package.json" "$INSTALL_DIR/"
    cp "$SCRIPT_DIR/uptime-monitor-api.js" "$INSTALL_DIR/"
    cp "$SCRIPT_DIR/index.html" "$INSTALL_DIR/"
    cp "$SCRIPT_DIR/recovery.html" "$INSTALL_DIR/"
    
    # Create secure data directory
    mkdir -p "$INSTALL_DIR/secure-data"
    chown -R "$USER_NAME:$GROUP_NAME" "$INSTALL_DIR"
    chmod -R 755 "$INSTALL_DIR"
    
    print_status "Project files copied successfully"
}

# Function to install dependencies
install_dependencies() {
    print_status "Installing Node.js dependencies..."
    
    cd "$INSTALL_DIR"
    
    # Install dependencies as the system user
    sudo -u "$USER_NAME" npm install
    
    print_status "Dependencies installed successfully"
}

# Function to create systemd service
create_systemd_service() {
    print_status "Creating systemd service..."
    
    cat > "$SERVICE_FILE" << EOF
[Unit]
Description=Uptime Monitor Pro
Documentation=https://github.com/crowninternet/server-monitor-pro
After=network.target

[Service]
Type=simple
User=$USER_NAME
Group=$GROUP_NAME
WorkingDirectory=$INSTALL_DIR
ExecStart=/usr/bin/node $INSTALL_DIR/uptime-monitor-api.js
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=uptime-monitor

# Security settings
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=$INSTALL_DIR

# Resource limits
LimitNOFILE=65536
LimitNPROC=4096

[Install]
WantedBy=multi-user.target
EOF
    
    # Reload systemd and enable service
    systemctl daemon-reload
    systemctl enable "$SERVICE_NAME"
    
    print_status "Systemd service created: $SERVICE_FILE"
}

# Function to create management script
create_management_script() {
    print_status "Creating management script..."
    
    cat > "$MANAGEMENT_SCRIPT" << 'EOF'
#!/bin/bash

# Uptime Monitor Pro - Management Script for Ubuntu
# Usage: sudo ./manage-uptime-monitor.sh {start|stop|restart|status|logs|uninstall}

INSTALL_DIR="/opt/uptime-monitor"
SERVICE_NAME="uptime-monitor"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"
USER_NAME="uptime-monitor"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

# Function to check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root (use sudo)"
        exit 1
    fi
}

# Function to show service status
show_status() {
    echo "Checking Uptime Monitor status..."
    echo ""
    
    if systemctl is-active --quiet "$SERVICE_NAME"; then
        print_success "Service is running"
        
        if curl -s http://localhost:3000/api/health > /dev/null 2>&1; then
            print_success "API is responding at http://localhost:3000"
            print_info "Web interface: http://localhost:3000"
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
    echo "Uptime Monitor Pro - Management Script for Ubuntu"
    echo ""
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
    echo "  uninstall - Remove Uptime Monitor completely"
    echo "  help      - Show this help message"
    echo ""
    echo "Configuration:"
    echo "  Install Directory: $INSTALL_DIR"
    echo "  Service Name: $SERVICE_NAME"
    echo "  Service File: $SERVICE_FILE"
    echo "  System User: $USER_NAME"
    echo ""
}

case "$1" in
    start)
        check_root
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
        echo "Recent log entries:"
        echo ""
        journalctl -u "$SERVICE_NAME" --no-pager -n 20
        ;;
        
    logs-tail)
        echo "Following logs in real-time (Press Ctrl+C to stop)..."
        echo ""
        journalctl -u "$SERVICE_NAME" --no-pager -f
        ;;
        
    test)
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
        
    uninstall)
        check_root
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
EOF
    
    chmod +x "$MANAGEMENT_SCRIPT"
    print_status "Management script created: $MANAGEMENT_SCRIPT"
}

# Function to start the service
start_service() {
    print_status "Starting Uptime Monitor service..."
    
    # Start the service
    systemctl start "$SERVICE_NAME"
    
    # Wait a moment for the service to start
    sleep 3
    
    # Check if the service is running
    if systemctl is-active --quiet "$SERVICE_NAME"; then
        print_status "✅ Uptime Monitor service started successfully"
        
        # Test the API
        sleep 2
        if curl -s http://localhost:3000/api/health > /dev/null 2>&1; then
            print_status "✅ API is responding"
        else
            print_warning "API may still be starting up..."
        fi
    else
        print_error "Failed to start Uptime Monitor service"
        print_info "Check the logs: journalctl -u $SERVICE_NAME"
        return 1
    fi
}

# Function to configure firewall
configure_firewall() {
    print_status "Configuring firewall..."
    
    # Check if ufw is installed and active
    if command_exists ufw && ufw status | grep -q "Status: active"; then
        print_status "Configuring UFW firewall rules..."
        ufw allow 3000/tcp comment "Uptime Monitor Pro"
        print_status "Firewall rule added for port 3000"
    else
        print_info "UFW firewall not active, skipping firewall configuration"
    fi
}

# Function to display completion message
show_completion_message() {
    echo ""
    echo -e "${GREEN}================================${NC}"
    echo -e "${GREEN}  Installation Complete! 🎉${NC}"
    echo -e "${GREEN}================================${NC}"
    echo ""
    echo -e "${CYAN}Uptime Monitor Pro has been successfully installed!${NC}"
    echo ""
    echo -e "${YELLOW}Access your monitoring dashboard:${NC}"
    echo -e "   🌐 ${BLUE}http://localhost:3000${NC}"
    echo -e "   🌐 ${BLUE}http://$(hostname -I | awk '{print $1}'):3000${NC} (external access)"
    echo ""
    echo -e "${YELLOW}Management commands:${NC}"
    echo -e "   📁 ${BLUE}sudo $MANAGEMENT_SCRIPT start${NC}     - Start the service"
    echo -e "   📁 ${BLUE}sudo $MANAGEMENT_SCRIPT stop${NC}      - Stop the service"
    echo -e "   📁 ${BLUE}sudo $MANAGEMENT_SCRIPT restart${NC}   - Restart the service"
    echo -e "   📁 ${BLUE}sudo $MANAGEMENT_SCRIPT status${NC}    - Check service status"
    echo -e "   📁 ${BLUE}sudo $MANAGEMENT_SCRIPT logs${NC}     - View logs"
    echo -e "   📁 ${BLUE}sudo $MANAGEMENT_SCRIPT uninstall${NC} - Remove completely"
    echo ""
    echo -e "${YELLOW}Installation location:${NC}"
    echo -e "   📂 ${BLUE}$INSTALL_DIR${NC}"
    echo ""
    echo -e "${YELLOW}Service status:${NC}"
    if systemctl is-active --quiet "$SERVICE_NAME"; then
        echo -e "   ✅ ${GREEN}Running${NC}"
    else
        echo -e "   ❌ ${RED}Not running${NC}"
    fi
    echo ""
    echo -e "${YELLOW}System user:${NC}"
    echo -e "   👤 ${BLUE}$USER_NAME${NC}"
    echo ""
    echo -e "${PURPLE}Next steps:${NC}"
    echo -e "   1. Open ${BLUE}http://localhost:3000${NC} in your browser"
    echo -e "   2. Add your first server to monitor"
    echo -e "   3. Configure SMS alerts (Twilio) - optional"
    echo -e "   4. Configure Email alerts (SendGrid) - optional"
    echo -e "   5. Set up FTP upload - optional"
    echo ""
    echo -e "${YELLOW}New in v1.2.0:${NC}"
    echo -e "   📧 ${GREEN}Email Settings${NC} - SendGrid integration for email alerts"
    echo -e "   🔧 ${GREEN}Enhanced Reliability${NC} - Improved FTP retry logic"
    echo -e "   ⏱️  ${GREEN}Countdown Fixes${NC} - Resolved concurrent check issues"
    echo ""
    echo -e "${GREEN}Happy monitoring! 🚀${NC}"
}

# Main installation function
main() {
    print_header
    
    # Check if running as root
    check_root
    
    # Check Ubuntu version
    UBUNTU_VERSION=$(detect_ubuntu_version)
    print_status "Detected Ubuntu version: $UBUNTU_VERSION"
    
    print_status "Starting installation process..."
    echo ""
    
    # Installation steps
    update_system
    install_nodejs
    create_system_user
    create_install_directory
    copy_project_files
    install_dependencies
    create_systemd_service
    create_management_script
    start_service
    configure_firewall
    
    show_completion_message
}

# Run main function
main "$@"
