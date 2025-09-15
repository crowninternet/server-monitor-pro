# Uptime Monitor Pro
## Version 1.2.0 - Now with Email Settings (SendGrid) Support

A powerful, self-hosted server monitoring solution with SMS, Email, and FTP capabilities.

## 🚀 Quick Installation

### One-Click Install (Recommended)

```bash
# Download and run the installer
chmod +x install.sh
./install.sh
```

### Manual Installation

See [INSTALLATION.md](INSTALLATION.md) for detailed manual installation instructions.

## ✨ Features

- **Real-time Monitoring** - Monitor HTTP/HTTPS, Ping, DNS, TCP, and Cloudflare-protected sites
- **SMS Alerts** - Get instant notifications via Twilio when servers go down
- **Email Alerts** - Professional email notifications via SendGrid when servers go down or come back online
- **FTP Upload** - Automatically upload public status pages to your web server
- **Persistent Storage** - File-based storage that persists across browser sessions
- **Auto-start Service** - Runs automatically on macOS startup
- **Modern UI** - Beautiful, responsive web interface
- **Drag & Drop** - Reorder servers with drag and drop
- **Status History** - Visual status charts showing uptime history
- **Recovery Tools** - Built-in recovery and troubleshooting tools

## 🎯 Getting Started

1. **Install** using the one-click installer
2. **Access** the web interface at `http://localhost:3000`
3. **Add servers** to monitor
4. **Configure SMS alerts** (optional)
5. **Configure Email alerts** (optional)
6. **Set up FTP upload** (optional)

## 🛠️ Management

After installation, use the management script:

```bash
cd ~/Documents/uptime-monitor

# Start the service
./manage-uptime-monitor.sh start

# Stop the service
./manage-uptime-monitor.sh stop

# Check status
./manage-uptime-monitor.sh status

# View logs
./manage-uptime-monitor.sh logs

# Uninstall
./manage-uptime-monitor.sh uninstall
```

## 📁 Project Structure

```
uptime-monitor/
├── install.sh                          # One-click installer
├── INSTALLATION.md                     # Detailed installation guide
├── manage-uptime-monitor.sh.template   # Management script template
├── com.uptimemonitor.plist.template    # Launch agent template
├── index.html                          # Main web interface
├── uptime-monitor-api.js               # Backend API server
├── recovery.html                       # Recovery tool
├── package.json                        # Node.js dependencies
└── secure-data/                        # Data storage (auto-created)
    ├── servers.json                    # Monitored servers
    └── config.json                     # Configuration
```

## 🔧 Configuration

### SMS Alerts (Twilio)
1. Sign up for a Twilio account
2. Get your Account SID and Auth Token
3. Purchase a phone number
4. Configure in the web interface

### Email Alerts (SendGrid) - NEW in v1.2.0
1. **Sign up for SendGrid**
   - Create a free account at [sendgrid.com](https://sendgrid.com)
   - Verify your email address
   - Complete account setup

2. **Create API Key**
   - Go to Settings → API Keys
   - Click "Create API Key"
   - Choose "Restricted Access" for security
   - Grant "Mail Send" permissions
   - Copy the API key (you won't see it again!)

3. **Verify Sender Identity**
   - Go to Settings → Sender Authentication
   - Choose "Single Sender Verification" (free)
   - Add your email address
   - Verify via email confirmation

4. **Configure in Web Interface**
   - Open `http://localhost:3000`
   - Click "Email Settings" button
   - Enter your SendGrid API Key
   - Enter your verified sender email
   - Enter recipient email for alerts
   - Enable Email alerts toggle
   - Test the configuration

5. **Professional Email Templates**
   - Beautiful HTML email alerts
   - Server status information
   - Response time details
   - Timestamp and server details

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
./manage-uptime-monitor.sh status

# View logs
./manage-uptime-monitor.sh logs

# Restart service
./manage-uptime-monitor.sh restart
```

### Common Problems
- **Port 3000 in use**: Kill the process using port 3000
- **Node.js not found**: Reinstall Node.js via Homebrew
- **Permission issues**: Check file permissions and ownership
- **Service won't start**: Check logs for error messages

## 🔄 Updates

To update to a newer version:

1. Stop the service: `./manage-uptime-monitor.sh stop`
2. Backup your data: `cp -r secure-data secure-data-backup`
3. Replace the application files
4. Update dependencies: `npm install`
5. Start the service: `./manage-uptime-monitor.sh start`

## 🗑️ Uninstallation

```bash
# Complete removal
./manage-uptime-monitor.sh uninstall
```

## 📞 Support

- Check the logs: `./manage-uptime-monitor.sh logs`
- Verify service status: `./manage-uptime-monitor.sh status`
- Test API: `curl http://localhost:3000/api/health`

## 📄 License

MIT License - see LICENSE file for details.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit pull requests or open issues.

---

**Uptime Monitor Pro** - Keep your servers running smoothly! 🚀