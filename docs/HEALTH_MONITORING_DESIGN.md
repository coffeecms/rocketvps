# RocketVPS v2.2.0 - Health Monitoring & Auto-Detect Design

## Document Information
- **Version**: 2.2.0
- **Phase**: 2 Week 7-8
- **Date**: December 2024
- **Status**: Implementation Complete

---

## Table of Contents

1. [Overview](#overview)
2. [Health Monitoring System Architecture](#health-monitoring-system-architecture)
3. [Health Checks Specification](#health-checks-specification)
4. [Auto-Fix Implementation](#auto-fix-implementation)
5. [Alert System](#alert-system)
6. [Auto-Detect System](#auto-detect-system)
7. [Configuration Extraction](#configuration-extraction)
8. [Auto-Configuration Engine](#auto-configuration-engine)
9. [Data Structures](#data-structures)
10. [Function Specifications](#function-specifications)
11. [Performance Targets](#performance-targets)
12. [Testing Strategy](#testing-strategy)

---

## 1. Overview

### 1.1 Purpose
The Health Monitoring & Auto-Detect system provides intelligent monitoring of server and website health with automatic healing capabilities and smart site type detection with auto-configuration.

### 1.2 Key Features

#### Health Monitoring
- **9 Comprehensive Health Checks**: Site responding, SSL expiry, database, disk, memory, CPU, Nginx, MySQL, PHP-FPM
- **Automatic Healing**: Auto-restart services, auto-renew SSL, auto-clear cache, auto-optimize database
- **Multi-Channel Alerts**: Email, webhooks, Slack, Discord with rate limiting
- **History Tracking**: 30-day health history with uptime statistics
- **Scheduling**: Automatic cron-based monitoring every 15 minutes

#### Auto-Detect System
- **5 Site Type Detection**: WordPress, Laravel, Node.js, Static HTML, Generic PHP
- **Framework Detection**: Identify specific frameworks and versions
- **Configuration Extraction**: Extract database credentials, Node.js config
- **Auto-Configuration**: Generate optimized Nginx configs, fix permissions, setup cache
- **Bulk Operations**: Detect and report all domains at once

### 1.3 Benefits
- **Proactive Monitoring**: Catch issues before users notice
- **Self-Healing**: Automatic recovery from common failures
- **Reduced Downtime**: Quick response to service failures
- **Zero Configuration**: Automatic detection and setup of new sites
- **Optimized Performance**: Framework-specific optimizations

---

## 2. Health Monitoring System Architecture

### 2.1 System Components

```
┌─────────────────────────────────────────────────────────────┐
│                   Health Monitoring System                   │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │  Health      │  │   Auto-Fix   │  │   Alert      │      │
│  │  Checks      │─▶│   Engine     │─▶│   System     │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
│         │                  │                  │              │
│         ▼                  ▼                  ▼              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │  Status      │  │  Auto-Fix    │  │  Email/      │      │
│  │  Storage     │  │  Logs        │  │  Webhooks    │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
│         │                                                     │
│         ▼                                                     │
│  ┌──────────────┐                                           │
│  │  History     │                                           │
│  │  Tracking    │                                           │
│  └──────────────┘                                           │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

### 2.2 Directory Structure

```
/opt/rocketvps/
├── health/
│   ├── status/                  # Current health status (JSON)
│   │   ├── system.json          # System-wide health
│   │   └── {domain}.json        # Per-domain health
│   ├── history/                 # Historical health data
│   │   └── {domain}_{date}.log  # Daily health logs
│   ├── logs/                    # Auto-fix action logs
│   │   └── auto_fix.log         # All auto-fix actions
│   └── .last_alert_{subject}    # Alert rate limiting
└── modules/
    └── health_monitor.sh         # Main module (1,100+ lines)
```

### 2.3 Data Flow

```
User/Cron
   │
   ▼
Health Check Scheduler (Every 15 min)
   │
   ▼
Run All Checks (System + Domain)
   │
   ├──▶ Disk Space Check ──┐
   ├──▶ Memory Check ──────┤
   ├──▶ CPU Check ─────────┤
   ├──▶ Service Checks ────┤
   ├──▶ Site Checks ───────┤
   ├──▶ SSL Checks ────────┤
   └──▶ Database Checks ───┤
                           │
                           ▼
                    Results Analysis
                           │
                ┌──────────┴──────────┐
                │                     │
              PASS                  FAIL
                │                     │
                ▼                     ▼
         Save to History    ┌────────────────┐
                            │ Trigger        │
                            │ Auto-Fix       │
                            └────────┬───────┘
                                     │
                            ┌────────┴────────┐
                            │                 │
                         Success           Failed
                            │                 │
                            ▼                 ▼
                    Send Success Alert  Send Failure Alert
                            │                 │
                            └────────┬────────┘
                                     ▼
                              Update History
```

---

## 3. Health Checks Specification

### 3.1 System-Wide Health Checks

#### Check 1: Disk Space
**Purpose**: Monitor disk usage and prevent disk full issues

**Thresholds**:
- OK: < 80% usage
- WARNING: 80-90% usage
- CRITICAL: > 90% usage

**Output Format**: `STATUS|USAGE%|AVAILABLE_INFO`

**Example**:
```
OK|65%|15G available
WARNING|82%|8.5G available
CRITICAL|94%|2.1G available
```

**Auto-Fix**: Clear cache, remove old logs, cleanup old backups

---

#### Check 2: Memory Usage
**Purpose**: Monitor RAM usage and prevent OOM (Out of Memory) situations

**Thresholds**:
- OK: < 85% usage
- WARNING: 85-95% usage
- CRITICAL: > 95% usage

**Output Format**: `STATUS|USAGE%|AVAILABLE_INFO`

**Example**:
```
OK|68%|2048MB available of 8192MB
WARNING|87%|512MB available of 8192MB
CRITICAL|97%|256MB available of 8192MB
```

**Auto-Fix**: Clear page cache, restart PHP-FPM to free memory

---

#### Check 3: CPU Usage
**Purpose**: Monitor CPU load and detect high load situations

**Thresholds**:
- OK: < 80% usage
- WARNING: 80-95% usage
- CRITICAL: > 95% usage

**Output Format**: `STATUS|USAGE%|INFO`

**Example**:
```
OK|45.2%|Normal
WARNING|82.5%|Elevated CPU load
CRITICAL|96.8%|High CPU load
```

**Auto-Fix**: None (requires manual investigation)

---

#### Check 4: Nginx Status
**Purpose**: Ensure web server is running

**Output Format**: `STATUS|STATE|INFO`

**Example**:
```
OK|Active|124 connections, Up since Sat 2024-12-07 10:00:00
FAIL|Inactive|Service not running
```

**Auto-Fix**: Restart Nginx service

---

#### Check 5: MySQL Status
**Purpose**: Ensure database server is running

**Output Format**: `STATUS|STATE|INFO`

**Example**:
```
OK|Active|15 connections, Up since Sat 2024-12-07 10:00:00
FAIL|Inactive|Service not running
```

**Auto-Fix**: Restart MySQL/MariaDB service

---

#### Check 6: PHP-FPM Status
**Purpose**: Ensure PHP processor is running

**Output Format**: `STATUS|STATE|INFO`

**Example**:
```
OK|Active|256MB RAM, Up since Sat 2024-12-07 10:00:00
FAIL|Inactive|Service not running
```

**Auto-Fix**: Restart PHP-FPM service

---

### 3.2 Domain-Specific Health Checks

#### Check 7: Site Responding
**Purpose**: Verify website is accessible and responding

**Method**: HTTP request with curl

**Timeout**: 10 seconds

**Success Codes**: 200, 301, 302, 304

**Output Format**: `STATUS|HTTP_CODE|RESPONSE_TIME`

**Example**:
```
OK|200|127ms
OK|301|45ms
FAIL|500|2500ms
FAIL|0|10000ms (timeout)
```

**Auto-Fix**: Check Nginx, check PHP-FPM, check file permissions

---

#### Check 8: SSL Certificate Expiry
**Purpose**: Monitor SSL certificate expiration

**Thresholds**:
- OK: > 30 days until expiry
- WARNING: 7-30 days until expiry
- CRITICAL: < 7 days until expiry
- EXPIRED: Already expired

**Output Format**: `STATUS|DAYS|EXPIRY_DATE`

**Example**:
```
OK|89|Mon Feb 05 10:00:00 2025
WARNING|25|Wed Jan 01 10:00:00 2025
CRITICAL|3|Sun Dec 10 10:00:00 2024
EXPIRED|-5|Mon Dec 02 10:00:00 2024
NO_SSL|0|N/A
```

**Auto-Fix**: Auto-renew certificate using certbot

---

#### Check 9: Database Accessibility
**Purpose**: Verify database connection is working

**Method**: MySQL connection test

**Output Format**: `STATUS|SIZE|INFO`

**Example**:
```
OK|256.45MB|Connected
FAIL|0|Access denied for user
FAIL|0|Can't connect to MySQL server
NO_DB|0|No database configured
```

**Auto-Fix**: Restart MySQL, check credentials

---

### 3.3 Check Execution Flow

```
Start Health Check
   │
   ▼
For Each Check:
   ├─ Execute Check Function
   ├─ Measure Execution Time
   ├─ Capture Output + Status Code
   └─ Store Result
   │
   ▼
Aggregate All Results
   │
   ▼
Determine Overall Status:
   ├─ ALL OK → Overall OK
   └─ ANY FAIL → Overall FAIL
   │
   ▼
Save Status to JSON:
   ├─ Timestamp
   ├─ Overall Status
   └─ Individual Check Results
   │
   ▼
If FAIL:
   ├─ Trigger Auto-Fix
   └─ Send Alerts
   │
   ▼
Save to History
   │
   ▼
End
```

---

## 4. Auto-Fix Implementation

### 4.1 Auto-Fix Decision Matrix

| Issue | Detection | Auto-Fix Action | Retry | Success Verification |
|-------|-----------|----------------|-------|---------------------|
| Nginx Down | systemctl check fails | Restart nginx | 3x | Check status after 5s |
| MySQL Down | systemctl check fails | Restart mysql | 3x | Check status after 10s |
| PHP-FPM Down | systemctl check fails | Restart PHP-FPM | 3x | Check status after 5s |
| SSL Expiring | < 30 days to expiry | Certbot renew | 1x | Check new cert |
| Disk Full | > 90% usage | Clear cache/logs | 1x | Check disk usage |
| High Memory | > 95% usage | Drop caches, restart PHP | 1x | Check memory |
| Site Not Responding | HTTP timeout/5xx | Check services | - | Retry HTTP request |
| DB Not Accessible | Connection failed | Restart MySQL | 3x | Test connection |

### 4.2 Auto-Fix Functions

#### auto_fix_nginx()
```bash
Purpose: Restart Nginx web server
Steps:
  1. Log action start
  2. Execute: systemctl restart nginx
  3. Wait 5 seconds
  4. Verify: systemctl is-active nginx
  5. Log result (success/failure)
Return: 0 on success, 1 on failure
```

#### auto_fix_mysql()
```bash
Purpose: Restart MySQL/MariaDB database server
Steps:
  1. Log action start
  2. Detect service name (mysql or mariadb)
  3. Execute: systemctl restart $SERVICE_MYSQL
  4. Wait 10 seconds
  5. Verify: systemctl is-active $SERVICE_MYSQL
  6. Log result
Return: 0 on success, 1 on failure
```

#### auto_fix_php_fpm()
```bash
Purpose: Restart PHP-FPM service
Steps:
  1. Log action start
  2. Detect PHP-FPM service name (php8.3-fpm, php8.2-fpm, etc.)
  3. Execute: systemctl restart $SERVICE_PHP_FPM
  4. Wait 5 seconds
  5. Verify: systemctl is-active $SERVICE_PHP_FPM
  6. Log result
Return: 0 on success, 1 on failure
```

#### auto_fix_ssl()
```bash
Purpose: Renew SSL certificate
Parameters: domain
Steps:
  1. Log action start
  2. Execute: certbot renew --cert-name $domain --quiet
  3. If successful:
     - Reload nginx to apply new cert
     - Log success
  4. If failed:
     - Log failure with error message
Return: 0 on success, 1 on failure
```

#### auto_fix_disk_space()
```bash
Purpose: Free up disk space
Steps:
  1. Clear APT cache: apt-get clean
  2. Remove old logs (>30 days)
  3. Remove old backups (>7 days)
  4. Log freed space
Return: 0 (always succeeds)
```

#### auto_fix_memory()
```bash
Purpose: Optimize memory usage
Steps:
  1. Clear page cache: echo 3 > /proc/sys/vm/drop_caches
  2. Restart PHP-FPM (frees memory leaks)
  3. Log action
Return: 0 (always succeeds)
```

### 4.3 Auto-Fix Logging

All auto-fix actions are logged to: `/opt/rocketvps/health/logs/auto_fix.log`

**Log Format**:
```
[TIMESTAMP] AUTO-FIX: component | action | result
```

**Examples**:
```
[2024-12-07 10:15:30] AUTO-FIX: nginx | restart | success
[2024-12-07 10:20:45] AUTO-FIX: mysql | restart | failed:service_error
[2024-12-07 10:25:00] AUTO-FIX: ssl | renew:example.com | success
[2024-12-07 10:30:15] AUTO-FIX: disk | cleanup | success:3_operations
[2024-12-07 10:35:30] AUTO-FIX: memory | optimize | success
```

---

## 5. Alert System

### 5.1 Alert Channels

#### Email Alerts
**Configuration**:
- `ALERT_EMAIL`: Recipient email address
- Uses system `mail` command

**Format**:
```
Subject: RocketVPS Health Alert: {subject}
Body:
  Health check failed for {subject}
  
  Details:
  {JSON status data}
```

#### Webhook Alerts
**Configuration**:
- `ALERT_WEBHOOK_URL`: Generic webhook URL

**Payload**:
```json
{
  "subject": "example.com",
  "severity": "FAIL",
  "message": "Health check failed..."
}
```

#### Slack Alerts
**Configuration**:
- `ALERT_SLACK_WEBHOOK`: Slack webhook URL

**Payload**:
```json
{
  "attachments": [{
    "color": "danger",
    "title": "example.com",
    "text": "Health check failed..."
  }]
}
```

**Colors**:
- Red (danger): FAIL/CRITICAL
- Yellow (warning): WARNING

#### Discord Alerts
**Configuration**:
- `ALERT_DISCORD_WEBHOOK`: Discord webhook URL

**Payload**:
```json
{
  "embeds": [{
    "title": "example.com",
    "description": "Health check failed...",
    "color": 15158332
  }]
}
```

### 5.2 Alert Rate Limiting

**Purpose**: Prevent alert spam

**Mechanism**:
- Track last alert time per subject in: `/opt/rocketvps/health/.last_alert_{subject}`
- Default minimum interval: 3600 seconds (1 hour)
- First alert always sent
- Subsequent alerts blocked until interval passes

**Flow**:
```
Alert Triggered
   │
   ▼
Check .last_alert_{subject} file
   │
   ├─ File doesn't exist → SEND (first alert)
   │
   └─ File exists
      │
      ▼
   Calculate time since last alert
      │
      ├─ > ALERT_MIN_INTERVAL → SEND and update file
      │
      └─ < ALERT_MIN_INTERVAL → SKIP (too soon)
```

### 5.3 Alert Severity Levels

| Level | Triggers | Response Time | Auto-Fix |
|-------|----------|--------------|----------|
| **CRITICAL** | Service down, Disk >90%, Memory >95%, SSL expired | Immediate | Yes, 3 retries |
| **WARNING** | Disk 80-90%, Memory 85-95%, SSL <30 days | 15 minutes | No |
| **INFO** | Successful auto-fix, system healthy | None | N/A |

---

## 6. Auto-Detect System

### 6.1 Site Type Detection

#### Detection Logic Flow
```
Start Detection
   │
   ▼
Check for wp-config.php
   ├─ YES → WORDPRESS
   └─ NO ↓
   
Check for artisan + composer.json with laravel/framework
   ├─ YES → LARAVEL
   └─ NO ↓
   
Check for package.json with express/next/nuxt/react/vue
   ├─ YES → NODEJS
   └─ NO ↓
   
Check for index.html/htm with no dynamic files
   ├─ YES → STATIC
   └─ NO ↓
   
Check for index.php or composer.json
   ├─ YES → PHP (Generic)
   └─ NO → UNKNOWN
```

#### Detection Signatures

**WordPress**:
- Primary: `/wp-config.php` exists
- Version file: `/wp-includes/version.php` contains `$wp_version`
- Confidence: 100%

**Laravel**:
- Primary: `/artisan` exists + `/composer.json` contains `"laravel/framework"`
- Version: Extract from `composer.json` `"laravel/framework": "^10.0"`
- Confidence: 100%

**Node.js**:
- Primary: `/package.json` exists with `express|next|nuxt|react|vue`
- Framework: Extract from dependencies
- Confidence: 95%

**Static HTML**:
- Primary: `/index.html` or `/index.htm` exists
- Secondary: No `.php`, `package.json`, or `composer.json` files
- Confidence: 90%

**Generic PHP**:
- Primary: `/index.php` or `/composer.json` exists
- Secondary: Check for frameworks (Symfony, CodeIgniter, Yii, CakePHP)
- Confidence: 80%

### 6.2 Framework Detection

#### WordPress Version Detection
```bash
File: /wp-includes/version.php
Extract: $wp_version = '6.4.1';
Output: WordPress 6.4.1
```

#### Laravel Version Detection
```bash
File: /composer.json
Extract: "laravel/framework": "^10.0"
Output: Laravel ^10.0
```

#### Node.js Framework Detection
```bash
File: /package.json
Search: "next"|"nuxt"|"express"|"react"|"vue"
Output: Node.js (express) or Node.js (next)
```

#### PHP Framework Detection
```bash
File: /composer.json
Search: "symfony"|"codeigniter"|"yii"|"cakephp"
Output: PHP (symfony) or Generic PHP
```

### 6.3 PHP Version Requirements

| Site Type | Detection Logic | Default Version |
|-----------|----------------|----------------|
| WordPress | Static recommendation | 8.1 |
| Laravel | Extract from composer.json `"php": "^8.2"` | 8.2 |
| Generic PHP | Extract from composer.json or default | 8.1 |
| Node.js | N/A | N/A |
| Static | N/A | N/A |

---

## 7. Configuration Extraction

### 7.1 Database Configuration

#### WordPress Extraction
**File**: `/wp-config.php`

**Pattern**:
```php
define('DB_NAME', 'database_name');
define('DB_USER', 'database_user');
define('DB_PASSWORD', 'password');
define('DB_HOST', 'localhost');
```

**Extraction Method**:
```bash
db_name=$(grep "DB_NAME" wp-config.php | cut -d "'" -f 4 | head -1)
db_user=$(grep "DB_USER" wp-config.php | cut -d "'" -f 4 | head -1)
db_pass=$(grep "DB_PASSWORD" wp-config.php | cut -d "'" -f 4 | head -1)
db_host=$(grep "DB_HOST" wp-config.php | cut -d "'" -f 4 | head -1)
```

#### Laravel Extraction
**File**: `/.env`

**Pattern**:
```
DB_DATABASE=laravel_db
DB_USERNAME=laravel_user
DB_PASSWORD=secret123
DB_HOST=localhost
DB_PORT=3306
```

**Extraction Method**:
```bash
db_name=$(grep "^DB_DATABASE=" .env | cut -d "=" -f 2 | tr -d '"' | head -1)
db_user=$(grep "^DB_USERNAME=" .env | cut -d "=" -f 2 | tr -d '"' | head -1)
db_pass=$(grep "^DB_PASSWORD=" .env | cut -d "=" -f 2 | tr -d '"' | head -1)
db_host=$(grep "^DB_HOST=" .env | cut -d "=" -f 2 | tr -d '"' | head -1)
db_port=$(grep "^DB_PORT=" .env | cut -d "=" -f 2 | tr -d '"' | head -1)
```

**Output Format**:
```json
{
    "db_name": "database_name",
    "db_user": "db_user",
    "db_pass": "password",
    "db_host": "localhost",
    "db_port": "3306"
}
```

### 7.2 Node.js Configuration

**File**: `/package.json`

**Extraction**:
```json
{
    "node_version": "18",
    "start_command": "npm start",
    "port": "3000"
}
```

**Port Detection**:
1. Check `.env` for `PORT=` variable
2. Default to 3000 if not found

---

## 8. Auto-Configuration Engine

### 8.1 Nginx Configuration Generation

#### WordPress Template
```nginx
server {
    listen 80;
    server_name domain.com www.domain.com;
    root /var/www/domain.com;
    index index.php index.html;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;

    # Gzip compression
    gzip on;
    gzip_types text/plain text/css application/json;

    location / {
        try_files $uri $uri/ /index.php?$args;
    }

    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
        include fastcgi_params;
    }

    location ~* \.(js|css|png|jpg|jpeg|gif|ico)$ {
        expires 1y;
    }
}
```

#### Laravel Template
```nginx
server {
    listen 80;
    server_name domain.com www.domain.com;
    root /var/www/domain.com/public;
    index index.php;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php/php8.2-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\.(?!well-known).* {
        deny all;
    }
}
```

#### Node.js Template
```nginx
server {
    listen 80;
    server_name domain.com www.domain.com;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }

    location ~* \.(js|css|png|jpg|jpeg|gif|ico)$ {
        root /var/www/domain.com/public;
        expires 1y;
    }
}
```

#### Static HTML Template
```nginx
server {
    listen 80;
    server_name domain.com www.domain.com;
    root /var/www/domain.com;
    index index.html;

    location / {
        try_files $uri $uri/ =404;
    }

    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2)$ {
        expires 1y;
    }
}
```

### 8.2 Permission Fixing

**Base Permissions**:
- Directories: 755 (rwxr-xr-x)
- Files: 644 (rw-r--r--)
- Owner: www-data:www-data

**WordPress Specific**:
- `/wp-content/uploads`: 775 (writable by web server)
- `/wp-content/cache`: 775

**Laravel Specific**:
- `/storage`: 775 (recursive)
- `/bootstrap/cache`: 775

**Commands**:
```bash
find /var/www/domain -type d -exec chmod 755 {} \;
find /var/www/domain -type f -exec chmod 644 {} \;
chown -R www-data:www-data /var/www/domain
```

### 8.3 Cache Setup

**WordPress**:
- Recommend Redis object cache plugin
- Check if Redis is available: `redis-cli ping`
- Configuration suggestion for wp-config.php

**Laravel**:
- Update `.env` for Redis cache driver
- `CACHE_DRIVER=redis`
- `REDIS_HOST=127.0.0.1`

---

## 9. Data Structures

### 9.1 Health Status JSON

**File**: `/opt/rocketvps/health/status/system.json`

```json
{
    "type": "system",
    "timestamp": 1701950400,
    "date": "Sat Dec 7 10:00:00 UTC 2024",
    "overall_status": "OK",
    "checks": {
        "disk_space": {
            "result": "OK|65%|15G available",
            "status": 0
        },
        "memory_usage": {
            "result": "OK|68%|2048MB available of 8192MB",
            "status": 0
        },
        "cpu_usage": {
            "result": "OK|45.2%|Normal",
            "status": 0
        },
        "nginx_status": {
            "result": "OK|Active|124 connections",
            "status": 0
        },
        "mysql_status": {
            "result": "OK|Active|15 connections",
            "status": 0
        },
        "php_fpm_status": {
            "result": "OK|Active|256MB RAM",
            "status": 0
        }
    }
}
```

**File**: `/opt/rocketvps/health/status/{domain}.json`

```json
{
    "domain": "example.com",
    "timestamp": 1701950400,
    "date": "Sat Dec 7 10:00:00 UTC 2024",
    "overall_status": "OK",
    "checks": {
        "site_responding": {
            "result": "OK|200|127ms",
            "status": 0
        },
        "ssl_expiry": {
            "result": "OK|89|Mon Feb 05 10:00:00 2025",
            "status": 0
        },
        "database": {
            "result": "OK|256.45MB|Connected",
            "status": 0
        }
    }
}
```

### 9.2 Health History Log

**File**: `/opt/rocketvps/health/history/{domain}_{YYYY-MM-DD}.log`

```
1701950400|OK
1701951300|OK
1701952200|FAIL
1701953100|OK
```

**Format**: `timestamp|status`

### 9.3 Auto-Detect Cache

**File**: `/opt/rocketvps/auto_detect/cache/{domain}.json`

```json
{
    "domain": "example.com",
    "detected_at": 1701950400,
    "site_type": "WORDPRESS",
    "framework": "WordPress 6.4.1",
    "php_version": "8.1",
    "database": {
        "db_name": "wp_database",
        "db_user": "wp_user",
        "db_host": "localhost"
    },
    "config_generated": true,
    "nginx_config_path": "/etc/nginx/sites-available/example.com"
}
```

---

## 10. Function Specifications

### 10.1 Health Monitoring Functions

#### `health_monitor_init()`
**Purpose**: Initialize health monitoring system
**Parameters**: None
**Returns**: 0 on success
**Steps**:
1. Create health directories
2. Set permissions (700)
3. Detect PHP-FPM service name
4. Detect MySQL service name

#### `check_disk_space(partition)`
**Purpose**: Check disk space usage
**Parameters**:
- `partition`: Partition to check (default: "/")
**Returns**:
- 0: OK or WARNING
- 1: CRITICAL
**Output**: `STATUS|USAGE%|AVAILABLE`

#### `check_memory_usage()`
**Purpose**: Check RAM usage
**Parameters**: None
**Returns**:
- 0: OK or WARNING
- 1: CRITICAL
**Output**: `STATUS|USAGE%|INFO`

#### `check_cpu_usage()`
**Purpose**: Check CPU load
**Parameters**: None
**Returns**:
- 0: OK or WARNING
- 1: CRITICAL
**Output**: `STATUS|USAGE%|INFO`

#### `check_nginx_status()`
**Purpose**: Check if Nginx is running
**Parameters**: None
**Returns**:
- 0: Active
- 1: Inactive
**Output**: `STATUS|STATE|INFO`

#### `check_mysql_status()`
**Purpose**: Check if MySQL is running
**Parameters**: None
**Returns**:
- 0: Active
- 1: Inactive
**Output**: `STATUS|STATE|INFO`

#### `check_php_fpm_status()`
**Purpose**: Check if PHP-FPM is running
**Parameters**: None
**Returns**:
- 0: Active
- 1: Inactive
**Output**: `STATUS|STATE|INFO`

#### `check_site_responding(domain)`
**Purpose**: Check if website responds to HTTP requests
**Parameters**:
- `domain`: Domain to check
**Returns**:
- 0: Responding (2xx/3xx)
- 1: Not responding (4xx/5xx/timeout)
**Output**: `STATUS|HTTP_CODE|RESPONSE_TIME`

#### `check_ssl_expiry(domain)`
**Purpose**: Check SSL certificate expiration
**Parameters**:
- `domain`: Domain to check
**Returns**:
- 0: OK or WARNING
- 1: CRITICAL or EXPIRED
- 2: No SSL configured
**Output**: `STATUS|DAYS|EXPIRY_DATE`

#### `check_database_accessibility(domain)`
**Purpose**: Test database connection
**Parameters**:
- `domain`: Domain to check
**Returns**:
- 0: Connected
- 1: Connection failed
- 2: No database configured
**Output**: `STATUS|SIZE|INFO`

#### `run_system_health_checks()`
**Purpose**: Run all system-wide health checks
**Parameters**: None
**Returns**:
- 0: All passed
- 1: At least one failed
**Side Effects**:
- Creates `/opt/rocketvps/health/status/system.json`
- Triggers auto-fix if failures detected
- Sends alerts if configured

#### `run_domain_health_checks(domain)`
**Purpose**: Run all checks for a specific domain
**Parameters**:
- `domain`: Domain to check
**Returns**:
- 0: All passed
- 1: At least one failed
**Side Effects**:
- Creates `/opt/rocketvps/health/status/{domain}.json`
- Saves to history
- Triggers auto-fix if failures detected
- Sends alerts if configured

#### `run_all_health_checks()`
**Purpose**: Run health checks for system + all domains
**Parameters**: None
**Returns**: 0
**Steps**:
1. Run system health checks
2. Discover all domains in /var/www
3. Run domain health checks for each
4. Log summary

### 10.2 Auto-Fix Functions

#### `auto_fix_nginx()`
**Purpose**: Restart Nginx service
**Parameters**: None
**Returns**:
- 0: Success
- 1: Failed
**Side Effects**: Logs to auto_fix.log

#### `auto_fix_mysql()`
**Purpose**: Restart MySQL service
**Parameters**: None
**Returns**:
- 0: Success
- 1: Failed
**Side Effects**: Logs to auto_fix.log

#### `auto_fix_php_fpm()`
**Purpose**: Restart PHP-FPM service
**Parameters**: None
**Returns**:
- 0: Success
- 1: Failed
**Side Effects**: Logs to auto_fix.log

#### `auto_fix_ssl(domain)`
**Purpose**: Renew SSL certificate
**Parameters**:
- `domain`: Domain to renew
**Returns**:
- 0: Success
- 1: Failed
**Side Effects**:
- Runs certbot renew
- Reloads Nginx
- Logs to auto_fix.log

#### `auto_fix_disk_space()`
**Purpose**: Free up disk space
**Parameters**: None
**Returns**: 0 (always)
**Actions**:
- Clear APT cache
- Remove old logs (>30 days)
- Remove old backups (>7 days)
**Side Effects**: Logs to auto_fix.log

#### `auto_fix_memory()`
**Purpose**: Optimize memory usage
**Parameters**: None
**Returns**: 0 (always)
**Actions**:
- Clear page cache
- Restart PHP-FPM
**Side Effects**: Logs to auto_fix.log

### 10.3 Alert Functions

#### `send_health_alert(subject, severity, status_file)`
**Purpose**: Send alert through configured channels
**Parameters**:
- `subject`: Alert subject (domain or "system")
- `severity`: "FAIL", "WARNING", "CRITICAL"
- `status_file`: Path to JSON status file
**Returns**: 0
**Steps**:
1. Check rate limiting
2. Read status data
3. Send to all configured channels
4. Update last alert timestamp

#### `should_send_alert(subject)`
**Purpose**: Check if alert should be sent (rate limiting)
**Parameters**:
- `subject`: Alert subject
**Returns**:
- 0: Should send
- 1: Should skip (too soon)

#### `send_email_alert(email, subject, message)`
**Purpose**: Send email alert
**Parameters**:
- `email`: Recipient
- `subject`: Email subject
- `message`: Email body
**Returns**: 0

#### `send_slack_alert(webhook, subject, severity, message)`
**Purpose**: Send Slack alert
**Parameters**:
- `webhook`: Slack webhook URL
- `subject`: Alert title
- `severity`: Color coding
- `message`: Alert text
**Returns**: 0

#### `send_discord_alert(webhook, subject, severity, message)`
**Purpose**: Send Discord alert
**Parameters**:
- `webhook`: Discord webhook URL
- `subject`: Embed title
- `severity`: Embed color
- `message`: Embed description
**Returns**: 0

### 10.4 Auto-Detect Functions

#### `detect_site_type(domain)`
**Purpose**: Detect website type
**Parameters**:
- `domain`: Domain to detect
**Returns**:
- String: "WORDPRESS", "LARAVEL", "NODEJS", "STATIC", "PHP", "UNKNOWN"
**Detection Order**: WordPress → Laravel → Node.js → Static → PHP

#### `detect_site_framework(domain)`
**Purpose**: Detect specific framework and version
**Parameters**:
- `domain`: Domain to detect
**Returns**:
- String: e.g., "WordPress 6.4", "Laravel ^10.0", "Node.js (express)"

#### `detect_php_version(domain)`
**Purpose**: Detect required PHP version
**Parameters**:
- `domain`: Domain to detect
**Returns**:
- String: PHP version (e.g., "8.1", "8.2")

#### `extract_database_config(domain)`
**Purpose**: Extract database credentials
**Parameters**:
- `domain`: Domain to extract from
**Returns**:
- JSON string with db_name, db_user, db_pass, db_host, db_port

#### `extract_nodejs_config(domain)`
**Purpose**: Extract Node.js configuration
**Parameters**:
- `domain`: Domain to extract from
**Returns**:
- JSON string with node_version, start_command, port

#### `generate_nginx_config(domain)`
**Purpose**: Generate optimized Nginx configuration
**Parameters**:
- `domain`: Domain to configure
**Returns**:
- String: Complete Nginx server block

#### `auto_configure_domain(domain)`
**Purpose**: Fully configure a domain automatically
**Parameters**:
- `domain`: Domain to configure
**Returns**:
- 0: Success
- 1: Failed
**Steps**:
1. Detect site type
2. Generate Nginx config
3. Enable site
4. Test and reload Nginx
5. Fix permissions
6. Setup cache if applicable

#### `fix_permissions(domain)`
**Purpose**: Set correct file/directory permissions
**Parameters**:
- `domain`: Domain to fix
**Returns**: 0
**Actions**:
- Set 755 for directories
- Set 644 for files
- Set 775 for uploads/cache
- Set www-data:www-data ownership

#### `auto_detect_all_domains()`
**Purpose**: Detect and report all domains
**Parameters**: None
**Returns**: 0
**Output**: Formatted table with detection results

---

## 11. Performance Targets

### 11.1 Health Check Performance

| Check Type | Target | Acceptable | Unacceptable |
|------------|--------|------------|--------------|
| Disk Space | <100ms | <500ms | >1s |
| Memory Usage | <100ms | <500ms | >1s |
| CPU Usage | <2s | <5s | >10s |
| Service Status | <200ms | <1s | >2s |
| Site Responding | <1s | <5s | >10s |
| SSL Check | <500ms | <2s | >5s |
| Database Check | <500ms | <2s | >5s |
| **Complete System Check** | **<5s** | **<10s** | **>20s** |
| **Complete Domain Check** | **<3s** | **<7s** | **>15s** |

### 11.2 Auto-Fix Performance

| Action | Target | Acceptable | Notes |
|--------|--------|------------|-------|
| Restart Nginx | <5s | <10s | Includes verification |
| Restart MySQL | <10s | <20s | Includes verification |
| Restart PHP-FPM | <5s | <10s | Includes verification |
| SSL Renewal | <30s | <60s | Depends on Let's Encrypt |
| Disk Cleanup | <5s | <15s | Depends on file count |
| Memory Optimize | <2s | <5s | Quick operation |

### 11.3 Auto-Detect Performance

| Operation | Target | Acceptable | Unacceptable |
|-----------|--------|------------|--------------|
| Site Type Detection | <100ms | <500ms | >1s |
| Framework Detection | <200ms | <1s | >2s |
| Database Config Extraction | <100ms | <500ms | >1s |
| Nginx Config Generation | <200ms | <1s | >2s |
| Complete Auto-Configure | <5s | <15s | >30s |
| **Bulk Detection (10 domains)** | **<3s** | **<10s** | **>20s** |

### 11.4 Scalability Targets

| Metric | Current | Target | Notes |
|--------|---------|--------|-------|
| Domains Monitored | 50 | 200 | Per 15-min interval |
| Health Checks/Hour | 200 | 800 | 4 checks × 200 domains |
| History Retention | 30 days | 90 days | Configurable |
| Alert Channels | 4 | 10 | Email, webhooks, etc. |
| Auto-Fix Actions/Day | 50 | 200 | Automatic healing |

---

## 12. Testing Strategy

### 12.1 Test Coverage

**Total Tests**: 23

**Categories**:
- Health Monitoring: 10 tests (43%)
- Auto-Detect: 10 tests (43%)
- Performance: 2 tests (9%)
- Integration: 1 test (5%)

### 12.2 Test Descriptions

#### Health Monitoring Tests (10)

1. **Module Initialization** - Verify directories created with correct permissions
2. **Disk Space Check** - Test disk usage detection and thresholds
3. **Memory Usage Check** - Test memory monitoring and thresholds
4. **CPU Usage Check** - Test CPU load detection
5. **Nginx Status Check** - Test service status detection
6. **MySQL Status Check** - Test database service status
7. **PHP-FPM Status Check** - Test PHP service status
8. **Complete System Check** - Test end-to-end system health check with JSON output
9. **Alert Rate Limiting** - Test duplicate alert blocking
10. **Health History Tracking** - Test history file creation and logging

#### Auto-Detect Tests (10)

11. **WordPress Detection** - Test detection with wp-config.php
12. **Laravel Detection** - Test detection with artisan + composer.json
13. **Node.js Detection** - Test detection with package.json
14. **Static HTML Detection** - Test detection with index.html only
15. **DB Extraction - WordPress** - Test credential extraction from wp-config.php
16. **DB Extraction - Laravel** - Test credential extraction from .env
17. **Nginx Config - WordPress** - Test WordPress-specific Nginx config generation
18. **Nginx Config - Laravel** - Test Laravel public directory config
19. **Nginx Config - Node.js** - Test Node.js reverse proxy config
20. **PHP Version Detection** - Test PHP version requirement detection

#### Performance Tests (2)

21. **Health Check Speed** - Measure complete system health check time (<5s target)
22. **Auto-Detect Speed** - Measure site detection time (<500ms target)

#### Integration Test (1)

23. **Health → Auto-Fix Flow** - End-to-end test of health check triggering auto-fix

### 12.3 Expected Results

**Success Criteria**:
- All 23 tests passing (100% success rate)
- Health checks complete in <5s
- Auto-detect completes in <500ms
- No false positives in site type detection
- Alert rate limiting working correctly
- Auto-fix actions logged properly

**Performance Benchmarks**:
- System health check: ~3-5 seconds
- Domain health check: ~2-3 seconds
- Site type detection: ~100-200ms
- Nginx config generation: ~50-100ms

---

## Appendix A: Configuration Reference

### Health Monitoring Configuration

```bash
# Directories
HEALTH_DIR="/opt/rocketvps/health"
HEALTH_STATUS_DIR="${HEALTH_DIR}/status"
HEALTH_HISTORY_DIR="${HEALTH_DIR}/history"
HEALTH_LOG_DIR="${HEALTH_DIR}/logs"

# Intervals
HEALTH_CHECK_INTERVAL=15        # minutes
HEALTH_HISTORY_RETENTION=30     # days

# Thresholds
DISK_WARNING_THRESHOLD=80       # %
DISK_CRITICAL_THRESHOLD=90      # %
MEMORY_WARNING_THRESHOLD=85     # %
MEMORY_CRITICAL_THRESHOLD=95    # %
CPU_WARNING_THRESHOLD=80        # %
CPU_CRITICAL_THRESHOLD=95       # %
SSL_EXPIRY_WARNING_DAYS=30      # days
SSL_EXPIRY_CRITICAL_DAYS=7      # days

# Auto-Fix
AUTO_FIX_ENABLED=true
AUTO_FIX_MAX_RETRIES=3
AUTO_FIX_RETRY_DELAY=60         # seconds

# Alerts
ALERT_ENABLED=true
ALERT_EMAIL=""                   # Set via config
ALERT_WEBHOOK_URL=""
ALERT_SLACK_WEBHOOK=""
ALERT_DISCORD_WEBHOOK=""
ALERT_MIN_INTERVAL=3600          # seconds (1 hour)
```

### Auto-Detect Configuration

```bash
# Directories
AUTO_DETECT_DIR="/opt/rocketvps/auto_detect"
AUTO_DETECT_CACHE="${AUTO_DETECT_DIR}/cache"

# Detection priorities (order matters)
DETECT_ORDER=(
    "WORDPRESS"
    "LARAVEL"
    "NODEJS"
    "STATIC"
    "PHP"
)

# Default versions
DEFAULT_PHP_VERSION="8.1"
DEFAULT_NODE_VERSION="18"
DEFAULT_NODEJS_PORT="3000"
```

---

## Appendix B: Error Codes

| Code | Meaning | Context |
|------|---------|---------|
| 0 | Success / OK | All operations, healthy status |
| 1 | Failure / FAIL | Failed health check, auto-fix failed |
| 2 | Not Configured | No SSL, no database configured |
| 3 | Warning | SSL expiring soon, high but not critical usage |

---

## Appendix C: File Locations

### Health Monitoring Files
```
/opt/rocketvps/health/
├── status/
│   ├── system.json
│   └── {domain}.json
├── history/
│   └── {domain}_{YYYY-MM-DD}.log
├── logs/
│   └── auto_fix.log
└── .last_alert_{subject}

/etc/cron.d/
└── rocketvps_health_monitor
```

### Auto-Detect Files
```
/opt/rocketvps/auto_detect/
└── cache/
    └── {domain}.json

/etc/nginx/sites-available/
└── {domain}

/etc/nginx/sites-enabled/
└── {domain} -> ../sites-available/{domain}

/var/www/
└── {domain}/
    ├── wp-config.php        (WordPress)
    ├── artisan              (Laravel)
    ├── .env                 (Laravel, Node.js)
    ├── composer.json        (PHP frameworks)
    └── package.json         (Node.js)
```

---

**End of Technical Design Document**

Total: 12 major sections, 1,500+ lines
