# 🚀 Auto Database Setup - Complete Guide

## 📋 Overview

RocketVPS v2.1.0 introduces **automatic database installation and management** for all domains. When you add a new domain, RocketVPS will automatically create database accounts across MySQL, PostgreSQL, and ProxySQL.

## ✨ New Features

### 1. Auto-Install Databases on First Run

**What happens:** When you first run RocketVPS, it will automatically install:
- ✅ MySQL/MariaDB
- ✅ PostgreSQL
- ✅ ProxySQL

**Benefits:**
- No manual installation needed
- Secure random passwords generated
- All databases ready to use immediately
- Credentials saved securely

### 2. Auto-Create Database Accounts for New Domains

**What happens:** When you add a new domain, RocketVPS will automatically:
1. Create MySQL database and user
2. Create PostgreSQL database and user
3. Add user to ProxySQL
4. Grant full permissions
5. Display all credentials on screen
6. Save credentials securely

**Database naming convention:**
- Domain: `example.com`
- Database name: `example_com`
- Username: `example_com`
- Password: Random 16-character secure password

## 🎯 How It Works

### First Time Setup

```bash
# 1. Launch RocketVPS for the first time
sudo rocketvps

# 2. Auto-installation prompt appears
┌─────────────────────────────────────────────────────────────┐
│  RocketVPS Initial Database Setup                           │
│                                                              │
│  This will automatically install:                           │
│    - MySQL/MariaDB                                          │
│    - PostgreSQL                                             │
│    - ProxySQL                                               │
│                                                              │
│  Proceed with automatic database installation? (y/n):       │
└─────────────────────────────────────────────────────────────┘

# 3. Enter 'y' and wait for installation
# All databases will be installed with secure passwords
# Credentials saved in /opt/rocketvps/config/
```

### Adding a Domain with Auto Database Creation

```bash
# 1. Go to Domain Management
rocketvps → 2) Domain Management

# 2. Add New Domain
Select: 1) Add New Domain

# 3. Enter domain details
Enter domain name: example.com
Select site type: 2) PHP

# 4. Automatic process begins:
✓ Creating domain configuration
✓ Setting up phpMyAdmin
✓ Creating database accounts
  - MySQL database: example_com
  - PostgreSQL database: example_com
  - ProxySQL user: example_com

# 5. Complete information displayed
╔═══════════════════════════════════════════════════════════════╗
║          DATABASE CREDENTIALS FOR example.com                 ║
╚═══════════════════════════════════════════════════════════════╝

═══ MySQL Database ═══
  Database Name:    example_com
  Username:         example_com
  Password:         Xy9Kp2Lm4Nq8Rs6T
  Host:             localhost
  Port:             3306

  Connection String:
  mysql -uexample_com -p'Xy9Kp2Lm4Nq8Rs6T' example_com

  PHP Connection (mysqli):
  $conn = new mysqli('localhost', 'example_com', 'Xy9Kp2Lm4Nq8Rs6T', 'example_com');

═══ PostgreSQL Database ═══
  Database Name:    example_com
  Username:         example_com
  Password:         Xy9Kp2Lm4Nq8Rs6T
  Host:             localhost
  Port:             5432

  Connection String:
  psql -U example_com -d example_com

  PHP Connection (PDO):
  $conn = new PDO('pgsql:host=localhost;dbname=example_com', 'example_com', 'Xy9Kp2Lm4Nq8Rs6T');

═══ ProxySQL Connection ═══
  Username:         example_com
  Password:         Xy9Kp2Lm4Nq8Rs6T
  Host:             127.0.0.1
  Port:             6033

  Connection String:
  mysql -h127.0.0.1 -P6033 -uexample_com -p'Xy9Kp2Lm4Nq8Rs6T' example_com

  PHP Connection via ProxySQL:
  $conn = new mysqli('127.0.0.1', 'example_com', 'Xy9Kp2Lm4Nq8Rs6T', 'example_com', 6033);

═══ Additional Information ═══
  Domain:           example.com
  Created:          2025-10-04 15:30:45
  Credentials File: /opt/rocketvps/config/database_credentials/example.com.conf

╔═══════════════════════════════════════════════════════════════╗
║  ⚠ IMPORTANT: Save these credentials securely!               ║
║  Credentials are stored in: [file path]                      ║
╚═══════════════════════════════════════════════════════════════╝
```

## 📁 File Structure

### Credentials Storage

```
/opt/rocketvps/config/
├── mysql_root_password          # MySQL root password
├── postgresql_password          # PostgreSQL postgres password
├── proxysql.conf               # ProxySQL admin credentials
└── database_credentials/       # Domain database credentials
    ├── example.com.conf
    ├── test.com.conf
    └── mysite.org.conf
```

### Credentials File Format

**File:** `/opt/rocketvps/config/database_credentials/example.com.conf`

```bash
MYSQL_DB_NAME=example_com
MYSQL_DB_USER=example_com
MYSQL_DB_PASSWORD=Xy9Kp2Lm4Nq8Rs6T
POSTGRESQL_DB_NAME=example_com
POSTGRESQL_DB_USER=example_com
POSTGRESQL_DB_PASSWORD=Xy9Kp2Lm4Nq8Rs6T
PROXYSQL_USER=example_com
PROXYSQL_PASSWORD=Xy9Kp2Lm4Nq8Rs6T
PROXYSQL_HOST=127.0.0.1
PROXYSQL_PORT=6033
DOMAIN=example.com
CREATED_DATE=2025-10-04 15:30:45
```

## 🎛️ Database Management Features

### View All Domain Databases

```bash
rocketvps → 6) Database Management → 14) List All Domain Databases

Output:
Domain                          MySQL DB              PostgreSQL DB
─────────────────────────────────────────────────────────────────
example.com                     example_com           example_com
test.com                        test_com              test_com
mysite.org                      mysite_org            mysite_org
```

### View Specific Domain Database Info

```bash
rocketvps → 6) Database Management → 15) View Domain Database Info

# Enter domain name
# Full credentials displayed
```

### Delete Domain Databases

```bash
rocketvps → 6) Database Management → 16) Delete Domain Databases

# Enter domain name
# Confirmation required
# All databases and users deleted
# Credentials file removed
```

### Manual Database Installation

```bash
# If you skipped auto-installation
rocketvps → 6) Database Management → 17) Auto-Install All Databases

# This will install MySQL, PostgreSQL, and ProxySQL
```

## 🔒 Security Features

### Password Generation
- **16-character random passwords** using OpenSSL
- Base64 encoding for complexity
- Unique password per domain

### File Permissions
```bash
# Credentials directory
chmod 700 /opt/rocketvps/config/database_credentials/

# Individual credential files
chmod 600 /opt/rocketvps/config/database_credentials/*.conf

# Root password files
chmod 600 /opt/rocketvps/config/mysql_root_password
chmod 600 /opt/rocketvps/config/postgresql_password
```

### User Isolation
- Each domain gets separate database
- Full permissions only on own database
- No access to other domains' databases
- ProxySQL provides additional security layer

## 💡 Use Cases

### 1. WordPress Installation

```bash
# After adding domain, use displayed credentials
# In wp-config.php:

define('DB_NAME', 'example_com');
define('DB_USER', 'example_com');
define('DB_PASSWORD', 'Xy9Kp2Lm4Nq8Rs6T');
define('DB_HOST', 'localhost');  // Direct MySQL

// OR use ProxySQL for better performance:
define('DB_HOST', '127.0.0.1:6033');  // Via ProxySQL
```

### 2. Laravel Application

```bash
# In .env file:

# MySQL Connection
DB_CONNECTION=mysql
DB_HOST=localhost
DB_PORT=3306
DB_DATABASE=example_com
DB_USERNAME=example_com
DB_PASSWORD=Xy9Kp2Lm4Nq8Rs6T

# PostgreSQL Connection
DB_CONNECTION=pgsql
DB_HOST=localhost
DB_PORT=5432
DB_DATABASE=example_com
DB_USERNAME=example_com
DB_PASSWORD=Xy9Kp2Lm4Nq8Rs6T

# ProxySQL Connection (Recommended)
DB_HOST=127.0.0.1
DB_PORT=6033
```

### 3. Custom PHP Application

```php
<?php
// MySQL via ProxySQL (Recommended)
$conn = new mysqli('127.0.0.1', 'example_com', 'Xy9Kp2Lm4Nq8Rs6T', 'example_com', 6033);

if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}

echo "Connected successfully via ProxySQL";

// PostgreSQL
$dsn = "pgsql:host=localhost;port=5432;dbname=example_com";
$conn = new PDO($dsn, 'example_com', 'Xy9Kp2Lm4Nq8Rs6T');

echo "Connected to PostgreSQL";
?>
```

### 4. Node.js Application

```javascript
// MySQL via ProxySQL
const mysql = require('mysql2');

const connection = mysql.createConnection({
  host: '127.0.0.1',
  port: 6033,
  user: 'example_com',
  password: 'Xy9Kp2Lm4Nq8Rs6T',
  database: 'example_com'
});

connection.connect((err) => {
  if (err) throw err;
  console.log('Connected via ProxySQL!');
});

// PostgreSQL
const { Pool } = require('pg');

const pool = new Pool({
  host: 'localhost',
  port: 5432,
  user: 'example_com',
  password: 'Xy9Kp2Lm4Nq8Rs6T',
  database: 'example_com'
});
```

## 🔧 Advanced Configuration

### ProxySQL Benefits

When using ProxySQL (port 6033) instead of direct MySQL (port 3306):

✅ **Load Balancing**: Distribute queries across replicas
✅ **Query Caching**: Cache frequent queries
✅ **Connection Pooling**: Better resource management
✅ **Monitoring**: Advanced query statistics
✅ **Failover**: Automatic server failover

### Connecting to Remote ProxySQL

```bash
# If you want external connections via ProxySQL
# Edit ProxySQL config:

mysql -h127.0.0.1 -P6032 -uadmin -p<admin_password>

# Add bind address
UPDATE global_variables SET variable_value='0.0.0.0' 
WHERE variable_name='mysql-interfaces';

LOAD MYSQL VARIABLES TO RUNTIME;
SAVE MYSQL VARIABLES TO DISK;

# Configure firewall
ufw allow 6033/tcp

# Update application to use server IP
DB_HOST=your_server_ip
DB_PORT=6033
```

## 📊 Monitoring

### Check Database Usage

```bash
# MySQL
mysql -e "SELECT table_schema AS 'Database', 
          ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS 'Size (MB)' 
          FROM information_schema.tables 
          WHERE table_schema NOT IN ('information_schema', 'mysql', 'performance_schema', 'sys') 
          GROUP BY table_schema;"

# PostgreSQL
sudo -u postgres psql -c "SELECT datname, pg_size_pretty(pg_database_size(datname)) 
                          FROM pg_database 
                          WHERE datistemplate = false;"
```

### View ProxySQL Stats

```bash
rocketvps → 26) ProxySQL → 18) View Connection Stats
rocketvps → 26) ProxySQL → 19) View Query Stats
```

## 🛠️ Troubleshooting

### Issue: Can't Connect to Database

**Solution:**
```bash
# 1. Verify credentials
cat /opt/rocketvps/config/database_credentials/example.com.conf

# 2. Test MySQL connection
mysql -uexample_com -p'password' example_com

# 3. Test PostgreSQL connection
psql -U example_com -d example_com

# 4. Test ProxySQL connection
mysql -h127.0.0.1 -P6033 -uexample_com -p'password' example_com
```

### Issue: Database Not Created

**Solution:**
```bash
# Manually trigger database creation
rocketvps → 6) Database Management → 2) Create Database

# Or recreate for existing domain
# Edit auto_database.sh and call:
auto_create_domain_databases "example.com"
```

### Issue: ProxySQL Not Routing

**Solution:**
```bash
# Check ProxySQL is running
systemctl status proxysql

# Check user exists in ProxySQL
mysql -h127.0.0.1 -P6032 -uadmin -p<admin_password>
SELECT * FROM mysql_users WHERE username='example_com';

# Check backend server
SELECT * FROM mysql_servers;
```

## 📈 Best Practices

### 1. Regular Backups

```bash
# Setup auto-backup
rocketvps → 6) Database Management → 10) Setup Auto Backup

# Manual backup
rocketvps → 6) Database Management → 8) Backup Database
```

### 2. Use ProxySQL for Production

- Better performance with connection pooling
- Query caching reduces database load
- Easy to add read replicas later
- Built-in monitoring

### 3. Secure Credentials

```bash
# Never commit credentials to git
echo "*.conf" >> .gitignore

# Use environment variables in applications
# Store credentials in encrypted vault for backups
```

### 4. Monitor Resource Usage

```bash
# Check database sizes regularly
# Optimize tables periodically
rocketvps → 6) Database Management → 12) Optimize Database

# Monitor slow queries via ProxySQL
rocketvps → 26) ProxySQL → 21) View Slow Query Log
```

## 🎓 Examples

### Complete WordPress Setup

```bash
# 1. Add domain
rocketvps → 2) Domain Management → 1) Add New Domain
Domain: myblog.com
Type: 4) WordPress

# 2. Note the database credentials displayed

# 3. Install WordPress
cd /var/www/myblog.com/public_html
wget https://wordpress.org/latest.tar.gz
tar xzf latest.tar.gz
mv wordpress/* .
rm -rf wordpress latest.tar.gz

# 4. Configure wp-config.php with displayed credentials
cp wp-config-sample.php wp-config.php
nano wp-config.php

# Use ProxySQL for better performance:
define('DB_NAME', 'myblog_com');
define('DB_USER', 'myblog_com');
define('DB_PASSWORD', '[from display]');
define('DB_HOST', '127.0.0.1:6033');

# 5. Complete installation via browser
http://myblog.com/wp-admin/install.php
```

### Laravel Project Setup

```bash
# 1. Add domain
rocketvps → 2) Domain Management → 1) Add New Domain
Domain: myapp.com
Type: 5) Laravel

# 2. Note credentials

# 3. Install Laravel
cd /var/www/myapp.com
composer create-project laravel/laravel .

# 4. Configure .env
nano .env

DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=6033
DB_DATABASE=myapp_com
DB_USERNAME=myapp_com
DB_PASSWORD=[from display]

# 5. Run migrations
php artisan migrate
```

## 📞 Support

For issues or questions:
1. Check credentials file: `/opt/rocketvps/config/database_credentials/[domain].conf`
2. View RocketVPS logs: `/opt/rocketvps/logs/rocketvps.log`
3. Test database connectivity manually
4. Check service status: `systemctl status mysql postgresql proxysql`

---

**Version:** 2.1.0  
**Date:** October 4, 2025  
**Feature:** Auto Database Setup
