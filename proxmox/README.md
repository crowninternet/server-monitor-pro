# Uptime Monitor Pro - Proxmox 9 + Debian 13 Installation

## 🚀 Quick Start (One-Click Installation)

### Prerequisites
- Proxmox VE 9.x
- Debian 13 (Bookworm) LXC container
- Root access to the container
- Internet connection

### Installation Steps

1. **Create a Debian 13 LXC Container**
   ```bash
   # In Proxmox web interface:
   # 1. Create new CT (Container)
   # 2. Select Debian 13 template
   # 3. Allocate at least 1GB RAM and 8GB storage
   # 4. Enable network access
   ```

2. **Access the Container**
   ```bash
   # Via Proxmox console or SSH
   pct enter <container-id>
   # Or SSH if configured
   ssh root@<container-ip>
   ```

3. **Run the One-Click Installer**
   ```bash
   # Download and run the installer
   curl -fsSL https://raw.githubusercontent.com/crowninternet/uptime-monitor/main/proxmox/install.sh | sudo bash
   
   # Or download first, then run
   wget https://raw.githubusercontent.com/crowninternet/uptime-monitor/main/proxmox/install.sh
   chmod +x install.sh
   sudo ./install.sh
   ```

4. **Access Your Dashboard**
   - Container internal: `http://localhost:3000`
   - External access: `http://<container-ip>:3000`
   - Configure port forwarding in Proxmox if needed

## 📋 What the Installer Does

The installation script automatically:

✅ **Updates system packages** (Debian 13)  
✅ **Installs Node.js** (latest LTS version)  
✅ **Creates system user** (`uptime-monitor`)  
✅ **Downloads application files** from GitHub  
✅ **Installs Node.js dependencies**  
✅ **Creates systemd service** with container optimizations  
✅ **Configures resource limits** (512MB RAM, 50% CPU)  
✅ **Enables security hardening**  
✅ **Starts the service**  
✅ **Creates management script**  

## 🎯 Manual Installation (Alternative)

If you prefer to install manually or the automated installer fails:

### Step 1: Update System
```bash
apt-get update -y
apt-get upgrade -y
apt-get install -y curl wget gnupg ca-certificates
```

### Step 2: Install Node.js
```bash
curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
apt-get install -y nodejs
```

### Step 3: Create System User
```bash
useradd --system --shell /bin/false --home-dir /opt/uptime-monitor --create-home uptime-monitor
```

### Step 4: Download Application
```bash
mkdir -p /opt/uptime-monitor
cd /opt/uptime-monitor

# Download files
curl -fsSL https://raw.githubusercontent.com/crowninternet/uptime-monitor/main/package.json -o package.json
curl -fsSL https://raw.githubusercontent.com/crowninternet/uptime-monitor/main/uptime-monitor-api.js -o uptime-monitor-api.js
curl -fsSL https://raw.githubusercontent.com/crowninternet/uptime-monitor/main/index.html -o index.html
curl -fsSL https://raw.githubusercontent.com/crowninternet/uptime-monitor/main/recovery.html -o recovery.html

# Install dependencies
sudo -u uptime-monitor npm install --production
```

### Step 5: Create Service
```bash
# Copy service file
curl -fsSL https://raw.githubusercontent.com/crowninternet/uptime-monitor/main/proxmox/uptime-monitor.service -o /etc/systemd/system/uptime-monitor.service

# Enable and start service
systemctl daemon-reload
systemctl enable uptime-monitor
systemctl start uptime-monitor
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

# Show system information
sudo ./manage-uptime-monitor.sh info

# Create backup
sudo ./manage-uptime-monitor.sh backup

# Restore from backup
sudo ./manage-uptime-monitor.sh restore /path/to/backup.tar.gz

# Update application
sudo ./manage-uptime-monitor.sh update

# Uninstall completely
sudo ./manage-uptime-monitor.sh uninstall
```

## 🌐 Accessing the Application

- **Container Internal:** `http://localhost:3000`
- **Container IP:** `http://<container-ip>:3000`
- **API Health Check:** `http://<container-ip>:3000/api/health`

### Port Forwarding (Optional)

To access from outside the Proxmox host:

1. **Via Proxmox Web Interface:**
   - Go to Datacenter → Firewall → Rules
   - Add rule: Source: Any, Dest: Container IP, Port: 3000

2. **Via iptables (on Proxmox host):**
   ```bash
   iptables -t nat -A PREROUTING -p tcp --dport 3000 -j DNAT --to-destination <container-ip>:3000
   iptables -A FORWARD -p tcp -d <container-ip> --dport 3000 -j ACCEPT
   ```

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
├── logs/                         # Application logs
├── container-config.json         # Container-specific config
├── manage-uptime-monitor.sh      # Management script
└── install.sh                   # Installation script
```

## 🔧 Container Optimizations

### Resource Limits
- **Memory Limit:** 512MB
- **CPU Quota:** 50%
- **File Descriptors:** 4,096
- **Process Limit:** 2,048

### Security Hardening
- **No New Privileges:** Enabled
- **Private Temp:** Enabled
- **Protect System:** Strict
- **Protect Home:** Enabled
- **Kernel Protection:** Enabled

### Performance Optimizations
- **Container Mode:** Enabled
- **Reduced Log Verbosity:** Enabled
- **Memory Usage Optimization:** Enabled
- **Systemd Integration:** Full

## 🔧 Configuration

### SMS Alerts (Optional)
1. Open the web interface at `http://<container-ip>:3000`
2. Click "SMS Settings" button
3. Enter your Twilio credentials:
   - Account SID
   - Auth Token
   - From Number (your Twilio phone number)
   - Alert Number (your phone number for alerts)
4. Enable SMS alerts toggle
5. Test the configuration

### Email Alerts (Optional)
1. Click "Email Settings" button
2. Enter your SendGrid credentials:
   - SendGrid API Key
   - From Email Address (verified sender)
   - To Email Address (recipient for alerts)
3. Enable Email alerts toggle
4. Test the configuration
5. Professional HTML email templates included

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
systemctl status uptime-monitor

# Check logs for errors
journalctl -u uptime-monitor -n 50

# Check if port is in use
netstat -tlnp | grep :3000

# Try starting manually
cd /opt/uptime-monitor
sudo -u uptime-monitor node uptime-monitor-api.js
```

### Container Resource Issues
```bash
# Check memory usage
free -h

# Check disk space
df -h

# Check CPU usage
top

# Check container limits
systemctl show uptime-monitor --property=MemoryMax,CPUQuota
```

### Network Connectivity Issues
```bash
# Test container network
ping 8.8.8.8

# Check DNS resolution
nslookup google.com

# Test API from container
curl http://localhost:3000/api/health

# Check firewall rules
ufw status
```

### Node.js Issues
```bash
# Check Node.js version
node --version
npm --version

# Reinstall Node.js if needed
curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
apt-get install -y nodejs

# Check dependencies
cd /opt/uptime-monitor
npm list
```

### Permission Issues
```bash
# Check file permissions
ls -la /opt/uptime-monitor/

# Fix permissions
chown -R uptime-monitor:uptime-monitor /opt/uptime-monitor
chmod 755 /opt/uptime-monitor
chmod 644 /opt/uptime-monitor/*.json /opt/uptime-monitor/*.js /opt/uptime-monitor/*.html
```

## 🔄 Updates

To update Uptime Monitor Pro:

```bash
# Use the management script
sudo /opt/uptime-monitor/manage-uptime-monitor.sh update

# Or manually:
# 1. Create backup
sudo /opt/uptime-monitor/manage-uptime-monitor.sh backup

# 2. Stop service
sudo systemctl stop uptime-monitor

# 3. Download updated files
cd /opt/uptime-monitor
curl -fsSL https://raw.githubusercontent.com/crowninternet/uptime-monitor/main/uptime-monitor-api.js -o uptime-monitor-api.js
curl -fsSL https://raw.githubusercontent.com/crowninternet/uptime-monitor/main/index.html -o index.html
curl -fsSL https://raw.githubusercontent.com/crowninternet/uptime-monitor/main/recovery.html -o recovery.html

# 4. Update dependencies
sudo -u uptime-monitor npm install --production

# 5. Start service
sudo systemctl start uptime-monitor
```

## 🗑️ Uninstallation

To completely remove Uptime Monitor Pro:

```bash
# Use the management script
sudo /opt/uptime-monitor/manage-uptime-monitor.sh uninstall

# Or manually:
systemctl stop uptime-monitor
systemctl disable uptime-monitor
rm -f /etc/systemd/system/uptime-monitor.service
rm -rf /opt/uptime-monitor
userdel uptime-monitor
systemctl daemon-reload
```

## 📞 Support

If you encounter issues:

1. **Check the logs:**
   ```bash
   sudo /opt/uptime-monitor/manage-uptime-monitor.sh logs
   ```

2. **Verify service status:**
   ```bash
   sudo /opt/uptime-monitor/manage-uptime-monitor.sh status
   ```

3. **Test the API:**
   ```bash
   curl http://localhost:3000/api/health
   ```

4. **Check system information:**
   ```bash
   sudo /opt/uptime-monitor/manage-uptime-monitor.sh info
   ```

5. **Check system requirements:**
   - Proxmox VE 9.x
   - Debian 13 (Bookworm)
   - Node.js 18+
   - Internet connection
   - At least 1GB RAM
   - At least 8GB storage

## 🎉 Getting Started

Once installed and running:

1. **Add your first server:**
   - Open `http://<container-ip>:3000`
   - Enter server name and URL
   - Select check type (HTTPS, Ping, DNS, TCP, Cloudflare)
   - Set check interval
   - Click "Add Server"

2. **Configure alerts:**
   - Set up SMS alerts for downtime notifications (Twilio)
   - Set up Email alerts for downtime notifications (SendGrid)
   - Configure FTP upload for public status pages

3. **Monitor your servers:**
   - View real-time status
   - Check uptime statistics
   - Review response times
   - Analyze status history

## 🔧 Proxmox-Specific Features

### Container Template
Consider creating a container template with:
- Pre-installed Node.js
- System packages
- Pre-configured systemd services
- Optimized resource limits

### Backup Integration
- Integrate with Proxmox backup system
- Configure automatic backups
- Include data directory in backups

### Monitoring Integration
- Add container health checks
- Monitor resource usage
- Alert on container issues

Your Uptime Monitor Pro is now ready to keep your servers running smoothly in your Proxmox environment! 🚀
