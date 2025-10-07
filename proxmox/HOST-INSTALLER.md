# Uptime Monitor Pro - Proxmox Host Installer

## 🚀 Single Command Container Creation

This installer runs from the **Proxmox host shell** and creates a complete LXC container with Uptime Monitor Pro pre-installed.

### **Quick Start**

```bash
# Run from Proxmox host shell
./create-uptime-monitor-container.sh --ip 192.168.1.100 --gateway 192.168.1.1
```

### **What This Does**

1. **Creates LXC Container** with Debian 12
2. **Configures Network** with specified IP and gateway
3. **Installs System Packages** (Node.js, dependencies)
4. **Creates Application Files** (embedded in script)
5. **Sets up Systemd Service** with container optimizations
6. **Starts the Service** automatically
7. **Provides Management Scripts** for ongoing operations

## 📋 Prerequisites

- **Proxmox VE 9.x** host
- **Root access** to Proxmox host
- **Debian 12 template** available in Proxmox
- **Network configuration** (IP address, gateway)

## 🛠️ Usage Options

### **Interactive Mode (Recommended)**

```bash
# Run without parameters for interactive setup
./create-uptime-monitor-container.sh
```

The script will prompt you for:
- Container name
- IP address
- Gateway
- Memory allocation
- CPU cores
- Disk size
- Authentication method

### **Command Line Mode**

```bash
# Basic usage
./create-uptime-monitor-container.sh --ip 192.168.1.100 --gateway 192.168.1.1

# Advanced usage
./create-uptime-monitor-container.sh \
  --name my-monitor \
  --ip 10.0.0.50 \
  --gateway 10.0.0.1 \
  --memory 2048 \
  --cores 4 \
  --disk 16 \
  --bridge vmbr0
```

### **Available Options**

| Option | Description | Default |
|--------|-------------|---------|
| `--name` | Container name | `uptime-monitor` |
| `--id` | Container ID | Auto-assign |
| `--template` | Template to use | `debian-12-standard` |
| `--memory` | Memory in MB | `1024` |
| `--cores` | CPU cores | `2` |
| `--disk` | Disk size in GB | `8` |
| `--ip` | IP address | Required |
| `--gateway` | Gateway | Required |
| `--bridge` | Bridge | `vmbr0` |

## 🌐 After Installation

Once the container is created, you can access:

- **Web Interface:** `http://<container-ip>:3000`
- **API Health Check:** `http://<container-ip>:3000/api/health`

## 🛠️ Container Management

### **From Proxmox Host**

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
