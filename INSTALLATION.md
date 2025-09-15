# Uptime Monitor Pro - Installation Guide for macOS
## Version 1.2.0 - Now with Email Settings (SendGrid) Support

## 🚀 Quick Start (One-Click Installation)

### Prerequisites
- macOS 10.15 (Catalina) or later
- Internet connection
- Administrator privileges

### Installation Steps

1. **Download the Installation Package**
   ```bash
   # Clone or download the uptime-monitor project
   git clone <repository-url> uptime-monitor
   cd uptime-monitor
   ```

2. **Run the One-Click Installer**
   ```bash
   # Make the script executable
   chmod +x install.sh
   
   # Run the installer
   ./install.sh
   ```

3. **Access Your Dashboard**
   - Open your browser and go to: `http://localhost:3000`
   - The service will start automatically

## 📋 What the Installer Does

The installation script automatically:

✅ **Installs Homebrew** (if not already installed)  
✅ **Installs Node.js** (latest LTS version)  
✅ **Creates installation directory** (`~/Documents/uptime-monitor`)  
✅ **Copies all project files**  
✅ **Installs Node.js dependencies**  
✅ **Creates macOS Launch Agent** (for auto-start)  
✅ **Creates management script**  
✅ **Starts the service**  
✅ **Creates desktop shortcut**  

## 🎯 Manual Installation (Alternative)

If you prefer to install manually or the automated installer fails:

### Step 1: Install Homebrew
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### Step 2: Install Node.js
```bash
brew install node
```

### Step 3: Create Project Directory
```bash
mkdir -p ~/Documents/uptime-monitor
cd ~/Documents/uptime-monitor
```

### Step 4: Copy Project Files
Copy these files to your installation directory:
- `package.json`
- `uptime-monitor-api.js`
- `index.html`
- `recovery.html`

### Step 5: Install Dependencies
```bash
npm install
```

### Step 6: Create Launch Agent
Create `~/Library/LaunchAgents/com.uptimemonitor.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.uptimemonitor</string>
    
    <key>ProgramArguments</key>
    <array>
        <string>/opt/homebrew/bin/node</string>
        <string>/Users/YOUR_USERNAME/Documents/uptime-monitor/uptime-monitor-api.js</string>
    </array>
    
    <key>WorkingDirectory</key>
    <string>/Users/YOUR_USERNAME/Documents/uptime-monitor</string>
    
    <key>RunAtLoad</key>
    <true/>
    
    <key>KeepAlive</key>
    <true/>
    
    <key>StandardOutPath</key>
    <string>/Users/YOUR_USERNAME/Documents/uptime-monitor/uptime-monitor.log</string>
    
    <key>StandardErrorPath</key>
    <string>/Users/YOUR_USERNAME/Documents/uptime-monitor/uptime-monitor-error.log</string>
    
    <key>EnvironmentVariables</key>
    <dict>
        <key>NODE_ENV</key>
        <string>production</string>
    </dict>
</dict>
</plist>
```

**Important:** Replace `YOUR_USERNAME` with your actual macOS username.

### Step 7: Start the Service
```bash
launchctl load ~/Library/LaunchAgents/com.uptimemonitor.plist
```

## 🛠️ Management Commands

After installation, use these commands to manage the service:

```bash
# Navigate to installation directory
cd ~/Documents/uptime-monitor

# Start the service
./manage-uptime-monitor.sh start

# Stop the service
./manage-uptime-monitor.sh stop

# Restart the service
./manage-uptime-monitor.sh restart

# Check service status
./manage-uptime-monitor.sh status

# View logs
./manage-uptime-monitor.sh logs

# Uninstall completely
./manage-uptime-monitor.sh uninstall
```

## 🌐 Accessing the Application

- **Web Interface:** `http://localhost:3000`
- **API Health Check:** `http://localhost:3000/api/health`
- **Desktop Shortcut:** Created automatically on your desktop

## 📁 File Structure

After installation, your directory structure will be:

```
~/Documents/uptime-monitor/
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
├── uptime-monitor.log            # Application logs
├── uptime-monitor-error.log      # Error logs
└── install.sh                   # Installation script
```

## 🔧 Configuration

### SMS Alerts (Optional)
1. Open the web interface at `http://localhost:3000`
2. Click "SMS Settings" button
3. Enter your Twilio credentials:
   - Account SID
   - Auth Token
   - From Number (your Twilio phone number)
   - Alert Number (your phone number for alerts)
4. Enable SMS alerts toggle
5. Test the configuration

### Email Alerts (Optional) - NEW in v1.2.0
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
# Check if the service is loaded
launchctl list | grep uptimemonitor

# Check logs for errors
tail -f ~/Documents/uptime-monitor/uptime-monitor-error.log

# Try starting manually
cd ~/Documents/uptime-monitor
node uptime-monitor-api.js
```

### Port 3000 Already in Use
```bash
# Find what's using port 3000
lsof -i :3000

# Kill the process (replace PID with actual process ID)
kill -9 PID

# Or change the port in uptime-monitor-api.js
# Edit the PORT variable at the top of the file
```

### Node.js Not Found
```bash
# Check if Node.js is installed
which node
node --version

# If not found, reinstall
brew install node

# Update PATH for Apple Silicon Macs
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
source ~/.zprofile
```

### Permission Issues
```bash
# Make scripts executable
chmod +x ~/Documents/uptime-monitor/manage-uptime-monitor.sh
chmod +x ~/Documents/uptime-monitor/install.sh

# Check file permissions
ls -la ~/Documents/uptime-monitor/
```

### Data Directory Issues
```bash
# Create secure data directory if missing
mkdir -p ~/Documents/uptime-monitor/secure-data

# Set proper permissions
chmod 755 ~/Documents/uptime-monitor/secure-data
```

## 🔄 Updates

To update Uptime Monitor Pro:

1. **Stop the service:**
   ```bash
   ~/Documents/uptime-monitor/manage-uptime-monitor.sh stop
   ```

2. **Backup your data:**
   ```bash
   cp -r ~/Documents/uptime-monitor/secure-data ~/Documents/uptime-monitor-backup
   ```

3. **Replace files:**
   - Copy new `uptime-monitor-api.js`
   - Copy new `index.html`
   - Copy new `recovery.html`

4. **Update dependencies:**
   ```bash
   cd ~/Documents/uptime-monitor
   npm install
   ```

5. **Start the service:**
   ```bash
   ~/Documents/uptime-monitor/manage-uptime-monitor.sh start
   ```

## 🗑️ Uninstallation

To completely remove Uptime Monitor Pro:

```bash
# Use the management script
~/Documents/uptime-monitor/manage-uptime-monitor.sh uninstall

# Or manually:
launchctl unload ~/Library/LaunchAgents/com.uptimemonitor.plist
rm -f ~/Library/LaunchAgents/com.uptimemonitor.plist
rm -rf ~/Documents/uptime-monitor
rm -f ~/Desktop/Uptime\ Monitor\ Pro.html
```

## 📞 Support

If you encounter issues:

1. **Check the logs:**
   ```bash
   ~/Documents/uptime-monitor/manage-uptime-monitor.sh logs
   ```

2. **Verify service status:**
   ```bash
   ~/Documents/uptime-monitor/manage-uptime-monitor.sh status
   ```

3. **Test the API:**
   ```bash
   curl http://localhost:3000/api/health
   ```

4. **Check system requirements:**
   - macOS 10.15+
   - Node.js 16+
   - Internet connection

## 🎉 Getting Started

Once installed and running:

1. **Add your first server:**
   - Open `http://localhost:3000`
   - Enter server name and URL
   - Select check type (HTTPS, Ping, DNS, TCP, Cloudflare)
   - Set check interval
   - Click "Add Server"

2. **Configure alerts:**
   - Set up SMS alerts for downtime notifications (Twilio)
   - Set up Email alerts for downtime notifications (SendGrid) - NEW!
   - Configure FTP upload for public status pages

3. **Monitor your servers:**
   - View real-time status
   - Check uptime statistics
   - Review response times
   - Analyze status history

Your Uptime Monitor Pro is now ready to keep your servers running smoothly! 🚀
