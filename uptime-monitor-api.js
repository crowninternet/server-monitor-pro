// Node.js Backend API for Uptime Monitor Pro
// Version 1.2.0 - Added Email Support with SendGrid
// Run with: node uptime-monitor-api.js

const express = require('express');
const cors = require('cors');
const twilio = require('twilio');
const sgMail = require('@sendgrid/mail');
const path = require('path');
const fs = require('fs');
const ftp = require('ftp');

const app = express();
const PORT = process.env.PORT || 3000;

// Data storage paths - using data directory inside application directory
const SECURE_DATA_DIR = path.join(__dirname, 'data');
const SERVERS_FILE = path.join(SECURE_DATA_DIR, 'servers.json');
const CONFIG_FILE = path.join(SECURE_DATA_DIR, 'config.json');

// Ensure secure data directory exists
if (!fs.existsSync(SECURE_DATA_DIR)) {
    fs.mkdirSync(SECURE_DATA_DIR, { recursive: true });
}

// Initialize default files if they don't exist
if (!fs.existsSync(SERVERS_FILE)) {
    fs.writeFileSync(SERVERS_FILE, JSON.stringify([], null, 2));
}
if (!fs.existsSync(CONFIG_FILE)) {
    fs.writeFileSync(CONFIG_FILE, JSON.stringify({}, null, 2));
}

// Helper functions for file operations
const readServers = () => {
    try {
        const data = fs.readFileSync(SERVERS_FILE, 'utf8');
        return JSON.parse(data);
    } catch (error) {
        console.error('Error reading servers:', error);
        return [];
    }
};

const writeServers = (servers) => {
    try {
        fs.writeFileSync(SERVERS_FILE, JSON.stringify(servers, null, 2));
        return true;
    } catch (error) {
        console.error('Error writing servers:', error);
        return false;
    }
};

const readConfig = () => {
    try {
        const data = fs.readFileSync(CONFIG_FILE, 'utf8');
        return JSON.parse(data);
    } catch (error) {
        console.error('Error reading config:', error);
        return {};
    }
};

const writeConfig = (config) => {
    try {
        fs.writeFileSync(CONFIG_FILE, JSON.stringify(config, null, 2));
        return true;
    } catch (error) {
        console.error('Error writing config:', error);
        return false;
    }
};

// FTP Upload functionality with retry logic
const uploadToFTP = async (config, retryCount = 0) => {
    if (!config.ftpEnabled || !config.ftpHost || !config.ftpUser || !config.ftpPassword) {
        return { success: false, error: 'FTP not configured' };
    }

    // Generate public HTML page
    const servers = readServers();
    const publicHTML = generatePublicHTML(servers);
    const remotePath = config.ftpRemotePath || 'index.html';
    const maxRetries = 3;
    
    // Use standard FTP only
    return new Promise((resolve, reject) => {
        const client = new ftp();
        
        // Set connection timeout
        client.on('ready', () => {
            console.log('📤 FTP connection established');
            
            // Upload the HTML file
            client.put(Buffer.from(publicHTML), remotePath, (err) => {
                if (err) {
                    console.error('FTP upload error:', err);
                    client.end();
                    
                    // Retry logic for upload failures
                    if (retryCount < maxRetries) {
                        console.log(`🔄 Retrying FTP upload (attempt ${retryCount + 1}/${maxRetries})`);
                        setTimeout(() => {
                            uploadToFTP(config, retryCount + 1)
                                .then(resolve)
                                .catch(reject);
                        }, 2000 * (retryCount + 1)); // Exponential backoff
                    } else {
                        reject({ success: false, error: err.message || 'FTP upload failed after retries' });
                    }
                } else {
                    console.log('✅ Public page uploaded successfully via FTP');
                    client.end();
                    resolve({ success: true, message: 'Public page uploaded successfully via FTP' });
                }
            });
        });
        
        client.on('error', (err) => {
            console.error('FTP connection error:', err);
            client.end();
            
            // Retry logic for connection failures
            if (retryCount < maxRetries) {
                console.log(`🔄 Retrying FTP connection (attempt ${retryCount + 1}/${maxRetries})`);
                setTimeout(() => {
                    uploadToFTP(config, retryCount + 1)
                        .then(resolve)
                        .catch(reject);
                }, 2000 * (retryCount + 1)); // Exponential backoff
            } else {
                reject({ success: false, error: err.message || 'FTP connection failed after retries' });
            }
        });
        
        // Connect to FTP server with timeout
        client.connect({
            host: config.ftpHost,
            user: config.ftpUser,
            password: config.ftpPassword,
            port: config.ftpPort || 21,
            secure: false,
            connTimeout: 10000, // 10 second connection timeout
            pasvTimeout: 10000, // 10 second passive timeout
            keepalive: 10000    // 10 second keepalive
        });
    });
};

// Generate public HTML page
const generatePublicHTML = (servers) => {
    const currentTime = new Date().toLocaleString();
    const totalServers = servers.length;
    const activeServers = servers.filter(s => !s.stopped).length;
    const upServers = servers.filter(s => s.status === 'up').length;
    const downServers = servers.filter(s => s.status === 'down').length;
    const warningServers = servers.filter(s => s.status === 'warning').length;
    
    return `<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Server Status Dashboard</title>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <style>
        :root {
            --primary: #6366f1;
            --secondary: #8b5cf6;
            --success: #10b981;
            --warning: #f59e0b;
            --danger: #ef4444;
            --dark: #1f2937;
            --light: #f9fafb;
            --gray: #6b7280;
            --border: #e5e7eb;
            --shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1);
            --gradient: linear-gradient(135deg, var(--primary), var(--secondary));
        }

        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif;
            background: var(--dark);
            color: white;
            line-height: 1.6;
            min-height: 100vh;
        }

        .container {
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
        }

        .header {
            text-align: center;
            margin-bottom: 30px;
            padding: 30px 0;
            background: var(--gradient);
            border-radius: 20px;
            box-shadow: var(--shadow);
        }

        .header h1 {
            font-size: 2.5rem;
            font-weight: 700;
            margin-bottom: 10px;
            background: linear-gradient(45deg, #fff, #e0e7ff);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
        }

        .header p {
            font-size: 1.2rem;
            opacity: 0.9;
            margin-bottom: 10px;
        }

        .last-updated {
            font-size: 0.9rem;
            opacity: 0.7;
        }

        .stats-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
            margin-bottom: 40px;
        }

        .stat-card {
            background: rgba(255, 255, 255, 0.1);
            backdrop-filter: blur(10px);
            border: 1px solid rgba(255, 255, 255, 0.2);
            border-radius: 15px;
            padding: 25px;
            text-align: center;
            box-shadow: var(--shadow);
        }

        .stat-value {
            font-size: 2.5rem;
            font-weight: 700;
            margin-bottom: 10px;
        }

        .stat-label {
            font-size: 1rem;
            opacity: 0.8;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }

        .stat-total { color: var(--primary); }
        .stat-active { color: var(--success); }
        .stat-up { color: var(--success); }
        .stat-down { color: var(--danger); }
        .stat-warning { color: var(--warning); }

        .servers-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(350px, 1fr));
            gap: 20px;
        }

        .server-card {
            background: rgba(255, 255, 255, 0.1);
            backdrop-filter: blur(10px);
            border: 1px solid rgba(255, 255, 255, 0.2);
            border-radius: 15px;
            padding: 20px;
            position: relative;
            overflow: hidden;
            transition: all 0.3s ease;
        }

        .server-card:hover {
            transform: translateY(-5px);
            box-shadow: 0 20px 40px rgba(0, 0, 0, 0.2);
        }

        .status-indicator {
            position: absolute;
            top: 0;
            right: 0;
            width: 12px;
            height: 100%;
        }

        .status-up { background: var(--success); }
        .status-warning { background: var(--warning); }
        .status-down { background: var(--danger); }
        .status-stopped { background: var(--gray); }

        .server-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 15px;
        }

        .server-name {
            font-weight: 700;
            font-size: 1.1rem;
        }

        .server-type {
            background: #374151;
            padding: 6px 12px;
            border-radius: 20px;
            font-size: 0.75rem;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            font-weight: 500;
            color: white;
            border: 1px solid #4b5563;
        }

        .server-url {
            color: var(--gray);
            font-size: 0.9rem;
            margin-bottom: 5px;
            word-break: break-all;
        }

        .server-checks {
            color: var(--gray);
            font-size: 0.8rem;
            margin-bottom: 15px;
            display: flex;
            gap: 15px;
            align-items: center;
        }

        .check-count {
            display: flex;
            align-items: center;
            gap: 4px;
        }

        .check-count.up {
            color: var(--success);
        }

        .check-count.down {
            color: var(--danger);
        }

        .server-stats {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 10px;
            margin-bottom: 15px;
        }

        .stat {
            text-align: center;
            padding: 10px;
            background: rgba(255, 255, 255, 0.1);
            border-radius: 8px;
        }

        .stat-value {
            font-size: 1.2rem;
            font-weight: 700;
            color: var(--primary);
        }

        .stat-label {
            font-size: 0.8rem;
            color: var(--gray);
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }

        .status-chart {
            display: flex;
            gap: 2px;
            margin: 10px 0;
            align-items: end;
        }

        .status-bar {
            width: 8px;
            height: 12px;
            border-radius: 2px;
            background: var(--gray);
        }

        .status-bar.up { background: var(--success); }
        .status-bar.warning { background: var(--warning); }
        .status-bar.down { background: var(--danger); }
        .status-bar.pending { background: var(--gray); }

        .last-check {
            font-size: 0.8rem;
            color: var(--gray);
            margin-top: 10px;
        }

        @media (max-width: 768px) {
            .header h1 { font-size: 2rem; }
            .stats-grid { display: none; }
            .servers-grid { grid-template-columns: 1fr; }
            .container { padding: 10px; }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1><i class="fas fa-server"></i> Server Status Dashboard</h1>
            <p>Real-time monitoring of all servers</p>
            <div class="last-updated">Last updated: ${currentTime}</div>
        </div>

        <div class="stats-grid">
            <div class="stat-card">
                <div class="stat-value stat-total">${totalServers}</div>
                <div class="stat-label">Total Servers</div>
            </div>
            <div class="stat-card">
                <div class="stat-value stat-active">${activeServers}</div>
                <div class="stat-label">Active</div>
            </div>
            <div class="stat-card">
                <div class="stat-value stat-up">${upServers}</div>
                <div class="stat-label">Online</div>
            </div>
            <div class="stat-card">
                <div class="stat-value stat-warning">${warningServers}</div>
                <div class="stat-label">Warning</div>
            </div>
            <div class="stat-card">
                <div class="stat-value stat-down">${downServers}</div>
                <div class="stat-label">Offline</div>
            </div>
        </div>

        <div class="servers-grid">
            ${servers.map(server => `
                <div class="server-card">
                    <div class="status-indicator status-${server.status}"></div>
                    <div class="server-header">
                        <div class="server-name">${server.name}</div>
                        <div class="server-type">${server.type.toUpperCase()}</div>
                    </div>
                    <div class="server-url">${server.url}</div>
                    <div class="server-checks">
                        <div class="check-count up">
                            <i class="fas fa-arrow-up"></i>
                            <span>${server.successfulChecks || 0}</span>
                        </div>
                        <div class="check-count down">
                            <i class="fas fa-arrow-down"></i>
                            <span>${(server.totalChecks || 0) - (server.successfulChecks || 0)}</span>
                        </div>
                    </div>
                    <div class="status-chart">
                        ${generateStatusChart(server)}
                    </div>
                    <div class="server-stats">
                        <div class="stat">
                            <div class="stat-value">${server.uptime}%</div>
                            <div class="stat-label">Uptime</div>
                        </div>
                        <div class="stat">
                            <div class="stat-value">${server.responseTime}ms</div>
                            <div class="stat-label">Response</div>
                        </div>
                    </div>
                    <div class="last-check">
                        Last check: ${server.lastCheck ? new Date(server.lastCheck).toLocaleString() : 'Never'}
                    </div>
                </div>
            `).join('')}
        </div>
    </div>
</body>
</html>`;
};

// Generate status chart for public page
const generateStatusChart = (server) => {
    if (!server.testHistory) server.testHistory = [];
    
    let chart = '';
    const maxBars = 15;
    const totalTests = server.testHistory.length;
    
    if (totalTests === 0) {
        for (let i = 0; i < maxBars; i++) {
            chart += `<div class="status-bar pending"></div>`;
        }
    } else if (totalTests <= maxBars) {
        const missingTests = maxBars - totalTests;
        for (let i = 0; i < missingTests; i++) {
            chart += `<div class="status-bar pending"></div>`;
        }
        for (let i = 0; i < totalTests; i++) {
            const status = server.testHistory[i];
            chart += `<div class="status-bar ${status}"></div>`;
        }
    } else {
        const recentTests = server.testHistory.slice(-maxBars);
        for (let i = 0; i < maxBars; i++) {
            const status = recentTests[i];
            chart += `<div class="status-bar ${status}"></div>`;
        }
    }
    
    return chart;
};

// Middleware
app.use(cors());
app.use(express.json());

// Serve static files from current directory
app.use(express.static(__dirname));

// SMS endpoint - now uses server-side Twilio config
app.post('/api/send-sms', async (req, res) => {
    try {
        const { message } = req.body;
        const config = readConfig();
        
        if (!message) {
            return res.status(400).json({ error: 'Missing message parameter' });
        }

        if (!config.twilioSid || !config.twilioToken || !config.twilioFrom || !config.twilioTo) {
            return res.status(400).json({ 
                success: false, 
                error: 'Twilio not configured. Please set up Twilio credentials first.' 
            });
        }

        // Initialize Twilio client with server-side config
        const client = twilio(config.twilioSid, config.twilioToken);
        
        // Send SMS
        console.log(`📱 Sending SMS: "${message}" to ${config.twilioTo}`);
        const result = await client.messages.create({
            body: message,
            from: config.twilioFrom,
            to: config.twilioTo
        });

        console.log(`✅ SMS sent successfully - SID: ${result.sid}`);
        res.json({ 
            success: true, 
            messageSid: result.sid,
            message: 'SMS sent successfully'
        });
        
    } catch (error) {
        console.error('SMS Error:', error);
        res.status(500).json({ 
            success: false, 
            error: error.message || 'Failed to send SMS'
        });
    }
});

// Server management endpoints
app.get('/api/servers', (req, res) => {
    try {
        const servers = readServers();
        res.json({ success: true, servers });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

app.post('/api/servers', (req, res) => {
    try {
        const { name, url, type, interval } = req.body;
        
        if (!name || !url || !type || !interval) {
            return res.status(400).json({ 
                success: false, 
                error: 'Missing required fields: name, url, type, interval' 
            });
        }

        const servers = readServers();
        const newServer = {
            id: Date.now().toString(),
            name,
            url,
            type,
            interval: parseInt(interval),
            status: 'unknown',
            lastCheck: null,
            uptime: 100,
            responseTime: 0,
            totalChecks: 0,
            successfulChecks: 0,
            testHistory: [], // Array to store last 15 test results
            stopped: false, // Whether monitoring is paused for this server
            consecutiveFailures: 0, // Track consecutive failures for HTTP/HTTPS
            smsAlertSent: false, // Track if SMS alert has been sent for current down state
            createdAt: new Date().toISOString()
        };

        servers.push(newServer);
        
        if (writeServers(servers)) {
            // Start monitoring the new server if not stopped
            if (!newServer.stopped && typeof startServerMonitoring !== 'undefined') {
                startServerMonitoring(newServer);
            }
            res.json({ success: true, server: newServer });
        } else {
            res.status(500).json({ success: false, error: 'Failed to save server' });
        }
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

app.put('/api/servers/:id', (req, res) => {
    try {
        const { id } = req.params;
        const updates = req.body;
        
        const servers = readServers();
        const serverIndex = servers.findIndex(s => s.id === id);
        
        if (serverIndex === -1) {
            return res.status(404).json({ success: false, error: 'Server not found' });
        }

        // Update server with new data
        servers[serverIndex] = { ...servers[serverIndex], ...updates, id, consecutiveFailures: 0, smsAlertSent: false };
        
        if (writeServers(servers)) {
            // Restart monitoring for this server if monitoring functions exist
            if (typeof stopServerMonitoring !== 'undefined' && typeof startServerMonitoring !== 'undefined') {
                stopServerMonitoring(id);
                if (!servers[serverIndex].stopped) {
                    startServerMonitoring(servers[serverIndex]);
                }
            }
            res.json({ success: true, server: servers[serverIndex] });
        } else {
            res.status(500).json({ success: false, error: 'Failed to update server' });
        }
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

app.delete('/api/servers/:id', (req, res) => {
    try {
        const { id } = req.params;
        
        const servers = readServers();
        const filteredServers = servers.filter(s => s.id !== id);
        
        if (servers.length === filteredServers.length) {
            return res.status(404).json({ success: false, error: 'Server not found' });
        }
        
        if (writeServers(filteredServers)) {
            // Stop monitoring for the deleted server
            if (typeof stopServerMonitoring !== 'undefined') {
                stopServerMonitoring(id);
            }
            res.json({ success: true, message: 'Server deleted successfully' });
        } else {
            res.status(500).json({ success: false, error: 'Failed to delete server' });
        }
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

// Reorder servers endpoint
app.post('/api/servers/reorder', (req, res) => {
    try {
        const { order } = req.body;
        
        if (!Array.isArray(order)) {
            return res.status(400).json({ 
                success: false, 
                error: 'Order must be an array of server IDs' 
            });
        }
        
        const servers = readServers();
        const reorderedServers = order.map(id => 
            servers.find(server => server.id === id)
        ).filter(Boolean);
        
        if (writeServers(reorderedServers)) {
            res.json({ success: true, message: 'Server order updated successfully' });
        } else {
            res.status(500).json({ success: false, error: 'Failed to save server order' });
        }
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

// Configuration endpoints
app.get('/api/config', (req, res) => {
    try {
        const config = readConfig();
        // Return config without sensitive credentials
        const safeConfig = {
            smsEnabled: config.smsEnabled || false,
            ftpEnabled: config.ftpEnabled || false,
            emailEnabled: config.emailEnabled || false,
            // Don't return sensitive credentials to frontend
        };
        res.json({ success: true, config: safeConfig });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

app.post('/api/config', (req, res) => {
    try {
        const config = req.body;
        
        if (writeConfig(config)) {
            // Return safe config without credentials
            const safeConfig = {
                smsEnabled: config.smsEnabled || false,
                ftpEnabled: config.ftpEnabled || false,
                emailEnabled: config.emailEnabled || false,
            };
            res.json({ success: true, config: safeConfig });
        } else {
            res.status(500).json({ success: false, error: 'Failed to save configuration' });
        }
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

// Twilio configuration endpoint (server-side only)
app.post('/api/twilio-config', (req, res) => {
    try {
        const { twilioSid, twilioToken, twilioFrom, twilioTo, smsEnabled } = req.body;
        
        if (!twilioSid || !twilioToken || !twilioFrom || !twilioTo) {
            return res.status(400).json({ 
                success: false, 
                error: 'Missing required Twilio parameters' 
            });
        }

        const config = readConfig();
        config.twilioSid = twilioSid;
        config.twilioToken = twilioToken;
        config.twilioFrom = twilioFrom;
        config.twilioTo = twilioTo;
        config.smsEnabled = smsEnabled || false;
        
        if (writeConfig(config)) {
            res.json({ 
                success: true, 
                message: 'Twilio configuration saved successfully' 
            });
        } else {
            res.status(500).json({ success: false, error: 'Failed to save Twilio configuration' });
        }
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

// FTP configuration endpoint (server-side only)
app.post('/api/ftp-config', (req, res) => {
    try {
        const { ftpHost, ftpUser, ftpPassword, ftpPort, ftpRemotePath, ftpEnabled } = req.body;
        
        if (!ftpHost || !ftpUser || !ftpPassword) {
            return res.status(400).json({ 
                success: false, 
                error: 'Missing required FTP parameters' 
            });
        }

        const config = readConfig();
        config.ftpHost = ftpHost;
        config.ftpUser = ftpUser;
        config.ftpPassword = ftpPassword;
        config.ftpPort = ftpPort || 21;
        config.ftpRemotePath = ftpRemotePath || 'index.html';
        config.ftpEnabled = ftpEnabled || false;
        
        if (writeConfig(config)) {
            res.json({ 
                success: true, 
                message: 'FTP configuration saved successfully' 
            });
        } else {
            res.status(500).json({ success: false, error: 'Failed to save FTP configuration' });
        }
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

// Get FTP configuration endpoint (server-side only)
app.get('/api/ftp-config', (req, res) => {
    try {
        const config = readConfig();
        
        // Return FTP config with masked password
        const ftpConfig = {
            ftpHost: config.ftpHost || '',
            ftpUser: config.ftpUser || '',
            ftpPassword: config.ftpPassword ? '••••••••••••••••••••••••••••' + config.ftpPassword.slice(-4) : '',
            ftpPort: config.ftpPort || 21,
            ftpRemotePath: config.ftpRemotePath || 'index.html',
            ftpEnabled: config.ftpEnabled || false
        };
        
        res.json({ success: true, config: ftpConfig });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

// Manual FTP upload endpoint
app.post('/api/upload-ftp', async (req, res) => {
    try {
        const config = readConfig();
        const result = await uploadToFTP(config);
        res.json(result);
    } catch (error) {
        console.error('FTP upload endpoint error:', error);
        let errorMessage = 'Unknown FTP upload error';
        
        if (error && typeof error === 'object') {
            if (error.error) {
                errorMessage = error.error;
            } else if (error.message) {
                errorMessage = error.message;
            } else if (error.code) {
                errorMessage = `FTP Error: ${error.code}`;
            }
        } else if (typeof error === 'string') {
            errorMessage = error;
        }
        
        res.status(500).json({ 
            success: false, 
            error: errorMessage
        });
    }
});

// Test SMS endpoint
app.post('/api/test-sms', async (req, res) => {
    try {
        const config = readConfig();
        
        if (!config.twilioSid || !config.twilioToken || !config.twilioFrom || !config.twilioTo) {
            return res.status(400).json({ 
                success: false, 
                error: 'Twilio not configured. Please set up Twilio credentials first.' 
            });
        }

        // Initialize Twilio client
        const client = twilio(config.twilioSid, config.twilioToken);
        
        // Send test SMS
        console.log(`📱 Sending TEST SMS to ${config.twilioTo}`);
        const result = await client.messages.create({
            body: 'Test SMS from Uptime Monitor Pro - Twilio configuration is working!',
            from: config.twilioFrom,
            to: config.twilioTo
        });

        console.log(`✅ TEST SMS sent successfully - SID: ${result.sid}`);

        res.json({ 
            success: true, 
            messageSid: result.sid,
            message: 'Test SMS sent successfully'
        });
        
    } catch (error) {
        console.error('Test SMS Error:', error);
        res.status(500).json({ 
            success: false, 
            error: error.message || 'Failed to send test SMS'
        });
    }
});

// Server-side URL check endpoint (bypasses CORS)
app.get('/api/check-url', async (req, res) => {
    try {
        const { url } = req.query;
        if (!url) {
            return res.status(400).json({ success: false, error: 'URL parameter required' });
        }

        const axios = require('axios');
        const startTime = Date.now();
        
        try {
            const response = await axios.get(url, {
                timeout: 10000,
                validateStatus: () => true // Don't throw on any status code
            });
            
            const responseTime = Date.now() - startTime;
            const isCloudflareError = response.status === 502 || response.status === 503 || response.status === 504;
            
            // Check for "Bad gateway" text in response content (case-insensitive)
            const responseText = response.data ? response.data.toString().toLowerCase() : '';
            const hasBadGatewayText = responseText.includes('bad gateway');
            
            // Combine status code and text-based detection for gateway errors
            const isGatewayError = isCloudflareError || hasBadGatewayText;
            
            res.json({
                success: true,
                status: response.status,
                responseTime: responseTime,
                isCloudflareError: isCloudflareError,
                hasBadGatewayText: hasBadGatewayText,
                isGatewayError: isGatewayError,
                isUp: response.status >= 200 && response.status < 300 && !isGatewayError,
                isFailure: response.status < 200 || response.status >= 300 || isGatewayError
            });
            
        } catch (error) {
            const responseTime = Date.now() - startTime;
            res.json({
                success: true,
                status: 0,
                responseTime: responseTime,
                isCloudflareError: false,
                hasBadGatewayText: false,
                isGatewayError: false,
                isUp: false,
                isFailure: true, // Treat network errors as failures
                error: error.message
            });
        }
        
    } catch (error) {
        console.error('URL check error:', error);
        res.status(500).json({ success: false, error: error.message });
    }
});

// Health check endpoint
app.get('/api/health', (req, res) => {
    res.json({ status: 'OK', timestamp: new Date().toISOString() });
});

// Serve the main HTML file
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'index.html'));
});

// Static files now handle recovery.html and other files automatically

// Start server
app.listen(PORT, () => {
    console.log(`🚀 Uptime Monitor Pro API running on http://localhost:${PORT}`);
    console.log(`📱 SMS endpoint: http://localhost:${PORT}/api/send-sms`);
    console.log(`📤 FTP upload endpoint: http://localhost:${PORT}/api/upload-ftp`);
    console.log(`💚 Health check: http://localhost:${PORT}/api/health`);
    
    // Start server-side monitoring engine
    console.log('');
    console.log('======================================');
    console.log('🔍 INITIALIZING SERVER-SIDE MONITORING');
    console.log('======================================');
    setTimeout(() => {
        startAllMonitoring();
        console.log('✅ Server-side monitoring is now active!');
        console.log('✅ Checks will run automatically even when browser is closed');
        console.log('');
    }, 2000); // Wait 2 seconds after startup
    
    // Start automatic FTP upload every 5 minutes
    const config = readConfig();
    if (config.ftpEnabled) {
        console.log('📤 Starting automatic FTP upload every 5 minutes');
        
        // Initial upload
        setTimeout(async () => {
            try {
                console.log('📤 Performing initial FTP upload...');
                const result = await uploadToFTP(config);
                if (result.success) {
                    console.log('✅ Initial FTP upload successful');
                } else {
                    console.log('❌ Initial FTP upload failed:', result.error);
                }
            } catch (error) {
                console.error('❌ Initial FTP upload error:', error);
            }
        }, 5000); // Wait 5 seconds after startup
        
        // Regular interval uploads
        setInterval(async () => {
            try {
                console.log('📤 Starting scheduled FTP upload...');
                const result = await uploadToFTP(config);
                if (result.success) {
                    console.log('✅ Scheduled FTP upload successful');
                } else {
                    console.log('❌ Scheduled FTP upload failed:', result.error);
                }
            } catch (error) {
                console.error('❌ Scheduled FTP upload error:', error);
            }
        }, 5 * 60 * 1000); // 5 minutes
    } else {
        console.log('📤 FTP upload disabled - enable in configuration to start automatic uploads');
    }
});

// Email functionality using SendGrid
const sendEmailAlert = async (config, subject, message, serverName, serverUrl) => {
    if (!config.emailEnabled || !config.sendgridApiKey || !config.emailFrom || !config.emailTo) {
        return { success: false, error: 'Email not configured' };
    }

    try {
        sgMail.setApiKey(config.sendgridApiKey);
        
        const msg = {
            to: config.emailTo,
            from: config.emailFrom,
            subject: `[Uptime Monitor] ${subject}`,
            html: `
                <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
                    <h2 style="color: #333; border-bottom: 2px solid #6366f1; padding-bottom: 10px;">
                        🚨 Uptime Monitor Alert
                    </h2>
                    <div style="background: #f8f9fa; padding: 20px; border-radius: 8px; margin: 20px 0;">
                        <h3 style="color: #333; margin-top: 0;">${subject}</h3>
                        <p style="font-size: 16px; line-height: 1.6; color: #555;">${message}</p>
                        <div style="background: white; padding: 15px; border-radius: 5px; margin-top: 15px;">
                            <strong>Server:</strong> ${serverName}<br>
                            <strong>URL:</strong> <a href="${serverUrl}" style="color: #6366f1;">${serverUrl}</a><br>
                            <strong>Time:</strong> ${new Date().toLocaleString()}
                        </div>
                    </div>
                    <div style="text-align: center; color: #666; font-size: 12px; margin-top: 30px;">
                        This alert was sent by Uptime Monitor Pro
                    </div>
                </div>
            `,
            text: `${subject}\n\n${message}\n\nServer: ${serverName}\nURL: ${serverUrl}\nTime: ${new Date().toLocaleString()}`
        };

        console.log(`📧 Sending email: "${subject}" to ${config.emailTo}`);
        const result = await sgMail.send(msg);
        
        console.log(`✅ Email sent successfully`);
        return { success: true, messageId: result[0].headers['x-message-id'] };
        
    } catch (error) {
        console.error('Email send error:', error);
        return { success: false, error: error.message || 'Failed to send email' };
    }
};

// Email endpoints
app.post('/api/send-email', async (req, res) => {
    try {
        const { subject, message, serverName, serverUrl } = req.body;
        const config = readConfig();
        
        if (!subject || !message) {
            return res.status(400).json({ error: 'Missing subject or message parameter' });
        }

        const result = await sendEmailAlert(config, subject, message, serverName || 'Unknown Server', serverUrl || '');
        res.json(result);
        
    } catch (error) {
        console.error('Email endpoint error:', error);
        res.status(500).json({ 
            success: false, 
            error: error.message || 'Unknown email error'
        });
    }
});

app.post('/api/email-config', (req, res) => {
    try {
        const { sendgridApiKey, emailFrom, emailTo, emailEnabled } = req.body;
        
        if (!emailFrom || !emailTo) {
            return res.status(400).json({ 
                success: false, 
                error: 'Missing required email parameters (emailFrom, emailTo)' 
            });
        }

        const config = readConfig();
        
        // Only update API key if a new one is provided and it's not a masked value
        if (sendgridApiKey && sendgridApiKey.trim() !== '' && !sendgridApiKey.includes('••••')) {
            // Validate that the API key starts with 'SG.' (SendGrid format)
            if (sendgridApiKey.startsWith('SG.')) {
                config.sendgridApiKey = sendgridApiKey;
            } else {
                return res.status(400).json({ 
                    success: false, 
                    error: 'Invalid SendGrid API key format. Key must start with "SG."' 
                });
            }
        }
        
        config.emailFrom = emailFrom;
        config.emailTo = emailTo;
        config.emailEnabled = emailEnabled || false;
        
        if (writeConfig(config)) {
            res.json({ 
                success: true, 
                message: 'Email configuration saved successfully' 
            });
        } else {
            res.status(500).json({ success: false, error: 'Failed to save email configuration' });
        }
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

app.get('/api/email-config', (req, res) => {
    try {
        const config = readConfig();
        
        const emailConfig = {
            sendgridApiKey: config.sendgridApiKey ? '••••••••••••••••••••••••••••' + config.sendgridApiKey.slice(-6) : '',
            emailFrom: config.emailFrom || '',
            emailTo: config.emailTo || '',
            emailEnabled: config.emailEnabled || false
        };
        
        res.json({ success: true, config: emailConfig });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

app.post('/api/test-email', async (req, res) => {
    try {
        const config = readConfig();
        
        if (!config.sendgridApiKey || !config.emailFrom || !config.emailTo) {
            return res.status(400).json({ 
                success: false, 
                error: 'Email not configured. Please set up email credentials first.' 
            });
        }

        const result = await sendEmailAlert(
            config, 
            'Test Email from Uptime Monitor Pro', 
            'This is a test email to verify your SendGrid configuration is working correctly. Your email alerts are now ready to use!',
            'Test Server',
            'https://example.com'
        );

        if (result.success) {
            res.json({ 
                success: true, 
                messageId: result.messageId,
                message: 'Test email sent successfully'
            });
        } else {
            res.status(500).json({ 
                success: false, 
                error: result.error || 'Failed to send test email'
            });
        }
        
    } catch (error) {
        console.error('Test email error:', error);
        res.status(500).json({ 
            success: false, 
            error: error.message || 'Failed to send test email'
        });
    }
});

// ============================================
// SERVER-SIDE MONITORING ENGINE
// ============================================

// Store monitoring intervals for each server
const monitoringIntervals = {};
let monitoringEnabled = true;

// Function to check a server and update its status
const performServerCheck = async (server) => {
    if (!server || server.stopped) {
        return;
    }

    console.log(`🔍 Checking server: ${server.name} (${server.type})`);
    const startTime = Date.now();
    let success = false;
    let responseTime = 0;
    let status = 'down';

    try {
        if (server.type === 'http' || server.type === 'https') {
            // HTTP/HTTPS check using axios
            const axios = require('axios');
            try {
                const response = await axios.get(server.url, {
                    timeout: 10000,
                    validateStatus: () => true
                });
                
                responseTime = Date.now() - startTime;
                const isCloudflareError = response.status === 502 || response.status === 503 || response.status === 504;
                const responseText = response.data ? response.data.toString().toLowerCase() : '';
                const hasBadGatewayText = responseText.includes('bad gateway');
                const isGatewayError = isCloudflareError || hasBadGatewayText;
                
                success = response.status >= 200 && response.status < 300 && !isGatewayError;
                
                if (success) {
                    server.consecutiveFailures = 0;
                    status = 'up';
                } else {
                    server.consecutiveFailures = (server.consecutiveFailures || 0) + 1;
                    status = server.consecutiveFailures >= 3 ? 'down' : 'warning';
                }
            } catch (error) {
                responseTime = Date.now() - startTime;
                server.consecutiveFailures = (server.consecutiveFailures || 0) + 1;
                status = server.consecutiveFailures >= 3 ? 'down' : 'warning';
                console.error(`Error checking ${server.name}:`, error.message);
            }
        } else if (server.type === 'ping') {
            // Simple ping check (you can enhance this with actual ICMP if needed)
            const axios = require('axios');
            try {
                const hostname = server.url.replace(/^https?:\/\//, '').split('/')[0];
                const testUrl = `http://${hostname}`;
                
                const response = await axios.head(testUrl, {
                    timeout: 10000,
                    validateStatus: () => true
                });
                
                responseTime = Date.now() - startTime;
                success = response.status >= 200 && response.status < 500;
                status = success ? 'up' : 'down';
            } catch (error) {
                responseTime = Date.now() - startTime;
                success = false;
                status = 'down';
            }
        }

        // Update server data
        const previousStatus = server.status;
        server.status = status;
        server.lastCheck = new Date().toISOString();
        server.responseTime = responseTime;
        server.totalChecks = (server.totalChecks || 0) + 1;
        
        if (success) {
            server.successfulChecks = (server.successfulChecks || 0) + 1;
        }
        
        // Update uptime percentage
        server.uptime = server.totalChecks > 0 
            ? Math.round((server.successfulChecks / server.totalChecks) * 100) 
            : 100;

        // Update test history (keep last 15 results)
        if (!server.testHistory) server.testHistory = [];
        server.testHistory.push(status);
        if (server.testHistory.length > 15) {
            server.testHistory.shift();
        }

        // Check if we need to send alerts
        const config = readConfig();
        
        // If server just went down (was up or warning, now down)
        if (status === 'down' && previousStatus !== 'down' && !server.smsAlertSent) {
            console.log(`🚨 Server ${server.name} is DOWN! Sending alerts...`);
            
            // Send SMS alert if enabled
            if (config.smsEnabled && config.twilioSid && config.twilioToken) {
                try {
                    const client = twilio(config.twilioSid, config.twilioToken);
                    await client.messages.create({
                        body: `🚨 ALERT: ${server.name} is DOWN!\nURL: ${server.url}\nTime: ${new Date().toLocaleString()}`,
                        from: config.twilioFrom,
                        to: config.twilioTo
                    });
                    console.log(`✅ SMS alert sent for ${server.name}`);
                    server.smsAlertSent = true;
                } catch (error) {
                    console.error(`❌ Failed to send SMS alert for ${server.name}:`, error.message);
                }
            }
            
            // Send email alert if enabled
            if (config.emailEnabled && config.sendgridApiKey) {
                try {
                    await sendEmailAlert(
                        config,
                        `Server DOWN: ${server.name}`,
                        `Server ${server.name} is not responding and has been marked as DOWN.`,
                        server.name,
                        server.url
                    );
                    console.log(`✅ Email alert sent for ${server.name}`);
                } catch (error) {
                    console.error(`❌ Failed to send email alert for ${server.name}:`, error.message);
                }
            }
        }
        
        // If server recovered (was down, now up)
        if (status === 'up' && previousStatus === 'down') {
            console.log(`✅ Server ${server.name} is back UP!`);
            server.smsAlertSent = false; // Reset alert flag
            server.consecutiveFailures = 0;
            
            // Send recovery notification if enabled
            if (config.smsEnabled && config.twilioSid && config.twilioToken) {
                try {
                    const client = twilio(config.twilioSid, config.twilioToken);
                    await client.messages.create({
                        body: `✅ RECOVERY: ${server.name} is back UP!\nURL: ${server.url}\nTime: ${new Date().toLocaleString()}`,
                        from: config.twilioFrom,
                        to: config.twilioTo
                    });
                    console.log(`✅ Recovery SMS sent for ${server.name}`);
                } catch (error) {
                    console.error(`❌ Failed to send recovery SMS for ${server.name}:`, error.message);
                }
            }
            
            if (config.emailEnabled && config.sendgridApiKey) {
                try {
                    await sendEmailAlert(
                        config,
                        `Server UP: ${server.name}`,
                        `Server ${server.name} has recovered and is now responding normally.`,
                        server.name,
                        server.url
                    );
                    console.log(`✅ Recovery email sent for ${server.name}`);
                } catch (error) {
                    console.error(`❌ Failed to send recovery email for ${server.name}:`, error.message);
                }
            }
        }

        // Save updated server data
        const servers = readServers();
        const serverIndex = servers.findIndex(s => s.id === server.id);
        if (serverIndex !== -1) {
            servers[serverIndex] = server;
            writeServers(servers);
            
            // Trigger FTP upload if enabled and status changed
            if (config.ftpEnabled && previousStatus !== status) {
                console.log(`📤 Status changed for ${server.name}, triggering FTP upload...`);
                try {
                    await uploadToFTP(config);
                } catch (error) {
                    console.error('FTP upload error after status change:', error);
                }
            }
        }

        console.log(`✅ Check complete for ${server.name}: ${status} (${responseTime}ms)`);

    } catch (error) {
        console.error(`❌ Error performing check for ${server.name}:`, error);
    }
};

// Start monitoring a specific server
const startServerMonitoring = (server) => {
    if (!server || server.stopped || monitoringIntervals[server.id]) {
        return;
    }

    console.log(`▶️  Starting monitoring for ${server.name} (interval: ${server.interval}s)`);
    
    // Perform immediate check
    performServerCheck(server);
    
    // Set up interval for recurring checks
    monitoringIntervals[server.id] = setInterval(() => {
        performServerCheck(server);
    }, server.interval * 1000);
};

// Stop monitoring a specific server
const stopServerMonitoring = (serverId) => {
    if (monitoringIntervals[serverId]) {
        clearInterval(monitoringIntervals[serverId]);
        delete monitoringIntervals[serverId];
        console.log(`⏸️  Stopped monitoring for server ID: ${serverId}`);
    }
};

// Start monitoring all servers
const startAllMonitoring = () => {
    console.log('🚀 Starting server-side monitoring engine...');
    const servers = readServers();
    
    servers.forEach(server => {
        if (!server.stopped) {
            startServerMonitoring(server);
        }
    });
    
    console.log(`✅ Monitoring started for ${Object.keys(monitoringIntervals).length} servers`);
};

// Stop all monitoring
const stopAllMonitoring = () => {
    console.log('⏸️  Stopping all server monitoring...');
    Object.keys(monitoringIntervals).forEach(serverId => {
        stopServerMonitoring(serverId);
    });
};

// Restart monitoring (useful when servers are added/updated)
const restartMonitoring = () => {
    stopAllMonitoring();
    setTimeout(() => {
        startAllMonitoring();
    }, 1000);
};

// API endpoint to control monitoring
app.post('/api/monitoring/control', (req, res) => {
    try {
        const { action } = req.body;
        
        switch (action) {
            case 'start':
                startAllMonitoring();
                res.json({ success: true, message: 'Monitoring started' });
                break;
            case 'stop':
                stopAllMonitoring();
                res.json({ success: true, message: 'Monitoring stopped' });
                break;
            case 'restart':
                restartMonitoring();
                res.json({ success: true, message: 'Monitoring restarted' });
                break;
            default:
                res.status(400).json({ success: false, error: 'Invalid action' });
        }
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

// API endpoint to get monitoring status
app.get('/api/monitoring/status', (req, res) => {
    try {
        const activeMonitors = Object.keys(monitoringIntervals).length;
        const servers = readServers();
        const totalServers = servers.filter(s => !s.stopped).length;
        
        res.json({
            success: true,
            enabled: monitoringEnabled,
            activeMonitors,
            totalServers,
            monitoredServerIds: Object.keys(monitoringIntervals)
        });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

// Export for testing
module.exports = app;
