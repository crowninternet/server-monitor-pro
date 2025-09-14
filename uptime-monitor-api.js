// Node.js Backend API for Uptime Monitor Pro
// Version 1.1.0 - Added FTP Upload Support
// Run with: node uptime-monitor-api.js

const express = require('express');
const cors = require('cors');
const twilio = require('twilio');
const path = require('path');
const fs = require('fs');
const ftp = require('ftp');

const app = express();
const PORT = process.env.PORT || 3000;

// Data storage paths - moved to secure directory outside web root
const SECURE_DATA_DIR = path.join(__dirname, '..', 'secure-data');
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

// FTP Upload functionality
const uploadToFTP = async (config) => {
    if (!config.ftpEnabled || !config.ftpHost || !config.ftpUser || !config.ftpPassword) {
        return { success: false, error: 'FTP not configured' };
    }

    // Generate public HTML page
    const servers = readServers();
    const publicHTML = generatePublicHTML(servers);
    const remotePath = config.ftpRemotePath || 'index.html';
    
    // Use standard FTP only
    return new Promise((resolve, reject) => {
        const client = new ftp();
        
        client.on('ready', () => {
            console.log('📤 FTP connection established');
            
            // Upload the HTML file
            client.put(Buffer.from(publicHTML), remotePath, (err) => {
                if (err) {
                    console.error('FTP upload error:', err);
                    client.end();
                    reject({ success: false, error: err.message || 'FTP upload failed' });
                } else {
                    console.log('✅ Public page uploaded successfully via FTP');
                    client.end();
                    resolve({ success: true, message: 'Public page uploaded successfully via FTP' });
                }
            });
        });
        
        client.on('error', (err) => {
            console.error('FTP connection error:', err);
            reject({ success: false, error: err.message || 'FTP connection failed' });
        });
        
        // Connect to FTP server
        client.connect({
            host: config.ftpHost,
            user: config.ftpUser,
            password: config.ftpPassword,
            port: config.ftpPort || 21,
            secure: false
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
            margin-bottom: 15px;
            word-break: break-all;
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
app.use(express.static('.')); // Serve static files from current directory

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
        // Return config without sensitive Twilio credentials
        const safeConfig = {
            smsEnabled: config.smsEnabled || false,
            ftpEnabled: config.ftpEnabled || false,
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

// Start server
app.listen(PORT, () => {
    console.log(`🚀 Uptime Monitor Pro API running on http://localhost:${PORT}`);
    console.log(`📱 SMS endpoint: http://localhost:${PORT}/api/send-sms`);
    console.log(`📤 FTP upload endpoint: http://localhost:${PORT}/api/upload-ftp`);
    console.log(`💚 Health check: http://localhost:${PORT}/api/health`);
    
    // Start automatic FTP upload every 5 minutes
    const config = readConfig();
    if (config.ftpEnabled) {
        console.log('📤 Starting automatic FTP upload every 5 minutes');
        setInterval(async () => {
            try {
                const result = await uploadToFTP(config);
                if (result.success) {
                    console.log('✅ Automatic FTP upload successful');
                } else {
                    console.log('❌ Automatic FTP upload failed:', result.error);
                }
            } catch (error) {
                console.error('❌ Automatic FTP upload error:', error);
            }
        }, 5 * 60 * 1000); // 5 minutes
    }
});

module.exports = app;
