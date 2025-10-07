# Update Uptime Monitor on Proxmox (Direct)

## Update Directly on Proxmox Host

### Step 1: SSH to Your Proxmox Host
```bash
ssh root@YOUR_PROXMOX_IP
```

### Step 2: Download the Updated File
```bash
cd /opt/uptime-monitor

# Backup the current file
sudo cp uptime-monitor-api.js uptime-monitor-api.js.backup-$(date +%Y%m%d-%H%M%S)

# Download the updated file from GitHub or your source
# Option A: If you have the file available via URL
# wget -O uptime-monitor-api.js https://your-url/uptime-monitor-api.js

# Option B: Manual copy - see below
```

### Step 3: Replace the File Manually

Since you need to copy the updated `uptime-monitor-api.js` file to Proxmox:

**From your Mac (in a new terminal):**
```bash
scp /Users/jmahon/Documents/uptime-monitor/uptime-monitor-api.js root@YOUR_PROXMOX_IP:/tmp/
```

**Then on Proxmox:**
```bash
cd /opt/uptime-monitor
sudo mv /tmp/uptime-monitor-api.js /opt/uptime-monitor/uptime-monitor-api.js
sudo chown uptime-monitor:uptime-monitor uptime-monitor-api.js
sudo chmod 644 uptime-monitor-api.js
```

### Step 4: Restart the Service
```bash
sudo systemctl restart uptime-monitor
```

### Step 5: Verify It's Working
```bash
# Check service status
sudo systemctl status uptime-monitor

# Watch the logs in real-time (Ctrl+C to exit)
sudo journalctl -u uptime-monitor -f
```

You should see messages like:
```
🔍 INITIALIZING SERVER-SIDE MONITORING
▶️  Starting monitoring for YourServer (interval: 60s)
✅ Server-side monitoring is now active!
✅ Checks will run automatically even when browser is closed
```

### Step 6: Test the Monitoring Status
```bash
# Check if monitoring is active
curl http://localhost:3000/api/monitoring/status

# Check API health
curl http://localhost:3000/api/health
```

## Quick Command Sequence

If you're comfortable with terminal, here's the quick version:

**From your Mac:**
```bash
scp /Users/jmahon/Documents/uptime-monitor/uptime-monitor-api.js root@YOUR_PROXMOX_IP:/tmp/
```

**On Proxmox (via SSH):**
```bash
cd /opt/uptime-monitor
sudo cp uptime-monitor-api.js uptime-monitor-api.js.backup-$(date +%Y%m%d-%H%M%S)
sudo mv /tmp/uptime-monitor-api.js ./uptime-monitor-api.js
sudo chown uptime-monitor:uptime-monitor uptime-monitor-api.js
sudo chmod 644 uptime-monitor-api.js
sudo systemctl restart uptime-monitor
sudo journalctl -u uptime-monitor -f
```

Press `Ctrl+C` to stop watching logs.

## Verification

### Check Recent Logs
```bash
sudo journalctl -u uptime-monitor -n 50 | grep -i monitoring
```

### Check Monitoring Status via API
```bash
curl -s http://localhost:3000/api/monitoring/status | python3 -m json.tool
```

Expected output:
```json
{
  "success": true,
  "enabled": true,
  "activeMonitors": 3,
  "totalServers": 3,
  "monitoredServerIds": ["xxx", "yyy", "zzz"]
}
```

### Test by Closing Browser
1. Note the current time
2. Close your browser
3. Wait 2-3 minutes
4. SSH to Proxmox and check logs:
```bash
sudo journalctl -u uptime-monitor --since "5 minutes ago" | grep "Check complete"
```

You should see check activities that happened while your browser was closed!

## Rollback (If Needed)

If something goes wrong:
```bash
cd /opt/uptime-monitor
sudo systemctl stop uptime-monitor
sudo cp uptime-monitor-api.js.backup-YYYYMMDD-HHMMSS uptime-monitor-api.js
sudo systemctl start uptime-monitor
```

Replace `YYYYMMDD-HHMMSS` with your backup file's timestamp.

## Troubleshooting

### Service Won't Start
```bash
# Check for errors
sudo journalctl -u uptime-monitor -n 100 --no-pager

# Check file permissions
ls -la /opt/uptime-monitor/uptime-monitor-api.js

# Should show: -rw-r--r-- 1 uptime-monitor uptime-monitor
```

### No Monitoring Activity
```bash
# Restart the service
sudo systemctl restart uptime-monitor

# Watch for monitoring startup messages
sudo journalctl -u uptime-monitor -f
```

### Check Specific Server Monitoring
```bash
# Get list of servers
curl -s http://localhost:3000/api/servers | python3 -m json.tool

# Check which servers are being monitored
curl -s http://localhost:3000/api/monitoring/status | python3 -m json.tool
```

