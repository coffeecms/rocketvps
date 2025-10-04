# RocketVPS Documentation

## Table of Contents

1. [Quick Start Guide](#quick-start-guide)
2. [Feature Guides](#feature-guides)
3. [Configuration](#configuration)
4. [Troubleshooting](#troubleshooting)
5. [Advanced Usage](#advanced-usage)

## Quick Start Guide

### Installation

```bash
curl -sSL https://raw.githubusercontent.com/yourusername/rocketvps/main/install.sh | sudo bash
```

### First Steps

After installation, run:

```bash
rocketvps
```

### Basic Workflow

1. **Install Nginx** (Menu 1 → Option 1)
2. **Add Domain** (Menu 2 → Option 1)
3. **Install SSL** (Menu 3 → Option 2)
4. **Apply Security** (Menu 12 → Option 1)

---

## Feature Guides

### 1. Nginx Management

#### Install Nginx

```bash
rocketvps → 1 → 1
```

Features:
- Installs latest stable version from official repository
- Configures optimal defaults
- Sets up log directories

#### Upgrade Nginx

```bash
rocketvps → 1 → 2
```

Safe upgrade process:
- Backs up configuration
- Stops service gracefully
- Upgrades packages
- Restores configuration
- Restarts service

#### Optimize Nginx

```bash
rocketvps → 1 → 3
```

Automatic optimization based on:
- CPU cores
- Available RAM
- Current connections

---

### 2. Domain Management

#### Add Domain

**Static HTML Site:**
```bash
rocketvps → 2 → 1 → Static → example.com
```

**WordPress Site:**
```bash
rocketvps → 2 → 1 → WordPress → example.com
```

**Laravel Site:**
```bash
rocketvps → 2 → 1 → Laravel → example.com
```

**Node.js Application:**
```bash
rocketvps → 2 → 1 → Node.js → example.com → Port (e.g., 3000)
```

#### Edit Domain

```bash
rocketvps → 2 → 3
```

Modify:
- Document root
- PHP version
- Caching rules
- SSL settings

#### Delete Domain

```bash
rocketvps → 2 → 4
```

Options:
- Keep files (only remove Nginx config)
- Delete all files (remove everything)

---

### 3. SSL Management

#### Install SSL Certificate

```bash
rocketvps → 3 → 2 → Select Domain → Enter Email
```

Process:
1. Verifies domain points to server
2. Requests certificate from Let's Encrypt
3. Configures Nginx for SSL
4. Sets up automatic renewal

#### Setup Auto-Renewal

```bash
rocketvps → 3 → 5
```

Creates cron job to renew every 7 days.

#### Force Renew SSL

```bash
rocketvps → 3 → 7
```

Manually renew specific domain certificate.

---

### 4. Cache Management (Redis)

#### Install Redis

```bash
rocketvps → 4 → 1
```

Includes:
- Latest stable Redis
- Optimized configuration
- Password authentication
- Persistence enabled

#### Configure Redis

```bash
rocketvps → 4 → 3
```

Optimization based on:
- Available memory
- Use case (caching vs persistence)
- Connection limits

#### Using Redis

**WordPress:**
```bash
# Install Redis plugin
wp plugin install redis-cache --activate

# Configure wp-config.php
define('WP_REDIS_HOST', '127.0.0.1');
define('WP_REDIS_PORT', 6379);
define('WP_REDIS_PASSWORD', 'your-password');
```

**Laravel:**
```env
# .env file
REDIS_HOST=127.0.0.1
REDIS_PASSWORD=your-password
REDIS_PORT=6379
```

---

### 5. PHP Management

#### Install Multiple PHP Versions

```bash
# Install PHP 8.2
rocketvps → 5 → 1 → 4

# Install PHP 7.4
rocketvps → 5 → 1 → 1

# Install PHP 8.3
rocketvps → 5 → 1 → 5
```

#### Set PHP Version for Domain

```bash
rocketvps → 5 → 4 → example.com → 8.2
```

This updates the Nginx configuration to use PHP 8.2 for example.com.

#### Install PHP Extensions

```bash
rocketvps → 5 → 5 → Select PHP Version
```

Common extensions:
- mysqli, pdo_mysql (database)
- curl (HTTP requests)
- gd, imagick (image processing)
- mbstring (multibyte strings)
- xml (XML processing)
- zip (compression)

#### Configure PHP-FPM

```bash
rocketvps → 5 → 7
```

Optimizes:
- pm.max_children
- pm.start_servers
- pm.min_spare_servers
- pm.max_spare_servers

Based on available RAM.

---

### 6. Database Management

#### Install Database

**MariaDB (Recommended):**
```bash
rocketvps → 6 → 1 → 1
```

**MySQL:**
```bash
rocketvps → 6 → 1 → 2
```

**PostgreSQL:**
```bash
rocketvps → 6 → 1 → 3
```

#### Create Database

```bash
rocketvps → 6 → 3
```

Creates:
- New database
- Dedicated user with full privileges
- Random secure password

#### Backup Database

**Single Database:**
```bash
rocketvps → 6 → 5 → Select Database
```

**All Databases:**
```bash
rocketvps → 6 → 6
```

**Setup Automatic Backup:**
```bash
rocketvps → 6 → 7 → Select Schedule → Select Destination
```

Destinations:
- Local storage
- Google Drive
- Amazon S3

#### Restore Database

**From Local:**
```bash
rocketvps → 6 → 8 → Select Backup
```

**From Google Drive:**
```bash
rocketvps → 6 → 9
```

**From S3:**
```bash
rocketvps → 6 → 10
```

---

### 7. FTP Management

#### Add FTP User

```bash
rocketvps → 7 → 1 → example.com → username
```

Creates:
- System user
- Home directory (domain root)
- Restricted access

#### Connect via FTP

```
Host: your-server-ip
Port: 21
Username: ftpuser_example
Password: (generated password)
```

#### Change FTP Password

```bash
rocketvps → 7 → 3
```

---

### 8. CSF Firewall

#### Install CSF

```bash
rocketvps → 8 → 1
```

Default ports opened:
- 20,21 (FTP)
- 22 (SSH)
- 25 (SMTP)
- 53 (DNS)
- 80 (HTTP)
- 443 (HTTPS)
- 3306 (MySQL)
- 5432 (PostgreSQL)

#### Block IP Address

```bash
rocketvps → 8 → 3 → Enter IP
```

#### Unblock IP Address

```bash
rocketvps → 8 → 4 → Enter IP
```

#### Manage Ports

**Open Port:**
```bash
rocketvps → 8 → 7 → Enter Port
```

**Close Port:**
```bash
rocketvps → 8 → 8 → Enter Port
```

---

### 9. Permission Management

#### Fix WordPress Permissions

```bash
rocketvps → 9 → 3 → Select Domain
```

Sets:
- 755 for directories
- 644 for files
- 640 for wp-config.php
- 775 for wp-content/uploads

#### Fix Laravel Permissions

```bash
rocketvps → 9 → 4 → Select Domain
```

Sets:
- 755 for directories
- 644 for files
- 775 for storage/
- 775 for bootstrap/cache/
- 640 for .env

#### Auto-Detect and Fix

```bash
rocketvps → 9 → 7
```

Automatically detects framework and applies appropriate permissions.

---

### 10. Backup & Restore

#### Backup Single Domain

```bash
rocketvps → 10 → 1 → Select Domain
```

Backs up:
- Website files
- Database (if linked)
- Nginx configuration

#### Schedule Automatic Backups

```bash
rocketvps → 10 → 5
```

Options:
- Daily at specific time
- Weekly on specific day
- Monthly on specific date

Retention: 7 days (configurable)

#### Restore Domain

```bash
rocketvps → 10 → 6 → Select Backup
```

Process:
1. Stops Nginx
2. Removes current files
3. Extracts backup
4. Restores database
5. Fixes permissions
6. Starts Nginx

---

### 11. Cronjob Management

#### Add Cronjob

```bash
rocketvps → 11 → 1
```

Presets:
- Every minute
- Hourly
- Daily
- Weekly
- Monthly
- Custom

#### Predefined Cronjobs

```bash
rocketvps → 11 → 2
```

Templates:
1. Clear cache (WordPress)
2. Renew SSL certificates
3. Database optimization
4. Clean old logs
5. Update system packages
6. Backup databases
7. Backup websites
8. Run security scan

---

### 12. Security Enhancement

#### Apply Security Level

**Basic Security:**
```bash
rocketvps → 12 → 1 → 1
```

Includes:
- Firewall configuration
- Automatic updates
- Basic SSH hardening

**Medium Security (Recommended):**
```bash
rocketvps → 12 → 1 → 2
```

Includes:
- All Basic features
- Fail2Ban installation
- Root login disabled
- SSH key authentication
- Database hardening

**Advanced Security:**
```bash
rocketvps → 12 → 1 → 3
```

Includes:
- All Medium features
- ModSecurity WAF
- Intrusion detection
- Advanced firewall rules
- Regular security audits

#### SSH Hardening

```bash
rocketvps → 12 → 2
```

Changes:
- Protocol 2 only
- No root login
- Max auth tries: 3
- Password authentication disabled
- SSH keys required

#### Fail2Ban Setup

```bash
rocketvps → 12 → 3
```

Protects against:
- SSH brute force
- Nginx unauthorized access
- WordPress login attacks
- Database brute force

#### Malware Scan

```bash
rocketvps → 12 → 6
```

Scans:
- Web directories
- Home directories
- Temporary directories

Uses ClamAV for detection.

#### Security Audit

```bash
rocketvps → 12 → 9
```

Checks:
- Open ports
- Running services
- User accounts
- File permissions
- Security updates
- Firewall status
- SSL certificates

---

## Configuration

### Configuration Files

```
/opt/rocketvps/config/
├── domains.list          # List of managed domains
├── php_versions.conf     # PHP version mappings
├── database.conf         # Database credentials
└── cloud_backup.conf     # Cloud backup settings
```

### Nginx Configuration

Main config: `/etc/nginx/nginx.conf`
Sites: `/etc/nginx/sites-available/`
Enabled: `/etc/nginx/sites-enabled/`

### PHP Configuration

PHP-FPM pools: `/etc/php/{version}/fpm/pool.d/`
PHP.ini: `/etc/php/{version}/fpm/php.ini`

### Database Configuration

MariaDB/MySQL: `/etc/mysql/my.cnf`
PostgreSQL: `/etc/postgresql/{version}/main/postgresql.conf`

---

## Troubleshooting

### Nginx Won't Start

**Check configuration:**
```bash
nginx -t
```

**Check logs:**
```bash
rocketvps → 13 → 2 → Nginx Errors
```

**Common issues:**
- Port already in use
- Configuration syntax error
- SSL certificate missing

### SSL Certificate Fails

**Verify domain points to server:**
```bash
dig +short yourdomain.com
```

**Check Certbot logs:**
```bash
cat /var/log/letsencrypt/letsencrypt.log
```

**Common issues:**
- Domain not pointing to server
- Port 80 blocked
- Rate limit reached (5 per week)

### PHP Errors

**Check PHP-FPM status:**
```bash
systemctl status php{version}-fpm
```

**Check PHP logs:**
```bash
rocketvps → 13 → 2 → PHP Errors
```

**Common issues:**
- Socket permission denied
- PHP-FPM not running
- Memory limit reached

### Database Connection Failed

**Check database service:**
```bash
systemctl status mysql  # or mariadb or postgresql
```

**Test connection:**
```bash
mysql -u username -p
```

**Common issues:**
- Wrong credentials
- Database not running
- User permissions

### Backup Fails

**Check disk space:**
```bash
df -h
```

**Check backup logs:**
```bash
cat /opt/rocketvps/logs/auto_backup.log
```

**Common issues:**
- Insufficient disk space
- Permission denied
- Cloud credentials expired

---

## Advanced Usage

### Custom Nginx Configuration

Edit domain config:
```bash
nano /etc/nginx/sites-available/yourdomain.com
```

Test configuration:
```bash
nginx -t
```

Reload Nginx:
```bash
systemctl reload nginx
```

### Custom PHP Configuration

Edit PHP-FPM pool:
```bash
nano /etc/php/8.2/fpm/pool.d/www.conf
```

Restart PHP-FPM:
```bash
systemctl restart php8.2-fpm
```

### Database Tuning

MySQL/MariaDB:
```bash
nano /etc/mysql/my.cnf
```

Add under `[mysqld]`:
```ini
innodb_buffer_pool_size = 1G
max_connections = 200
query_cache_size = 32M
```

Restart:
```bash
systemctl restart mysql
```

### Custom Firewall Rules

Edit CSF configuration:
```bash
nano /etc/csf/csf.conf
```

Common settings:
- `TCP_IN`: Incoming TCP ports
- `TCP_OUT`: Outgoing TCP ports
- `DENY_IP_LIMIT`: Max denied IPs
- `LF_TRIGGER`: Login failure threshold

Apply changes:
```bash
csf -r
```

### Monitoring

**Install monitoring tools:**
```bash
apt install htop iotop nethogs
```

**Monitor in real-time:**
```bash
# CPU and memory
htop

# Disk I/O
iotop

# Network usage
nethogs

# Nginx connections
watch -n 1 'netstat -an | grep :80 | wc -l'
```

---

## Support

- **Documentation**: https://github.com/yourusername/rocketvps/wiki
- **Issues**: https://github.com/yourusername/rocketvps/issues
- **Discussions**: https://github.com/yourusername/rocketvps/discussions

---

**Last Updated**: 2025-10-03
**Version**: 1.0.0
