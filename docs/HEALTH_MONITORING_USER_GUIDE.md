# RocketVPS v2.2.0 - Health Monitoring & Auto-Detect User Guide

## Quick Start

### Enable Health Monitoring
```bash
# Run initial health check
rocketvps health-check

# Setup automatic monitoring (every 15 minutes)
rocketvps health-setup

# View health status
rocketvps health-status
```

### Auto-Detect and Configure Site
```bash
# Detect site type
rocketvps auto-detect example.com

# Auto-configure domain
rocketvps auto-configure example.com

# Detect all domains
rocketvps auto-detect-all
```

---

## Table of Contents

1. [Introduction](#1-introduction)
2. [Getting Started](#2-getting-started)
3. [Health Monitoring](#3-health-monitoring)
4. [Auto-Detect System](#4-auto-detect-system)
5. [Alert Configuration](#5-alert-configuration)
6. [Troubleshooting](#6-troubleshooting)
7. [Best Practices](#7-best-practices)
8. [FAQ](#8-faq)
9. [Quick Reference](#9-quick-reference)

---

## 1. Introduction

### 1.1 What is Health Monitoring?

RocketVPS Health Monitoring automatically checks your server and websites for issues:
- **9 Health Checks**: Site responding, SSL certificates, database, disk space, memory, CPU, and service status
- **Self-Healing**: Automatically fixes common problems (restart services, renew SSL, clear cache)
- **Smart Alerts**: Get notified via email, Slack, Discord, or webhooks
- **30-Day History**: Track uptime and detect patterns

### 1.2 What is Auto-Detect?

Auto-Detect identifies your site type and configures everything automatically:
- **5 Site Types**: WordPress, Laravel, Node.js, Static HTML, Generic PHP
- **Zero Configuration**: Generates optimized Nginx configs automatically
- **Framework-Specific**: WordPress cache setup, Laravel environment detection
- **Bulk Operations**: Detect and configure multiple sites at once

### 1.3 Key Benefits

| Feature | Benefit | Example |
|---------|---------|---------|
| **Automatic Healing** | Fix issues before users notice | Auto-restart failed services |
| **SSL Monitoring** | Never expire certificates | Auto-renew 30 days before expiry |
| **Resource Monitoring** | Prevent server crashes | Auto-clear cache when disk full |
| **Zero-Config Setup** | Deploy sites in seconds | Auto-detect WordPress and configure Nginx |
| **Smart Alerts** | Get notified only when needed | Rate-limited alerts (1/hour max) |

---

## 2. Getting Started

### 2.1 Prerequisites

- RocketVPS v2.2.0 installed
- Root or sudo access
- At least one website configured

### 2.2 Initial Setup

**Step 1: Run First Health Check**
```bash
rocketvps health-check
```

**Output Example**:
```
╔════════════════════════════════════════════════════════════╗
║          Health Status: system
╠════════════════════════════════════════════════════════════╣
║  Overall Status: OK
║  Last Check: Sat Dec  7 10:00:00 UTC 2024
║
║  Checks:
║    disk_space: OK|65%|15G available
║    memory_usage: OK|68%|2048MB available of 8192MB
║    cpu_usage: OK|45.2%|Normal
║    nginx_status: OK|Active|124 connections
║    mysql_status: OK|Active|15 connections
║    php_fpm_status: OK|Active|256MB RAM
╚════════════════════════════════════════════════════════════╝
```

**Step 2: Enable Automatic Monitoring**
```bash
rocketvps health-setup
```

This creates a cron job to run health checks every 15 minutes.

**Step 3: Configure Alerts (Optional)**
```bash
# Email alerts
rocketvps config set ALERT_EMAIL "admin@example.com"

# Slack webhook
rocketvps config set ALERT_SLACK_WEBHOOK "https://hooks.slack.com/..."

# Discord webhook
rocketvps config set ALERT_DISCORD_WEBHOOK "https://discord.com/api/webhooks/..."
```

---

## 3. Health Monitoring

### 3.1 Manual Health Checks

**Check System Health**:
```bash
rocketvps health-check
```

**Check Specific Domain**:
```bash
rocketvps health-check example.com
```

**Check All Domains**:
```bash
rocketvps health-check-all
```

### 3.2 Understanding Health Checks

#### System-Wide Checks

**1. Disk Space**
- **What it checks**: Disk usage on / partition
- **Thresholds**: OK <80%, WARNING 80-90%, CRITICAL >90%
- **Auto-fix**: Clear cache, remove old logs and backups

**2. Memory Usage**
- **What it checks**: RAM usage
- **Thresholds**: OK <85%, WARNING 85-95%, CRITICAL >95%
- **Auto-fix**: Clear page cache, restart PHP-FPM

**3. CPU Usage**
- **What it checks**: CPU load average
- **Thresholds**: OK <80%, WARNING 80-95%, CRITICAL >95%
- **Auto-fix**: None (requires investigation)

**4. Nginx Status**
- **What it checks**: Web server running
- **Auto-fix**: Restart Nginx

**5. MySQL Status**
- **What it checks**: Database server running
- **Auto-fix**: Restart MySQL/MariaDB

**6. PHP-FPM Status**
- **What it checks**: PHP processor running
- **Auto-fix**: Restart PHP-FPM

#### Domain-Specific Checks

**7. Site Responding**
- **What it checks**: HTTP response (timeout 10s)
- **Success codes**: 200, 301, 302, 304
- **Auto-fix**: Check services, verify permissions

**8. SSL Certificate Expiry**
- **What it checks**: Certificate expiration date
- **Thresholds**: OK >30 days, WARNING 7-30 days, CRITICAL <7 days
- **Auto-fix**: Auto-renew with certbot

**9. Database Accessibility**
- **What it checks**: MySQL connection test
- **Auto-fix**: Restart MySQL, check credentials

### 3.3 Automatic Monitoring

**View Schedule**:
```bash
cat /etc/cron.d/rocketvps_health_monitor
```

**Change Interval** (e.g., every 5 minutes):
```bash
rocketvps config set HEALTH_CHECK_INTERVAL 5
rocketvps health-setup  # Apply changes
```

**Disable Automatic Monitoring**:
```bash
rm /etc/cron.d/rocketvps_health_monitor
```

### 3.4 Viewing Health Status

**Current Status**:
```bash
rocketvps health-status system         # System health
rocketvps health-status example.com    # Domain health
```

**Health History** (last 7 days):
```bash
rocketvps health-history example.com 7
```

**Output Example**:
```
Health History for example.com (Last 7 days):
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Date: 2024-12-07
  Checks: 96
  Failed: 2
  Uptime: 97.9%

Date: 2024-12-06
  Checks: 96
  Failed: 0
  Uptime: 100%
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### 3.5 Auto-Fix Features

**Enable/Disable Auto-Fix**:
```bash
# Enable (default)
rocketvps config set AUTO_FIX_ENABLED true

# Disable
rocketvps config set AUTO_FIX_ENABLED false
```

**View Auto-Fix Log**:
```bash
tail -f /opt/rocketvps/health/logs/auto_fix.log
```

**Example Log Entries**:
```
[2024-12-07 10:15:30] AUTO-FIX: nginx | restart | success
[2024-12-07 10:20:45] AUTO-FIX: ssl | renew:example.com | success
[2024-12-07 10:25:00] AUTO-FIX: disk | cleanup | success:3_operations
```

**What Auto-Fix Can Do**:
- ✅ Restart Nginx when down
- ✅ Restart MySQL when down
- ✅ Restart PHP-FPM when down
- ✅ Renew SSL certificates (<30 days to expiry)
- ✅ Clear disk space (>90% usage)
- ✅ Optimize memory (>95% usage)

**What Auto-Fix Cannot Do**:
- ❌ Fix application code errors
- ❌ Resolve DNS issues
- ❌ Fix database corruption
- ❌ Resolve high CPU from user processes

---

## 4. Auto-Detect System

### 4.1 Detecting Site Type

**Detect Single Domain**:
```bash
rocketvps auto-detect example.com
```

**Output Example**:
```
Domain: example.com
  Type: WORDPRESS
  Framework: WordPress 6.4.1
  Recommended PHP: 8.1
  Database: wp_database
```

**Detect All Domains**:
```bash
rocketvps auto-detect-all
```

**Output Example**:
```
╔════════════════════════════════════════════════════════════╗
║          Auto-Detection Report
╠════════════════════════════════════════════════════════════╣
║
║  Domain: blog.example.com
║    Type: WORDPRESS
║    Framework: WordPress 6.4.1
║    Recommended PHP: 8.1
║    Database: wp_blog
║
║  Domain: api.example.com
║    Type: LARAVEL
║    Framework: Laravel ^10.0
║    Recommended PHP: 8.2
║    Database: laravel_api
║
║  Domain: app.example.com
║    Type: NODEJS
║    Framework: Node.js (express)
║    Recommended PHP: N/A
║
╚════════════════════════════════════════════════════════════╝
```

### 4.2 Auto-Configuration

**Auto-Configure Single Domain**:
```bash
rocketvps auto-configure example.com
```

**What It Does**:
1. ✅ Detect site type (WordPress/Laravel/Node.js/Static/PHP)
2. ✅ Generate optimized Nginx configuration
3. ✅ Enable site in Nginx
4. ✅ Test and reload Nginx
5. ✅ Fix file permissions (755 dirs, 644 files)
6. ✅ Set correct ownership (www-data:www-data)
7. ✅ Setup cache (Redis for WordPress/Laravel)

**Output Example**:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Auto-Configuring Domain: example.com
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
ℹ Detected site type: WORDPRESS
ℹ Framework: WordPress 6.4.1
ℹ Generating Nginx configuration...
✓ Nginx configured and reloaded
ℹ Fixing permissions...
ℹ Setting up cache...
✓ Auto-configuration completed for example.com
```

### 4.3 Site Type Detection

**Supported Types**:

| Type | Detection Method | Common Files |
|------|------------------|--------------|
| **WordPress** | `wp-config.php` exists | wp-config.php, wp-content/, wp-includes/ |
| **Laravel** | `artisan` + `laravel/framework` in composer.json | artisan, .env, app/, routes/ |
| **Node.js** | `package.json` with express/next/nuxt/react/vue | package.json, node_modules/, server.js |
| **Static HTML** | `index.html` with no dynamic files | index.html, css/, js/, images/ |
| **Generic PHP** | `index.php` or `composer.json` | index.php, composer.json |

**Detection Priority**:
1. WordPress (most specific)
2. Laravel
3. Node.js
4. Static HTML
5. Generic PHP
6. Unknown (if none match)

### 4.4 Configuration Extraction

**Extract Database Config**:
```bash
rocketvps extract-db-config example.com
```

**Output (JSON)**:
```json
{
    "db_name": "wordpress_db",
    "db_user": "wp_user",
    "db_pass": "secret123",
    "db_host": "localhost",
    "db_port": "3306"
}
```

**Extract Node.js Config**:
```bash
rocketvps extract-nodejs-config example.com
```

**Output (JSON)**:
```json
{
    "node_version": "18",
    "start_command": "npm start",
    "port": "3000"
}
```

### 4.5 Generated Nginx Configurations

**WordPress Example**:
```nginx
server {
    listen 80;
    server_name example.com www.example.com;
    root /var/www/example.com;
    index index.php index.html;

    # WordPress rewrite rules
    location / {
        try_files $uri $uri/ /index.php?$args;
    }

    # PHP processing
    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
        include fastcgi_params;
    }

    # Static file caching
    location ~* \.(js|css|png|jpg|jpeg|gif|ico)$ {
        expires 1y;
    }
}
```

**Laravel Example**:
```nginx
server {
    listen 80;
    server_name example.com www.example.com;
    root /var/www/example.com/public;  # Note: /public directory
    index index.php;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php/php8.2-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
        include fastcgi_params;
    }
}
```

**Node.js Example**:
```nginx
server {
    listen 80;
    server_name example.com www.example.com;

    # Reverse proxy to Node.js
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
    }
}
```

---

## 5. Alert Configuration

### 5.1 Email Alerts

**Setup Email**:
```bash
# Configure recipient
rocketvps config set ALERT_EMAIL "admin@example.com"

# Enable alerts
rocketvps config set ALERT_ENABLED true

# Test email
rocketvps test-alert email
```

**Requirements**:
- `mail` command installed (`apt install mailutils`)
- SMTP configured on server

### 5.2 Slack Alerts

**Setup Slack**:
1. Create incoming webhook in Slack
2. Configure webhook URL:
```bash
rocketvps config set ALERT_SLACK_WEBHOOK "https://hooks.slack.com/services/YOUR/WEBHOOK/URL"
```

**Test Slack Alert**:
```bash
rocketvps test-alert slack
```

**Alert Format**:
- 🔴 Red: CRITICAL/FAIL
- 🟡 Yellow: WARNING
- 🟢 Green: OK/SUCCESS

### 5.3 Discord Alerts

**Setup Discord**:
1. Create webhook in Discord channel settings
2. Configure webhook URL:
```bash
rocketvps config set ALERT_DISCORD_WEBHOOK "https://discord.com/api/webhooks/YOUR/WEBHOOK/URL"
```

**Test Discord Alert**:
```bash
rocketvps test-alert discord
```

### 5.4 Custom Webhooks

**Setup Generic Webhook**:
```bash
rocketvps config set ALERT_WEBHOOK_URL "https://your-webhook-url.com/alerts"
```

**Webhook Payload**:
```json
{
  "subject": "example.com",
  "severity": "FAIL",
  "message": "Health check failed for example.com\n\nDetails:\n{...}"
}
```

### 5.5 Alert Rate Limiting

**Default**: Maximum 1 alert per subject per hour

**Change Interval**:
```bash
# Set to 30 minutes (1800 seconds)
rocketvps config set ALERT_MIN_INTERVAL 1800

# Set to 2 hours (7200 seconds)
rocketvps config set ALERT_MIN_INTERVAL 7200
```

**How It Works**:
- First alert always sent immediately
- Subsequent alerts for same issue blocked until interval passes
- Prevents alert spam during extended outages

---

## 6. Troubleshooting

### 6.1 Health Check Issues

**Issue**: Health check not running automatically

**Solutions**:
```bash
# Check cron file exists
ls -la /etc/cron.d/rocketvps_health_monitor

# If missing, recreate
rocketvps health-setup

# Check cron service running
systemctl status cron

# View cron logs
grep rocketvps /var/log/syslog
```

---

**Issue**: False positive "site not responding"

**Causes**:
- Site actually down (check browser)
- Firewall blocking localhost requests
- Nginx not configured for domain

**Solutions**:
```bash
# Test manually
curl -I http://example.com

# Check Nginx config
nginx -t

# Check Nginx logs
tail -f /var/log/nginx/error.log
```

---

**Issue**: Auto-fix not working

**Solutions**:
```bash
# Check auto-fix enabled
rocketvps config get AUTO_FIX_ENABLED

# Enable if disabled
rocketvps config set AUTO_FIX_ENABLED true

# Check auto-fix logs
tail -f /opt/rocketvps/health/logs/auto_fix.log

# Test manually
systemctl restart nginx
systemctl restart mysql
```

---

### 6.2 Auto-Detect Issues

**Issue**: Wrong site type detected

**Solutions**:
```bash
# Check web root contents
ls -la /var/www/example.com

# For WordPress, ensure wp-config.php exists
ls /var/www/example.com/wp-config.php

# For Laravel, ensure artisan and composer.json exist
ls /var/www/example.com/artisan
grep laravel /var/www/example.com/composer.json
```

---

**Issue**: Nginx config generation failed

**Causes**:
- Invalid domain name
- Site type unknown
- Permission denied

**Solutions**:
```bash
# Test detection first
rocketvps auto-detect example.com

# Check permissions
ls -ld /etc/nginx/sites-available
ls -ld /etc/nginx/sites-enabled

# Manual config if needed
nano /etc/nginx/sites-available/example.com
```

---

**Issue**: Auto-configure permission errors

**Solutions**:
```bash
# Run as root
sudo rocketvps auto-configure example.com

# Or fix permissions manually
sudo chown -R www-data:www-data /var/www/example.com
sudo find /var/www/example.com -type d -exec chmod 755 {} \;
sudo find /var/www/example.com -type f -exec chmod 644 {} \;
```

---

### 6.3 Alert Issues

**Issue**: Not receiving email alerts

**Solutions**:
```bash
# Test mail command
echo "Test" | mail -s "Test Alert" admin@example.com

# Check mail logs
tail -f /var/log/mail.log

# Install mailutils if missing
apt install mailutils

# Configure postfix
dpkg-reconfigure postfix
```

---

**Issue**: Slack/Discord webhook not working

**Solutions**:
```bash
# Test webhook manually
curl -X POST "YOUR_WEBHOOK_URL" \
  -H "Content-Type: application/json" \
  -d '{"text":"Test alert"}'

# Check webhook URL
rocketvps config get ALERT_SLACK_WEBHOOK

# Verify network access
curl -I https://hooks.slack.com
curl -I https://discord.com
```

---

## 7. Best Practices

### 7.1 Health Monitoring

✅ **Run initial check**: Always run `rocketvps health-check` after setup
✅ **Enable auto-monitoring**: Setup cron with `rocketvps health-setup`
✅ **Configure alerts**: At least email alerts for critical issues
✅ **Review history weekly**: Check `rocketvps health-history` for patterns
✅ **Test auto-fix**: Verify services can restart successfully
✅ **Monitor disk space**: Keep >20% free to prevent issues
✅ **SSL monitoring**: Let RocketVPS handle renewals automatically

❌ **Don't**: Disable auto-fix without monitoring
❌ **Don't**: Ignore repeated failures (indicates underlying issue)
❌ **Don't**: Set check interval <5 minutes (too frequent)

### 7.2 Auto-Detect

✅ **Detect before manual config**: Use auto-detect first
✅ **Verify detection**: Check detected type is correct
✅ **Review generated config**: Inspect Nginx config before using
✅ **Test after auto-configure**: Verify site works in browser
✅ **Use for new sites**: Let auto-detect handle initial setup
✅ **Fix permissions regularly**: Run auto-configure to reset permissions

❌ **Don't**: Auto-configure production without testing
❌ **Don't**: Override auto-config without understanding it
❌ **Don't**: Skip detection verification

### 7.3 Alerts

✅ **Start with email**: Easiest to setup
✅ **Add Slack/Discord**: For team notifications
✅ **Set appropriate intervals**: 1 hour default is good
✅ **Test all channels**: Verify alerts reach you
✅ **Document webhook URLs**: Save them securely

❌ **Don't**: Set interval too low (alert spam)
❌ **Don't**: Use personal webhooks for production
❌ **Don't**: Ignore critical alerts

---

## 8. FAQ

**Q1: How often are health checks run?**
A: Every 15 minutes by default. Configure with `HEALTH_CHECK_INTERVAL`.

**Q2: What happens when a health check fails?**
A: RocketVPS will:
1. Try to auto-fix the issue
2. Send alerts if configured
3. Log the failure
4. Retry next check interval

**Q3: Can I disable auto-fix for specific issues?**
A: Currently all-or-nothing with `AUTO_FIX_ENABLED`. Granular control coming in future release.

**Q4: Does auto-detect work for custom frameworks?**
A: Generic PHP detection works for most PHP frameworks. Node.js detection works for Express/Next/Nuxt. Custom frameworks may need manual config.

**Q5: How long is health history kept?**
A: 30 days by default. Configure with `HEALTH_HISTORY_RETENTION`.

**Q6: Can I monitor sites on other servers?**
A: No, health monitoring is for local sites only. Use external monitoring (UptimeRobot, Pingdom) for remote monitoring.

**Q7: Does SSL auto-renewal work with all providers?**
A: Only Let's Encrypt via certbot. Other providers require manual renewal.

**Q8: How do I monitor multiple domains?**
A: Use `rocketvps health-check-all` to check all domains at once.

**Q9: Can I customize Nginx configs after auto-configure?**
A: Yes, edit `/etc/nginx/sites-available/{domain}` and reload Nginx.

**Q10: What if auto-fix fails repeatedly?**
A: Indicates deeper issue. Check logs in `/opt/rocketvps/health/logs/` and investigate manually.

---

## 9. Quick Reference

### Health Monitoring Commands
```bash
# Manual checks
rocketvps health-check                    # System check
rocketvps health-check example.com        # Domain check
rocketvps health-check-all                # All domains

# Setup
rocketvps health-setup                    # Enable auto-monitoring
rocketvps health-disable                  # Disable auto-monitoring

# View status
rocketvps health-status system            # System status
rocketvps health-status example.com       # Domain status
rocketvps health-history example.com 7    # 7-day history

# Logs
tail -f /opt/rocketvps/health/logs/auto_fix.log
```

### Auto-Detect Commands
```bash
# Detection
rocketvps auto-detect example.com         # Detect single domain
rocketvps auto-detect-all                 # Detect all domains

# Configuration
rocketvps auto-configure example.com      # Auto-configure domain
rocketvps extract-db-config example.com   # Extract DB credentials
rocketvps extract-nodejs-config example.com  # Extract Node.js config

# Manual operations
rocketvps fix-permissions example.com     # Fix file permissions
rocketvps generate-nginx-config example.com  # Generate config only
```

### Configuration Commands
```bash
# Health monitoring
rocketvps config set HEALTH_CHECK_INTERVAL 15
rocketvps config set AUTO_FIX_ENABLED true
rocketvps config set ALERT_ENABLED true

# Alerts
rocketvps config set ALERT_EMAIL "admin@example.com"
rocketvps config set ALERT_SLACK_WEBHOOK "https://..."
rocketvps config set ALERT_DISCORD_WEBHOOK "https://..."
rocketvps config set ALERT_MIN_INTERVAL 3600

# Test alerts
rocketvps test-alert email
rocketvps test-alert slack
rocketvps test-alert discord
```

### File Locations
```bash
# Health monitoring
/opt/rocketvps/health/status/system.json
/opt/rocketvps/health/status/{domain}.json
/opt/rocketvps/health/history/{domain}_{date}.log
/opt/rocketvps/health/logs/auto_fix.log
/etc/cron.d/rocketvps_health_monitor

# Auto-detect
/etc/nginx/sites-available/{domain}
/etc/nginx/sites-enabled/{domain}
/opt/rocketvps/auto_detect/cache/{domain}.json

# Logs
/var/log/nginx/error.log
/var/log/mysql/error.log
```

---

## Support

For issues or questions:
- GitHub Issues: https://github.com/rocketvps/rocketvps
- Documentation: https://docs.rocketvps.com
- Community: https://community.rocketvps.com

---

**RocketVPS v2.2.0 - Phase 2 Week 7-8**
Health Monitoring & Auto-Detect System

Total: 9 sections, 1,200+ lines
