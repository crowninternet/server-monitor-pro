# Uptime Monitor Pro - Minimal Container Installation

## 🚀 For Containers Without curl or sudo

If your container doesn't have `curl` or `sudo` installed, use this installation method:

### Step 1: Download the Minimal Installer

```bash
# Use wget to download the installer
wget https://raw.githubusercontent.com/crowninternet/uptime-monitor/main/proxmox/install-minimal.sh

# Make it executable
chmod +x install-minimal.sh
```

### Step 2: Run the Installer

```bash
# Run as root (no sudo needed)
./install-minimal.sh
```

## 🔧 What This Installer Does

1. **Installs basic tools** (wget, gnupg, ca-certificates, etc.)
2. **Installs Node.js** from NodeSource repository
3. **Creates system user** (`uptime-monitor`)
4. **Downloads application files** from GitHub using wget
5. **Installs dependencies** using npm
6. **Creates systemd service** with container optimizations
7. **Starts the service** automatically

## 📋 Prerequisites

- **Root access** to the container
- **Internet connection** for downloading packages and files
- **Debian 13** (Bookworm) container
- **At least 1GB RAM** and **8GB storage**

## 🌐 Access After Installation

- **Container Internal:** `http://localhost:3000`
- **Container IP:** `http://<container-ip>:3000`
- **API Health Check:** `http://<container-ip>:3000/api/health`

## 🛠️ Management Commands

After installation:

```bash
# Navigate to installation directory
cd /opt/uptime-monitor

# Start/stop/restart
./manage-uptime-monitor.sh start
./manage-uptime-monitor.sh stop
./manage-uptime-monitor.sh restart

# Status and logs
./manage-uptime-monitor.sh status
./manage-uptime-monitor.sh logs

# System information
./manage-uptime-monitor.sh info

# Create backup
./manage-uptime-monitor.sh backup

# Uninstall
./manage-uptime-monitor.sh uninstall
```

## 🚨 Troubleshooting

### If wget is not available:
```bash
# Install wget first
apt-get update
apt-get install -y wget
```

### If the installer fails:
```bash
# Check system requirements
cat /etc/os-release
free -h
df -h
```

### If the service won't start:
```bash
# Check logs
journalctl -u uptime-monitor -n 50

# Check if port is in use
netstat -tlnp | grep :3000
```

## 📞 Support

If you encounter issues:

1. **Check logs:** `./manage-uptime-monitor.sh logs`
2. **Check status:** `./manage-uptime-monitor.sh status`
3. **Test API:** `wget -q -O- http://localhost:3000/api/health`
4. **Check system info:** `./manage-uptime-monitor.sh info`

## 🎉 Getting Started

Once installed:

1. **Add your first server** to monitor
2. **Configure alerts** (SMS/Email)
3. **Set up FTP upload** for public status pages
4. **Monitor your servers** 24/7

Your Uptime Monitor Pro is now ready! 🚀
