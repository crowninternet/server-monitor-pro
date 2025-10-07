# Update from Proxmox Host Shell

## Update Instructions (Run from Proxmox Host)

If your uptime monitor is running in an LXC container, use these commands from your **Proxmox host shell**:

### Step 1: Find Your Container ID

```bash
pct list | grep uptime
```

This will show your container ID. Let's say it's `100` (replace with your actual ID).

### Step 2: Enter the Container and Update

```bash
# Enter the container (replace 100 with your container ID)
pct enter 100

# Now you're inside the container - run the update commands:
cd /opt/uptime-monitor

# Backup current file
cp uptime-monitor-api.js uptime-monitor-api.js.backup-$(date +%Y%m%d-%H%M%S)

# Pull latest changes from git
sudo -u uptime-monitor git pull origin master

# Restart the service
systemctl restart uptime-monitor

# Watch the logs (Ctrl+C to exit)
journalctl -u uptime-monitor -f
```

### Step 3: Exit the Container

Press `Ctrl+C` to stop watching logs, then:
```bash
exit
```

You're now back on the Proxmox host.

## Alternative: One-Line Command from Host

You can also run commands in the container without entering it:

```bash
# Replace 100 with your container ID
pct exec 100 -- bash -c "cd /opt/uptime-monitor && cp uptime-monitor-api.js uptime-monitor-api.js.backup-\$(date +%Y%m%d-%H%M%S) && sudo -u uptime-monitor git pull origin master && systemctl restart uptime-monitor"

# Check the logs
pct exec 100 -- journalctl -u uptime-monitor -n 30
```

## Verify It's Working

### From Proxmox host, check container logs:
```bash
pct exec 100 -- journalctl -u uptime-monitor -n 30 | grep -i monitoring
```

### From Proxmox host, check monitoring status:
```bash
pct exec 100 -- curl -s http://localhost:3000/api/monitoring/status
```

### From Proxmox host, watch live logs:
```bash
pct exec 100 -- journalctl -u uptime-monitor -f
```

## What You Should See

After the update, you should see logs like:

```
======================================
🔍 INITIALIZING SERVER-SIDE MONITORING
======================================
▶️  Starting monitoring for Website (interval: 60s)
✅ Server-side monitoring is now active!
✅ Checks will run automatically even when browser is closed

🔍 Checking server: Website (https)
✅ Check complete for Website: up (234ms)
```

## Full Update Script from Proxmox Host

Save this as a script on your Proxmox host:

```bash
#!/bin/bash
# update-uptime-monitor.sh
# Run this from Proxmox host shell

CONTAINER_ID="100"  # Change this to your container ID

echo "Updating Uptime Monitor in container $CONTAINER_ID..."

# Enter container and update
pct exec $CONTAINER_ID -- bash -c '
    cd /opt/uptime-monitor
    echo "Creating backup..."
    cp uptime-monitor-api.js uptime-monitor-api.js.backup-$(date +%Y%m%d-%H%M%S)
    
    echo "Pulling latest changes..."
    sudo -u uptime-monitor git pull origin master
    
    echo "Restarting service..."
    systemctl restart uptime-monitor
    
    echo "Waiting for service to start..."
    sleep 3
    
    echo ""
    echo "Service status:"
    systemctl is-active uptime-monitor && echo "✅ Service is running" || echo "❌ Service failed"
    
    echo ""
    echo "Recent logs:"
    journalctl -u uptime-monitor -n 20 | grep -i "monitoring\|check complete"
    
    echo ""
    echo "Monitoring status:"
    curl -s http://localhost:3000/api/monitoring/status | python3 -m json.tool
'

echo ""
echo "Update complete!"
```

Make it executable and run:
```bash
chmod +x update-uptime-monitor.sh
./update-uptime-monitor.sh
```

## Quick Reference

### Find container ID:
```bash
pct list
```

### Enter container:
```bash
pct enter CONTAINER_ID
```

### Run command in container without entering:
```bash
pct exec CONTAINER_ID -- COMMAND
```

### Check container status:
```bash
pct status CONTAINER_ID
```

### View container logs:
```bash
pct exec CONTAINER_ID -- journalctl -u uptime-monitor -f
```

## Test the Update

From Proxmox host:

```bash
# Check monitoring is active
pct exec 100 -- curl -s http://localhost:3000/api/monitoring/status

# View recent checks
pct exec 100 -- journalctl -u uptime-monitor --since "5 minutes ago" | grep "Check complete"
```

You should see monitoring activity even if no browser is connected!

## Troubleshooting

### Can't find container:
```bash
pct list
```

### Container not running:
```bash
pct start CONTAINER_ID
```

### Service not starting:
```bash
pct exec CONTAINER_ID -- systemctl status uptime-monitor
pct exec CONTAINER_ID -- journalctl -u uptime-monitor -n 50
```

### Rollback if needed:
```bash
pct exec CONTAINER_ID -- bash -c "cd /opt/uptime-monitor && systemctl stop uptime-monitor && cp uptime-monitor-api.js.backup-TIMESTAMP uptime-monitor-api.js && systemctl start uptime-monitor"
```

