#!/bin/bash

# Find All Data Script for Container 104
# Run from Proxmox HOST
# Searches entire container for old data files

CONTAINER_ID=104

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }

echo "========================================"
echo "  Find All Data in Container 104"
echo "========================================"
echo ""

print_info "Searching entire container for JSON files..."
echo ""

# Find all servers.json files
print_info "Looking for servers.json files:"
echo "----------------------------------------"
pct exec $CONTAINER_ID -- find / -name "servers.json" -type f 2>/dev/null | while read file; do
    echo "📄 Found: $file"
    SIZE=$(pct exec $CONTAINER_ID -- stat -f%z "$file" 2>/dev/null || pct exec $CONTAINER_ID -- stat -c%s "$file" 2>/dev/null)
    echo "   Size: $SIZE bytes"
    if [ "$SIZE" -gt 10 ]; then
        echo "   Content preview:"
        pct exec $CONTAINER_ID -- head -50 "$file" | sed 's/^/   /'
    fi
    echo ""
done
echo "----------------------------------------"
echo ""

# Find all config.json files
print_info "Looking for config.json files:"
echo "----------------------------------------"
pct exec $CONTAINER_ID -- find / -name "config.json" -type f 2>/dev/null | while read file; do
    echo "📄 Found: $file"
    SIZE=$(pct exec $CONTAINER_ID -- stat -f%z "$file" 2>/dev/null || pct exec $CONTAINER_ID -- stat -c%s "$file" 2>/dev/null)
    echo "   Size: $SIZE bytes"
    if [ "$SIZE" -gt 10 ]; then
        echo "   Content preview:"
        pct exec $CONTAINER_ID -- head -50 "$file" | sed 's/^/   /'
    fi
    echo ""
done
echo "----------------------------------------"
echo ""

# Check current data directory
print_info "Current data directory contents:"
echo "----------------------------------------"
pct exec $CONTAINER_ID -- ls -lah /opt/uptime-monitor/data/ 2>/dev/null || echo "Directory doesn't exist or is empty"
echo ""
if pct exec $CONTAINER_ID -- test -f /opt/uptime-monitor/data/servers.json; then
    echo "Current servers.json:"
    pct exec $CONTAINER_ID -- cat /opt/uptime-monitor/data/servers.json
fi
echo ""
if pct exec $CONTAINER_ID -- test -f /opt/uptime-monitor/data/config.json; then
    echo "Current config.json:"
    pct exec $CONTAINER_ID -- cat /opt/uptime-monitor/data/config.json
fi
echo "----------------------------------------"
echo ""

# Check for backup files
print_info "Looking for backup files:"
echo "----------------------------------------"
pct exec $CONTAINER_ID -- find /opt/uptime-monitor -name "*.backup*" -type f 2>/dev/null | while read file; do
    echo "💾 Found backup: $file"
    SIZE=$(pct exec $CONTAINER_ID -- stat -f%z "$file" 2>/dev/null || pct exec $CONTAINER_ID -- stat -c%s "$file" 2>/dev/null)
    echo "   Size: $SIZE bytes"
    echo ""
done
echo "----------------------------------------"
echo ""

print_info "Search complete!"
echo ""
print_info "To manually restore data:"
echo "  1. Pick the correct file path from above"
echo "  2. Use the manual-restore-data-104.sh script (coming next)"
echo ""

