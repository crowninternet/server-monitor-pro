# Quick Start: Deploy Server-Side Monitoring

## What Changed?
Your uptime monitor now has **server-side monitoring** that runs 24/7, even when the browser is closed.

## Deploy in 3 Steps

### Step 1: Deploy to Your Proxmox Server
```bash
cd /Users/jmahon/Documents/uptime-monitor
./deploy-to-proxmox.sh root@YOUR_PROXMOX_IP
```

Replace `YOUR_PROXMOX_IP` with your actual Proxmox IP address (e.g., `192.168.1.100`).

### Step 2: Verify It's Working
```bash
./verify-monitoring.sh root@YOUR_PROXMOX_IP
```

You should see:
- ✅ Service is running
- ✅ API is responding  
- ✅ Monitoring API is responding
- Recent monitoring activity logs

### Step 3: Test It
1. Close all browser windows
2. Wait 2-3 minutes
3. Open http://YOUR_PROXMOX_IP:3000
4. Check that "Last Check" times are recent (checks ran while browser was closed!)

## That's It!

Your monitoring is now running 24/7 on the server. No browser needed!

## View Live Logs (Optional)
```bash
ssh root@YOUR_PROXMOX_IP
sudo journalctl -u uptime-monitor -f
```

Press `Ctrl+C` to stop viewing logs.

## What You'll See in Logs

When monitoring starts:
```
🔍 INITIALIZING SERVER-SIDE MONITORING
▶️  Starting monitoring for Website (interval: 60s)
✅ Server-side monitoring is now active!
```

During checks:
```
🔍 Checking server: Website (https)
✅ Check complete for Website: up (156ms)
```

When a server goes down:
```
🚨 Server Website is DOWN! Sending alerts...
✅ SMS alert sent for Website
✅ Email alert sent for Website
```

## Troubleshooting

### Deploy script fails?
Make sure you can SSH to your Proxmox server:
```bash
ssh root@YOUR_PROXMOX_IP
```

If that doesn't work, fix your SSH connection first.

### Service not starting?
Check the logs:
```bash
ssh root@YOUR_PROXMOX_IP 'sudo journalctl -u uptime-monitor -n 50'
```

### No monitoring activity in logs?
Restart the service:
```bash
ssh root@YOUR_PROXMOX_IP 'sudo systemctl restart uptime-monitor'
```

## Need Help?

Read the detailed guide:
```bash
cat SERVER-SIDE-MONITORING-UPDATE.md
```

