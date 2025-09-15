# Uptime Monitor Pro - Installation Guide for Docker

## 🚀 Quick Start (One-Click Installation)

### Prerequisites
- Docker Engine 20.10+ or Docker Desktop
- Docker Compose V2 (recommended) or Docker Compose V1
- Internet connection
- 1GB+ free disk space

### Installation Steps

1. **Download the Installation Package**
   ```bash
   # Clone or download the uptime-monitor project
   git clone <repository-url> uptime-monitor
   cd uptime-monitor/docker
   ```

2. **Run the One-Click Installer**
   ```bash
   # Make the script executable
   chmod +x install.sh
   
   # Run the installer
   ./install.sh
   ```

3. **Access Your Dashboard**
   - Open your browser and go to: `http://localhost:3000`
   - The service will start automatically

## 📋 What the Installer Does

The installation script automatically:

✅ **Checks Docker installation** and ensures it's running  
✅ **Checks Docker Compose** (V1 or V2)  
✅ **Creates project directories** (`./data`, `./logs`)  
✅ **Copies all project files**  
✅ **Creates environment configuration** (`.env`)  
✅ **Creates Nginx configuration** (for production)  
✅ **Builds Docker image** (multi-stage build)  
✅ **Starts containers** with Docker Compose  
✅ **Creates management script**  
✅ **Waits for service readiness**  
✅ **Shows completion instructions**  

## 🎯 Manual Installation (Alternative)

If you prefer to install manually or the automated installer fails:

### Step 1: Install Docker
```bash
# Ubuntu/Debian
sudo apt update
sudo apt install docker.io docker-compose-plugin
sudo systemctl start docker
sudo systemctl enable docker

# Add user to docker group (optional)
sudo usermod -aG docker $USER
newgrp docker
```

### Step 2: Create Project Directory
```bash
mkdir uptime-monitor-docker
cd uptime-monitor-docker
```

### Step 3: Copy Project Files
Copy these files to your project directory:
- `Dockerfile`
- `docker-compose.yml`
- `package.json`
- `uptime-monitor-api.js`
- `index.html`
- `recovery.html`

### Step 4: Create Data Directories
```bash
mkdir -p data logs
chmod 755 data logs
```

### Step 5: Create Environment File
Create `.env`:
```bash
# Uptime Monitor Pro - Environment Configuration
NODE_ENV=production
PORT=3000
DATA_PATH=/app/secure-data
LOGS_PATH=/app/logs
```

### Step 6: Build and Start
```bash
# Build the image
docker build -t uptime-monitor-pro:latest .

# Start the services
docker-compose up -d

# Check status
docker-compose ps
```

## 🛠️ Management Commands

After installation, use these commands to manage the service:

```bash
# Navigate to project directory
cd uptime-monitor-docker

# Start the service
./manage-uptime-monitor.sh start

# Stop the service
./manage-uptime-monitor.sh stop

# Restart the service
./manage-uptime-monitor.sh restart

# Check service status
./manage-uptime-monitor.sh status

# View logs
./manage-uptime-monitor.sh logs

# Follow logs in real-time
./manage-uptime-monitor.sh logs-tail

# Test API connectivity
./manage-uptime-monitor.sh test

# Uninstall completely
./manage-uptime-monitor.sh uninstall
```

## 🌐 Accessing the Application

- **Local Access:** `http://localhost:3000`
- **External Access:** `http://your-server-ip:3000`
- **API Health Check:** `http://localhost:3000/api/health`

## 📁 File Structure

After installation, your directory structure will be:

```
uptime-monitor-docker/
├── Dockerfile                    # Docker image definition
├── docker-compose.yml            # Docker Compose configuration
├── .env                         # Environment variables
├── nginx.conf                   # Nginx configuration (optional)
├── package.json                 # Node.js dependencies
├── uptime-monitor-api.js        # Backend API server
├── index.html                   # Main web interface
├── recovery.html                # Recovery tool
├── manage-uptime-monitor.sh     # Management script
├── install.sh                   # Installation script
├── data/                        # Persistent data storage
│   ├── servers.json            # Monitored servers data
│   └── config.json             # Configuration data
└── logs/                        # Application logs
```

## 🔧 Configuration

### Environment Variables
Edit `.env` file to customize:
```bash
# Application Settings
NODE_ENV=production
PORT=3000

# Data Persistence
DATA_PATH=/app/secure-data
LOGS_PATH=/app/logs

# Optional: Custom domain for Traefik labels
DOMAIN=uptime.yourdomain.com
```

### Docker Compose Configuration
Edit `docker-compose.yml` to customize:
- Port mappings
- Volume mounts
- Environment variables
- Network settings
- Health checks

### SMS Alerts (Optional)
1. Open the web interface at `http://localhost:3000`
2. Click "SMS Settings" button
3. Enter your Twilio credentials
4. Enable SMS alerts toggle
5. Test the configuration

### FTP Upload (Optional)
1. Click "FTP Settings" button
2. Enter your FTP server details
3. Enable FTP upload toggle
4. Test the configuration

## 🚨 Troubleshooting

### Docker Issues
```bash
# Check Docker status
docker --version
docker info

# Check if Docker is running
sudo systemctl status docker

# Start Docker if stopped
sudo systemctl start docker
```

### Container Issues
```bash
# Check container status
docker-compose ps

# View container logs
docker-compose logs uptime-monitor

# Restart containers
docker-compose restart

# Rebuild and restart
docker-compose down
docker-compose up -d --build
```

### Port Conflicts
```bash
# Check what's using port 3000
sudo lsof -i :3000

# Kill the process (replace PID with actual process ID)
sudo kill -9 PID

# Or change port in docker-compose.yml
# Edit the ports section: "3001:3000"
```

### Permission Issues
```bash
# Check data directory permissions
ls -la data/

# Fix permissions
chmod 755 data logs
chown -R $USER:$USER data logs
```

### Data Persistence Issues
```bash
# Check volume mounts
docker-compose config

# Verify data directory
ls -la data/

# Check container file system
docker exec -it uptime-monitor-pro ls -la /app/secure-data
```

## 🔄 Updates

To update Uptime Monitor Pro:

1. **Stop the containers:**
   ```bash
   docker-compose down
   ```

2. **Backup your data:**
   ```bash
   cp -r data data-backup
   ```

3. **Update the files:**
   - Copy new `uptime-monitor-api.js`
   - Copy new `index.html`
   - Copy new `recovery.html`

4. **Rebuild and restart:**
   ```bash
   docker-compose up -d --build
   ```

## 🗑️ Uninstallation

To completely remove Uptime Monitor Pro:

```bash
# Use the management script
./manage-uptime-monitor.sh uninstall

# Or manually:
docker-compose down
docker rmi uptime-monitor-pro:latest
docker-compose down -v
rm -rf data logs
```

## 🐳 Docker Commands Reference

### Basic Commands
```bash
# Start services
docker-compose up -d

# Stop services
docker-compose down

# View logs
docker-compose logs -f

# Check status
docker-compose ps

# Execute commands in container
docker exec -it uptime-monitor-pro sh
```

### Advanced Commands
```bash
# Rebuild image
docker-compose build --no-cache

# Scale services (if needed)
docker-compose up -d --scale uptime-monitor=2

# View resource usage
docker stats

# Clean up unused resources
docker system prune
```

## 🔒 Security Considerations

### Container Security
- Runs as non-root user (`uptime-monitor`)
- Minimal Alpine Linux base image
- Multi-stage build for smaller image size
- Health checks for monitoring

### Data Security
- Data persisted in host volumes
- Proper file permissions
- Environment variables for configuration
- No sensitive data in image layers

### Network Security
- Internal Docker network
- Optional Nginx reverse proxy
- Configurable port mappings
- Optional SSL/TLS termination

## 📊 Production Deployment

### With Nginx Reverse Proxy
```bash
# Enable Nginx service in docker-compose.yml
docker-compose --profile production up -d

# Configure SSL certificates
mkdir ssl
# Copy your SSL certificates to ssl/ directory
```

### With Traefik (Advanced)
The docker-compose.yml includes Traefik labels for automatic SSL:
```yaml
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.uptime-monitor.rule=Host(`uptime.yourdomain.com`)"
  - "traefik.http.routers.uptime-monitor.tls=true"
```

### Resource Limits
Add resource limits to docker-compose.yml:
```yaml
services:
  uptime-monitor:
    deploy:
      resources:
        limits:
          memory: 512M
          cpus: '0.5'
```

## 📞 Support

If you encounter issues:

1. **Check the logs:**
   ```bash
   docker-compose logs uptime-monitor
   ```

2. **Verify container status:**
   ```bash
   docker-compose ps
   ```

3. **Test the API:**
   ```bash
   curl http://localhost:3000/api/health
   ```

4. **Check system requirements:**
   - Docker Engine 20.10+
   - Docker Compose V1 or V2
   - 1GB+ free disk space
   - Internet connection

## 🎉 Getting Started

Once installed and running:

1. **Add your first server:**
   - Open `http://localhost:3000`
   - Enter server name and URL
   - Select check type (HTTPS, Ping, DNS, TCP, Cloudflare)
   - Set check interval
   - Click "Add Server"

2. **Configure alerts:**
   - Set up SMS alerts for downtime notifications
   - Configure FTP upload for public status pages

3. **Monitor your servers:**
   - View real-time status
   - Check uptime statistics
   - Review response times
   - Analyze status history

Your Uptime Monitor Pro is now running in Docker and ready to keep your servers running smoothly! 🚀
