#!/bin/bash

# Quick fix script to complete the installation
# Run from Proxmox host: bash fix-installation.sh <container-id>

set -e

CTID=$1

if [ -z "$CTID" ]; then
    echo "Usage: bash fix-installation.sh <container-id>"
    exit 1
fi

echo "Fixing installation for container $CTID..."

# Create systemd service
echo "Creating systemd service..."
pct exec $CTID -- bash -c 'cat > /etc/systemd/system/uptime-monitor.service << "EOF"
[Unit]
Description=Uptime Monitor Pro
Documentation=https://github.com/crowninternet/server-monitor-pro
After=network.target

[Service]
Type=simple
User=uptime-monitor
Group=uptime-monitor
WorkingDirectory=/opt/uptime-monitor
ExecStart=/usr/bin/node /opt/uptime-monitor/uptime-monitor-api.js
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

# Container-specific optimizations
MemoryMax=512M
CPUQuota=50%
LimitNOFILE=4096
LimitNPROC=2048

# Security settings
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/opt/uptime-monitor
ProtectKernelTunables=true
ProtectKernelModules=true
ProtectControlGroups=true

# Environment variables
Environment=NODE_ENV=production
Environment=PORT=3000

[Install]
WantedBy=multi-user.target
EOF'

# Create configuration script
echo "Creating configuration script..."
pct exec $CTID -- bash -c "curl -fsSL https://raw.githubusercontent.com/crowninternet/server-monitor-pro/master/proxmox/configure-credentials.sh -o /opt/uptime-monitor/configure-credentials.sh"
pct exec $CTID -- bash -c "chmod +x /opt/uptime-monitor/configure-credentials.sh && chown uptime-monitor:uptime-monitor /opt/uptime-monitor/configure-credentials.sh"

# Reload systemd and enable service
echo "Enabling and starting service..."
pct exec $CTID -- bash -c "systemctl daemon-reload && systemctl enable uptime-monitor && systemctl start uptime-monitor"

# Wait a moment
sleep 3

# Check status
echo ""
echo "Service status:"
pct exec $CTID -- systemctl status uptime-monitor --no-pager

echo ""
echo "Installation fixed!"
echo ""
echo "Access the dashboard at: http://$(pct exec $CTID -- hostname -I | awk '{print $1}'):3000"

