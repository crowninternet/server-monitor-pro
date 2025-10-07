#!/bin/bash

# Uptime Monitor Pro - Proxmox LXC Container Installer
# Compatible with Proxmox VE 9.x
# Usage: bash -c "$(curl -fsSL https://raw.githubusercontent.com/crowninternet/server-monitor-pro/master/proxmox/uptime-monitor.sh)"

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Default values
CTID=""
HOSTNAME="uptime-monitor"
PASSWORD=""
MEMORY="1024"
CORES="2"
DISK_SIZE="8"
BRIDGE="vmbr0"
IP=""
GATEWAY=""
TEMPLATE=""
TEMPLATE_STORAGE="local"
STORAGE="local-lvm"
UNPRIVILEGED="1"
ONBOOT="1"

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
    echo -e "${PURPLE}  Proxmox LXC Container${NC}"
    echo -e "${PURPLE}================================${NC}"
    echo ""
}

# Function to show help
show_help() {
    echo "Uptime Monitor Pro - Proxmox LXC Container Installer"
    echo ""
    echo "Usage: bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/crowninternet/server-monitor-pro/master/proxmox/uptime-monitor.sh)\""
    echo ""
    echo "Environment Variables:"
    echo "  CTID          - Container ID (default: auto-assign)"
    echo "  HOSTNAME      - Container hostname (default: uptime-monitor)"
    echo "  PASSWORD      - Root password (default: prompt)"
    echo "  MEMORY        - Memory in MB (default: 1024)"
    echo "  CORES         - CPU cores (default: 2)"
    echo "  DISK_SIZE     - Disk size in GB (default: 8)"
    echo "  BRIDGE        - Network bridge (default: vmbr0)"
    echo "  IP            - IP address or 'dhcp' (default: prompt)"
    echo "  GATEWAY       - Gateway (required for static IP)"
    echo "  TEMPLATE      - Template (default: auto-detect and download)"
    echo "  STORAGE       - Storage (default: local-lvm)"
    echo ""
    echo "Examples:"
    echo "  # Interactive mode (choose DHCP or Static)"
    echo "  bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/crowninternet/server-monitor-pro/master/proxmox/uptime-monitor.sh)\""
    echo ""
    echo "  # With DHCP"
    echo "  IP=dhcp bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/crowninternet/server-monitor-pro/master/proxmox/uptime-monitor.sh)\""
    echo ""
    echo "  # With static IP"
    echo "  IP=192.168.1.100 GATEWAY=192.168.1.1 bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/crowninternet/server-monitor-pro/master/proxmox/uptime-monitor.sh)\""
    echo ""
    echo "  # Full example with DHCP"
    echo "  CTID=100 HOSTNAME=monitor IP=dhcp MEMORY=2048 CORES=4 bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/crowninternet/server-monitor-pro/master/proxmox/uptime-monitor.sh)\""
}

# Function to check if running on Proxmox host
check_proxmox() {
    if [ ! -f /etc/pve/local/pve-ssl.pem ]; then
        print_error "This script must be run on a Proxmox VE host"
        exit 1
    fi
    
    if ! command -v pct >/dev/null 2>&1; then
        print_error "pct command not found"
        exit 1
    fi
}

# Function to get next available CTID
get_next_ctid() {
    local next_id=100
    while pct list | grep -q "^$next_id "; do
        ((next_id++))
    done
    CTID=$next_id
}

# Function to find and download Debian template
find_debian_template() {
    print_status "Checking for Debian templates..."
    
    # First check if template is already downloaded locally
    # pveam list returns format: local:vztmpl/debian-12-standard_12.12-1_amd64.tar.zst
    local local_templates=$(pveam list $TEMPLATE_STORAGE 2>/dev/null)
    
    if echo "$local_templates" | grep -q "debian-12-standard"; then
        # pveam list format is: local:vztmpl/debian-12-standard_12.12-1_amd64.tar.zst
        # We need just the filename part
        local template_file=$(echo "$local_templates" | grep "debian-12-standard" | grep -v "pre-release" | head -1 | awk '{print $1}' | sed 's/.*vztmpl\///')
        TEMPLATE="$TEMPLATE_STORAGE:vztmpl/$template_file"
        print_status "Found local Debian 12 template"
        print_status "Using template: $TEMPLATE"
        return 0
    elif echo "$local_templates" | grep -q "debian-11-standard"; then
        local template_file=$(echo "$local_templates" | grep "debian-11-standard" | grep -v "pre-release" | head -1 | awk '{print $1}' | sed 's/.*vztmpl\///')
        TEMPLATE="$TEMPLATE_STORAGE:vztmpl/$template_file"
        print_status "Found local Debian 11 template"
        print_status "Using template: $TEMPLATE"
        return 0
    fi
    
    # No local template found, check available templates for download
    print_status "No local template found, checking available downloads..."
    print_status "Updating template list..."
    pveam update >/dev/null 2>&1
    
    local available_templates=$(pveam available | grep -i "debian.*standard" | grep -v "pre-release")
    
    # Try to find Debian 12 first, then 11
    if echo "$available_templates" | grep -q "debian-12-standard"; then
        TEMPLATE=$(echo "$available_templates" | grep "debian-12-standard" | head -1 | awk '{print $2}')
        print_status "Found Debian 12 template: $TEMPLATE"
    elif echo "$available_templates" | grep -q "debian-11-standard"; then
        TEMPLATE=$(echo "$available_templates" | grep "debian-11-standard" | head -1 | awk '{print $2}')
        print_status "Found Debian 11 template: $TEMPLATE"
    else
        print_error "No Debian standard template found"
        exit 1
    fi
    
    # Download the template
    print_status "Downloading template $TEMPLATE..."
    print_status "This may take a few minutes..."
    pveam download $TEMPLATE_STORAGE $TEMPLATE
    print_status "Template downloaded successfully"
    
    # Get the full template path
    TEMPLATE="$TEMPLATE_STORAGE:vztmpl/$TEMPLATE"
    print_status "Using template: $TEMPLATE"
}

# Function to get network configuration
get_network_config() {
    if [ -z "$IP" ]; then
        echo ""
        print_status "Network Configuration"
        echo ""
        echo "Choose network configuration:"
        echo "1) DHCP (automatic IP assignment)"
        echo "2) Static IP (manual configuration)"
        read -p "Enter choice (1 or 2): " -r
        
        if [ "$REPLY" = "1" ]; then
            IP="dhcp"
            GATEWAY=""
            print_status "Using DHCP for automatic IP assignment"
        elif [ "$REPLY" = "2" ]; then
            read -p "Enter IP address (e.g., 192.168.1.100): " IP
            read -p "Enter gateway (e.g., 192.168.1.1): " GATEWAY
            
            if [ -z "$IP" ] || [ -z "$GATEWAY" ]; then
                print_error "IP address and gateway are required for static configuration"
                exit 1
            fi
            print_status "Network configuration: $IP/$NETMASK via $GATEWAY on $BRIDGE"
        else
            print_error "Invalid choice"
            exit 1
        fi
    elif [ "$IP" = "dhcp" ] || [ "$IP" = "DHCP" ]; then
        IP="dhcp"
        GATEWAY=""
        print_status "Using DHCP for automatic IP assignment"
    else
        # Static IP provided via environment variable
        if [ -z "$GATEWAY" ]; then
            print_error "Gateway is required when using static IP"
            exit 1
        fi
        print_status "Network configuration: $IP/$NETMASK via $GATEWAY on $BRIDGE"
    fi
}

# Function to get password
get_password() {
    if [ -z "$PASSWORD" ]; then
        echo ""
        print_status "Authentication"
        read -s -p "Enter root password: " PASSWORD
        echo
        read -s -p "Confirm password: " PASSWORD_CONFIRM
        echo
        
        if [ "$PASSWORD" != "$PASSWORD_CONFIRM" ]; then
            print_error "Passwords do not match"
            exit 1
        fi
    fi
}

# Function to create container
create_container() {
    print_status "Creating LXC container..."
    
    local create_cmd="pct create $CTID $TEMPLATE"
    create_cmd="$create_cmd --hostname $HOSTNAME"
    create_cmd="$create_cmd --memory $MEMORY"
    create_cmd="$create_cmd --cores $CORES"
    create_cmd="$create_cmd --rootfs $STORAGE:${DISK_SIZE}"
    
    # Configure network - DHCP or Static
    if [ "$IP" = "dhcp" ]; then
        create_cmd="$create_cmd --net0 name=eth0,bridge=$BRIDGE,ip=dhcp"
        print_status "Configuring network with DHCP"
    else
        create_cmd="$create_cmd --net0 name=eth0,bridge=$BRIDGE,ip=$IP/24,gw=$GATEWAY"
        print_status "Configuring network with static IP: $IP"
    fi
    
    create_cmd="$create_cmd --password $PASSWORD"
    create_cmd="$create_cmd --unprivileged $UNPRIVILEGED"
    create_cmd="$create_cmd --onboot $ONBOOT"
    
    eval "$create_cmd"
    
    print_status "Container $CTID created successfully"
}

# Function to start container
start_container() {
    print_status "Starting container..."
    pct start $CTID
    
    # Wait for container to be ready
    print_status "Waiting for container to be ready..."
    sleep 10
    
    # Test connectivity
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if pct exec $CTID -- ping -c 1 8.8.8.8 >/dev/null 2>&1; then
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
    
    pct exec $CTID -- bash -c "
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
}

# Function to install Node.js
install_nodejs() {
    print_status "Installing Node.js..."
    
    pct exec $CTID -- bash -c "
        curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
        apt-get install -y nodejs
        node --version
        npm --version
    "
}

# Function to create system user
create_system_user() {
    print_status "Creating system user..."
    
    pct exec $CTID -- bash -c "
        useradd --system --shell /bin/false --home-dir /opt/uptime-monitor --create-home uptime-monitor
    "
}

# Function to create application files
create_application_files() {
    print_status "Creating application files..."
    
    # Create package.json
    pct exec $CTID -- bash -c "cat > /opt/uptime-monitor/package.json << 'EOF'
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
    pct exec $CTID -- bash -c "cat > /opt/uptime-monitor/uptime-monitor-api.js << 'EOF'
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
    pct exec $CTID -- bash -c "cat > /opt/uptime-monitor/index.html << 'EOF'
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
    
    # Create recovery.html
    pct exec $CTID -- bash -c "cat > /opt/uptime-monitor/recovery.html << 'EOF'
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
            <h1>🔄 Uptime Monitor Pro - Recovery</h1>
            <p>This is the recovery page for Uptime Monitor Pro.</p>
            <p>If you can see this page, the web server is running correctly.</p>
            <button class=\"btn\" onclick=\"window.location.href='/'\">Go to Main Dashboard</button>
        </div>
    </div>
</body>
</html>
EOF"
    
    # Create directories and set permissions
    pct exec $CTID -- bash -c "
        mkdir -p /opt/uptime-monitor/secure-data
        mkdir -p /opt/uptime-monitor/logs
        chown -R uptime-monitor:uptime-monitor /opt/uptime-monitor
        chmod -R 755 /opt/uptime-monitor
        chmod 644 /opt/uptime-monitor/*.json /opt/uptime-monitor/*.js /opt/uptime-monitor/*.html
    "
}

# Function to install dependencies
install_dependencies() {
    print_status "Installing Node.js dependencies..."
    
    pct exec $CTID -- bash -c "
        cd /opt/uptime-monitor
        runuser -l uptime-monitor -c 'cd /opt/uptime-monitor && npm install --production'
    "
}

# Function to create systemd service
create_systemd_service() {
    print_status "Creating systemd service..."
    
    pct exec $CTID -- bash -c "cat > /etc/systemd/system/uptime-monitor.service << 'EOF'
[Unit]
Description=Uptime Monitor Pro
Documentation=https://github.com/crowninternet/uptime-monitor
After=network.target
Wants=network-online.target

[Service]
Type=simple
User=uptime-monitor
Group=uptime-monitor
WorkingDirectory=/opt/uptime-monitor
ExecStart=/usr/bin/node /opt/uptime-monitor/uptime-monitor-api.js
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=uptime-monitor

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
ReadWritePaths=/opt/uptime-monitor
ProtectKernelTunables=true
ProtectKernelModules=true
ProtectControlGroups=true

# Environment variables
Environment=NODE_ENV=production
Environment=PORT=3000
Environment=CONTAINER_ID=$CTID

[Install]
WantedBy=multi-user.target
EOF"
    
    pct exec $CTID -- bash -c "
        systemctl daemon-reload
        systemctl enable uptime-monitor
    "
}

# Function to create configuration script
create_configuration_script() {
    print_status "Creating configuration script..."
    
    pct exec $CTID -- bash -c "curl -fsSL https://raw.githubusercontent.com/crowninternet/server-monitor-pro/master/proxmox/configure-credentials.sh -o /opt/uptime-monitor/configure-credentials.sh"
    
    pct exec $CTID -- bash -c "
        chmod +x /opt/uptime-monitor/configure-credentials.sh
        chown uptime-monitor:uptime-monitor /opt/uptime-monitor/configure-credentials.sh
    "
    
    print_status "Configuration script created"
}

# Function to create management script
create_management_script() {
    print_status "Creating management script..."
    
    pct exec $CTID -- bash -c "cat > /opt/uptime-monitor/manage-uptime-monitor.sh << 'EOF'
#!/bin/bash

# Uptime Monitor Pro - Management Script
# Usage: ./manage-uptime-monitor.sh {start|stop|restart|status|logs|uninstall}

INSTALL_DIR=\"/opt/uptime-monitor\"
SERVICE_NAME=\"uptime-monitor\"
SERVICE_FILE=\"/etc/systemd/system/\${SERVICE_NAME}.service\"
USER_NAME=\"uptime-monitor\"
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
    
    pct exec $CTID -- bash -c "
        chmod +x /opt/uptime-monitor/manage-uptime-monitor.sh
    "
}

# Function to start service
start_service() {
    print_status "Starting Uptime Monitor service..."
    
    pct exec $CTID -- bash -c "
        systemctl start uptime-monitor
        sleep 3
    "
    
    # Test if service is running
    if pct exec $CTID -- systemctl is-active --quiet uptime-monitor; then
        print_status "✅ Service started successfully"
        
        # Test API
        sleep 2
        if pct exec $CTID -- wget -q --spider http://localhost:3000/api/health 2>/dev/null; then
            print_status "✅ API is responding"
        else
            print_warning "API may still be starting up..."
        fi
    else
        print_error "Failed to start service"
        return 1
    fi
}

# Function to show completion message
show_completion_message() {
    # Get actual IP address if DHCP was used
    local actual_ip="$IP"
    if [ "$IP" = "dhcp" ]; then
        print_status "Getting DHCP-assigned IP address..."
        actual_ip=$(pct exec $CTID -- hostname -I | awk '{print $1}')
        if [ -z "$actual_ip" ]; then
            actual_ip="DHCP (check with: pct exec $CTID -- hostname -I)"
        fi
    fi
    
    echo ""
    echo -e "${GREEN}================================${NC}"
    echo -e "${GREEN}  Installation Complete! 🎉${NC}"
    echo -e "${GREEN}================================${NC}"
    echo ""
    echo -e "${CYAN}Uptime Monitor Pro container has been successfully created!${NC}"
    echo ""
    echo -e "${YELLOW}Container Information:${NC}"
    echo -e "   🏷️  ${BLUE}Container ID: $CTID${NC}"
    echo -e "   🏷️  ${BLUE}Container Name: $HOSTNAME${NC}"
    if [ "$IP" = "dhcp" ]; then
        echo -e "   🌐 ${BLUE}IP Address: $actual_ip (DHCP)${NC}"
    else
        echo -e "   🌐 ${BLUE}IP Address: $actual_ip${NC}"
    fi
    echo -e "   🔧 ${BLUE}Resources: ${MEMORY}MB RAM, $CORES cores, ${DISK_SIZE}GB disk${NC}"
    echo ""
    echo -e "${YELLOW}Access your monitoring dashboard:${NC}"
    echo -e "   🌐 ${BLUE}http://$actual_ip:3000${NC}"
    echo -e "   🌐 ${BLUE}http://localhost:3000${NC} (from container)"
    echo ""
    echo -e "${YELLOW}Container Management:${NC}"
    echo -e "   📁 ${BLUE}pct start $CTID${NC}     - Start container"
    echo -e "   📁 ${BLUE}pct stop $CTID${NC}      - Stop container"
    echo -e "   📁 ${BLUE}pct restart $CTID${NC}   - Restart container"
    echo -e "   📁 ${BLUE}pct enter $CTID${NC}     - Enter container shell"
    echo -e "   📁 ${BLUE}pct destroy $CTID${NC}   - Destroy container"
    echo ""
    echo -e "${YELLOW}Application Management (from host):${NC}"
    echo -e "   📁 ${BLUE}pct exec $CTID -- /opt/uptime-monitor/manage-uptime-monitor.sh start${NC}"
    echo -e "   📁 ${BLUE}pct exec $CTID -- /opt/uptime-monitor/manage-uptime-monitor.sh stop${NC}"
    echo -e "   📁 ${BLUE}pct exec $CTID -- /opt/uptime-monitor/manage-uptime-monitor.sh status${NC}"
    echo -e "   📁 ${BLUE}pct exec $CTID -- /opt/uptime-monitor/manage-uptime-monitor.sh logs${NC}"
    echo ""
    echo -e "${YELLOW}Configure Credentials (from host):${NC}"
    echo -e "   🔐 ${BLUE}pct exec $CTID -- /opt/uptime-monitor/configure-credentials.sh${NC}"
    echo -e "   ${CYAN}Configure Twilio, SendGrid, and FTP securely${NC}"
    echo ""
    echo -e "${YELLOW}Service status:${NC}"
    if pct exec $CTID -- systemctl is-active --quiet uptime-monitor; then
        echo -e "   ✅ ${GREEN}Running${NC}"
    else
        echo -e "   ❌ ${RED}Not running${NC}"
    fi
    echo ""
    echo -e "${PURPLE}Next steps:${NC}"
    echo -e "   1. ${BLUE}Configure credentials:${NC} pct exec $CTID -- /opt/uptime-monitor/configure-credentials.sh"
    echo -e "   2. Open ${BLUE}http://$actual_ip:3000${NC} in your browser"
    echo -e "   3. Add your first server to monitor"
    echo -e "   4. Optionally configure alerts via web interface"
    if [ "$IP" = "dhcp" ]; then
        echo ""
        echo -e "${CYAN}💡 Tip: You can make the DHCP IP static in your firewall/router settings${NC}"
        echo -e "${CYAN}   Or convert to static IP inside container: edit /etc/network/interfaces${NC}"
    fi
    echo ""
    echo -e "${GREEN}Happy monitoring! 🚀${NC}"
}

# Main function
main() {
    print_header
    
    # Check if help is requested
    if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
        show_help
        exit 0
    fi
    
    # Check if running on Proxmox host
    check_proxmox
    
    # Get CTID if not set
    if [ -z "$CTID" ]; then
        get_next_ctid
    fi
    
    # Find and download Debian template if not set
    if [ -z "$TEMPLATE" ]; then
        find_debian_template
    fi
    
    # Get network configuration
    get_network_config
    
    # Get password
    get_password
    
    print_status "Starting container creation process..."
    echo ""
    
    # Container creation steps
    create_container
    start_container
    install_system_packages
    install_nodejs
    create_system_user
    create_application_files
    install_dependencies
    create_systemd_service
    create_configuration_script
    create_management_script
    start_service
    
    show_completion_message
}

# Run main function
main "$@"
