# Uptime Monitor Pro

A modern, secure uptime monitoring application similar to Uptime Kuma, built with HTML, CSS, JavaScript, and Node.js.

## Features

- **Multi-protocol monitoring**: HTTPS, HTTP, Ping, DNS, TCP
- **SMS alerts**: Twilio integration for downtime notifications
- **Real-time status**: Live monitoring with countdown timers
- **Visual charts**: Status history with green/red/yellow indicators
- **Secure storage**: Credentials stored server-side outside web root
- **Modern UI**: Responsive design with glassmorphism effects
- **Auto-start**: macOS launchd integration for automatic startup

## Security Features

- Twilio credentials stored securely in `../secure-data/` directory
- No sensitive data exposed via web browser
- Server-side API endpoints for SMS functionality
- Masked credential display in UI (last 6 digits only)

## Installation

1. **Clone the repository**:
   ```bash
   git clone <your-repo-url>
   cd uptime-monitor
   ```

2. **Install dependencies**:
   ```bash
   npm install
   ```

3. **Set up secure data directory**:
   ```bash
   mkdir -p ../secure-data
   ```

4. **Configure Twilio (optional)**:
   - Create a `../secure-data/config.json` file with your Twilio credentials
   - Or use the SMS Settings modal in the web interface

5. **Start the application**:
   ```bash
   node uptime-monitor-api.js
   ```

6. **Access the web interface**:
   Open `http://localhost:3000` in your browser

## Auto-start on macOS

To run the monitor automatically on system startup:

1. **Install the launchd service**:
   ```bash
   ./manage-uptime-monitor.sh install
   ```

2. **Start the service**:
   ```bash
   ./manage-uptime-monitor.sh start
   ```

3. **Check status**:
   ```bash
   ./manage-uptime-monitor.sh status
   ```

## Usage

1. **Add servers**: Use the "Add New Server" form to monitor websites
2. **Configure SMS**: Click "SMS Settings" to set up Twilio notifications
3. **Monitor status**: View real-time status and uptime statistics
4. **Test manually**: Use the "Test" button for immediate checks

## Monitoring Types

- **HTTPS/HTTP**: HEAD request to check website availability
- **Ping**: Simple connectivity test with favicon fallback
- **DNS**: Domain name resolution test using Google DNS
- **TCP**: Port connectivity test via WebSocket

## SMS Alert Logic

- **3-strike rule**: HTTP/HTTPS servers marked as "warning" (yellow) after 1-2 failures, "down" (red) after 3 consecutive failures
- **First down alert**: SMS sent only on first "down" status, not repeatedly
- **Back online alert**: SMS sent when server recovers from down status
- **Test SMS**: Use "Test SMS" button to verify Twilio configuration

## File Structure

```
uptime-monitor/
├── index.html              # Main web application
├── uptime-monitor-api.js   # Node.js backend API
├── package.json            # Node.js dependencies
├── manage-uptime-monitor.sh # macOS service management
├── com.uptimemonitor.plist # macOS launchd configuration
└── ../secure-data/         # Secure credential storage (outside web root)
    ├── config.json         # Twilio credentials
    └── servers.json        # Server monitoring data
```

## API Endpoints

- `GET /api/servers` - Get all monitored servers
- `POST /api/servers` - Add new server
- `PUT /api/servers/:id` - Update server
- `DELETE /api/servers/:id` - Remove server
- `GET /api/config` - Get SMS configuration status
- `POST /api/twilio-config` - Save Twilio credentials
- `POST /api/send-sms` - Send SMS alert
- `POST /api/test-sms` - Send test SMS

## Security Notes

- Never commit the `../secure-data/` directory to version control
- Twilio credentials are masked in the UI (only last 6 digits visible)
- All sensitive operations handled server-side
- Static file serving restricted to prevent credential exposure

## Requirements

- Node.js 14+
- Twilio account (for SMS alerts)
- macOS (for auto-start functionality)

## License

MIT License - See LICENSE file for details