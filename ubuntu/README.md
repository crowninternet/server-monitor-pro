# Uptime Monitor Pro - Ubuntu 24.04 Server Edition

A powerful, self-hosted server monitoring solution with SMS alerts and FTP upload capabilities, optimized for Ubuntu 24.04 LTS Server.

## 🚀 Quick Installation

### One-Click Install (Recommended)

```bash
# Download and run the installer
chmod +x install.sh
sudo ./install.sh
```

### Manual Installation

See [INSTALLATION.md](INSTALLATION.md) for detailed manual installation instructions.

## ✨ Features

- **Real-time Monitoring** - Monitor HTTP/HTTPS, Ping, DNS, TCP, and Cloudflare-protected sites
- **SMS Alerts** - Get instant notifications via Twilio when servers go down
- **FTP Upload** - Automatically upload public status pages to your web server
- **Persistent Storage** - File-based storage that persists across browser sessions
- **Auto-start Service** - Runs automatically on Ubuntu startup via systemd
- **Modern UI** - Beautiful, responsive web interface
- **Drag & Drop** - Reorder servers with drag and drop
- **Status History** - Visual status charts showing uptime history
- **Recovery Tools** - Built-in recovery and troubleshooting tools
- **Security** - Runs as dedicated system user with minimal privileges

## 🎯 Getting Started

1. **Install** using the one-click installer
2. **Access** the web interface at `http://your-server-ip:3000`
3. **Add servers** to monitor
4. **Configure SMS alerts** (optional)
5. **Set up FTP upload** (optional)

## 🛠️ Management

After installation, use the management script:

```bash
cd /opt/uptime-monitor

# Start the service
sudo ./manage-uptime-monitor.sh start

# Stop the service
sudo ./manage-uptime-monitor.sh stop

# Check status
sudo ./manage-uptime-monitor.sh status

# View logs
sudo ./manage-uptime-monitor.sh logs

# Follow logs in real-time
sudo ./manage-uptime-monitor.sh logs-tail

# Test API
sudo ./manage-uptime-monitor.sh test

# Uninstall
sudo ./manage-uptime-monitor.sh uninstall
```

## 📁 Project Structure

```
ubuntu/
├── install.sh                          # One-click installer
├── INSTALLATION.md                     # Detailed installation guide
├── manage-uptime-monitor.sh.template   # Management script template
├── uptime-monitor.service.template     # systemd service template
├── test-installation.sh                # Installation validation script
└── README.md                           # This file
```

## 🔧 Configuration

### SMS Alerts (Twilio)
1. Sign up for a Twilio account
2. Get your Account SID and Auth Token
3. Purchase a phone number
4. Configure in the web interface

### FTP Upload
1. Set up FTP server credentials
2. Configure upload settings
3. Enable automatic uploads

## 📊 Monitoring Types

- **HTTPS/HTTP** - Web server monitoring with 3-strike failure detection
- **Ping** - Basic connectivity testing
- **DNS** - Domain name resolution checking
- **TCP** - Port connectivity testing
- **Cloudflare** - Specialized monitoring for Cloudflare-protected sites

## 🚨 Troubleshooting

### Service Issues
```bash
# Check service status
sudo systemctl status uptime-monitor

# View logs
sudo journalctl -u uptime-monitor --no-pager -n 50

# Restart service
sudo systemctl restart uptime-monitor
```

### Common Problems
- **Port 3000 in use**: Kill the process using port 3000
- **Node.js not found**: Reinstall Node.js via NodeSource repository
- **Permission issues**: Check file permissions and ownership
- **Service won't start**: Check logs for error messages
- **Firewall issues**: Configure UFW to allow port 3000

## 🔄 Updates

To update to a newer version:

1. Stop the service: `sudo systemctl stop uptime-monitor`
2. Backup your data: `sudo cp -r /opt/uptime-monitor/secure-data /opt/uptime-monitor-backup`
3. Replace the application files
4. Update dependencies: `cd /opt/uptime-monitor && sudo -u uptime-monitor npm install`
5. Start the service: `sudo systemctl start uptime-monitor`

## 🗑️ Uninstallation

```bash
# Complete removal
sudo /opt/uptime-monitor/manage-uptime-monitor.sh uninstall
```

## 🔒 Security Features

### System User
- Runs as dedicated `uptime-monitor` system user
- No shell access or login capabilities
- Minimal system privileges

### Service Security
- `NoNewPrivileges=true` - Prevents privilege escalation
- `PrivateTmp=true` - Private temporary directory
- `ProtectSystem=strict` - Read-only system directories
- `ProtectHome=true` - No access to user home directories

### File Permissions
- Installation directory: `755` (readable by all, writable by owner)
- Service files: `644` (readable by all, writable by root)

## 📞 Support

- Check the logs: `sudo journalctl -u uptime-monitor --no-pager -n 50`
- Verify service status: `sudo systemctl status uptime-monitor`
- Test API: `curl http://localhost:3000/api/health`

## 📄 License

MIT License - see LICENSE file for details.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit pull requests or open issues.

---

**Uptime Monitor Pro** - Keep your servers running smoothly on Ubuntu! 🚀
