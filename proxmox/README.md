# Uptime Monitor Pro - Proxmox Installation

Complete uptime monitoring solution with server-side monitoring, SMS/email alerts, and 24/7 operation.

## Quick Install (Recommended)

Run this **single command** on your Proxmox host:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/crowninternet/server-monitor-pro/master/proxmox/fresh-install.sh)
```

That's it! The script will:
- ✅ Create a new LXC container
- ✅ Install Node.js and dependencies
- ✅ Install Uptime Monitor with server-side monitoring
- ✅ Configure systemd service
- ✅ Start monitoring automatically

## What You Get

### Core Features
- 📊 **Real-time monitoring** - HTTP/HTTPS/Ping checks
- 🔔 **SMS alerts** - Twilio integration for down/up notifications
- 📧 **Email alerts** - SendGrid integration for notifications
- 📤 **Public dashboard** - Auto-upload to FTP server
- 📈 **Statistics** - Uptime percentage, response times, check history
- 🎨 **Modern UI** - Beautiful, responsive web interface

### Server-Side Monitoring
- ⚡ **24/7 operation** - Checks run in Node.js backend
- 🌐 **No browser needed** - Works even when UI is closed
- 🔄 **Auto-restart** - systemd service survives reboots
- 💾 **Persistent data** - All configuration saved to disk
- 📊 **API endpoints** - Full REST API for automation

## System Requirements

- Proxmox VE 7.0 or newer
- 512MB RAM minimum (1GB recommended)
- 8GB disk space
- Network connectivity

## Manual Installation

If you prefer step-by-step installation:

### 1. Download the Script

```bash
wget https://raw.githubusercontent.com/crowninternet/server-monitor-pro/master/proxmox/fresh-install.sh
chmod +x fresh-install.sh
```

### 2. Run the Script

```bash
./fresh-install.sh
```

The script will ask for:
- Container ID (e.g., 100)
- Hostname (default: uptime-monitor)
- Disk size (default: 8GB)
- RAM (default: 512MB)
- Storage pool (default: local-lxc)

### 3. Access the Web Interface

After installation completes, open your browser to:
```
http://CONTAINER_IP:3000
```

## Management

### Service Commands

Run these from your **Proxmox host** (replace 100 with your container ID):

```bash
# Start service
pct exec 100 -- systemctl start uptime-monitor

# Stop service
pct exec 100 -- systemctl stop uptime-monitor

# Restart service
pct exec 100 -- systemctl restart uptime-monitor

# Check status
pct exec 100 -- systemctl status uptime-monitor

# View live logs
pct exec 100 -- journalctl -u uptime-monitor -f

# Check monitoring status
pct exec 100 -- curl http://localhost:3000/api/monitoring/status
```

### Container Commands

```bash
# Enter container
pct enter 100

# Start container
pct start 100

# Stop container
pct stop 100

# Container status
pct status 100
```

## Configuration

### SMS Alerts (Twilio)

1. Sign up at https://www.twilio.com
2. Get your Account SID, Auth Token, and phone numbers
3. Open web interface → Settings → SMS
4. Enter credentials and test

### Email Alerts (SendGrid)

1. Sign up at https://sendgrid.com
2. Create an API key
3. Verify your sender email
4. Open web interface → Settings → Email
5. Enter credentials and test

### FTP Upload (Public Dashboard)

1. Have FTP credentials ready
2. Open web interface → Settings → FTP
3. Enter host, username, password, path
4. Test upload

## Updating

### Update via Git

From Proxmox host:

```bash
pct exec 100 -- bash -c "cd /opt/uptime-monitor && curl -fsSL https://raw.githubusercontent.com/crowninternet/server-monitor-pro/master/uptime-monitor-api.js -o uptime-monitor-api.js && systemctl restart uptime-monitor"
```

### Update Script

```bash
wget https://raw.githubusercontent.com/crowninternet/server-monitor-pro/master/proxmox/update-from-git.sh
chmod +x update-from-git.sh
./update-from-git.sh 100
```

## Backup & Restore

### Create Backup

```bash
pct exec 100 -- tar -czf /tmp/uptime-backup.tar.gz /opt/uptime-monitor/data/
pct pull 100 /tmp/uptime-backup.tar.gz ./uptime-backup.tar.gz
```

### Restore Backup

```bash
pct push 100 ./uptime-backup.tar.gz /tmp/uptime-backup.tar.gz
pct exec 100 -- tar -xzf /tmp/uptime-backup.tar.gz -C /
pct exec 100 -- chown -R uptime-monitor:uptime-monitor /opt/uptime-monitor/data
pct exec 100 -- systemctl restart uptime-monitor
```

## Troubleshooting

### Service Won't Start

```bash
# Check logs
pct exec 100 -- journalctl -u uptime-monitor -n 50

# Check permissions
pct exec 100 -- ls -la /opt/uptime-monitor/data/

# Fix permissions
pct exec 100 -- chown -R uptime-monitor:uptime-monitor /opt/uptime-monitor
pct exec 100 -- systemctl restart uptime-monitor
```

### Can't Access Web Interface

```bash
# Check service is running
pct exec 100 -- systemctl status uptime-monitor

# Check port is open
pct exec 100 -- netstat -tlnp | grep 3000

# Check firewall (if enabled)
pct exec 100 -- iptables -L
```

### Monitoring Not Running

```bash
# Check for monitoring activity
pct exec 100 -- journalctl -u uptime-monitor --since "5 minutes ago" | grep "Check complete"

# Verify monitoring API
pct exec 100 -- curl http://localhost:3000/api/monitoring/status

# Restart service
pct exec 100 -- systemctl restart uptime-monitor
```

## Architecture

### File Locations

```
/opt/uptime-monitor/
├── uptime-monitor-api.js    # Main Node.js application
├── index.html               # Web interface
├── recovery.html            # Recovery page
├── package.json             # Dependencies
├── node_modules/            # NPM packages
└── data/                    # Data directory
    ├── servers.json         # Server configurations
    └── config.json          # App configuration
```

### Service Details

- **Service name**: uptime-monitor
- **User**: uptime-monitor (non-root)
- **Port**: 3000
- **Auto-start**: Yes (enabled on boot)
- **Restart policy**: Always (10s delay)

### Resource Limits

- Memory: 512MB max
- CPU: 50% quota
- File descriptors: 4096
- Processes: 2048

## Security

### Built-in Protections

- ✅ Non-root user execution
- ✅ Private /tmp directory
- ✅ Read-only system files
- ✅ Protected home directory
- ✅ Kernel protections enabled
- ✅ SUID/SGID restrictions
- ✅ Namespace restrictions

### Best Practices

1. **Change default port** (edit service file)
2. **Use reverse proxy** (nginx/Apache with SSL)
3. **Restrict network access** (firewall rules)
4. **Regular backups** (automate with cron)
5. **Keep updated** (check for updates monthly)

## Support

- **Documentation**: See main README.md
- **Issues**: GitHub Issues
- **Repository**: https://github.com/crowninternet/server-monitor-pro

## License

See LICENSE file in repository.

---

**Made with ❤️ for Proxmox users**
