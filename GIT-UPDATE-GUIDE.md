# Update via Git on Proxmox

## Quick Update Instructions

SSH to your Proxmox host and run these commands:

```bash
# SSH to Proxmox
ssh root@YOUR_PROXMOX_IP

# Navigate to installation directory
cd /opt/uptime-monitor

# Backup current file (just in case)
sudo cp uptime-monitor-api.js uptime-monitor-api.js.backup-$(date +%Y%m%d-%H%M%S)

# Pull latest changes from git
sudo -u uptime-monitor git pull origin master

# Restart the service
sudo systemctl restart uptime-monitor

# Watch the logs to see monitoring start
sudo journalctl -u uptime-monitor -f
```

Press `Ctrl+C` to stop watching logs.

## What You Should See

After restarting, you should see in the logs:

```
======================================
🔍 INITIALIZING SERVER-SIDE MONITORING
======================================
▶️  Starting monitoring for Website (interval: 60s)
▶️  Starting monitoring for API Server (interval: 120s)
✅ Server-side monitoring is now active!
✅ Checks will run automatically even when browser is closed

🔍 Checking server: Website (https)
✅ Check complete for Website: up (156ms)
```

## Verify It's Working

### Check monitoring status:
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
  "monitoredServerIds": ["1234567890", "1234567891", "1234567892"]
}
```

### Check recent monitoring activity:
```bash
sudo journalctl -u uptime-monitor --since "5 minutes ago" | grep -i "check complete"
```

### View live logs:
```bash
sudo journalctl -u uptime-monitor -f
```

## Test It

1. **Close all browser windows** (don't view the monitor interface)
2. **Wait 3-5 minutes**
3. **On Proxmox**, check that monitoring continued:
```bash
sudo journalctl -u uptime-monitor --since "10 minutes ago" | grep "Check complete"
```

You should see checks that happened while your browser was closed! 🎉

## If Git Pull Fails

If you get an error about local changes, reset to the remote version:

```bash
cd /opt/uptime-monitor
sudo -u uptime-monitor git fetch origin
sudo -u uptime-monitor git reset --hard origin/master
sudo systemctl restart uptime-monitor
```

## Rollback If Needed

If something goes wrong:

```bash
cd /opt/uptime-monitor
sudo systemctl stop uptime-monitor
sudo cp uptime-monitor-api.js.backup-YYYYMMDD-HHMMSS uptime-monitor-api.js
sudo systemctl start uptime-monitor
```

Replace `YYYYMMDD-HHMMSS` with your backup timestamp.

## Quick Command Summary

```bash
# Update from git
cd /opt/uptime-monitor && sudo -u uptime-monitor git pull origin master && sudo systemctl restart uptime-monitor

# Watch logs
sudo journalctl -u uptime-monitor -f

# Check status
curl http://localhost:3000/api/monitoring/status

# View recent checks
sudo journalctl -u uptime-monitor --since "5 minutes ago" | grep "Check complete"
```

## What Changed

✅ **Server-side monitoring** - Checks now run in the Node.js backend 24/7  
✅ **No browser needed** - Monitoring continues even when browser is closed  
✅ **Automatic alerts** - SMS/email when servers go down (if configured)  
✅ **Recovery notifications** - Alerts when servers come back up  
✅ **FTP auto-upload** - Public page updates when status changes  

## Need More Info?

See the detailed documentation:
- `SERVER-SIDE-MONITORING-UPDATE.md` - Full feature documentation
- `UPDATE-ON-PROXMOX.md` - Detailed update instructions

## Support

If you encounter issues:
1. Check the logs: `sudo journalctl -u uptime-monitor -n 100`
2. Check service status: `sudo systemctl status uptime-monitor`
3. Test API: `curl http://localhost:3000/api/health`

