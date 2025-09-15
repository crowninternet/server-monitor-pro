# Changelog

All notable changes to Uptime Monitor Pro will be documented in this file.

## [1.2.0] - 2025-01-15

### Added
- **Email Settings Integration** - Complete SendGrid API integration for email alerts
- **Email Settings Modal** - Professional configuration interface for email settings
- **Email Alert System** - Automatic email notifications when servers go down or come back online
- **Test Email Functionality** - Verify SendGrid configuration with test emails
- **Professional HTML Email Templates** - Beautiful, responsive email templates for alerts
- **Enhanced Error Handling** - Better error messages and user feedback

### Enhanced
- **FTP Upload Reliability** - Added retry logic with exponential backoff for failed uploads
- **Countdown Timer Fixes** - Resolved issues with countdown getting stuck on "Now" during concurrent server checks
- **Connection Timeouts** - Added proper timeout handling for FTP connections
- **Installation Script** - Updated to reflect new Email Settings features
- **Documentation** - Comprehensive updates to installation and configuration guides

### Technical Improvements
- **SendGrid Dependency** - Added `@sendgrid/mail` package for email functionality
- **API Endpoints** - New endpoints for email configuration and testing
- **Security** - Enhanced credential storage and validation
- **Code Organization** - Improved code structure and error handling

### Fixed
- **Countdown Timer Race Conditions** - Fixed countdown getting stuck when multiple servers check simultaneously
- **FTP Intermittent Failures** - Improved reliability with automatic retry mechanism
- **Port Conflict Handling** - Better error messages for port conflicts
- **Memory Leaks** - Improved cleanup of intervals and event listeners

## [1.1.0] - Previous Release

### Added
- FTP upload functionality for public status pages
- Enhanced recovery tool with localStorage sync
- Ubuntu and Docker installation packages
- Comprehensive installation documentation

### Enhanced
- Bad Gateway detection improvements
- Code cleanup and optimization
- Installation package summaries

## [1.0.0] - Initial Release

### Added
- Multi-type server monitoring (HTTPS, Ping, DNS, TCP, Cloudflare)
- SMS alerts via Twilio integration
- Professional web interface with drag-and-drop management
- Real-time countdown timers and status charts
- Secure server-side credential storage
- macOS Launch Agent integration
- Management scripts for service control

---

## Upgrade Instructions

### From v1.1.0 to v1.2.0

1. **Stop the service:**
   ```bash
   ~/Documents/uptime-monitor/manage-uptime-monitor.sh stop
   ```

2. **Backup your data:**
   ```bash
   cp -r ~/Documents/uptime-monitor/secure-data ~/Documents/uptime-monitor-backup
   ```

3. **Update files:**
   - Replace `uptime-monitor-api.js` with new version
   - Replace `index.html` with new version
   - Replace `package.json` with new version

4. **Update dependencies:**
   ```bash
   cd ~/Documents/uptime-monitor
   npm install
   ```

5. **Start the service:**
   ```bash
   ~/Documents/uptime-monitor/manage-uptime-monitor.sh start
   ```

6. **Configure Email Settings (Optional):**
   - Open `http://localhost:3000`
   - Click "Email Settings" button
   - Enter your SendGrid API key and email addresses
   - Test the configuration

---

## Breaking Changes

None in v1.2.0 - This is a backward-compatible update.

---

## Known Issues

- None currently known

---

## Future Roadmap

- Webhook notifications
- Custom alert templates
- Multi-user support
- Advanced reporting and analytics
- Mobile app integration
