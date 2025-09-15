# Uptime Monitor Pro - Installation Guide for Ubuntu 24.04 Server

## 🚀 Quick Start (One-Click Installation)

### Prerequisites
- Ubuntu 24.04 LTS Server or later
- Root access or sudo privileges
- Internet connection

### Installation Steps

1. **Download the Installation Package**
   ```bash
   # Clone or download the uptime-monitor project
   git clone <repository-url> uptime-monitor
   cd uptime-monitor/ubuntu
   ```

2. **Run the One-Click Installer**
   ```bash
   # Make the script executable
   chmod +x install.sh
   
   # Run the installer (requires root privileges)
   sudo ./install.sh
   ```

3. **Access Your Dashboard**
   - Open your browser and go to: `http://your-server-ip:3000`
   - The service will start automatically

## 📋 What the Installer Does

The installation script automatically:

✅ **Updates system packages** (apt update && apt upgrade)  
✅ **Installs Node.js** (latest LTS version from NodeSource)  
✅ **Creates system user** (`uptime-monitor`)  
✅ **Creates installation directory** (`/opt/uptime-monitor`)  
✅ **Copies all project files**  
✅ **Installs Node.js dependencies**  
✅ **Creates systemd service** (for auto-start)  
✅ **Creates management script**  
✅ **Starts the service**  
✅ **Configures firewall** (if UFW is active)  

## 🎯 Manual Installation (Alternative)

If you prefer to install manually or the automated installer fails:

### Step 1: Update System Packages
```bash
sudo apt update
sudo apt upgrade -y
```

### Step 2: Install Node.js
```bash
# Install curl if not present
sudo apt install -y curl

# Add NodeSource repository
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -

# Install Node.js
sudo apt install -y nodejs

# Verify installation
node --version
npm --version
```

### Step 3: Create System User
```bash
sudo useradd --system --shell /bin/false --home-dir /opt/uptime-monitor --create-home uptime-monitor
```

### Step 4: Create Project Directory
```bash
sudo mkdir -p /opt/uptime-monitor
sudo chown uptime-monitor:uptime-monitor /opt/uptime-monitor
sudo chmod 755 /opt/uptime-monitor
```

### Step 5: Copy Project Files
Copy these files to `/opt/uptime-monitor/`:
- `package.json`
- `uptime-monitor-api.js`
- `index.html`
- `recovery.html`

```bash
sudo cp package.json uptime-monitor-api.js index.html recovery.html /opt/uptime-monitor/
sudo mkdir -p /opt/uptime-monitor/secure-data
sudo chown -R uptime-monitor:uptime-monitor /opt/uptime-monitor
sudo chmod -R 755 /opt/uptime-monitor
```

### Step 6: Install Dependencies
```bash
cd /opt/uptime-monitor
sudo -u uptime-monitor npm install
```

### Step 7: Create systemd Service
Create `/etc/systemd/system/uptime-monitor.service`:

```ini
[Unit]
Description=Uptime Monitor Pro
Documentation=https://github.com/crowninternet/server-monitor-pro
After=network.target

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

# Security settings
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/opt/uptime-monitor

# Resource limits
LimitNOFILE=65536
LimitNPROC=4096

[Install]
WantedBy=multi-user.target
```

### Step 8: Enable and Start Service
```bash
# Reload systemd
sudo systemctl daemon-reload

# Enable service to start on boot
sudo systemctl enable uptime-monitor

# Start the service
sudo systemctl start uptime-monitor

# Check status
sudo systemctl status uptime-monitor
```

### Step 9: Configure Firewall (Optional)
```bash
# If using UFW firewall
sudo ufw allow 3000/tcp comment "Uptime Monitor Pro"

# Check firewall status
sudo ufw status
```

## 🛠️ Management Commands

After installation, use these commands to manage the service:

```bash
# Navigate to installation directory
cd /opt/uptime-monitor

# Start the service
sudo ./manage-uptime-monitor.sh start

# Stop the service
sudo ./manage-uptime-monitor.sh stop

# Restart the service
sudo ./manage-uptime-monitor.sh restart

# Check service status
sudo ./manage-uptime-monitor.sh status

# View logs
sudo ./manage-uptime-monitor.sh logs

# Follow logs in real-time
sudo ./manage-uptime-monitor.sh logs-tail

# Test API connectivity
sudo ./manage-uptime-monitor.sh test

# Uninstall completely
sudo ./manage-uptime-monitor.sh uninstall
```

## 🌐 Accessing the Application

- **Local Access:** `http://localhost:3000`
- **External Access:** `http://your-server-ip:3000`
- **API Health Check:** `http://your-server-ip:3000/api/health`

## 📁 File Structure

After installation, your directory structure will be:

```
/opt/uptime-monitor/
├── index.html                    # Main web interface
├── uptime-monitor-api.js         # Backend API server
├── recovery.html                 # Recovery tool
├── package.json                  # Node.js dependencies
├── package-lock.json            # Dependency lock file
├── node_modules/                 # Installed dependencies
├── secure-data/                  # Data storage directory
│   ├── servers.json             # Monitored servers data
│   └── config.json              # Configuration data
├── manage-uptime-monitor.sh      # Management script
└── install.sh                   # Installation script
```

## 🔧 Configuration

### SMS Alerts (Optional)
1. Open the web interface at `http://your-server-ip:3000`
2. Click "SMS Settings" button
3. Enter your Twilio credentials:
   - Account SID
   - Auth Token
   - From Number (your Twilio phone number)
   - Alert Number (your phone number for alerts)
4. Enable SMS alerts toggle
5. Test the configuration

### FTP Upload (Optional)
1. Click "FTP Settings" button
2. Enter your FTP server details:
   - FTP Host
   - Username
   - Password
   - Port (default: 21)
   - Remote Path (default: index.html)
3. Enable FTP upload toggle
4. Test the configuration

## 🚨 Troubleshooting

### Service Won't Start
```bash
# Check service status
sudo systemctl status uptime-monitor

# Check logs for errors
sudo journalctl -u uptime-monitor --no-pager -n 50

# Try starting manually
cd /opt/uptime-monitor
sudo -u uptime-monitor node uptime-monitor-api.js
```

### Port 3000 Already in Use
```bash
# Find what's using port 3000
sudo lsof -i :3000

# Kill the process (replace PID with actual process ID)
sudo kill -9 PID

# Or change the port in uptime-monitor-api.js
# Edit the PORT variable at the top of the file
```

### Node.js Not Found
```bash
# Check if Node.js is installed
which node
node --version

# If not found, reinstall
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt install -y nodejs
```

### Permission Issues
```bash
# Check file permissions
ls -la /opt/uptime-monitor/

# Fix ownership
sudo chown -R uptime-monitor:uptime-monitor /opt/uptime-monitor

# Fix permissions
sudo chmod -R 755 /opt/uptime-monitor
```

### Data Directory Issues
```bash
# Create secure data directory if missing
sudo mkdir -p /opt/uptime-monitor/secure-data

# Set proper permissions
sudo chown uptime-monitor:uptime-monitor /opt/uptime-monitor/secure-data
sudo chmod 755 /opt/uptime-monitor/secure-data
```

### Firewall Issues
```bash
# Check UFW status
sudo ufw status

# Allow port 3000
sudo ufw allow 3000/tcp

# Check if port is open
sudo netstat -tlnp | grep :3000
```

## 🔄 Updates

To update Uptime Monitor Pro:

1. **Stop the service:**
   ```bash
   sudo systemctl stop uptime-monitor
   ```

2. **Backup your data:**
   ```bash
   sudo cp -r /opt/uptime-monitor/secure-data /opt/uptime-monitor-backup
   ```

3. **Replace files:**
   - Copy new `uptime-monitor-api.js`
   - Copy new `index.html`
   - Copy new `recovery.html`

4. **Update dependencies:**
   ```bash
   cd /opt/uptime-monitor
   sudo -u uptime-monitor npm install
   ```

5. **Start the service:**
   ```bash
   sudo systemctl start uptime-monitor
   ```

## 🗑️ Uninstallation

To completely remove Uptime Monitor Pro:

```bash
# Use the management script
sudo /opt/uptime-monitor/manage-uptime-monitor.sh uninstall

# Or manually:
sudo systemctl stop uptime-monitor
sudo systemctl disable uptime-monitor
sudo rm -f /etc/systemd/system/uptime-monitor.service
sudo rm -rf /opt/uptime-monitor
sudo userdel uptime-monitor
sudo systemctl daemon-reload
```

## 🔒 Security Considerations

### System User
- The service runs as a dedicated system user (`uptime-monitor`)
- No shell access or home directory login
- Minimal privileges

### File Permissions
- Installation directory: `755` (readable by all, writable by owner)
- Data files: `755` (secure but accessible)
- Service files: `644` (readable by all, writable by root)

### Firewall
- Only port 3000 is opened (if UFW is active)
- Service binds to all interfaces (0.0.0.0:3000)

### Service Security
- `NoNewPrivileges=true` - Prevents privilege escalation
- `PrivateTmp=true` - Private temporary directory
- `ProtectSystem=strict` - Read-only system directories
- `ProtectHome=true` - No access to user home directories

## 📞 Support

If you encounter issues:

1. **Check the logs:**
   ```bash
   sudo journalctl -u uptime-monitor --no-pager -n 50
   ```

2. **Verify service status:**
   ```bash
   sudo systemctl status uptime-monitor
   ```

3. **Test the API:**
   ```bash
   curl http://localhost:3000/api/health
   ```

4. **Check system requirements:**
   - Ubuntu 24.04+
   - Node.js 18+
   - Internet connection
   - Root/sudo access

## 🎉 Getting Started

Once installed and running:

1. **Add your first server:**
   - Open `http://your-server-ip:3000`
   - Enter server name and URL
   - Select check type (HTTPS, Ping, DNS, TCP, Cloudflare)
   - Set check interval
   - Click "Add Server"

2. **Configure alerts:**
   - Set up SMS alerts for downtime notifications
   - Configure FTP upload for public status pages

3. **Monitor your servers:**
   - View real-time status
   - Check uptime statistics
   - Review response times
   - Analyze status history

Your Uptime Monitor Pro is now ready to keep your servers running smoothly! 🚀
