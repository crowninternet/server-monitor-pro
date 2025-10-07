# Update Uptime Monitor on Proxmox

## Quick Update (3 Commands)

Run these commands **on your Proxmox host** (not in the container):

```bash
wget https://raw.githubusercontent.com/crowninternet/server-monitor-pro/master/proxmox/update-from-git.sh
chmod +x update-from-git.sh
./update-from-git.sh
```

That's it! The script will:
- ✅ Auto-detect your uptime monitor container
- ✅ Create a backup of current files
- ✅ Pull latest changes from git
- ✅ Restart the service
- ✅ Show monitoring status

## What This Update Does

Adds **server-side monitoring** so checks run 24/7 in the backend:
- Monitors run automatically without needing a browser open
- Sends SMS/email alerts when servers go down (if configured)
- Sends recovery notifications when servers come back up
- Updates FTP public page when status changes

## After Update

Check the logs to see monitoring in action:

```bash
# Replace 100 with your container ID
pct exec 100 -- journalctl -u uptime-monitor -f
```

You should see:
```
🔍 INITIALIZING SERVER-SIDE MONITORING
✅ Server-side monitoring is now active!
✅ Checks will run automatically even when browser is closed
🔍 Checking server: Website (https)
✅ Check complete for Website: up (234ms)
```

## Test It

1. Close your browser completely
2. Wait 5 minutes
3. Run: `pct exec 100 -- journalctl -u uptime-monitor --since "10 minutes ago" | grep "Check complete"`

You'll see checks that ran while browser was closed! 🎉

## Manual Update (If Preferred)

If you prefer to do it manually:

```bash
# Find your container
pct list | grep uptime

# Enter the container (replace 100 with your container ID)
pct enter 100

# Inside container:
cd /opt/uptime-monitor
cp uptime-monitor-api.js uptime-monitor-api.js.backup-$(date +%Y%m%d-%H%M%S)
git pull origin master
systemctl restart uptime-monitor
journalctl -u uptime-monitor -f

# Exit container
exit
```

## Need Help?

- Full documentation: See `../PROXMOX-HOST-UPDATE.md`
- Technical details: See `../SERVER-SIDE-MONITORING-UPDATE.md`
- Git guide: See `../GIT-UPDATE-GUIDE.md`

