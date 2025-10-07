# Uptime Monitor Pro - Proxmox 9 + Debian 13 Installation Guide

## 🚀 One-Click Installation from GitHub

### Quick Start Command

```bash
# Run this command in your Proxmox Debian 13 container:
curl -fsSL https://raw.githubusercontent.com/crowninternet/uptime-monitor/main/proxmox/install.sh | sudo bash
```

### What This Does

1. **Downloads** the latest installer from GitHub
2. **Installs** all dependencies (Node.js, system packages)
3. **Downloads** the application files from GitHub
4. **Configures** the systemd service with container optimizations
5. **Starts** the Uptime Monitor Pro service
6. **Provides** management commands for ongoing operations

## 📋 Prerequisites

### Proxmox Container Requirements
- **Proxmox VE:** 9.x
- **Container OS:** Debian 13 (Bookworm)
- **Memory:** Minimum 1GB RAM (recommended 2GB)
- **Storage:** Minimum 8GB (recommended 16GB)
- **Network:** Internet access for installation and monitoring

### Container Setup
1. Create a new LXC container in Proxmox
2. Use Debian 13 template
3. Allocate resources as specified above
4. Enable network access
5. Start the container

## 🛠️ Installation Methods

### Method 1: Direct GitHub Installation (Recommended)

```bash
# Access your container
pct enter <container-id>
# Or SSH: ssh root@<container-ip>

# Run the installer
curl -fsSL https://raw.githubusercontent.com/crowninternet/uptime-monitor/main/proxmox/install.sh | sudo bash
```

### Method 2: Download and Run

```bash
# Download the installer
wget https://raw.githubusercontent.com/crowninternet/uptime-monitor/main/proxmox/install.sh

# Make it executable
chmod +x install.sh

# Run the installer
sudo ./install.sh
```

### Method 3: Manual Installation

If you prefer manual installation or need to customize:

```bash
# 1. Update system
apt-get update -y && apt-get upgrade -y

# 2. Install Node.js
curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
apt-get install -y nodejs

# 3. Create system user
useradd --system --shell /bin/false --home-dir /opt/uptime-monitor --create-home uptime-monitor

# 4. Download application files
mkdir -p /opt/uptime-monitor
cd /opt/uptime-monitor

curl -fsSL https://raw.githubusercontent.com/crowninternet/uptime-monitor/main/package.json -o package.json
curl -fsSL https://raw.githubusercontent.com/crowninternet/uptime-monitor/main/uptime-monitor-api.js -o uptime-monitor-api.js
curl -fsSL https://raw.githubusercontent.com/crowninternet/uptime-monitor/main/index.html -o index.html
curl -fsSL https://raw.githubusercontent.com/crowninternet/uptime-monitor/main/recovery.html -o recovery.html

# 5. Install dependencies
sudo -u uptime-monitor npm install --production

# 6. Create service file
curl -fsSL https://raw.githubusercontent.com/crowninternet/uptime-monitor/main/proxmox/uptime-monitor.service -o /etc/systemd/system/uptime-monitor.service

# 7. Start service
systemctl daemon-reload
systemctl enable uptime-monitor
systemctl start uptime-monitor
```

## 🌐 Accessing the Application

After installation, access the application at:

- **Container Internal:** `http://localhost:3000`
- **Container IP:** `http://<container-ip>:3000`
- **API Health Check:** `http://<container-ip>:3000/api/health`

### Port Forwarding (Optional)

To access from outside the Proxmox host:

#### Via Proxmox Web Interface
1. Go to Datacenter → Firewall → Rules
2. Add rule: Source: Any, Dest: Container IP, Port: 3000

#### Via Command Line (on Proxmox host)
```bash
# Replace <container-ip> with your container's IP
iptables -t nat -A PREROUTING -p tcp --dport 3000 -j DNAT --to-destination <container-ip>:3000
iptables -A FORWARD -p tcp -d <container-ip> --dport 3000 -j ACCEPT
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

## 🔧 Configuration

### SMS Alerts (Optional)
1. Open `http://<container-ip>:3000`
2. Click "SMS Settings"
3. Enter Twilio credentials
4. Enable SMS alerts

### Email Alerts (Optional)
1. Click "Email Settings"
2. Enter SendGrid credentials
3. Enable Email alerts

### FTP Upload (Optional)
1. Click "FTP Settings"
2. Enter FTP server details
3. Enable FTP upload

## 🚨 Troubleshooting

### Service Won't Start
```bash
# Check service status
systemctl status uptime-monitor

# Check logs
journalctl -u uptime-monitor -n 50

# Check port usage
netstat -tlnp | grep :3000
```

### Container Resource Issues
```bash
# Check memory usage
free -h

# Check disk space
df -h

# Check container limits
systemctl show uptime-monitor --property=MemoryMax,CPUQuota
```

### Network Issues
```bash
# Test connectivity
ping 8.8.8.8

# Test API
curl http://localhost:3000/api/health

# Check firewall
ufw status
```

## 🔄 Updates

To update the application:

```bash
# Use the management script
sudo /opt/uptime-monitor/manage-uptime-monitor.sh update
```

## 🗑️ Uninstallation

To completely remove:

```bash
# Use the management script
sudo /opt/uptime-monitor/manage-uptime-monitor.sh uninstall
```

## 📞 Support

If you encounter issues:

1. Check logs: `sudo /opt/uptime-monitor/manage-uptime-monitor.sh logs`
2. Check status: `sudo /opt/uptime-monitor/manage-uptime-monitor.sh status`
3. Test API: `curl http://localhost:3000/api/health`
4. Check system info: `sudo /opt/uptime-monitor/manage-uptime-monitor.sh info`

## 🎉 Getting Started

Once installed:

1. **Add your first server** to monitor
2. **Configure alerts** (SMS/Email)
3. **Set up FTP upload** for public status pages
4. **Monitor your servers** 24/7

Your Uptime Monitor Pro is now ready to keep your servers running smoothly! 🚀
