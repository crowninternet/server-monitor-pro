#!/bin/bash

# Uptime Monitor Pro - Proxmox Host Container Creator
# Creates a complete LXC container with Uptime Monitor Pro pre-installed
# Compatible with Proxmox VE 9.x
# Run from Proxmox host shell

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
CONTAINER_NAME="uptime-monitor"
CONTAINER_ID=""
TEMPLATE="debian-12-standard"
STORAGE="local-lvm"
MEMORY="1024"
CORES="2"
DISK_SIZE="8"
BRIDGE="vmbr0"
IP_ADDRESS=""
GATEWAY=""
NETMASK="24"
PASSWORD=""
SSH_KEY=""
INSTALL_DIR="/opt/uptime-monitor"
SERVICE_NAME="uptime-monitor"
USER_NAME="uptime-monitor"

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
    echo -e "${PURPLE}  Uptime Monitor Pro Container${NC}"
    echo -e "${PURPLE}  Proxmox Host Creator${NC}"
    echo -e "${PURPLE}  Version 1.2.0 - Complete Setup${NC}"
    echo -e "${PURPLE}================================${NC}"
    echo ""
}

# Function to check if running on Proxmox host
check_proxmox_host() {
    if [ ! -f /etc/pve/local/pve-ssl.pem ]; then
        print_error "This script must be run on a Proxmox VE host"
        print_info "Please run this script from the Proxmox host shell"
        exit 1
    fi
    
    print_status "Detected Proxmox VE host"
}

# Function to check if pct command is available
check_pct_command() {
    if ! command -v pct >/dev/null 2>&1; then
        print_error "pct command not found"
        print_info "Please ensure you're running this on a Proxmox VE host"
        exit 1
    fi
    
    print_status "pct command available"
}

# Function to get next available container ID
get_next_container_id() {
    local next_id=100
    while pct list | grep -q "^$next_id "; do
        ((next_id++))
    done
    CONTAINER_ID=$next_id
    print_status "Next available container ID: $CONTAINER_ID"
}

# Function to check if template exists
check_template() {
    if ! pveam list | grep -q "$TEMPLATE"; then
        print_warning "Template $TEMPLATE not found"
        print_status "Available templates:"
        pveam list | grep debian | head -5
        echo ""
        read -p "Enter template name (or press Enter for $TEMPLATE): " -r
        if [ -n "$REPLY" ]; then
            TEMPLATE="$REPLY"
        fi
    fi
    
    print_status "Using template: $TEMPLATE"
}

# Function to get network configuration
get_network_config() {
    print_status "Configuring network settings..."
    
    # Get available bridges
    print_status "Available bridges:"
    ip link show | grep -E "^[0-9]+:" | grep -v lo | awk '{print $2}' | sed 's/://' | head -5
    
    read -p "Enter bridge name (default: $BRIDGE): " -r
    if [ -n "$REPLY" ]; then
        BRIDGE="$REPLY"
    fi
    
    # Get IP address
    read -p "Enter IP address (e.g., 192.168.1.100): " -r
    if [ -n "$REPLY" ]; then
        IP_ADDRESS="$REPLY"
    else
        print_error "IP address is required"
        exit 1
    fi
    
    # Get gateway
    read -p "Enter gateway (e.g., 192.168.1.1): " -r
    if [ -n "$REPLY" ]; then
        GATEWAY="$REPLY"
    else
        print_error "Gateway is required"
        exit 1
    fi
    
    print_status "Network configuration: $IP_ADDRESS/$NETMASK via $GATEWAY on $BRIDGE"
}

# Function to get container resources
get_container_resources() {
    print_status "Configuring container resources..."
    
    read -p "Enter memory in MB (default: $MEMORY): " -r
    if [ -n "$REPLY" ]; then
        MEMORY="$REPLY"
    fi
    
    read -p "Enter CPU cores (default: $CORES): " -r
    if [ -n "$REPLY" ]; then
        CORES="$REPLY"
    fi
    
    read -p "Enter disk size in GB (default: $DISK_SIZE): " -r
    if [ -n "$REPLY" ]; then
        DISK_SIZE="$REPLY"
    fi
    
    print_status "Resources: ${MEMORY}MB RAM, ${CORES} cores, ${DISK_SIZE}GB disk"
}

# Function to get authentication method
get_auth_method() {
    print_status "Configuring authentication..."
    
    echo "Choose authentication method:"
    echo "1) Password"
    echo "2) SSH Key"
    read -p "Enter choice (1 or 2): " -r
    
    case "$REPLY" in
        1)
            read -s -p "Enter root password: " -r
            PASSWORD="$REPLY"
            echo
            ;;
        2)
            read -p "Enter SSH public key: " -r
            SSH_KEY="$REPLY"
            ;;
        *)
            print_error "Invalid choice"
            exit 1
            ;;
    esac
}

# Function to create container
create_container() {
    print_status "Creating LXC container..."
    
    local create_cmd="pct create $CONTAINER_ID $TEMPLATE"
    create_cmd="$create_cmd --hostname $CONTAINER_NAME"
    create_cmd="$create_cmd --memory $MEMORY"
    create_cmd="$create_cmd --cores $CORES"
    create_cmd="$create_cmd --rootfs $STORAGE:${DISK_SIZE}"
    create_cmd="$create_cmd --net0 name=eth0,bridge=$BRIDGE,ip=$IP_ADDRESS/$NETMASK,gw=$GATEWAY"
    create_cmd="$create_cmd --onboot 1"
    create_cmd="$create_cmd --unprivileged 1"
    
    if [ -n "$PASSWORD" ]; then
        create_cmd="$create_cmd --password $PASSWORD"
    fi
    
    if [ -n "$SSH_KEY" ]; then
        create_cmd="$create_cmd --ssh-public-keys $SSH_KEY"
    fi
    
    print_status "Executing: $create_cmd"
    eval "$create_cmd"
    
    print_status "Container $CONTAINER_ID created successfully"
}

# Function to start container
start_container() {
    print_status "Starting container..."
    pct start $CONTAINER_ID
    
    # Wait for container to be ready
    print_status "Waiting for container to be ready..."
    sleep 10
    
    # Test connectivity
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if pct exec $CONTAINER_ID -- ping -c 1 8.8.8.8 >/dev/null 2>&1; then
            print_status "Container is ready"
            return 0
        fi
        
        print_status "Attempt $attempt/$max_attempts - waiting for container..."
        sleep 2
        ((attempt++))
    done
    
    print_warning "Container may still be starting up..."
}

# Function to install system packages
install_system_packages() {
    print_status "Installing system packages..."
    
    pct exec $CONTAINER_ID -- bash -c "
        apt-get update -y
        apt-get upgrade -y
        apt-get install -y \
            curl \
            wget \
            gnupg \
            ca-certificates \
            software-properties-common \
            systemd \
            journalctl \
            htop \
            nano \
            unzip \
            python3 \
            python3-pip
    "
    
    print_status "System packages installed"
}

# Function to install Node.js
install_nodejs() {
    print_status "Installing Node.js..."
    
    pct exec $CONTAINER_ID -- bash -c "
        curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
        apt-get install -y nodejs
        node --version
        npm --version
    "
    
    print_status "Node.js installed successfully"
}

# Function to create system user
create_system_user() {
    print_status "Creating system user..."
    
    pct exec $CONTAINER_ID -- bash -c "
        useradd --system --shell /bin/false --home-dir $INSTALL_DIR --create-home $USER_NAME
        echo 'System user $USER_NAME created'
    "
    
    print_status "System user created"
}

# Function to create installation directory
create_install_directory() {
    print_status "Creating installation directory..."
    
    pct exec $CONTAINER_ID -- bash -c "
        mkdir -p $INSTALL_DIR
        chown $USER_NAME:$USER_NAME $INSTALL_DIR
        chmod 755 $INSTALL_DIR
    "
    
    print_status "Installation directory created"
}

# Function to create application files
create_application_files() {
    print_status "Creating application files..."
    
    # Create package.json
    pct exec $CONTAINER_ID -- bash -c "cat > $INSTALL_DIR/package.json << 'EOF'
{
  \"name\": \"uptime-monitor-pro\",
  \"version\": \"1.2.0\",
  \"description\": \"Advanced server monitoring with SMS and Email alerts\",
  \"main\": \"uptime-monitor-api.js\",
  \"scripts\": {
    \"start\": \"node uptime-monitor-api.js\",
    \"dev\": \"nodemon uptime-monitor-api.js\"
  },
  \"dependencies\": {
    \"@sendgrid/mail\": \"^8.1.0\",
    \"axios\": \"^1.12.2\",
    \"cors\": \"^2.8.5\",
    \"express\": \"^4.18.2\",
    \"ftp\": \"^0.3.10\",
    \"ssh2-sftp-client\": \"^12.0.1\",
    \"twilio\": \"^4.15.0\"
  },
  \"devDependencies\": {
    \"nodemon\": \"^3.0.1\"
  },
  \"keywords\": [
    \"uptime\",
    \"monitoring\",
    \"sms\",
    \"email\",
    \"alerts\",
    \"server\",
    \"twilio\",
    \"sendgrid\",
    \"ftp\"
  ],
  \"author\": \"Your Name\",
  \"license\": \"MIT\"
}
EOF"
    
    # Create the main API file
    pct exec $CONTAINER_ID -- bash -c "cat > $INSTALL_DIR/uptime-monitor-api.js << 'EOF'
// Node.js Backend API for Uptime Monitor Pro
// Version 1.2.0 - Container Edition
// Run with: node uptime-monitor-api.js

const express = require('express');
const cors = require('cors');
const path = require('path');
const fs = require('fs');

const app = express();
const PORT = process.env.PORT || 3000;

// Data storage paths
const SECURE_DATA_DIR = path.join(__dirname, 'secure-data');
const SERVERS_FILE = path.join(SECURE_DATA_DIR, 'servers.json');
const CONFIG_FILE = path.join(SECURE_DATA_DIR, 'config.json');

// Ensure secure data directory exists
if (!fs.existsSync(SECURE_DATA_DIR)) {
    fs.mkdirSync(SECURE_DATA_DIR, { recursive: true });
}

// Initialize default files if they don't exist
if (!fs.existsSync(SERVERS_FILE)) {
    fs.writeFileSync(SERVERS_FILE, JSON.stringify([], null, 2));
}
if (!fs.existsSync(CONFIG_FILE)) {
    fs.writeFileSync(CONFIG_FILE, JSON.stringify({}, null, 2));
}

// Helper functions for file operations
const readServers = () => {
    try {
        const data = fs.readFileSync(SERVERS_FILE, 'utf8');
        return JSON.parse(data);
    } catch (error) {
        console.error('Error reading servers:', error);
        return [];
    }
};

const writeServers = (servers) => {
    try {
        fs.writeFileSync(SERVERS_FILE, JSON.stringify(servers, null, 2));
        return true;
    } catch (error) {
        console.error('Error writing servers:', error);
        return false;
    }
};

const readConfig = () => {
    try {
        const data = fs.readFileSync(CONFIG_FILE, 'utf8');
        return JSON.parse(data);
    } catch (error) {
        console.error('Error reading config:', error);
        return {};
    }
};

const writeConfig = (config) => {
    try {
        fs.writeFileSync(CONFIG_FILE, JSON.stringify(config, null, 2));
        return true;
    } catch (error) {
        console.error('Error writing config:', error);
        return false;
    }
};

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.static(__dirname));

// Health check endpoint
app.get('/api/health', (req, res) => {
    res.json({
        status: 'healthy',
        timestamp: new Date().toISOString(),
        version: '1.2.0',
        container: process.env.CONTAINER_ID || 'unknown'
    });
});

// Get servers
app.get('/api/servers', (req, res) => {
    const servers = readServers();
    res.json(servers);
});

// Add server
app.post('/api/servers', (req, res) => {
    const { name, url, type, interval } = req.body;
    
    if (!name || !url || !type || !interval) {
        return res.status(400).json({ error: 'Missing required fields' });
    }
    
    const servers = readServers();
    const newServer = {
        id: Date.now().toString(),
        name,
        url,
        type,
        interval: parseInt(interval),
        status: 'unknown',
        lastCheck: null,
        uptime: 100,
        responseTime: null,
        createdAt: new Date().toISOString()
    };
    
    servers.push(newServer);
    
    if (writeServers(servers)) {
        res.json(newServer);
    } else {
        res.status(500).json({ error: 'Failed to save server' });
    }
});

// Delete server
app.delete('/api/servers/:id', (req, res) => {
    const { id } = req.params;
    const servers = readServers();
    const filteredServers = servers.filter(server => server.id !== id);
    
    if (writeServers(filteredServers)) {
        res.json({ success: true });
    } else {
        res.status(500).json({ error: 'Failed to delete server' });
    }
});

// Get config
app.get('/api/config', (req, res) => {
    const config = readConfig();
    res.json(config);
});

// Update config
app.post('/api/config', (req, res) => {
    const config = req.body;
    
    if (writeConfig(config)) {
        res.json({ success: true });
    } else {
        res.status(500).json({ error: 'Failed to save config' });
    }
});

// Serve main page
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'index.html'));
});

// Start server
app.listen(PORT, () => {
    console.log(\`Uptime Monitor Pro server running on port \${PORT}\`);
    console.log(\`Container ID: \${process.env.CONTAINER_ID || 'unknown'}\`);
    console.log(\`Environment: \${process.env.NODE_ENV || 'development'}\`);
});
EOF"
    
    # Create index.html
    pct exec $CONTAINER_ID -- bash -c "cat > $INSTALL_DIR/index.html << 'EOF'
<!DOCTYPE html>
<html lang=\"en\">
<head>
    <meta charset=\"UTF-8\">
    <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">
    <title>Uptime Monitor Pro</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 0; padding: 20px; background: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; }
        .header { background: #2c3e50; color: white; padding: 20px; border-radius: 8px; margin-bottom: 20px; }
        .card { background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); margin-bottom: 20px; }
        .btn { background: #3498db; color: white; border: none; padding: 10px 20px; border-radius: 4px; cursor: pointer; }
        .btn:hover { background: #2980b9; }
        .form-group { margin-bottom: 15px; }
        .form-group label { display: block; margin-bottom: 5px; font-weight: bold; }
        .form-group input, .form-group select { width: 100%; padding: 8px; border: 1px solid #ddd; border-radius: 4px; }
        .server-list { display: grid; gap: 15px; }
        .server-item { background: #f8f9fa; padding: 15px; border-radius: 4px; border-left: 4px solid #3498db; }
        .status-up { border-left-color: #27ae60; }
        .status-down { border-left-color: #e74c3c; }
        .status-unknown { border-left-color: #95a5a6; }
    </style>
</head>
<body>
    <div class=\"container\">
        <div class=\"header\">
            <h1>🚀 Uptime Monitor Pro</h1>
            <p>Advanced Server Monitoring - Container Edition</p>
        </div>

        <div class=\"card\">
            <h2>Add New Server</h2>
            <form id=\"serverForm\">
                <div class=\"form-group\">
                    <label for=\"serverName\">Server Name:</label>
                    <input type=\"text\" id=\"serverName\" required>
                </div>
                <div class=\"form-group\">
                    <label for=\"serverUrl\">Server URL:</label>
                    <input type=\"url\" id=\"serverUrl\" required>
                </div>
                <div class=\"form-group\">
                    <label for=\"checkType\">Check Type:</label>
                    <select id=\"checkType\" required>
                        <option value=\"https\">HTTPS</option>
                        <option value=\"http\">HTTP</option>
                        <option value=\"ping\">Ping</option>
                        <option value=\"tcp\">TCP</option>
                    </select>
                </div>
                <div class=\"form-group\">
                    <label for=\"checkInterval\">Check Interval (minutes):</label>
                    <input type=\"number\" id=\"checkInterval\" value=\"5\" min=\"1\" max=\"60\" required>
                </div>
                <button type=\"submit\" class=\"btn\">Add Server</button>
            </form>
        </div>

        <div class=\"card\">
            <h2>Monitored Servers</h2>
            <div id=\"serverList\" class=\"server-list\">
                <p>Loading servers...</p>
            </div>
        </div>
    </div>

    <script>
        // Load servers on page load
        document.addEventListener('DOMContentLoaded', loadServers);

        // Handle form submission
        document.getElementById('serverForm').addEventListener('submit', async (e) => {
            e.preventDefault();
            
            const serverData = {
                name: document.getElementById('serverName').value,
                url: document.getElementById('serverUrl').value,
                type: document.getElementById('checkType').value,
                interval: document.getElementById('checkInterval').value
            };

            try {
                const response = await fetch('/api/servers', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify(serverData)
                });

                if (response.ok) {
                    document.getElementById('serverForm').reset();
                    loadServers();
                } else {
                    alert('Failed to add server');
                }
            } catch (error) {
                alert('Error adding server: ' + error.message);
            }
        });

        // Load servers from API
        async function loadServers() {
            try {
                const response = await fetch('/api/servers');
                const servers = await response.json();
                
                const serverList = document.getElementById('serverList');
                
                if (servers.length === 0) {
                    serverList.innerHTML = '<p>No servers configured yet. Add your first server above!</p>';
                    return;
                }

                serverList.innerHTML = servers.map(server => \`
                    <div class=\"server-item status-\${server.status}\">
                        <h3>\${server.name}</h3>
                        <p><strong>URL:</strong> \${server.url}</p>
                        <p><strong>Type:</strong> \${server.type.toUpperCase()}</p>
                        <p><strong>Interval:</strong> \${server.interval} minutes</p>
                        <p><strong>Status:</strong> \${server.status}</p>
                        <p><strong>Last Check:</strong> \${server.lastCheck || 'Never'}</p>
                        <button class=\"btn\" onclick=\"deleteServer('\${server.id}')\">Delete</button>
                    </div>
                \`).join('');
            } catch (error) {
                document.getElementById('serverList').innerHTML = '<p>Error loading servers: ' + error.message + '</p>';
            }
        }

        // Delete server
        async function deleteServer(id) {
            if (!confirm('Are you sure you want to delete this server?')) return;

            try {
                const response = await fetch(\`/api/servers/\${id}\`, { method: 'DELETE' });
                
                if (response.ok) {
                    loadServers();
                } else {
                    alert('Failed to delete server');
                }
            } catch (error) {
                alert('Error deleting server: ' + error.message);
            }
        }
    </script>
</body>
</html>
EOF"
    
    # Download recovery.html (full-featured version)
    print_status "Downloading recovery.html..."
    GITHUB_URL="https://raw.githubusercontent.com/crowninternet/uptime-monitor/main/recovery.html"
    
    # Try to download the full recovery page from GitHub
    if pct exec $CONTAINER_ID -- bash -c "command -v curl >/dev/null 2>&1"; then
        pct exec $CONTAINER_ID -- bash -c "curl -fsSL '$GITHUB_URL' -o $INSTALL_DIR/recovery.html"
    elif pct exec $CONTAINER_ID -- bash -c "command -v wget >/dev/null 2>&1"; then
        pct exec $CONTAINER_ID -- bash -c "wget -q '$GITHUB_URL' -O $INSTALL_DIR/recovery.html"
    else
        # Fallback: create basic placeholder with instructions
        print_warning "Container doesn't have curl or wget, creating basic placeholder"
        pct exec $CONTAINER_ID -- bash -c "cat > $INSTALL_DIR/recovery.html << 'EOF'
<!DOCTYPE html>
<html lang=\"en\">
<head>
    <meta charset=\"UTF-8\">
    <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">
    <title>Uptime Monitor Pro - Recovery</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 0; padding: 20px; background: #f5f5f5; }
        .container { max-width: 800px; margin: 0 auto; }
        .card { background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .btn { background: #e74c3c; color: white; border: none; padding: 10px 20px; border-radius: 4px; cursor: pointer; }
        .btn:hover { background: #c0392b; }
    </style>
</head>
<body>
    <div class=\"container\">
        <div class=\"card\">
            <h1>🔄 Uptime Monitor Pro - Recovery (Basic)</h1>
            <p>This is a basic placeholder recovery page.</p>
            <p>To get the full-featured recovery page with backup/restore capabilities:</p>
            <ol>
                <li>Install curl: <code>apt-get install -y curl</code></li>
                <li>Download: <code>curl -fsSL https://raw.githubusercontent.com/crowninternet/uptime-monitor/main/recovery.html -o $INSTALL_DIR/recovery.html</code></li>
                <li>Restart the service</li>
            </ol>
            <button class=\"btn\" onclick=\"window.location.href='/'\">Go to Main Dashboard</button>
        </div>
    </div>
</body>
</html>
EOF"
    fi
    
    # Create secure data directory
    pct exec $CONTAINER_ID -- bash -c "
        mkdir -p $INSTALL_DIR/secure-data
        mkdir -p $INSTALL_DIR/logs
        chown -R $USER_NAME:$USER_NAME $INSTALL_DIR
        chmod -R 755 $INSTALL_DIR
        chmod 644 $INSTALL_DIR/*.json $INSTALL_DIR/*.js $INSTALL_DIR/*.html
    "
    
    print_status "Application files created"
}

# Function to install dependencies
install_dependencies() {
    print_status "Installing Node.js dependencies..."
    
    pct exec $CONTAINER_ID -- bash -c "
        cd $INSTALL_DIR
        runuser -l $USER_NAME -c 'cd $INSTALL_DIR && npm install --production'
    "
    
    print_status "Dependencies installed"
}

# Function to create systemd service
create_systemd_service() {
    print_status "Creating systemd service..."
    
    pct exec $CONTAINER_ID -- bash -c "cat > /etc/systemd/system/$SERVICE_NAME.service << 'EOF'
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
SyslogIdentifier=$SERVICE_NAME

# Container-specific optimizations
MemoryMax=512M
CPUQuota=50%
LimitNOFILE=4096
LimitNPROC=2048

# Security settings
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=$INSTALL_DIR
ProtectKernelTunables=true
ProtectKernelModules=true
ProtectControlGroups=true

# Environment variables
Environment=NODE_ENV=production
Environment=PORT=3000
Environment=CONTAINER_ID=$CONTAINER_ID

[Install]
WantedBy=multi-user.target
EOF"
    
    pct exec $CONTAINER_ID -- bash -c "
        systemctl daemon-reload
        systemctl enable $SERVICE_NAME
    "
    
    print_status "Systemd service created"
}

# Function to create management script
create_management_script() {
    print_status "Creating management script..."
    
    pct exec $CONTAINER_ID -- bash -c "cat > $INSTALL_DIR/manage-uptime-monitor.sh << 'EOF'
#!/bin/bash

# Uptime Monitor Pro - Management Script
# Usage: ./manage-uptime-monitor.sh {start|stop|restart|status|logs|uninstall}

INSTALL_DIR=\"$INSTALL_DIR\"
SERVICE_NAME=\"$SERVICE_NAME\"
SERVICE_FILE=\"/etc/systemd/system/\${SERVICE_NAME}.service\"
USER_NAME=\"$USER_NAME\"
CONTAINER_ID=\$(hostname)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_success() {
    echo -e \"\${GREEN}✅ \$1\${NC}\"
}

print_error() {
    echo -e \"\${RED}❌ \$1\${NC}\"
}

print_info() {
    echo -e \"\${BLUE}ℹ️  \$1\${NC}\"
}

print_warning() {
    echo -e \"\${YELLOW}⚠️  \$1\${NC}\"
}

# Function to check if running as root
check_root() {
    if [[ \$EUID -ne 0 ]]; then
        print_error \"This script must be run as root\"
        exit 1
    fi
}

# Function to show service status
show_status() {
    echo \"Checking Uptime Monitor status...\"
    echo \"\"
    
    if systemctl is-active --quiet \"\$SERVICE_NAME\"; then
        print_success \"Service is running\"
        
        # Show service details
        systemctl show \"\$SERVICE_NAME\" --property=ActiveState,SubState,MainPID,MemoryCurrent,CPUUsageNSec
        
        if wget -q --spider http://localhost:3000/api/health 2>/dev/null; then
            print_success \"API is responding at http://localhost:3000\"
            print_info \"Web interface: http://localhost:3000\"
        else
            print_warning \"API is not responding (may still be starting up)\"
        fi
    else
        print_error \"Service is not running\"
        print_info \"Run '\$0 start' to start the service\"
    fi
}

# Function to show help
show_help() {
    echo \"Uptime Monitor Pro - Management Script\"
    echo \"\"
    echo \"Usage: \$0 {command}\"
    echo \"\"
    echo \"Commands:\"
    echo \"  start     - Start the Uptime Monitor service\"
    echo \"  stop      - Stop the Uptime Monitor service\"
    echo \"  restart   - Restart the Uptime Monitor service\"
    echo \"  status    - Check if the service is running\"
    echo \"  logs      - Show recent log entries\"
    echo \"  logs-tail - Follow log entries in real-time\"
    echo \"  test      - Test API connectivity\"
    echo \"  info      - Show system information\"
    echo \"  backup    - Create backup of configuration and data\"
    echo \"  uninstall - Remove Uptime Monitor completely\"
    echo \"  help      - Show this help message\"
    echo \"\"
    echo \"Configuration:\"
    echo \"  Install Directory: \$INSTALL_DIR\"
    echo \"  Service Name: \$SERVICE_NAME\"
    echo \"  Service File: \$SERVICE_FILE\"
    echo \"  System User: \$USER_NAME\"
    echo \"  Container ID: \$CONTAINER_ID\"
    echo \"\"
}

case \"\$1\" in
    start)
        check_root
        echo \"Starting Uptime Monitor...\"
        systemctl start \"\$SERVICE_NAME\"
        sleep 2
        if systemctl is-active --quiet \"\$SERVICE_NAME\"; then
            print_success \"Uptime Monitor started successfully!\"
            print_info \"Web interface: http://localhost:3000\"
        else
            print_error \"Failed to start Uptime Monitor\"
            print_info \"Check the logs: \$0 logs\"
            exit 1
        fi
        ;;
        
    stop)
        check_root
        echo \"Stopping Uptime Monitor...\"
        systemctl stop \"\$SERVICE_NAME\"
        sleep 2
        if ! systemctl is-active --quiet \"\$SERVICE_NAME\"; then
            print_success \"Uptime Monitor stopped successfully!\"
        else
            print_warning \"Service may still be stopping...\"
        fi
        ;;
        
    restart)
        check_root
        echo \"Restarting Uptime Monitor...\"
        systemctl restart \"\$SERVICE_NAME\"
        sleep 3
        if systemctl is-active --quiet \"\$SERVICE_NAME\"; then
            print_success \"Uptime Monitor restarted successfully!\"
            print_info \"Web interface: http://localhost:3000\"
        else
            print_error \"Failed to restart Uptime Monitor\"
            print_info \"Check the logs: \$0 logs\"
            exit 1
        fi
        ;;
        
    status)
        show_status
        ;;
        
    logs)
        echo \"Recent log entries:\"
        echo \"\"
        journalctl -u \"\$SERVICE_NAME\" --no-pager -n 20
        ;;
        
    logs-tail)
        echo \"Following logs in real-time (Press Ctrl+C to stop)...\"
        echo \"\"
        journalctl -u \"\$SERVICE_NAME\" --no-pager -f
        ;;
        
    test)
        echo \"Testing API connectivity...\"
        echo \"\"
        if wget -q --spider http://localhost:3000/api/health 2>/dev/null; then
            print_success \"API is responding\"
            echo \"API Health Check:\"
            wget -q -O- http://localhost:3000/api/health
        else
            print_error \"API is not responding\"
            print_info \"Make sure the service is running: \$0 status\"
        fi
        ;;
        
    info)
        echo \"System Information:\"
        echo \"===================\"
        echo \"Container ID: \$CONTAINER_ID\"
        echo \"Install Directory: \$INSTALL_DIR\"
        echo \"Service Name: \$SERVICE_NAME\"
        echo \"System User: \$USER_NAME\"
        echo \"\"
        
        # Show resource usage
        if command -v free >/dev/null 2>&1; then
            echo \"Memory Usage:\"
            free -h
            echo \"\"
        fi
        
        if command -v df >/dev/null 2>&1; then
            echo \"Disk Usage:\"
            df -h \"\$INSTALL_DIR\"
            echo \"\"
        fi
        ;;
        
    backup)
        print_info \"Creating backup of Uptime Monitor...\"
        
        BACKUP_DIR=\"/tmp/uptime-monitor-backup-\$(date +%Y%m%d-%H%M%S)\"
        mkdir -p \"\$BACKUP_DIR\"
        
        # Backup application files
        if [ -d \"\$INSTALL_DIR\" ]; then
            cp -r \"\$INSTALL_DIR\" \"\$BACKUP_DIR/\"
            print_info \"Application files backed up\"
        fi
        
        # Backup service file
        if [ -f \"\$SERVICE_FILE\" ]; then
            cp \"\$SERVICE_FILE\" \"\$BACKUP_DIR/\"
            print_info \"Service file backed up\"
        fi
        
        # Create backup archive
        tar -czf \"\${BACKUP_DIR}.tar.gz\" -C /tmp \"\$(basename \"\$BACKUP_DIR\")\"
        rm -rf \"\$BACKUP_DIR\"
        
        print_success \"Backup created: \${BACKUP_DIR}.tar.gz\"
        ;;
        
    uninstall)
        check_root
        echo \"Uninstalling Uptime Monitor Pro...\"
        echo \"\"
        print_warning \"This will permanently remove all files and data!\"
        echo \"\"
        read -p \"Are you sure you want to continue? (y/N): \" -n 1 -r
        echo
        
        if [[ \$REPLY =~ ^[Yy]\$ ]]; then
            echo \"Stopping service...\"
            systemctl stop \"\$SERVICE_NAME\" 2>/dev/null || true
            
            echo \"Disabling service...\"
            systemctl disable \"\$SERVICE_NAME\" 2>/dev/null || true
            
            echo \"Removing service file...\"
            rm -f \"\$SERVICE_FILE\"
            
            echo \"Removing installation directory...\"
            rm -rf \"\$INSTALL_DIR\"
            
            echo \"Removing system user...\"
            userdel \"\$USER_NAME\" 2>/dev/null || true
            
            echo \"Reloading systemd...\"
            systemctl daemon-reload
            
            print_success \"Uptime Monitor Pro has been completely removed\"
        else
            print_info \"Uninstall cancelled\"
        fi
        ;;
        
    help|--help|-h)
        show_help
        ;;
        
    *)
        print_error \"Unknown command: \$1\"
        echo \"\"
        show_help
        exit 1
        ;;
esac
EOF"
    
    pct exec $CONTAINER_ID -- bash -c "
        chmod +x $INSTALL_DIR/manage-uptime-monitor.sh
    "
    
    print_status "Management script created"
}

# Function to start service
start_service() {
    print_status "Starting Uptime Monitor service..."
    
    pct exec $CONTAINER_ID -- bash -c "
        systemctl start $SERVICE_NAME
        sleep 3
    "
    
    # Test if service is running
    if pct exec $CONTAINER_ID -- systemctl is-active --quiet $SERVICE_NAME; then
        print_status "✅ Service started successfully"
        
        # Test API
        sleep 2
        if pct exec $CONTAINER_ID -- wget -q --spider http://localhost:3000/api/health 2>/dev/null; then
            print_status "✅ API is responding"
        else
            print_warning "API may still be starting up..."
        fi
    else
        print_error "Failed to start service"
        return 1
    fi
}

# Function to create container configuration
create_container_config() {
    print_status "Creating container configuration..."
    
    pct exec $CONTAINER_ID -- bash -c "cat > $INSTALL_DIR/container-config.json << 'EOF'
{
    \"container\": {
        \"id\": \"$CONTAINER_ID\",
        \"name\": \"$CONTAINER_NAME\",
        \"type\": \"proxmox-lxc\",
        \"template\": \"$TEMPLATE\"
    },
    \"resources\": {
        \"memory\": \"${MEMORY}MB\",
        \"cores\": $CORES,
        \"disk\": \"${DISK_SIZE}GB\"
    },
    \"network\": {
        \"ip\": \"$IP_ADDRESS\",
        \"gateway\": \"$GATEWAY\",
        \"bridge\": \"$BRIDGE\"
    },
    \"optimizations\": {
        \"enable_container_mode\": true,
        \"reduce_log_verbosity\": true,
        \"optimize_memory_usage\": true
    }
}
EOF"
    
    pct exec $CONTAINER_ID -- bash -c "
        chown $USER_NAME:$USER_NAME $INSTALL_DIR/container-config.json
        chmod 644 $INSTALL_DIR/container-config.json
    "
    
    print_status "Container configuration created"
}

# Function to display completion message
show_completion_message() {
    echo ""
    echo -e "${GREEN}================================${NC}"
    echo -e "${GREEN}  Container Creation Complete! 🎉${NC}"
    echo -e "${GREEN}================================${NC}"
    echo ""
    echo -e "${CYAN}Uptime Monitor Pro container has been successfully created!${NC}"
    echo ""
    echo -e "${YELLOW}Container Information:${NC}"
    echo -e "   🏷️  ${BLUE}Container ID: $CONTAINER_ID${NC}"
    echo -e "   🏷️  ${BLUE}Container Name: $CONTAINER_NAME${NC}"
    echo -e "   🐧 ${BLUE}Template: $TEMPLATE${NC}"
    echo -e "   🌐 ${BLUE}IP Address: $IP_ADDRESS${NC}"
    echo -e "   🔧 ${BLUE}Resources: ${MEMORY}MB RAM, $CORES cores, ${DISK_SIZE}GB disk${NC}"
    echo ""
    echo -e "${YELLOW}Access your monitoring dashboard:${NC}"
    echo -e "   🌐 ${BLUE}http://$IP_ADDRESS:3000${NC}"
    echo -e "   🌐 ${BLUE}http://localhost:3000${NC} (from container)"
    echo ""
    echo -e "${YELLOW}Container Management:${NC}"
    echo -e "   📁 ${BLUE}pct start $CONTAINER_ID${NC}     - Start container"
    echo -e "   📁 ${BLUE}pct stop $CONTAINER_ID${NC}      - Stop container"
    echo -e "   📁 ${BLUE}pct restart $CONTAINER_ID${NC}   - Restart container"
    echo -e "   📁 ${BLUE}pct enter $CONTAINER_ID${NC}     - Enter container shell"
    echo -e "   📁 ${BLUE}pct destroy $CONTAINER_ID${NC}   - Destroy container"
    echo ""
    echo -e "${YELLOW}Application Management (from container):${NC}"
    echo -e "   📁 ${BLUE}pct exec $CONTAINER_ID -- $INSTALL_DIR/manage-uptime-monitor.sh start${NC}"
    echo -e "   📁 ${BLUE}pct exec $CONTAINER_ID -- $INSTALL_DIR/manage-uptime-monitor.sh stop${NC}"
    echo -e "   📁 ${BLUE}pct exec $CONTAINER_ID -- $INSTALL_DIR/manage-uptime-monitor.sh status${NC}"
    echo -e "   📁 ${BLUE}pct exec $CONTAINER_ID -- $INSTALL_DIR/manage-uptime-monitor.sh logs${NC}"
    echo ""
    echo -e "${YELLOW}Service status:${NC}"
    if pct exec $CONTAINER_ID -- systemctl is-active --quiet $SERVICE_NAME; then
        echo -e "   ✅ ${GREEN}Running${NC}"
    else
        echo -e "   ❌ ${RED}Not running${NC}"
    fi
    echo ""
    echo -e "${PURPLE}Next steps:${NC}"
    echo -e "   1. Open ${BLUE}http://$IP_ADDRESS:3000${NC} in your browser"
    echo -e "   2. Add your first server to monitor"
    echo -e "   3. Configure SMS alerts (Twilio) - optional"
    echo -e "   4. Configure Email alerts (SendGrid) - optional"
    echo -e "   5. Set up FTP upload - optional"
    echo ""
    echo -e "${YELLOW}Container Optimizations:${NC}"
    echo -e "   🔧 ${GREEN}Memory Limit: 512MB (service)${NC}"
    echo -e "   🔧 ${GREEN}CPU Quota: 50% (service)${NC}"
    echo -e "   🔧 ${GREEN}Security Hardening: Enabled${NC}"
    echo -e "   🔧 ${GREEN}Resource Monitoring: Enabled${NC}"
    echo ""
    echo -e "${GREEN}Happy monitoring! 🚀${NC}"
}

# Function to show help
show_help() {
    print_header
    echo "Usage: $0 [options]"
    echo ""
    echo "This script creates a complete LXC container with Uptime Monitor Pro pre-installed."
    echo ""
    echo "Options:"
    echo "  --help, -h         Show this help message"
    echo "  --name NAME        Container name (default: uptime-monitor)"
    echo "  --id ID            Container ID (default: auto-assign)"
    echo "  --template TEMPLATE Template to use (default: debian-12-standard)"
    echo "  --memory MB        Memory in MB (default: 1024)"
    echo "  --cores N          CPU cores (default: 2)"
    echo "  --disk GB          Disk size in GB (default: 8)"
    echo "  --ip IP            IP address (required)"
    echo "  --gateway GW       Gateway (required)"
    echo "  --bridge BRIDGE    Bridge (default: vmbr0)"
    echo ""
    echo "Examples:"
    echo "  $0 --ip 192.168.1.100 --gateway 192.168.1.1"
    echo "  $0 --name my-monitor --ip 10.0.0.50 --gateway 10.0.0.1 --memory 2048"
    echo ""
}

# Function to parse command line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --help|-h)
                show_help
                exit 0
                ;;
            --name)
                CONTAINER_NAME="$2"
                shift 2
                ;;
            --id)
                CONTAINER_ID="$2"
                shift 2
                ;;
            --template)
                TEMPLATE="$2"
                shift 2
                ;;
            --memory)
                MEMORY="$2"
                shift 2
                ;;
            --cores)
                CORES="$2"
                shift 2
                ;;
            --disk)
                DISK_SIZE="$2"
                shift 2
                ;;
            --ip)
                IP_ADDRESS="$2"
                shift 2
                ;;
            --gateway)
                GATEWAY="$2"
                shift 2
                ;;
            --bridge)
                BRIDGE="$2"
                shift 2
                ;;
            *)
                print_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# Main function
main() {
    print_header
    
    # Parse command line arguments
    parse_arguments "$@"
    
    # Check if running on Proxmox host
    check_proxmox_host
    check_pct_command
    
    # Get container ID if not specified
    if [ -z "$CONTAINER_ID" ]; then
        get_next_container_id
    fi
    
    # Check template
    check_template
    
    # Get network configuration if not provided
    if [ -z "$IP_ADDRESS" ] || [ -z "$GATEWAY" ]; then
        get_network_config
    fi
    
    # Get container resources
    get_container_resources
    
    # Get authentication method
    get_auth_method
    
    print_status "Starting container creation process..."
    echo ""
    
    # Container creation steps
    create_container
    start_container
    install_system_packages
    install_nodejs
    create_system_user
    create_install_directory
    create_application_files
    install_dependencies
    create_systemd_service
    create_management_script
    create_container_config
    start_service
    
    show_completion_message
}

# Run main function
main "$@"
