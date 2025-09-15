#!/bin/bash

# Uptime Monitor Pro - One-Click Install Script for macOS
# Version 1.0.0
# Compatible with macOS 10.15+ and Apple Silicon/Intel Macs

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
INSTALL_DIR="$HOME/Documents/uptime-monitor"
SERVICE_NAME="com.uptimemonitor"
LAUNCH_AGENT_PATH="$HOME/Library/LaunchAgents/${SERVICE_NAME}.plist"
MANAGEMENT_SCRIPT="$INSTALL_DIR/manage-uptime-monitor.sh"

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
    echo -e "${PURPLE}================================${NC}"
    echo ""
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to detect architecture
detect_architecture() {
    if [[ $(uname -m) == "arm64" ]]; then
        echo "arm64"
    else
        echo "x86_64"
    fi
}

# Function to install Homebrew
install_homebrew() {
    print_status "Installing Homebrew..."
    
    if command_exists brew; then
        print_status "Homebrew is already installed"
        return 0
    fi
    
    print_status "Installing Homebrew (this may take a few minutes)..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Add Homebrew to PATH for Apple Silicon Macs
    if [[ $(uname -m) == "arm64" ]]; then
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
    
    print_status "Homebrew installed successfully"
}

# Function to install Node.js
install_nodejs() {
    print_status "Installing Node.js..."
    
    if command_exists node; then
        NODE_VERSION=$(node --version)
        print_status "Node.js is already installed: $NODE_VERSION"
        
        # Check if version is 16 or higher
        MAJOR_VERSION=$(echo $NODE_VERSION | cut -d'.' -f1 | sed 's/v//')
        if [ "$MAJOR_VERSION" -lt 16 ]; then
            print_warning "Node.js version $NODE_VERSION is outdated. Upgrading..."
            brew upgrade node
        else
            print_status "Node.js version is compatible"
            return 0
        fi
    else
        print_status "Installing Node.js via Homebrew..."
        brew install node
    fi
    
    print_status "Node.js installed successfully"
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
    cd "$INSTALL_DIR"
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
    
    print_status "Project files copied successfully"
}

# Function to install dependencies
install_dependencies() {
    print_status "Installing Node.js dependencies..."
    
    cd "$INSTALL_DIR"
    npm install
    
    print_status "Dependencies installed successfully"
}

# Function to create launch agent
create_launch_agent() {
    print_status "Creating launch agent..."
    
    # Detect Node.js path
    NODE_PATH=$(which node)
    
    cat > "$LAUNCH_AGENT_PATH" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$SERVICE_NAME</string>
    
    <key>ProgramArguments</key>
    <array>
        <string>$NODE_PATH</string>
        <string>$INSTALL_DIR/uptime-monitor-api.js</string>
    </array>
    
    <key>WorkingDirectory</key>
    <string>$INSTALL_DIR</string>
    
    <key>RunAtLoad</key>
    <true/>
    
    <key>KeepAlive</key>
    <true/>
    
    <key>StandardOutPath</key>
    <string>$INSTALL_DIR/uptime-monitor.log</string>
    
    <key>StandardErrorPath</key>
    <string>$INSTALL_DIR/uptime-monitor-error.log</string>
    
    <key>EnvironmentVariables</key>
    <dict>
        <key>NODE_ENV</key>
        <string>production</string>
    </dict>
</dict>
</plist>
EOF
    
    print_status "Launch agent created: $LAUNCH_AGENT_PATH"
}

# Function to create management script
create_management_script() {
    print_status "Creating management script..."
    
    cat > "$MANAGEMENT_SCRIPT" << 'EOF'
#!/bin/bash

# Uptime Monitor Management Script
# Usage: ./manage-uptime-monitor.sh {start|stop|restart|status|logs|uninstall}

INSTALL_DIR="$HOME/Documents/uptime-monitor"
SERVICE_NAME="com.uptimemonitor"
LAUNCH_AGENT_PATH="$HOME/Library/LaunchAgents/${SERVICE_NAME}.plist"

case "$1" in
    start)
        echo "Starting Uptime Monitor..."
        launchctl load "$LAUNCH_AGENT_PATH"
        echo "✅ Uptime Monitor started!"
        echo "🌐 Access the web interface at: http://localhost:3000"
        ;;
    stop)
        echo "Stopping Uptime Monitor..."
        launchctl unload "$LAUNCH_AGENT_PATH"
        echo "✅ Uptime Monitor stopped!"
        ;;
    restart)
        echo "Restarting Uptime Monitor..."
        launchctl unload "$LAUNCH_AGENT_PATH" 2>/dev/null || true
        sleep 2
        launchctl load "$LAUNCH_AGENT_PATH"
        echo "✅ Uptime Monitor restarted!"
        echo "🌐 Access the web interface at: http://localhost:3000"
        ;;
    status)
        echo "Checking Uptime Monitor status..."
        if launchctl list | grep -q "$SERVICE_NAME"; then
            echo "✅ Uptime Monitor is running"
            if curl -s http://localhost:3000/api/health > /dev/null 2>&1; then
                echo "✅ API is responding at http://localhost:3000"
            else
                echo "❌ API not responding"
            fi
        else
            echo "❌ Uptime Monitor is not running"
        fi
        ;;
    logs)
        echo "Recent logs:"
        if [ -f "$INSTALL_DIR/uptime-monitor.log" ]; then
            tail -n 20 "$INSTALL_DIR/uptime-monitor.log"
        else
            echo "No logs found"
        fi
        ;;
    uninstall)
        echo "Uninstalling Uptime Monitor..."
        echo "This will stop the service and remove all files."
        read -p "Are you sure? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            launchctl unload "$LAUNCH_AGENT_PATH" 2>/dev/null || true
            rm -f "$LAUNCH_AGENT_PATH"
            rm -rf "$INSTALL_DIR"
            echo "✅ Uptime Monitor uninstalled successfully"
        else
            echo "Uninstall cancelled"
        fi
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status|logs|uninstall}"
        echo ""
        echo "Commands:"
        echo "  start     - Start the Uptime Monitor service"
        echo "  stop      - Stop the Uptime Monitor service"
        echo "  restart   - Restart the Uptime Monitor service"
        echo "  status    - Check if the service is running"
        echo "  logs      - Show recent log entries"
        echo "  uninstall - Remove Uptime Monitor completely"
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
    
    # Load the launch agent
    launchctl load "$LAUNCH_AGENT_PATH"
    
    # Wait a moment for the service to start
    sleep 3
    
    # Check if the service is running
    if launchctl list | grep -q "$SERVICE_NAME"; then
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
        return 1
    fi
}

# Function to create desktop shortcut
create_desktop_shortcut() {
    print_status "Creating desktop shortcut..."
    
    # Create a simple HTML file that opens the app
    cat > "$HOME/Desktop/Uptime Monitor Pro.html" << EOF
<!DOCTYPE html>
<html>
<head>
    <title>Uptime Monitor Pro</title>
    <meta charset="UTF-8">
</head>
<body>
    <h1>Uptime Monitor Pro</h1>
    <p>Click the button below to open Uptime Monitor Pro:</p>
    <button onclick="window.open('http://localhost:3000', '_blank')">Open Uptime Monitor Pro</button>
    <p><strong>Note:</strong> Make sure the Uptime Monitor service is running.</p>
    <p>To start the service, run: <code>~/Documents/uptime-monitor/manage-uptime-monitor.sh start</code></p>
</body>
</html>
EOF
    
    print_status "Desktop shortcut created"
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
    echo ""
    echo -e "${YELLOW}Management commands:${NC}"
    echo -e "   📁 ${BLUE}$MANAGEMENT_SCRIPT start${NC}     - Start the service"
    echo -e "   📁 ${BLUE}$MANAGEMENT_SCRIPT stop${NC}      - Stop the service"
    echo -e "   📁 ${BLUE}$MANAGEMENT_SCRIPT restart${NC}   - Restart the service"
    echo -e "   📁 ${BLUE}$MANAGEMENT_SCRIPT status${NC}    - Check service status"
    echo -e "   📁 ${BLUE}$MANAGEMENT_SCRIPT logs${NC}     - View logs"
    echo -e "   📁 ${BLUE}$MANAGEMENT_SCRIPT uninstall${NC} - Remove completely"
    echo ""
    echo -e "${YELLOW}Installation location:${NC}"
    echo -e "   📂 ${BLUE}$INSTALL_DIR${NC}"
    echo ""
    echo -e "${YELLOW}Service status:${NC}"
    if launchctl list | grep -q "$SERVICE_NAME"; then
        echo -e "   ✅ ${GREEN}Running${NC}"
    else
        echo -e "   ❌ ${RED}Not running${NC}"
    fi
    echo ""
    echo -e "${PURPLE}Next steps:${NC}"
    echo -e "   1. Open ${BLUE}http://localhost:3000${NC} in your browser"
    echo -e "   2. Add your first server to monitor"
    echo -e "   3. Configure SMS alerts (optional)"
    echo -e "   4. Set up FTP upload (optional)"
    echo ""
    echo -e "${GREEN}Happy monitoring! 🚀${NC}"
}

# Main installation function
main() {
    print_header
    
    # Check if running on macOS
    if [[ "$OSTYPE" != "darwin"* ]]; then
        print_error "This script is designed for macOS only"
        exit 1
    fi
    
    # Check macOS version
    MACOS_VERSION=$(sw_vers -productVersion)
    print_status "Detected macOS version: $MACOS_VERSION"
    
    # Detect architecture
    ARCH=$(detect_architecture)
    print_status "Detected architecture: $ARCH"
    
    print_status "Starting installation process..."
    echo ""
    
    # Installation steps
    install_homebrew
    install_nodejs
    create_install_directory
    copy_project_files
    install_dependencies
    create_launch_agent
    create_management_script
    start_service
    create_desktop_shortcut
    
    show_completion_message
}

# Run main function
main "$@"
