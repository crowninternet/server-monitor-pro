# Uptime Monitor Pro - Docker Edition

A powerful, self-hosted server monitoring solution with SMS alerts and FTP upload capabilities, containerized with Docker and Docker Compose.

## 🚀 Quick Installation

### One-Click Install (Recommended)

```bash
# Download and run the installer
chmod +x install.sh
./install.sh
```

### Manual Installation

See [INSTALLATION.md](INSTALLATION.md) for detailed manual installation instructions.

## ✨ Features

- **Real-time Monitoring** - Monitor HTTP/HTTPS, Ping, DNS, TCP, and Cloudflare-protected sites
- **SMS Alerts** - Get instant notifications via Twilio when servers go down
- **FTP Upload** - Automatically upload public status pages to your web server
- **Persistent Storage** - File-based storage that persists across container restarts
- **Auto-start Service** - Runs automatically with Docker Compose
- **Modern UI** - Beautiful, responsive web interface
- **Drag & Drop** - Reorder servers with drag and drop
- **Status History** - Visual status charts showing uptime history
- **Recovery Tools** - Built-in recovery and troubleshooting tools
- **Containerized** - Runs in isolated Docker containers
- **Scalable** - Easy to scale and deploy

## 🎯 Getting Started

1. **Install** using the one-click installer
2. **Access** the web interface at `http://localhost:3000`
3. **Add servers** to monitor
4. **Configure SMS alerts** (optional)
5. **Set up FTP upload** (optional)

## 🛠️ Management

After installation, use the management script:

```bash
cd uptime-monitor-docker

# Start the service
./manage-uptime-monitor.sh start

# Stop the service
./manage-uptime-monitor.sh stop

# Check status
./manage-uptime-monitor.sh status

# View logs
./manage-uptime-monitor.sh logs

# Follow logs in real-time
./manage-uptime-monitor.sh logs-tail

# Test API
./manage-uptime-monitor.sh test

# Open shell in container
./manage-uptime-monitor.sh shell

# Backup data
./manage-uptime-monitor.sh backup

# Restore data
./manage-uptime-monitor.sh restore

# Uninstall
./manage-uptime-monitor.sh uninstall
```

## 📁 Project Structure

```
docker/
├── install.sh                          # One-click installer
├── INSTALLATION.md                     # Detailed installation guide
├── manage-uptime-monitor.sh.template   # Management script template
├── docker-compose.yml                  # Docker Compose configuration
├── Dockerfile                          # Docker image definition
├── test-installation.sh                # Installation validation script
└── README.md                           # This file
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
- Resource limits

### SMS Alerts (Twilio)
1. Sign up for a Twilio account
2. Get your Account SID and Auth Token
3. Purchase a phone number
4. Configure in the web interface

### FTP Upload
1. Set up FTP server credentials
2. Configure upload settings
3. Enable automatic uploads

## 📊 Monitoring Types

- **HTTPS/HTTP** - Web server monitoring with 3-strike failure detection
- **Ping** - Basic connectivity testing
- **DNS** - Domain name resolution checking
- **TCP** - Port connectivity testing
- **Cloudflare** - Specialized monitoring for Cloudflare-protected sites

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

### Common Problems
- **Port 3000 in use**: Kill the process using port 3000
- **Permission issues**: Check Docker group membership
- **Container won't start**: Check logs for error messages
- **Data not persisting**: Verify volume mounts

## 🔄 Updates

To update to a newer version:

1. Stop the containers: `docker-compose down`
2. Backup your data: `./manage-uptime-monitor.sh backup`
3. Replace the application files
4. Rebuild and restart: `docker-compose up -d --build`

## 🗑️ Uninstallation

```bash
# Complete removal
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

## 🔒 Security Features

### Container Security
- Runs as non-root user (`uptime-monitor`)
- Minimal Alpine Linux base image
- Multi-stage build for smaller image size
- Health checks for monitoring
- Resource limits

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

- Check the logs: `docker-compose logs uptime-monitor`
- Verify container status: `docker-compose ps`
- Test API: `curl http://localhost:3000/api/health`

## 📄 License

MIT License - see LICENSE file for details.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit pull requests or open issues.

---

**Uptime Monitor Pro** - Keep your servers running smoothly with Docker! 🚀
