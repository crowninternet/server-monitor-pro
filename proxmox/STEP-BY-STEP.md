# Step-by-Step Update Guide

## WHERE TO RUN THIS

✅ **Run on:** Proxmox HOST shell (SSH to your Proxmox server)  
❌ **NOT on:** Inside the LXC container  
❌ **NOT on:** Your local Mac/Windows computer  

---

## Step 1: SSH to Your Proxmox Host

From your computer (Mac/Windows/Linux):

```bash
ssh root@YOUR_PROXMOX_IP
```

Example:
```bash
ssh root@192.168.1.100
```

You should see a prompt like:
```
root@pve:~#
```

This means you're on the **Proxmox host**. ✅

---

## Step 2: Download the Update Script

**ON THE PROXMOX HOST**, run:

```bash
wget https://raw.githubusercontent.com/crowninternet/server-monitor-pro/master/proxmox/update-from-git.sh
```

---

## Step 3: Make it Executable

**ON THE PROXMOX HOST**, run:

```bash
chmod +x update-from-git.sh
```

---

## Step 4: Run the Script

**ON THE PROXMOX HOST**, run:

```bash
./update-from-git.sh
```

The script will:
- Find your uptime monitor container automatically
- Ask for confirmation: `Update container XXX? (y/N):`
- Type `y` and press Enter
- Update the container and show results

---

## What You'll See

```
========================================
  Uptime Monitor Pro - Git Update
  ⚠️  RUN FROM PROXMOX HOST (NOT CONTAINER)
========================================

ℹ️  Looking for Uptime Monitor container...
✅ Found container: 100

Update container 100? (y/N): y

✅ Container is running

Step 1/5: Creating backup...
✅ Backup created

Step 2/5: Pulling latest changes from git...
✅ Git pull successful

Step 3/5: Restarting service...
✅ Service restarted

Step 4/5: Checking service status...
✅ Service is running

Step 5/5: Checking monitoring engine...

Recent logs:
----------------------------------------
🔍 INITIALIZING SERVER-SIDE MONITORING
✅ Server-side monitoring is now active!
✅ Checks will run automatically even when browser is closed
🔍 Checking server: Website (https)
✅ Check complete for Website: up (234ms)
----------------------------------------

✅ Update completed successfully!
```

---

## How the Script Works

The script runs **FROM** the Proxmox host but manages the **container**:

1. **Detects** which LXC container has uptime monitor
2. **Uses `pct exec`** to run commands inside that container
3. **Never requires** you to enter the container manually
4. **Automates** the entire update process

---

## Quick Reference

### Where am I?

Check your prompt:
- `root@pve:~#` = Proxmox host ✅ (correct)
- `root@uptime-monitor:~#` = Inside container ❌ (wrong)

### How to verify container?

From Proxmox host:
```bash
pct list
```

Shows all containers.

---

## Troubleshooting

### "pct: command not found"
❌ You're not on the Proxmox host. SSH to your Proxmox server first.

### Script can't find container
Run on Proxmox host:
```bash
pct list | grep -i uptime
```

If no results, find your container ID manually:
```bash
pct list
```

Then run:
```bash
./update-from-git.sh CONTAINER_ID
```

Example:
```bash
./update-from-git.sh 100
```

---

## Summary

1. SSH to Proxmox: `ssh root@YOUR_PROXMOX_IP`
2. Download script: `wget https://raw.githubusercontent.com/crowninternet/server-monitor-pro/master/proxmox/update-from-git.sh`
3. Make executable: `chmod +x update-from-git.sh`
4. Run it: `./update-from-git.sh`
5. Type `y` when prompted
6. Done! ✅

---

**DO NOT** enter the container (`pct enter`). The script handles everything from the Proxmox host.

