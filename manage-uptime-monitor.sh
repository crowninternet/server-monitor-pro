#!/bin/bash

# Uptime Monitor Management Script

case "$1" in
    start)
        echo "Starting Uptime Monitor..."
        launchctl load ~/Library/LaunchAgents/com.uptimemonitor.plist
        echo "✅ Uptime Monitor started!"
        ;;
    stop)
        echo "Stopping Uptime Monitor..."
        launchctl unload ~/Library/LaunchAgents/com.uptimemonitor.plist
        echo "✅ Uptime Monitor stopped!"
        ;;
    restart)
        echo "Restarting Uptime Monitor..."
        launchctl unload ~/Library/LaunchAgents/com.uptimemonitor.plist
        sleep 2
        launchctl load ~/Library/LaunchAgents/com.uptimemonitor.plist
        echo "✅ Uptime Monitor restarted!"
        ;;
    status)
        echo "Checking Uptime Monitor status..."
        if launchctl list | grep -q "com.uptimemonitor"; then
            echo "✅ Uptime Monitor is running"
            curl -s http://localhost:3000/api/servers > /dev/null && echo "✅ API is responding" || echo "❌ API not responding"
        else
            echo "❌ Uptime Monitor is not running"
        fi
        ;;
    logs)
        echo "Recent logs:"
        tail -n 20 /Users/jmahon/Documents/uptime-monitor/uptime-monitor.log 2>/dev/null || echo "No logs found"
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status|logs}"
        echo ""
        echo "Commands:"
        echo "  start   - Start the Uptime Monitor service"
        echo "  stop    - Stop the Uptime Monitor service"
        echo "  restart - Restart the Uptime Monitor service"
        echo "  status  - Check if the service is running"
        echo "  logs    - Show recent log entries"
        exit 1
        ;;
esac
