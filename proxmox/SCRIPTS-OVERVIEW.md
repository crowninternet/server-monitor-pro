# Proxmox Scripts Overview

This directory contains essential scripts for Proxmox LXC deployment.

## Installation Scripts

### 1. fresh-install.sh ⭐ (RECOMMENDED)
**Purpose**: Complete fresh installation from Proxmox host

**Usage**:
```bash
# Interactive
./fresh-install.sh

# One-liner
bash <(curl -fsSL https://raw.githubusercontent.com/crowninternet/server-monitor-pro/master/proxmox/fresh-install.sh)
```

**What it does**:
- Creates new LXC container
- Installs Node.js and dependencies
- Sets up Uptime Monitor with all bug fixes
- Configures systemd service
- Starts monitoring automatically

**Status**: ✅ Production ready with all fixes

---

## Management Scripts

### 2. manage-uptime-monitor.sh
**Purpose**: Manage the service inside the container

**Usage** (from Proxmox host):
```bash
pct exec CONTAINER_ID -- /opt/uptime-monitor/manage-uptime-monitor.sh {start|stop|restart|status|logs}
```

**Commands**:
- `start` - Start the service
- `stop` - Stop the service
- `restart` - Restart the service
- `status` - Show service status
- `logs` - View recent logs
- `logs-tail` - Follow logs in real-time
- `info` - Show system information
- `backup` - Create backup
- `uninstall` - Remove installation

---

## Update Scripts

### 3. update-from-git.sh
**Purpose**: Update existing installation to latest version

**Usage** (from Proxmox host):
```bash
./update-from-git.sh CONTAINER_ID
```

**What it does**:
- Auto-detects container if ID not provided
- Pulls latest code from GitHub
- Restarts service
- Verifies update

**Example**:
```bash
./update-from-git.sh 100
```

---

## Backup & Restore Scripts

### 4. backup.sh
**Purpose**: Create backup of Uptime Monitor data

**Usage** (inside container):
```bash
/opt/uptime-monitor/backup.sh
```

**What it backs up**:
- Server configurations (servers.json)
- Application settings (config.json)
- Service configuration
- Application files

**Output**: Creates timestamped tar.gz file

### 5. restore.sh
**Purpose**: Restore from backup

**Usage** (inside container):
```bash
/opt/uptime-monitor/restore.sh /path/to/backup.tar.gz
```

---

## Service File

### uptime-monitor.service
**Purpose**: systemd service definition

**Location**: Copied to `/etc/systemd/system/uptime-monitor.service`

**Features**:
- Auto-restart on failure
- Resource limits (512MB RAM, 50% CPU)
- Security hardening
- Runs as non-root user

---

## Documentation

### README.md
**Purpose**: Complete installation and usage guide

**Contents**:
- Quick install instructions
- System requirements
- Configuration guides
- Troubleshooting
- Management commands

### INSTALL-VERIFIED.md
**Purpose**: Installation verification checklist

**Contents**:
- Script verification
- Bug fixes included
- Expected output
- Post-installation tests

### SECURE-CONFIGURATION.md
**Purpose**: Security hardening guide

**Contents**:
- Firewall configuration
- SSL/TLS setup
- Access restrictions
- Best practices

---

## Removed Scripts (No Longer Needed)

The following scripts have been removed as they're outdated or replaced:

❌ `create-uptime-monitor-container.sh` - Replaced by fresh-install.sh  
❌ `install.sh` - Replaced by fresh-install.sh  
❌ `install-minimal.sh` - No longer needed  
❌ `install-standalone.sh` - No longer needed  
❌ `uptime-monitor.sh` - Duplicate/old  
❌ `configure-credentials.sh` - Done in web UI  
❌ `fix-installation.sh` - Not needed with fresh install  
❌ `update-monitoring.sh` - Replaced by update-from-git.sh  
❌ All container-104 specific debug scripts  

---

## Quick Reference

### Fresh Install (New Container)
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/crowninternet/server-monitor-pro/master/proxmox/fresh-install.sh)
```

### Update Existing Container
```bash
./update-from-git.sh CONTAINER_ID
```

### Manage Service
```bash
pct exec CONTAINER_ID -- systemctl {start|stop|restart|status} uptime-monitor
```

### View Logs
```bash
pct exec CONTAINER_ID -- journalctl -u uptime-monitor -f
```

### Backup Data
```bash
pct exec CONTAINER_ID -- /opt/uptime-monitor/backup.sh
```

---

## Support

For issues or questions:
- Check README.md for troubleshooting
- View logs for errors
- Check GitHub repository for updates

