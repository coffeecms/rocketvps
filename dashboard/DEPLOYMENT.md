# 🚀 RocketVPS Dashboard - Deployment Guide

Complete step-by-step guide for deploying the RocketVPS Dashboard to production.

---

## 📋 Table of Contents

1. [Prerequisites](#prerequisites)
2. [Installation](#installation)
3. [Configuration](#configuration)
4. [Running the Server](#running-the-server)
5. [Production Deployment](#production-deployment)
6. [Nginx Configuration](#nginx-configuration)
7. [SSL/HTTPS Setup](#sslhttps-setup)
8. [Monitoring](#monitoring)
9. [Troubleshooting](#troubleshooting)
10. [Security Checklist](#security-checklist)

---

## 1. Prerequisites

### System Requirements

- **OS:** Ubuntu 20.04+ / Debian 10+ / CentOS 8+
- **Node.js:** v18.0.0 or higher
- **npm:** v9.0.0 or higher
- **RocketVPS:** v2.2.0 installed at `/opt/rocketvps`
- **RAM:** Minimum 512MB, Recommended 1GB+
- **Disk:** 100MB for dashboard files

### Check Prerequisites

```bash
# Check Node.js version
node --version    # Should be v18+

# Check npm version
npm --version     # Should be v9+

# Check RocketVPS installation
ls -la /opt/rocketvps/modules/

# Check available memory
free -h

# Check disk space
df -h
```

### Install Node.js (if needed)

```bash
# Ubuntu/Debian
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# CentOS/RHEL
curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -
sudo yum install -y nodejs

# Verify installation
node --version
npm --version
```

---

## 2. Installation

### Step 1: Navigate to Dashboard Directory

```bash
cd /opt/rocketvps/dashboard
```

### Step 2: Install Dependencies

```bash
# Install production dependencies
npm install --production

# Or install all dependencies (including dev)
npm install
```

**Expected Output:**
```
added 65 packages in 12s

10 packages are looking for funding
  run `npm fund` for details
```

### Step 3: Verify Installation

```bash
# Check installed packages
npm list --depth=0

# Should show:
# ├── bcryptjs@2.4.3
# ├── body-parser@1.20.2
# ├── cookie-parser@1.4.6
# ├── cors@2.8.5
# ├── dotenv@16.3.1
# ├── express@4.18.2
# ├── express-rate-limit@7.1.5
# ├── helmet@7.1.0
# ├── jsonwebtoken@9.0.2
# └── socket.io@4.6.1
```

---

## 3. Configuration

### Step 1: Create Environment File

```bash
# Copy example configuration
cp .env.example .env

# Edit configuration
vim .env
```

### Step 2: Configure Environment Variables

```bash
# Server Configuration
PORT=3000
HOST=0.0.0.0

# RocketVPS Path
ROCKETVPS_PATH=/opt/rocketvps

# Security - IMPORTANT: Change in production!
JWT_SECRET=your-super-secret-jwt-key-change-this-in-production

# JWT Token Expiry
JWT_EXPIRY=24h                # Access token expiry
JWT_REFRESH_EXPIRY=7d         # Refresh token expiry

# CORS Configuration
CORS_ORIGIN=*                 # Change to your domain in production

# Rate Limiting
RATE_LIMIT_WINDOW_MS=900000   # 15 minutes
RATE_LIMIT_MAX_REQUESTS=100   # Max requests per window

# Logging
LOG_LEVEL=info
LOG_FILE=/var/log/rocketvps/dashboard.log

# WebSocket Configuration
WEBSOCKET_PING_INTERVAL=25000
WEBSOCKET_PING_TIMEOUT=60000

# Node Environment
NODE_ENV=production
```

### Step 3: Generate Secure JWT Secret

```bash
# Generate random secret
openssl rand -base64 32

# Copy output and update JWT_SECRET in .env
```

### Step 4: Update CORS Origin

```bash
# For single domain
CORS_ORIGIN=https://dashboard.yourdomain.com

# For multiple domains (comma-separated)
CORS_ORIGIN=https://dashboard.yourdomain.com,https://admin.yourdomain.com
```

### Step 5: Create Log Directory

```bash
# Create log directory
sudo mkdir -p /var/log/rocketvps

# Set permissions
sudo chown -R $USER:$USER /var/log/rocketvps

# Create log file
touch /var/log/rocketvps/dashboard.log
```

---

## 4. Running the Server

### Development Mode (with auto-reload)

```bash
# Install nodemon (if not installed)
npm install -g nodemon

# Start development server
npm run dev

# Or directly
nodemon server.js
```

**Expected Output:**
```
[nodemon] 3.0.2
[nodemon] to restart at any time, enter `rs`
[nodemon] watching path(s): *.*
[nodemon] watching extensions: js,json
[nodemon] starting `node server.js`

============================================================
🚀 RocketVPS Dashboard v2.2.0
============================================================
✅ Server running on http://0.0.0.0:3000

📡 WebSocket: Enabled
🔒 Authentication: Enabled

🌐 API Endpoints:
   Authentication:
   - POST   /api/auth/login
   ...
============================================================
```

### Production Mode

```bash
# Start server
npm start

# Or directly
node server.js
```

### Test Server

```bash
# Open browser
http://localhost:3000

# Or test with curl
curl http://localhost:3000/api/health/system
```

---

## 5. Production Deployment

### Option 1: Using PM2 (Recommended)

#### Install PM2

```bash
# Install PM2 globally
sudo npm install -g pm2

# Verify installation
pm2 --version
```

#### Start Application with PM2

```bash
# Navigate to dashboard directory
cd /opt/rocketvps/dashboard

# Start with PM2
pm2 start server.js --name rocketvps-dashboard

# Check status
pm2 status
```

**Expected Output:**
```
┌─────┬───────────────────────┬─────────┬─────────┬──────────┐
│ id  │ name                  │ mode    │ status  │ memory   │
├─────┼───────────────────────┼─────────┼─────────┼──────────┤
│ 0   │ rocketvps-dashboard   │ fork    │ online  │ 45.2mb   │
└─────┴───────────────────────┴─────────┴─────────┴──────────┘
```

#### Configure PM2 Startup Script

```bash
# Generate startup script
pm2 startup

# Copy and run the output command (starts with sudo)
# Example:
# sudo env PATH=$PATH:/usr/bin /usr/lib/node_modules/pm2/bin/pm2 startup systemd -u ubuntu --hp /home/ubuntu

# Save PM2 process list
pm2 save
```

#### PM2 Management Commands

```bash
# View logs
pm2 logs rocketvps-dashboard

# Monitor
pm2 monit

# Restart
pm2 restart rocketvps-dashboard

# Stop
pm2 stop rocketvps-dashboard

# Delete
pm2 delete rocketvps-dashboard

# List all processes
pm2 list
```

### Option 2: Using Systemd

#### Create Systemd Service

```bash
# Create service file
sudo vim /etc/systemd/system/rocketvps-dashboard.service
```

**Service Configuration:**
```ini
[Unit]
Description=RocketVPS Dashboard
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/rocketvps/dashboard
ExecStart=/usr/bin/node /opt/rocketvps/dashboard/server.js
Restart=always
RestartSec=10
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=rocketvps-dashboard
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
```

#### Enable and Start Service

```bash
# Reload systemd
sudo systemctl daemon-reload

# Enable service
sudo systemctl enable rocketvps-dashboard

# Start service
sudo systemctl start rocketvps-dashboard

# Check status
sudo systemctl status rocketvps-dashboard

# View logs
sudo journalctl -u rocketvps-dashboard -f
```

### Option 3: Using Docker

#### Create Dockerfile

```bash
# Create Dockerfile
vim /opt/rocketvps/dashboard/Dockerfile
```

**Dockerfile Content:**
```dockerfile
FROM node:18-alpine

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm install --production

# Copy application files
COPY . .

# Expose port
EXPOSE 3000

# Set environment
ENV NODE_ENV=production

# Start server
CMD ["node", "server.js"]
```

#### Build and Run

```bash
# Build image
cd /opt/rocketvps/dashboard
docker build -t rocketvps-dashboard:latest .

# Run container
docker run -d \
  --name rocketvps-dashboard \
  -p 3000:3000 \
  -v /opt/rocketvps:/opt/rocketvps \
  --restart unless-stopped \
  rocketvps-dashboard:latest

# Check logs
docker logs -f rocketvps-dashboard

# Stop container
docker stop rocketvps-dashboard

# Start container
docker start rocketvps-dashboard
```

---

## 6. Nginx Configuration

### Install Nginx

```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y nginx

# CentOS/RHEL
sudo yum install -y nginx

# Start Nginx
sudo systemctl start nginx
sudo systemctl enable nginx
```

### Configure Nginx as Reverse Proxy

```bash
# Create Nginx configuration
sudo vim /etc/nginx/sites-available/rocketvps-dashboard
```

**Basic Configuration (HTTP):**
```nginx
server {
    listen 80;
    server_name dashboard.yourdomain.com;

    # Logging
    access_log /var/log/nginx/rocketvps-dashboard-access.log;
    error_log /var/log/nginx/rocketvps-dashboard-error.log;

    # Proxy to Node.js
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # WebSocket support
    location /socket.io/ {
        proxy_pass http://localhost:3000/socket.io/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

### Enable Configuration

```bash
# Create symbolic link
sudo ln -s /etc/nginx/sites-available/rocketvps-dashboard /etc/nginx/sites-enabled/

# Test configuration
sudo nginx -t

# Reload Nginx
sudo systemctl reload nginx
```

---

## 7. SSL/HTTPS Setup

### Using Let's Encrypt (Certbot)

#### Install Certbot

```bash
# Ubuntu/Debian
sudo apt-get install -y certbot python3-certbot-nginx

# CentOS/RHEL
sudo yum install -y certbot python3-certbot-nginx
```

#### Obtain SSL Certificate

```bash
# Get certificate (automatic Nginx configuration)
sudo certbot --nginx -d dashboard.yourdomain.com

# Follow prompts:
# 1. Enter email address
# 2. Agree to terms
# 3. Choose to redirect HTTP to HTTPS (recommended: 2)
```

#### Verify SSL

```bash
# Test SSL
curl -I https://dashboard.yourdomain.com

# Should return:
# HTTP/2 200
# ...
```

#### Auto-renewal

```bash
# Test renewal
sudo certbot renew --dry-run

# Certbot auto-renewal is already set up via systemd timer
sudo systemctl status certbot.timer
```

### Manual SSL Configuration

**HTTPS Configuration:**
```nginx
server {
    listen 443 ssl http2;
    server_name dashboard.yourdomain.com;

    # SSL Certificates
    ssl_certificate /etc/letsencrypt/live/dashboard.yourdomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/dashboard.yourdomain.com/privkey.pem;

    # SSL Configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

    # Security Headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    # Logging
    access_log /var/log/nginx/rocketvps-dashboard-access.log;
    error_log /var/log/nginx/rocketvps-dashboard-error.log;

    # Proxy configuration
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # WebSocket support
    location /socket.io/ {
        proxy_pass http://localhost:3000/socket.io/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}

# HTTP redirect to HTTPS
server {
    listen 80;
    server_name dashboard.yourdomain.com;
    return 301 https://$server_name$request_uri;
}
```

---

## 8. Monitoring

### PM2 Monitoring

```bash
# Real-time monitoring
pm2 monit

# View logs
pm2 logs rocketvps-dashboard --lines 100

# View errors only
pm2 logs rocketvps-dashboard --err

# Flush logs
pm2 flush
```

### System Monitoring

```bash
# Check server status
curl http://localhost:3000/api/health/system

# Check process
ps aux | grep node

# Check port
lsof -i :3000

# Check memory
free -h

# Check disk
df -h
```

### Log Monitoring

```bash
# Dashboard logs
tail -f /var/log/rocketvps/dashboard.log

# Nginx access logs
tail -f /var/log/nginx/rocketvps-dashboard-access.log

# Nginx error logs
tail -f /var/log/nginx/rocketvps-dashboard-error.log

# System logs
sudo journalctl -u rocketvps-dashboard -f
```

---

## 9. Troubleshooting

### Issue 1: Server Won't Start

**Symptoms:** Server fails to start or exits immediately

**Solutions:**
```bash
# Check Node.js version
node --version    # Must be v18+

# Check port availability
lsof -i :3000

# Kill existing process
kill -9 $(lsof -t -i:3000)

# Check RocketVPS path
ls -la /opt/rocketvps/modules/

# Check file permissions
chmod +x server.js
chmod -R 755 /opt/rocketvps/dashboard

# Check logs
pm2 logs rocketvps-dashboard
```

### Issue 2: Authentication Errors

**Symptoms:** Login fails, token errors

**Solutions:**
```bash
# Check JWT secret is set
grep JWT_SECRET .env

# Check users.json exists
cat /opt/rocketvps/dashboard/users.json

# Reset to default user
rm users.json
npm start    # Will recreate with admin/rocketvps2025

# Check cookies are enabled in browser
```

### Issue 3: WebSocket Not Connecting

**Symptoms:** Real-time updates not working

**Solutions:**
```bash
# Check Socket.IO path
curl http://localhost:3000/socket.io/socket.io.js

# Check Nginx WebSocket config
sudo nginx -t

# Check firewall
sudo ufw status
sudo ufw allow 3000/tcp

# Check browser console for errors
```

### Issue 4: API Returns 500 Errors

**Symptoms:** API calls fail with server errors

**Solutions:**
```bash
# Check RocketVPS modules
bash -c 'source /opt/rocketvps/modules/bulk_operations.sh && discover_all_domains'

# Check file permissions
chmod -R 755 /opt/rocketvps/modules/

# Check logs
pm2 logs rocketvps-dashboard --err

# Restart server
pm2 restart rocketvps-dashboard
```

### Issue 5: High Memory Usage

**Symptoms:** Server uses too much RAM

**Solutions:**
```bash
# Check memory usage
pm2 monit

# Restart server
pm2 restart rocketvps-dashboard

# Limit memory with PM2
pm2 delete rocketvps-dashboard
pm2 start server.js --name rocketvps-dashboard --max-memory-restart 200M

# Use Redis for sessions (future enhancement)
```

---

## 10. Security Checklist

### Pre-Production Checklist

- [ ] Change default JWT_SECRET to random string
- [ ] Update CORS_ORIGIN to your domain
- [ ] Change default admin password
- [ ] Enable HTTPS (SSL certificate)
- [ ] Configure firewall (UFW/iptables)
- [ ] Set NODE_ENV=production
- [ ] Enable security headers (Helmet)
- [ ] Configure rate limiting
- [ ] Set up backup for users.json
- [ ] Enable access logs
- [ ] Configure log rotation
- [ ] Test all endpoints
- [ ] Test authentication flow
- [ ] Test WebSocket connection

### Firewall Configuration

```bash
# Enable UFW
sudo ufw enable

# Allow SSH
sudo ufw allow 22/tcp

# Allow HTTP
sudo ufw allow 80/tcp

# Allow HTTPS
sudo ufw allow 443/tcp

# Allow Node.js (if not behind Nginx)
sudo ufw allow 3000/tcp

# Check status
sudo ufw status
```

### Regular Maintenance

```bash
# Update dependencies (monthly)
npm update

# Check for vulnerabilities
npm audit

# Fix vulnerabilities
npm audit fix

# Backup users.json (daily)
cp users.json users.json.backup.$(date +%Y%m%d)

# Rotate logs (weekly)
pm2 flush

# Update SSL certificate (auto with certbot)
sudo certbot renew

# Check server status (daily)
pm2 status
curl https://dashboard.yourdomain.com/api/health/system
```

---

## 📞 Support

### Documentation
- README.md - Complete usage guide
- API Documentation - All endpoints
- This guide - Deployment instructions

### Default Credentials
```
Username: admin
Password: rocketvps2025
```

**⚠️ IMPORTANT: Change default password after first login!**

### Access URLs
```
Dashboard: https://dashboard.yourdomain.com
Login:     https://dashboard.yourdomain.com/login.html
API:       https://dashboard.yourdomain.com/api/*
```

---

## ✅ Deployment Complete!

Your RocketVPS Dashboard should now be:
- ✅ Running on production server
- ✅ Accessible via your domain
- ✅ Secured with HTTPS
- ✅ Monitored with PM2
- ✅ Protected with firewall
- ✅ Ready for production use

**Next Steps:**
1. Login with default credentials
2. Change admin password
3. Create additional users (if needed)
4. Configure backup schedule
5. Monitor server health
6. Enjoy your dashboard! 🎉

---

**Version:** 2.2.0  
**Last Updated:** October 4, 2025  
**Status:** Production Ready ✅
