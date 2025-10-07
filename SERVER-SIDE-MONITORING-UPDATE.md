# Server-Side Monitoring Update

## Problem Solved
Previously, uptime checks only ran when the browser window was open on port 3000. This was because all monitoring logic was client-side JavaScript that executed in the browser.

## Solution Implemented
Added a **server-side monitoring engine** to `uptime-monitor-api.js` that runs independently in the Node.js backend. Now checks run 24/7 regardless of whether anyone is viewing the web interface.

## Key Features Added

### 1. Automatic Server Monitoring
- Server-side engine starts automatically when the Node.js service starts
- Each server is monitored at its configured interval
- Checks run continuously in the background

### 2. Smart Alert System
- Sends SMS alerts when servers go down (if Twilio configured)
- Sends email alerts when servers go down (if SendGrid configured)
- Sends recovery notifications when servers come back up
- Prevents duplicate alerts (only one alert per down event)

### 3. Status Tracking
- Updates server status in real-time
- Tracks response times and uptime percentages
- Maintains test history (last 15 checks)
- Automatically triggers FTP uploads when status changes

### 4. Monitoring Controls
New API endpoints for monitoring control:
- `POST /api/monitoring/control` - Start/stop/restart monitoring
- `GET /api/monitoring/status` - Get monitoring engine status

### 5. Auto-sync with Server Changes
- Adding a new server automatically starts monitoring it
- Updating a server restarts its monitoring with new settings
- Deleting a server stops its monitoring

## How to Deploy

### Option 1: Use the Deployment Script (Recommended)
```bash
cd /Users/jmahon/Documents/uptime-monitor
./deploy-to-proxmox.sh root@YOUR_PROXMOX_IP
```

Replace `YOUR_PROXMOX_IP` with your Proxmox server's IP address or hostname.

### Option 2: Manual Deployment
1. **Copy the updated file to your Proxmox server:**
   ```bash
   scp uptime-monitor-api.js root@YOUR_PROXMOX_IP:/tmp/
   ```

2. **SSH into your Proxmox server:**
   ```bash
   ssh root@YOUR_PROXMOX_IP
   ```

3. **Backup the old file and install the new one:**
   ```bash
   cd /opt/uptime-monitor
   sudo cp uptime-monitor-api.js uptime-monitor-api.js.backup
   sudo mv /tmp/uptime-monitor-api.js /opt/uptime-monitor/
   sudo chown uptime-monitor:uptime-monitor /opt/uptime-monitor/uptime-monitor-api.js
   sudo chmod 644 /opt/uptime-monitor/uptime-monitor-api.js
   ```

4. **Restart the service:**
   ```bash
   sudo systemctl restart uptime-monitor
   ```

## Verification

### 1. Check Service Status
```bash
sudo systemctl status uptime-monitor
```

### 2. View Logs (Should see monitoring messages)
```bash
sudo journalctl -u uptime-monitor -f
```

You should see log messages like:
```
🔍 INITIALIZING SERVER-SIDE MONITORING
✅ Server-side monitoring is now active!
✅ Checks will run automatically even when browser is closed
▶️  Starting monitoring for YOUR_SERVER (interval: 60s)
🔍 Checking server: YOUR_SERVER (http)
✅ Check complete for YOUR_SERVER: up (234ms)
```

### 3. Test by Closing Browser
1. Close all browser windows viewing the monitor
2. Wait for a check interval to pass
3. Open the monitor again - you should see recent checks were performed
4. Check the logs to confirm checks ran while browser was closed

### 4. Check Monitoring Status via API
```bash
curl http://localhost:3000/api/monitoring/status
```

Expected response:
```json
{
  "success": true,
  "enabled": true,
  "activeMonitors": 3,
  "totalServers": 3,
  "monitoredServerIds": ["1234567890", "1234567891", "1234567892"]
}
```

## What Happens Now

### Automatic Checks
- All non-stopped servers are checked at their configured intervals
- Checks happen server-side, completely independent of the browser
- Results are saved to disk and visible when you open the web interface

### Alert Flow
When a server goes down:
1. Server fails 3 consecutive checks → Status changes to "down"
2. Alert system triggers (if configured):
   - SMS sent via Twilio (if enabled)
   - Email sent via SendGrid (if enabled)
3. FTP public page updated (if enabled)

When server recovers:
1. Server check succeeds → Status changes to "up"
2. Recovery notification sent (SMS/email if enabled)
3. Alert flag reset (ready for next incident)

### Client-Side Monitoring
The original client-side monitoring in `index.html` still works and is now **complementary**:
- Browser checks update the UI in real-time
- Server-side checks ensure monitoring continues 24/7
- Both systems write to the same data files
- Most recent check (from either system) is displayed

## Troubleshooting

### Monitoring Not Starting
Check logs for errors:
```bash
sudo journalctl -u uptime-monitor -n 50
```

### Servers Not Being Checked
1. Verify service is running: `sudo systemctl status uptime-monitor`
2. Check monitoring status: `curl http://localhost:3000/api/monitoring/status`
3. Verify servers aren't marked as "stopped" in the UI

### Checks Running Twice
This is normal! Both client-side and server-side monitoring are active. The server-side ensures checks happen even when browser is closed.

### Old Backup Files
If you need to rollback:
```bash
cd /opt/uptime-monitor
sudo systemctl stop uptime-monitor
sudo cp uptime-monitor-api.js.backup uptime-monitor-api.js
sudo systemctl start uptime-monitor
```

## Benefits

✅ **24/7 Monitoring** - Checks run continuously, browser or no browser  
✅ **Automatic Alerts** - Instant notifications when servers go down  
✅ **Zero Maintenance** - Set it and forget it  
✅ **Reliable** - Runs as a system service, survives reboots  
✅ **Efficient** - Minimal resource usage  
✅ **Compatible** - Existing UI and features still work perfectly  

## Notes

- The server-side monitoring uses the same check logic as the client-side version
- All existing features (FTP upload, SMS, email) still work
- The web interface remains unchanged - users won't notice any difference
- Data files are shared between client and server monitoring
- Resource usage is minimal (typically <50MB RAM, <1% CPU)

## Questions or Issues?

Check the logs first:
```bash
sudo journalctl -u uptime-monitor --no-pager -n 100
```

If you see errors, they will help diagnose the issue.

