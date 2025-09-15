# Uptime Monitor Pro

A comprehensive server monitoring solution with SMS, Email, and FTP support.

## Features

### 🔍 **Multi-Type Server Monitoring**
- **HTTPS/HTTP**: Web service monitoring with SSL certificate tracking
- **Ping**: ICMP ping monitoring for network connectivity
- **DNS**: DNS resolution monitoring with custom record types
- **TCP**: Port connectivity monitoring
- **Cloudflare**: Cloudflare-specific monitoring

### 📱 **SMS Alerts (Twilio)**
- Real-time SMS notifications when servers go down or come back online
- Secure server-side credential storage
- Configurable phone numbers and messaging

### 📧 **Email Alerts (SendGrid)**
- Professional HTML email templates
- Detailed server status information
- Configurable sender and recipient emails
- SendGrid API integration

### 📤 **FTP Upload**
- Automatic public status page generation
- Configurable upload intervals (every 5 minutes)
- Retry logic with exponential backoff
- Secure credential storage

### 🎨 **Professional Web Interface**
- Drag-and-drop server management
- Real-time countdown timers
- Interactive status charts
- Responsive design
- Dark/light theme support

### 🔒 **Security Features**
- Server-side credential storage
- Secure API endpoints
- Input validation and sanitization
- CORS protection

## Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd uptime-monitor
   ```

2. **Install dependencies**
   ```bash
   npm install
   ```

3. **Configure credentials**
   - Create a `secure-data/` directory
   - Add your API keys and credentials (see Configuration section)

4. **Start the application**
   ```bash
   npm start
   ```

5. **Access the web interface**
   - Open http://localhost:3000 in your browser

## Configuration

### SMS Configuration (Twilio)
- Account SID
- Auth Token
- Phone numbers (from/to)

### Email Configuration (SendGrid)
- API Key
- From email address
- To email address

### FTP Configuration
- Host, username, password
- Remote path for status page
- Upload interval settings

## API Endpoints

### Server Management
- `GET /api/servers` - Get all servers
- `POST /api/servers` - Add new server
- `PUT /api/servers/:id` - Update server
- `DELETE /api/servers/:id` - Delete server

### Monitoring
- `POST /api/check-server/:id` - Manual server check
- `GET /api/server-status/:id` - Get server status

### Alerts
- `POST /api/send-sms` - Send SMS alert
- `POST /api/send-email` - Send email alert
- `POST /api/test-sms` - Test SMS configuration
- `POST /api/test-email` - Test email configuration

### FTP
- `POST /api/upload-ftp` - Manual FTP upload
- `GET /api/ftp-config` - Get FTP configuration
- `POST /api/ftp-config` - Update FTP configuration

## File Structure

```
uptime-monitor/
├── index.html              # Main web interface
├── uptime-monitor-api.js   # Backend API server
├── package.json            # Dependencies and scripts
├── recovery.html           # Recovery tool interface
├── manage-uptime-monitor.sh # Management script
├── .gitignore             # Git ignore rules
└── README.md              # This file
```

## Dependencies

- **Express.js**: Web server framework
- **Twilio**: SMS messaging service
- **SendGrid**: Email service
- **FTP**: File transfer protocol
- **CORS**: Cross-origin resource sharing
- **Axios**: HTTP client

## Version History

- **v1.2.0**: Added Email support with SendGrid integration
- **v1.1.0**: Added FTP upload support
- **v1.0.0**: Initial release with SMS support

## License

This project is licensed under the MIT License.

## Support

For issues and feature requests, please create an issue in the repository.
