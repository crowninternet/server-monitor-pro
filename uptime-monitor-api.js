// Node.js Backend API for Uptime Monitor Pro
// Version 1.0.0
// Run with: node uptime-monitor-api.js

const express = require('express');
const cors = require('cors');
const twilio = require('twilio');
const path = require('path');
const fs = require('fs');

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

// Configuration endpoints
app.get('/api/config', (req, res) => {
    try {
        const config = readConfig();
        // Return config without sensitive Twilio credentials
        const safeConfig = {
            smsEnabled: config.smsEnabled || false,
            // Don't return Twilio credentials to frontend
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
    console.log(`💚 Health check: http://localhost:${PORT}/api/health`);
});

module.exports = app;
