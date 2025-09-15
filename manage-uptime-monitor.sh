#!/bin/bash

# Uptime Monitor Management Script
# Usage: ./manage-uptime-monitor.sh {start|stop|restart|status|logs|uninstall}

INSTALL_DIR="$HOME/Documents/uptime-monitor"
SERVICE_NAME="com.uptimemonitor"
LAUNCH_AGENT_PATH="$HOME/Library/LaunchAgents/${SERVICE_NAME}.plist"

case "$1" in
    start)
        echo "Starting Uptime Monitor..."
        launchctl load "$LAUNCH_AGENT_PATH"
        echo "✅ Uptime Monitor started!"
        echo "🌐 Access the web interface at: http://localhost:3000"
        ;;
    stop)
        echo "Stopping Uptime Monitor..."
        launchctl unload "$LAUNCH_AGENT_PATH"
        echo "✅ Uptime Monitor stopped!"
        ;;
    restart)
        echo "Restarting Uptime Monitor..."
        launchctl unload "$LAUNCH_AGENT_PATH" 2>/dev/null || true
        sleep 2
        launchctl load "$LAUNCH_AGENT_PATH"
        echo "✅ Uptime Monitor restarted!"
        echo "🌐 Access the web interface at: http://localhost:3000"
        ;;
    status)
        echo "Checking Uptime Monitor status..."
        if launchctl list | grep -q "$SERVICE_NAME"; then
            echo "✅ Uptime Monitor is running"
            if curl -s http://localhost:3000/api/health > /dev/null 2>&1; then
                echo "✅ API is responding at http://localhost:3000"
            else
                echo "❌ API not responding"
            fi
        else
            echo "❌ Uptime Monitor is not running"
        fi
        ;;
    logs)
        echo "Recent logs:"
        if [ -f "$INSTALL_DIR/uptime-monitor.log" ]; then
            tail -n 20 "$INSTALL_DIR/uptime-monitor.log"
        else
            echo "No logs found"
        fi
        ;;
    uninstall)
        echo "Uninstalling Uptime Monitor..."
        echo "This will stop the service and remove all files."
        read -p "Are you sure? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            launchctl unload "$LAUNCH_AGENT_PATH" 2>/dev/null || true
            rm -f "$LAUNCH_AGENT_PATH"
            rm -rf "$INSTALL_DIR"
            echo "✅ Uptime Monitor uninstalled successfully"
        else
            echo "Uninstall cancelled"
        fi
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status|logs|uninstall}"
        echo ""
        echo "Commands:"
        echo "  start     - Start the Uptime Monitor service"
        echo "  stop      - Stop the Uptime Monitor service"
        echo "  restart   - Restart the Uptime Monitor service"
        echo "  status    - Check if the service is running"
        echo "  logs      - Show recent log entries"
        echo "  uninstall - Remove Uptime Monitor completely"
        exit 1
        ;;
esac
