# Uptime Monitor Pro - Secure Credentials Configuration

## 🔐 Overview

This guide explains how to securely configure sensitive credentials (Twilio, SendGrid, FTP) in your Proxmox container.

## 🎯 Two Configuration Methods

### **Method 1: Interactive Configuration Script (Recommended)**

Use the built-in configuration script for secure, guided setup:

```bash
# From Proxmox host
pct exec <container-id> -- /opt/uptime-monitor/configure-credentials.sh

# Or enter the container and run
pct enter <container-id>
/opt/uptime-monitor/configure-credentials.sh
```

### **Method 2: Web Interface**

Configure credentials through the web interface after installation:
- Navigate to `http://<container-ip>:3000`
- Click "SMS Settings", "Email Settings", or "FTP Settings"
- Enter your credentials
- Credentials are stored in `/opt/uptime-monitor/secure-data/config.json`

## 🔒 Security Features

### **File Permissions**
- **`.env` file:** `600` (read/write owner only)
- **`secure-data/` directory:** `700` (owner only)
- **`config.json`:** `600` (read/write owner only)
- **Owner:** `uptime-monitor` user (non-root)

### **Storage Locations**
- **Environment Variables:** `/opt/uptime-monitor/.env`
- **Configuration:** `/opt/uptime-monitor/secure-data/config.json`
- **Not accessible from web:** Both locations are outside the web root

## 📋 Configuration Script Features

The `configure-credentials.sh` script provides:

1. **Interactive prompts** for all credentials
2. **Password masking** for sensitive inputs
3. **Automatic backup** of existing configuration
4. **Secure file permissions** (600/700)
5. **Service restart** option after configuration

## 🛠️ Configuring Twilio (SMS Alerts)

### **Using Configuration Script**
```bash
pct exec <container-id> -- /opt/uptime-monitor/configure-credentials.sh
```

Select "Yes" when prompted for Twilio configuration, then provide:
- Twilio Account SID
- Twilio Auth Token (masked input)
- From Number (e.g., +1234567890)
- To Number (e.g., +1234567890)

### **Manual Configuration**
Edit `/opt/uptime-monitor/.env` as root:
```bash
TWILIO_ACCOUNT_SID=your_account_sid
TWILIO_AUTH_TOKEN=your_auth_token
TWILIO_FROM_NUMBER=+1234567890
TWILIO_TO_NUMBER=+1234567890
```

Then restart the service:
```bash
systemctl restart uptime-monitor
```

## 📧 Configuring SendGrid (Email Alerts)

### **Using Configuration Script**
```bash
pct exec <container-id> -- /opt/uptime-monitor/configure-credentials.sh
```

Select "Yes" when prompted for SendGrid configuration, then provide:
- SendGrid API Key (masked input)
- From Email Address (must be verified in SendGrid)
- To Email Address (recipient for alerts)

### **Manual Configuration**
Edit `/opt/uptime-monitor/.env` as root:
```bash
SENDGRID_API_KEY=your_api_key
SENDGRID_FROM_EMAIL=alerts@yourdomain.com
SENDGRID_TO_EMAIL=admin@yourdomain.com
```

Then restart the service:
```bash
systemctl restart uptime-monitor
```

## 📤 Configuring FTP Upload

### **Using Configuration Script**
```bash
pct exec <container-id> -- /opt/uptime-monitor/configure-credentials.sh
```

Select "Yes" when prompted for FTP configuration, then provide:
- FTP Host
- FTP Username
- FTP Password (masked input)
- FTP Port (default: 21)
- Remote Path (default: index.html)

### **Manual Configuration**
Edit `/opt/uptime-monitor/.env` as root:
```bash
FTP_HOST=ftp.yourdomain.com
FTP_USER=your_username
FTP_PASSWORD=your_password
FTP_PORT=21
FTP_REMOTE_PATH=index.html
```

Then restart the service:
```bash
systemctl restart uptime-monitor
```

## 🔄 Updating Configuration

### **Re-run Configuration Script**
```bash
# Automatically backs up existing config
pct exec <container-id> -- /opt/uptime-monitor/configure-credentials.sh
```

### **Edit Manually**
```bash
# Enter container
pct enter <container-id>

# Edit .env file
nano /opt/uptime-monitor/.env

# Restart service
systemctl restart uptime-monitor
```

### **Via Web Interface**
- Navigate to `http://<container-ip>:3000`
- Click the relevant settings button
- Update credentials
- Click "Save" and "Test"

## 📁 File Locations

| File | Location | Permissions | Owner |
|------|----------|-------------|-------|
| Environment Variables | `/opt/uptime-monitor/.env` | `600` | `uptime-monitor` |
| Configuration JSON | `/opt/uptime-monitor/secure-data/config.json` | `600` | `uptime-monitor` |
| Configuration Script | `/opt/uptime-monitor/configure-credentials.sh` | `755` | `uptime-monitor` |
| Backup Files | `/opt/uptime-monitor/.env.backup-*` | `600` | `uptime-monitor` |

## 🔍 Viewing Configuration

### **View Environment Variables**
```bash
# As root only
cat /opt/uptime-monitor/.env
```

### **View Configuration JSON**
```bash
# As root only
cat /opt/uptime-monitor/secure-data/config.json
```

### **Check File Permissions**
```bash
ls -la /opt/uptime-monitor/.env
ls -la /opt/uptime-monitor/secure-data/
```

## 🗑️ Removing Configuration

### **Remove Specific Service**
Edit `/opt/uptime-monitor/.env` and remove the relevant lines, then restart:
```bash
systemctl restart uptime-monitor
```

### **Remove All Credentials**
```bash
# Backup first
cp /opt/uptime-monitor/.env /opt/uptime-monitor/.env.backup

# Remove .env file
rm /opt/uptime-monitor/.env

# Restart service
systemctl restart uptime-monitor
```

## 🚨 Security Best Practices

### **Do's**
✅ Use the configuration script for secure setup
✅ Keep `.env` file permissions at `600`
✅ Regularly rotate credentials
✅ Use strong, unique passwords
✅ Backup configuration before changes
✅ Test configuration after updates

### **Don'ts**
❌ Don't commit `.env` files to version control
❌ Don't share credentials in plain text
❌ Don't use weak passwords
❌ Don't store credentials in web-accessible directories
❌ Don't run the application as root

## 🔄 Backup & Restore

### **Backup Configuration**
```bash
# Using management script
pct exec <container-id> -- /opt/uptime-monitor/manage-uptime-monitor.sh backup

# Manual backup
pct exec <container-id> -- tar -czf /tmp/uptime-monitor-config-backup.tar.gz /opt/uptime-monitor/.env /opt/uptime-monitor/secure-data/
```

### **Restore Configuration**
```bash
# Extract backup
pct exec <container-id> -- tar -xzf /tmp/uptime-monitor-config-backup.tar.gz -C /

# Fix permissions
pct exec <container-id> -- chown -R uptime-monitor:uptime-monitor /opt/uptime-monitor/.env /opt/uptime-monitor/secure-data/
pct exec <container-id> -- chmod 600 /opt/uptime-monitor/.env

# Restart service
pct exec <container-id> -- systemctl restart uptime-monitor
```

## 📞 Support

If you encounter issues:

1. **Check file permissions:**
   ```bash
   ls -la /opt/uptime-monitor/.env
   ls -la /opt/uptime-monitor/secure-data/
   ```

2. **Check service logs:**
   ```bash
   journalctl -u uptime-monitor -n 50
   ```

3. **Test configuration:**
   - Use web interface test buttons
   - Check service logs for connection errors

4. **Verify credentials:**
   - Ensure API keys are valid
   - Check account permissions
   - Verify phone numbers format (+1234567890)
   - Confirm email addresses are verified

## 🎉 Next Steps

After configuring credentials:

1. **Test each service:**
   - Send test SMS
   - Send test email
   - Test FTP upload

2. **Monitor logs:**
   ```bash
   journalctl -u uptime-monitor -f
   ```

3. **Add servers to monitor:**
   - Access web interface
   - Add your first server
   - Verify alerts are working

Your credentials are now securely configured! 🔒
