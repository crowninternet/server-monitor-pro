# Uptime Monitor Pro - One-Liner Proxmox Installer

## 🚀 Single Command Installation

Just like the Proxmox community scripts, install Uptime Monitor Pro with a single command:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/crowninternet/server-monitor-pro/master/proxmox/uptime-monitor.sh)"
```

## 📋 What This Does

1. **Creates LXC Container** with Debian 12
2. **Configures Network** with your specified IP and gateway
3. **Installs Node.js** and all dependencies
4. **Deploys Application** with embedded files
5. **Sets up Systemd Service** with container optimizations
6. **Starts the Service** automatically
7. **Provides Management Scripts** for ongoing operations

## 🛠️ Usage Options

### **Interactive Mode (Default)**
```bash
# Run without parameters for interactive setup
bash -c "$(curl -fsSL https://raw.githubusercontent.com/crowninternet/server-monitor-pro/master/proxmox/uptime-monitor.sh)"
```

The script will prompt you for:
- IP address
- Gateway
- Root password

### **Environment Variables Mode**
```bash
# Basic usage with environment variables
CTID=100 IP=192.168.1.100 GATEWAY=192.168.1.1 bash -c "$(curl -fsSL https://raw.githubusercontent.com/crowninternet/server-monitor-pro/master/proxmox/uptime-monitor.sh)"
```

### **Full Customization**
```bash
# Advanced usage with all options
CTID=100 \
HOSTNAME=monitor \
IP=192.168.1.100 \
GATEWAY=192.168.1.1 \
MEMORY=2048 \
CORES=4 \
DISK_SIZE=16 \
bash -c "$(curl -fsSL https://raw.githubusercontent.com/crowninternet/server-monitor-pro/master/proxmox/uptime-monitor.sh)"
```

## 🔧 Available Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `CTID` | Container ID | Auto-assign |
| `HOSTNAME` | Container hostname | `uptime-monitor` |
| `PASSWORD` | Root password | Prompt |
| `MEMORY` | Memory in MB | `1024` |
| `CORES` | CPU cores | `2` |
| `DISK_SIZE` | Disk size in GB | `8` |
| `BRIDGE` | Network bridge | `vmbr0` |
| `IP` | IP address | Prompt |
| `GATEWAY` | Gateway | Prompt |
| `TEMPLATE` | Template | `debian-12-standard` |
| `STORAGE` | Storage | `local-lvm` |

## 🌐 After Installation

Once installed, access your monitoring dashboard at:

- **Web Interface:** `http://<container-ip>:3000`
- **API Health Check:** `http://<container-ip>:3000/api/health`

## 🛠️ Management Commands

### **Container Management (from Proxmox host)**
```bash
# Start container
pct start <container-id>

# Stop container
pct stop <container-id>

# Restart container
pct restart <container-id>

# Enter container shell
pct enter <container-id>

# Destroy container
pct destroy <container-id>
```

### **Application Management (from host)**
```bash
# Start service
pct exec <container-id> -- /opt/uptime-monitor/manage-uptime-monitor.sh start

# Stop service
pct exec <container-id> -- /opt/uptime-monitor/manage-uptime-monitor.sh stop

# Check status
pct exec <container-id> -- /opt/uptime-monitor/manage-uptime-monitor.sh status

# View logs
pct exec <container-id> -- /opt/uptime-monitor/manage-uptime-monitor.sh logs
```

### **Application Management (from container)**
```bash
# Enter container
pct enter <container-id>

# Start service
/opt/uptime-monitor/manage-uptime-monitor.sh start

# Stop service
/opt/uptime-monitor/manage-uptime-monitor.sh stop

# Check status
/opt/uptime-monitor/manage-uptime-monitor.sh status

# View logs
/opt/uptime-monitor/manage-uptime-monitor.sh logs
```

## 🔧 Container Specifications

### **Default Resources**
- **Memory:** 1024MB
- **CPU:** 2 cores
- **Disk:** 8GB
- **Network:** Bridge mode with static IP

### **Service Optimizations**
- **Memory Limit:** 512MB (for the service)
- **CPU Quota:** 50% (for the service)
- **Security Hardening:** Enabled
- **Auto-restart:** On failure
- **Logging:** Systemd journal

## 🚨 Troubleshooting

### **Container Won't Start**
```bash
# Check container status
pct status <container-id>

# Check logs
pct enter <container-id>
journalctl -u uptime-monitor -n 50
```

### **Service Won't Start**
```bash
# Enter container
pct enter <container-id>

# Check service status
systemctl status uptime-monitor

# Check logs
journalctl -u uptime-monitor -n 50

# Test API
curl http://localhost:3000/api/health
```

### **Network Issues**
```bash
# Check network configuration
pct enter <container-id>
ip addr show
ping 8.8.8.8
```

## 🔄 Updates

To update the application:

```bash
# Enter container
pct enter <container-id>

# Create backup
/opt/uptime-monitor/manage-uptime-monitor.sh backup

# Update application (if update script available)
/opt/uptime-monitor/manage-uptime-monitor.sh update
```

## 🗑️ Removal

To completely remove the container:

```bash
# Stop container
pct stop <container-id>

# Destroy container
pct destroy <container-id>
```

## 📞 Support

If you encounter issues:

1. **Check container status:** `pct status <container-id>`
2. **Check service logs:** `pct exec <container-id> -- journalctl -u uptime-monitor`
3. **Test API:** `pct exec <container-id> -- curl http://localhost:3000/api/health`
4. **Check system info:** `pct exec <container-id> -- /opt/uptime-monitor/manage-uptime-monitor.sh info`

## 🎉 Getting Started

Once the container is created:

1. **Open** `http://<container-ip>:3000` in your browser
2. **Add your first server** to monitor
3. **Configure alerts** (SMS/Email)
4. **Set up FTP upload** for public status pages
5. **Monitor your servers** 24/7

Your Uptime Monitor Pro is now ready to keep your servers running smoothly! 🚀

## 📋 Prerequisites

- **Proxmox VE 9.x** host
- **Root access** to Proxmox host
- **Debian 12 template** available in Proxmox
- **Network configuration** (IP address, gateway)

## 🔗 Similar to Proxmox Community Scripts

This installer follows the same pattern as other Proxmox community scripts:

- **Uptime Kuma:** `bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/uptimekuma.sh)"`
- **Uptime Monitor Pro:** `bash -c "$(curl -fsSL https://raw.githubusercontent.com/crowninternet/server-monitor-pro/master/proxmox/uptime-monitor.sh)"`

Both provide the same simple, one-command installation experience!
