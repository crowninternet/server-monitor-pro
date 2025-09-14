# File-Based Storage Setup Guide

## 🚀 **File-Based Storage System Implemented!**

Your Uptime Monitor Pro now uses **file-based storage** instead of browser localStorage, meaning your servers and configurations persist across all browser sessions and devices.

## 📁 **How It Works:**

### **Data Storage:**
- **Servers**: Stored in `/data/servers.json`
- **Configuration**: Stored in `/data/config.json`
- **Automatic Creation**: Data directory and files are created automatically

### **API Endpoints:**
- `GET /api/servers` - Load all servers
- `POST /api/servers` - Add new server
- `PUT /api/servers/:id` - Update server status
- `DELETE /api/servers/:id` - Delete server
- `GET /api/config` - Load configuration
- `POST /api/config` - Save configuration

## 🔧 **Installation & Setup:**

### **Option 1: Install Node.js (Recommended)**
```bash
# Install Node.js from https://nodejs.org
# Then run:
cd /Users/jmahon/Documents/uptime-monitor
npm install
npm start
```

### **Option 2: Use Standalone HTML (Limited)**
- Open `index.html` directly in browser
- Will use localStorage fallback if API unavailable
- Servers won't persist across devices

## 📊 **Benefits of File-Based Storage:**

✅ **Cross-Device Persistence** - Servers saved on any device  
✅ **No Database Required** - Simple JSON file storage  
✅ **Backup Friendly** - Easy to backup `/data` folder  
✅ **Version Control** - Track changes with Git  
✅ **API-Driven** - RESTful endpoints for all operations  
✅ **Fallback Support** - Graceful degradation to localStorage  

## 🗂️ **File Structure:**
```
uptime-monitor/
├── index.html              # Frontend application
├── uptime-monitor-api.js   # Backend API server
├── package.json           # Dependencies
├── README.md              # Documentation
├── data/                  # Auto-created data storage
│   ├── servers.json      # All monitored servers
│   └── config.json       # Twilio configuration
└── SETUP.md              # This file
```

## 🔄 **Data Flow:**
1. **Frontend** makes API calls to backend
2. **Backend** reads/writes JSON files in `/data` folder
3. **Data persists** across browser sessions and devices
4. **Fallback** to localStorage if backend unavailable

## 🚀 **Ready to Use:**
Once Node.js is installed and server is running:
1. Add servers via the web interface
2. Configuration automatically saves to files
3. All data persists between sessions
4. Share the same monitoring across multiple devices

Your uptime monitoring is now truly persistent and device-independent! 🎉
