# 🚀 RocketVPS Quick Reference

## Installation

```bash
curl -sSL https://raw.githubusercontent.com/yourusername/rocketvps/main/install.sh | sudo bash
```

## Quick Commands

```bash
# Run RocketVPS
rocketvps

# Or with sudo
sudo rocketvps
```

---

## Menu Quick Reference

### 1️⃣ Nginx Management
- **1** → Install Nginx
- **2** → Upgrade Nginx
- **3** → Optimize Nginx
- **5** → Restart Nginx
- **6** → Reload Nginx

### 2️⃣ Domain Management
- **1** → Add Domain (Static/PHP/WordPress/Laravel/Node.js)
- **2** → List Domains
- **3** → Edit Domain
- **4** → Delete Domain
- **5** → Enable Domain
- **6** → Disable Domain

### 3️⃣ SSL Management
- **1** → Install Certbot
- **2** → Install SSL for Domain
- **3** → List SSL Certificates
- **5** → Setup Auto-Renewal (every 7 days)
- **7** → Force Renew SSL

### 4️⃣ Cache Management (Redis)
- **1** → Install Redis
- **2** → Upgrade Redis
- **3** → Configure Redis
- **4** → Optimize Redis
- **8** → Flush Cache

### 5️⃣ PHP Management
- **1** → Install PHP (7.4/8.0/8.1/8.2/8.3)
- **3** → Set Default PHP Version
- **4** → Set PHP Version for Domain
- **5** → Install PHP Extensions
- **7** → Configure PHP-FPM
- **8** → Optimize PHP

### 6️⃣ Database Management
- **1** → Install Database (MariaDB/MySQL/PostgreSQL)
- **3** → Create Database
- **4** → Delete Database
- **5** → Backup Single Database
- **6** → Backup All Databases
- **7** → Setup Auto Backup
- **8** → Restore from Local
- **9** → Restore from Google Drive
- **10** → Restore from S3

### 7️⃣ FTP Management
- **1** → Add FTP User
- **2** → List FTP Users
- **3** → Change FTP Password
- **4** → Delete FTP User
- **5** → Enable FTP User
- **6** → Disable FTP User

### 8️⃣ CSF Firewall
- **1** → Install CSF
- **2** → Configure CSF
- **3** → Block IP
- **4** → Unblock IP
- **5** → Unblock All IPs
- **7** → Open Port
- **8** → Close Port

### 9️⃣ Permission Management
- **1** → View Permissions
- **2** → Apply Secure Permissions (755/644)
- **3** → Fix WordPress Permissions
- **4** → Fix Laravel Permissions
- **7** → Auto-Detect and Fix

### 🔟 Backup & Restore
- **1** → Backup Single Domain
- **2** → Backup All Domains
- **3** → Backup to Google Drive
- **4** → Backup to S3
- **5** → Schedule Backups
- **6** → Restore from Local
- **7** → Restore from Google Drive
- **8** → Restore from S3

### 1️⃣1️⃣ Cronjob Management
- **1** → Add Cronjob
- **2** → Add Predefined Cronjob
  - Clear Cache
  - Renew SSL
  - Optimize Database
  - Clean Logs
  - Update System
  - Backup Databases
  - Backup Websites
  - Security Scan
- **3** → List Cronjobs
- **4** → Delete Cronjob

### 1️⃣2️⃣ Security Enhancement
- **1** → Apply Security Level
  - **Basic**: Firewall + Updates
  - **Medium**: + Fail2Ban + SSH Hardening
  - **Advanced**: + ModSecurity + IDS
- **2** → SSH Hardening
- **3** → Setup Fail2Ban
- **4** → Install ModSecurity
- **6** → Scan for Malware
- **9** → Run Security Audit

### 1️⃣3️⃣ System Utilities
- **1** → Show System Info
- **2** → View Logs
- **3** → Server Health Check
- **4** → Clean Temp Files
- **7** → Update RocketVPS

---

## Common Tasks

### 🌐 Add New Website

```bash
rocketvps
↓
2 (Domain Management)
↓
1 (Add Domain)
↓
Enter domain name: example.com
↓
Select type: 3 (WordPress)
```

### 🔒 Setup SSL

```bash
rocketvps
↓
3 (SSL Management)
↓
2 (Install SSL)
↓
Select domain
↓
Enter email
```

### 🐘 Install PHP 8.2

```bash
rocketvps
↓
5 (PHP Management)
↓
1 (Install PHP)
↓
4 (PHP 8.2)
```

### 💾 Create Database

```bash
rocketvps
↓
6 (Database Management)
↓
3 (Create Database)
↓
Enter database name
↓
Enter username
```

### 🛡️ Apply Security

```bash
rocketvps
↓
12 (Security)
↓
1 (Apply Security Level)
↓
2 (Medium - Recommended)
```

### 💾 Setup Auto Backup

```bash
rocketvps
↓
10 (Backup & Restore)
↓
5 (Schedule Backups)
↓
Select schedule
↓
Select destination (Local/Google Drive/S3)
```

---

## File Locations

### RocketVPS Files
```
/opt/rocketvps/                 # Main directory
├── rocketvps.sh               # Main script
├── modules/*.sh               # Feature modules
├── config/                    # Configuration
├── backups/                   # Local backups
└── logs/                      # Log files
```

### Nginx Files
```
/etc/nginx/nginx.conf          # Main config
/etc/nginx/sites-available/    # Available sites
/etc/nginx/sites-enabled/      # Enabled sites
/var/log/nginx/                # Nginx logs
```

### PHP Files
```
/etc/php/{version}/fpm/php.ini              # PHP config
/etc/php/{version}/fpm/pool.d/www.conf      # PHP-FPM pool
/var/log/php{version}-fpm.log               # PHP logs
```

### Database Files
```
/etc/mysql/my.cnf              # MySQL/MariaDB config
/var/lib/mysql/                # MySQL data
/var/log/mysql/                # MySQL logs
```

### SSL Files
```
/etc/letsencrypt/              # SSL certificates
/var/log/letsencrypt/          # Certbot logs
```

---

## Configuration Files

### Domain List
```bash
cat /opt/rocketvps/config/domains.list
```

### PHP Versions
```bash
cat /opt/rocketvps/config/php_versions.conf
```

### Database Credentials
```bash
cat /opt/rocketvps/config/database.conf
```

### Cloud Backup Settings
```bash
cat /opt/rocketvps/config/cloud_backup.conf
```

---

## Log Files

### RocketVPS Main Log
```bash
tail -f /opt/rocketvps/logs/rocketvps.log
```

### SSL Renewal Log
```bash
tail -f /opt/rocketvps/logs/ssl_renewal.log
```

### Auto Backup Log
```bash
tail -f /opt/rocketvps/logs/auto_backup.log
```

### Nginx Error Log
```bash
tail -f /var/log/nginx/error.log
```

### Nginx Access Log
```bash
tail -f /var/log/nginx/access.log
```

---

## Troubleshooting

### Check Nginx Configuration
```bash
nginx -t
```

### Check Nginx Status
```bash
systemctl status nginx
```

### Check PHP-FPM Status
```bash
systemctl status php8.2-fpm
```

### Check Database Status
```bash
systemctl status mysql
# or
systemctl status mariadb
# or
systemctl status postgresql
```

### Check Redis Status
```bash
systemctl status redis
```

### Check CSF Status
```bash
csf -l
```

### Check Disk Space
```bash
df -h
```

### Check Memory Usage
```bash
free -h
```

### Check Running Processes
```bash
htop
```

---

## Common Port Numbers

- **20-21**: FTP
- **22**: SSH
- **25**: SMTP
- **53**: DNS
- **80**: HTTP
- **443**: HTTPS
- **3306**: MySQL/MariaDB
- **5432**: PostgreSQL
- **6379**: Redis

---

## Security Checklist

- ✅ Apply Medium or Advanced Security
- ✅ Enable SSL for all domains
- ✅ Disable root SSH login
- ✅ Configure firewall (CSF)
- ✅ Setup Fail2Ban
- ✅ Enable automatic backups
- ✅ Change default passwords
- ✅ Keep system updated
- ✅ Monitor logs regularly
- ✅ Run security audits

---

## Backup Schedule Recommendations

### WordPress Sites
- **Daily**: Full backup at 2 AM
- **Retention**: 7 days
- **Destination**: Google Drive or S3

### E-commerce Sites
- **Every 6 hours**: Database backup
- **Daily**: Full backup at 2 AM
- **Retention**: 14 days
- **Destination**: Google Drive AND S3 (dual)

### Static Sites
- **Weekly**: Full backup on Sunday at 2 AM
- **Retention**: 30 days
- **Destination**: Local

---

## Performance Optimization Tips

### Nginx
```bash
rocketvps → 1 → 3 (Optimize Nginx)
```
- Worker processes = CPU cores
- Worker connections = 1024+
- Gzip compression enabled
- FastCGI caching

### PHP
```bash
rocketvps → 5 → 8 (Optimize PHP)
```
- OPcache enabled
- PHP-FPM pool optimized
- Memory limits adjusted

### Redis
```bash
rocketvps → 4 → 4 (Optimize Redis)
```
- Maxmemory = 25% of RAM
- LRU eviction policy
- Persistence enabled

### Database
```bash
rocketvps → 6 → 12 (Optimize Database)
```
- InnoDB buffer pool optimized
- Query cache enabled
- Slow query log enabled

---

## Support & Resources

### Documentation
- **Quick Start**: README.md
- **Full Guide**: DOCUMENTATION.md
- **Security**: SECURITY.md
- **Contributing**: CONTRIBUTING.md

### Online
- **GitHub**: https://github.com/yourusername/rocketvps
- **Issues**: https://github.com/yourusername/rocketvps/issues
- **Discussions**: https://github.com/yourusername/rocketvps/discussions

### Commands
```bash
# View help
rocketvps --help

# Check version
rocketvps --version

# Update RocketVPS
rocketvps
# Then: 13 → 7
```

---

## Version Information

**Current Version**: 1.0.0  
**Release Date**: 2025-10-03  
**License**: MIT  

---

**🚀 RocketVPS - Professional VPS Management Made Simple**

For detailed documentation, see: [DOCUMENTATION.md](DOCUMENTATION.md)
