# RocketVPS v2.2.0 - Credentials Vault User Guide

## Table of Contents
1. [Overview](#overview)
2. [Getting Started](#getting-started)
3. [Managing Credentials](#managing-credentials)
4. [Security Features](#security-features)
5. [Export & Import](#export--import)
6. [Password Rotation](#password-rotation)
7. [Troubleshooting](#troubleshooting)
8. [Best Practices](#best-practices)

---

## Overview

The **Credentials Vault** is a secure, encrypted storage system for all your domain credentials. It uses military-grade AES-256-CBC encryption to protect your sensitive information.

### Key Features
- **AES-256 Encryption**: Bank-level security for all stored credentials
- **Master Password**: Single password to access all credentials
- **Auto-Save**: Automatically stores credentials when setting up domains
- **Session Management**: Auto-lock after 15 minutes of inactivity
- **Brute-Force Protection**: Locks after 5 failed attempts
- **Access Logging**: Complete audit trail of all vault operations
- **Password Rotation**: Generate new strong passwords on demand
- **Multi-Format Export**: Export as JSON, CSV, or plain text

### What Gets Stored

The vault stores credentials for:
- **WordPress**: Admin login, database, FTP, Redis
- **Laravel**: Database, Redis, queue workers
- **Node.js**: Application port, PM2 configuration
- **E-commerce**: WooCommerce admin, database
- **SaaS**: Multi-tenant database, Redis
- **Static Sites**: Deployment configuration

---

## Getting Started

### First-Time Setup

#### 1. Initialize the Vault

From the main RocketVPS menu:
```
Main Menu → Credentials Vault → Initialize Vault
```

Or via command line:
```bash
./rocketvps vault init
```

#### 2. Create Master Password

When prompted, create a strong master password:

**Requirements:**
- At least 12 characters
- Mix of uppercase and lowercase letters
- At least one number
- At least one special character
- Avoid common words or patterns

**Example of Strong Password:**
```
MyV@ult2024!Secure
```

**Bad Examples:**
```
password123      ❌ Too weak
Admin@123       ❌ Too common
mypassword      ❌ No special chars
```

#### 3. Confirm Master Password

Re-enter the master password to confirm. The vault will be initialized and locked.

**✓ Success!** Your vault is now ready to use.

---

### Unlocking the Vault

#### From Menu:
```
Main Menu → Credentials Vault → Unlock Vault
```

#### From Command Line:
```bash
./rocketvps vault unlock
```

You'll be prompted for your master password. After successful unlock:
- Session remains active for **15 minutes**
- Auto-locks after inactivity
- Can be manually locked anytime

#### Checking Vault Status:
```bash
./rocketvps vault status
```

Output:
```
Vault Status: UNLOCKED
Session Expires: 14 minutes remaining
Stored Domains: 5
Last Access: 2024-01-15 10:30:45
```

---

### Locking the Vault

#### Manual Lock:
```
Main Menu → Credentials Vault → Lock Vault
```

Or:
```bash
./rocketvps vault lock
```

#### Auto-Lock:
The vault automatically locks after:
- **15 minutes** of inactivity
- System reboot
- SSH session ends

---

## Managing Credentials

### Viewing All Credentials

#### From Menu:
```
Main Menu → Credentials Vault → View All Credentials
```

#### Display Format:
```
╔═══════════════════════════════════════════════════════════════╗
║                     STORED CREDENTIALS                        ║
╚═══════════════════════════════════════════════════════════════╝

Domain                    Profile      Created              Status
────────────────────────────────────────────────────────────────
example.com              wordpress    2024-01-15 10:30    ● Active
myapp.com                laravel      2024-01-14 15:20    ● Active
api.service.com          nodejs       2024-01-13 09:15    ● Active

Total: 3 domains
```

**Status Indicators:**
- 🟢 **Active**: Credentials currently in use
- 🟡 **Archived**: Backup or old credentials
- 🔴 **Expired**: Needs rotation

---

### Viewing Domain Details

#### From Menu:
```
Main Menu → Credentials Vault → View Domain Details
```

Select a domain to see complete information:

```
╔═══════════════════════════════════════════════════════════════╗
║              CREDENTIALS: example.com                         ║
╚═══════════════════════════════════════════════════════════════╝

DOMAIN INFORMATION
  Domain:           example.com
  Document Root:    /var/www/example.com
  Profile Type:     wordpress
  PHP Version:      8.2
  SSL Enabled:      Yes
  Created:          2024-01-15 10:30:45
  Last Updated:     2024-01-15 10:30:45

ADMIN CREDENTIALS
  URL:              https://example.com/wp-admin
  Username:         admin
  Password:         **************** [Show]
  Email:            admin@example.com

DATABASE CREDENTIALS
  Type:             mysql
  Host:             localhost
  Port:             3306
  Database:         wpdb_example
  Username:         wpuser_example
  Password:         **************** [Show]

FTP CREDENTIALS
  Host:             example.com
  Port:             21
  Username:         wp_admin
  Password:         **************** [Show]
  Path:             /var/www/example.com

SERVICES
  Redis:            Enabled (localhost:6379)
  Backup:           Enabled (daily, 7 days retention)

Press [S] to show passwords | [C] to copy | [E] to edit | [Q] to quit
```

---

### Searching Credentials

#### From Menu:
```
Main Menu → Credentials Vault → Search
```

**Search Options:**
1. **By Domain Name**: Find exact or partial matches
2. **By Profile Type**: wordpress, laravel, nodejs, etc.
3. **By Status**: active, archived, expired

#### Example Search:
```
Enter search term: example

Search Results (2 found):
  1. example.com (wordpress)
  2. api.example.com (nodejs)

Select a domain to view details, or Q to quit.
```

---

### Adding Credentials Manually

While credentials are auto-saved during domain setup, you can add them manually:

#### From Menu:
```
Main Menu → Credentials Vault → Add Credentials
```

#### Follow Prompts:
1. **Domain Name**: example.com
2. **Profile Type**: wordpress / laravel / nodejs / static / ecommerce / saas
3. **Credential Details**: Varies by profile type

#### Example - WordPress:
```
Domain: example.com
Profile: wordpress

Admin Username: admin
Admin Password: [generate or enter]
Admin Email: admin@example.com

Database Name: wpdb_example
Database User: wpuser_example
Database Password: [generate or enter]

FTP User: wp_admin
FTP Password: [generate or enter]

✓ Credentials saved successfully!
```

---

### Updating Credentials

#### From Menu:
```
Main Menu → Credentials Vault → Update Credentials
```

**Steps:**
1. Select domain
2. Choose field to update:
   - Admin password
   - Database password
   - FTP password
   - Email address
   - Other fields
3. Enter new value
4. Confirm changes

#### Example:
```
Domain: example.com
Select field to update:
  1. Admin Password
  2. Database Password
  3. FTP Password
  4. Admin Email
  5. Other

Choice: 1

Current Admin Password: ****************
New Admin Password: [enter or generate]
Confirm Password: [confirm]

✓ Admin password updated successfully!
⚠ Remember to update WordPress admin panel with new password.
```

---

### Deleting Credentials

#### From Menu:
```
Main Menu → Credentials Vault → Delete Credentials
```

**⚠ Warning**: This action cannot be undone!

**Steps:**
1. Select domain to delete
2. Type 'DELETE' to confirm
3. Credentials are permanently removed

**Best Practice**: Export credentials before deletion as backup.

---

## Security Features

### Master Password Protection

#### Changing Master Password

**⚠ Important**: This will re-encrypt all stored credentials.

```
Main Menu → Credentials Vault → Settings → Change Master Password
```

**Process:**
1. Enter current master password
2. Enter new master password (must meet requirements)
3. Confirm new master password
4. System re-encrypts entire database

**Time Required**: ~1-2 seconds per stored domain

---

### Session Management

#### Session Timeout

- **Default**: 15 minutes
- **Action**: Auto-lock vault
- **Reset**: Any vault operation resets timer

#### Session Status:
```bash
./rocketvps vault session
```

Output:
```
Session Active: Yes
Time Remaining: 12 minutes 34 seconds
Last Activity: 2024-01-15 10:45:12
```

#### Extending Session:
```bash
./rocketvps vault extend
```

Resets timer to 15 minutes.

---

### Brute-Force Protection

#### How It Works:
- **Maximum Attempts**: 5 failed passwords
- **Lockout Duration**: 15 minutes
- **Counter Reset**: After successful unlock

#### If Locked Out:
```
❌ TOO MANY FAILED ATTEMPTS

Vault is locked for security.
Please wait 15 minutes before trying again.

Lockout expires: 2024-01-15 11:00:00
Time remaining: 14 minutes 32 seconds
```

**Emergency Access**:
```bash
sudo rm /opt/rocketvps/config/vault/lockout
```

⚠ Only use if you're certain of your password!

---

### Access Logging

#### Viewing Access Log

```
Main Menu → Credentials Vault → View Access Log
```

**Log Display Options:**
1. Last 20 entries
2. Last 50 entries
3. Last 1000 entries
4. Search by keyword

#### Example Log:
```
TIMESTAMP            USER     ACTION              STATUS  DETAILS
──────────────────────────────────────────────────────────────────
2024-01-15 10:45:12  root     unlock              success
2024-01-15 10:45:30  root     get_credentials     success domain: example.com
2024-01-15 10:46:15  root     update_credentials  success domain: example.com, field: admin.password
2024-01-15 10:50:20  root     export              success domain: example.com, format: json
2024-01-15 11:00:00  root     lock                success auto-timeout
2024-01-15 11:15:45  root     unlock              failed  wrong_password
```

#### Log Location:
```
/opt/rocketvps/vault/access.log
```

#### Analyzing Logs:
```bash
# Failed unlock attempts
grep "unlock.*failed" /opt/rocketvps/vault/access.log

# Credential exports
grep "export" /opt/rocketvps/vault/access.log

# Today's activity
grep "$(date +%Y-%m-%d)" /opt/rocketvps/vault/access.log
```

---

## Export & Import

### Exporting Credentials

#### From Menu:
```
Main Menu → Credentials Vault → Export Credentials
```

#### Export Options:

**1. Single Domain**
- Choose domain
- Select format (JSON / CSV / TXT)
- Specify output file

**2. All Domains**
- Select format
- Creates archive with all credentials

#### Export Formats:

**JSON** (Structured, machine-readable):
```json
{
  "domain": "example.com",
  "profile": "wordpress",
  "created": "2024-01-15 10:30:45",
  "admin": {
    "username": "admin",
    "password": "SecurePass@123",
    "email": "admin@example.com"
  },
  "database": {
    "type": "mysql",
    "host": "localhost",
    "database": "wpdb_example",
    "username": "wpuser_example",
    "password": "DbPass@456"
  }
}
```

**CSV** (Spreadsheet compatible):
```csv
Domain,Profile,Admin_User,Admin_Pass,DB_Host,DB_Name,DB_User,DB_Pass
example.com,wordpress,admin,SecurePass@123,localhost,wpdb_example,wpuser_example,DbPass@456
```

**TXT** (Human-readable):
```
DOMAIN: example.com
PROFILE: wordpress
CREATED: 2024-01-15 10:30:45

ADMIN CREDENTIALS:
  Username: admin
  Password: SecurePass@123
  Email: admin@example.com

DATABASE CREDENTIALS:
  Host: localhost
  Database: wpdb_example
  Username: wpuser_example
  Password: DbPass@456
```

#### Export Security:

⚠ **Exported files contain PLAIN TEXT passwords!**

**Best Practices:**
1. Export to encrypted USB drive
2. Delete exported files after use
3. Never email unencrypted exports
4. Use secure file transfer (SFTP/SCP)

---

### Importing Credentials

#### From Existing Config Files:
```
Main Menu → Credentials Vault → Import → From Config Files
```

**Supported Imports:**
- WordPress wp-config.php
- Laravel .env
- Node.js .env / config files

**Process:**
1. Select import source
2. Choose domains to import
3. Verify detected credentials
4. Confirm import

#### Example:
```
Scanning for WordPress installations...

Found 3 WordPress sites:
  ☑ example.com      (/var/www/example.com/wp-config.php)
  ☑ mysite.com       (/var/www/mysite.com/wp-config.php)
  ☐ testsite.local   (credentials already in vault)

Import selected sites? [y/n]: y

Importing example.com... ✓
Importing mysite.com... ✓

✓ Successfully imported 2 domains
```

#### From Backup:
```
Main Menu → Credentials Vault → Import → From Backup
```

Restore vault database from encrypted backup.

---

## Password Rotation

### Automatic Password Generation

#### Rotate Single Domain:
```
Main Menu → Credentials Vault → Rotate Passwords → Single Domain
```

**Steps:**
1. Select domain
2. Choose which passwords to rotate:
   - Admin password
   - Database password
   - FTP password
   - All passwords
3. Confirm rotation
4. Passwords automatically updated in vault

**New Password Specs:**
- Length: 20-24 characters
- Mixed case: A-Z, a-z
- Numbers: 0-9
- Special characters: !@#$%^&*
- No ambiguous characters: 0/O, 1/l/I

#### Example Output:
```
Rotating passwords for: example.com

Admin Password:      nK9$mP2xL#vQ8rT4wS6yU
Database Password:   fH3@jK7*pR5$nM9!qW2xZ
FTP Password:        cV8#bN4*mL6@hK2$pQ9yT

✓ Passwords rotated successfully!
✓ Vault updated

⚠ IMPORTANT NEXT STEPS:
  1. Update WordPress admin password manually
  2. Update wp-config.php with new database password
  3. Update FTP client configuration
```

---

#### Rotate All Domains:
```
Main Menu → Credentials Vault → Rotate Passwords → All Domains
```

⚠ **Use with caution!** This rotates passwords for ALL stored domains.

**Confirmation Required**: Type 'ROTATE ALL' to proceed

---

### Manual Password Update

After rotation, you must manually update:

#### WordPress:
```bash
# Update wp-config.php
nano /var/www/example.com/wp-config.php

# Find and update:
define('DB_PASSWORD', 'NEW_PASSWORD_HERE');
```

#### Laravel:
```bash
# Update .env
nano /var/www/example.com/.env

# Find and update:
DB_PASSWORD=NEW_PASSWORD_HERE
```

#### MySQL Direct:
```bash
mysql -u root -p
ALTER USER 'username'@'localhost' IDENTIFIED BY 'NEW_PASSWORD';
FLUSH PRIVILEGES;
```

---

## Troubleshooting

### Forgot Master Password

**⚠ CRITICAL**: There is **NO PASSWORD RECOVERY**!

If you forget your master password:
1. All encrypted credentials are **permanently lost**
2. You must **reinitialize** the vault
3. You must **re-enter** all credentials manually

**Prevention:**
- Write down master password in secure location
- Use a password manager
- Keep encrypted backup of vault database

---

### Vault Won't Unlock

**Check:**

1. **Correct Password?**
   ```
   Try entering password carefully
   Check Caps Lock
   ```

2. **Locked Out?**
   ```bash
   ./rocketvps vault status
   ```
   
   If locked out, wait 15 minutes or:
   ```bash
   sudo rm /opt/rocketvps/config/vault/lockout
   ```

3. **Corrupted Database?**
   ```bash
   ./rocketvps vault verify
   ```
   
   If corrupted, restore from backup:
   ```bash
   ./rocketvps vault restore /path/to/backup
   ```

---

### Session Keeps Expiring

**Extend Session Timeout:**

Edit vault config:
```bash
nano /opt/rocketvps/vault/config.conf
```

Change:
```bash
SESSION_TIMEOUT=1800  # 30 minutes instead of 15
```

Restart vault:
```bash
./rocketvps vault restart
```

⚠ **Security Trade-off**: Longer timeout = more exposure risk

---

### Export Fails

**Check Permissions:**
```bash
ls -la /opt/rocketvps/vault/
```

Should show:
```
drwx------  root root  vault/
-rw-------  root root  credentials.db.enc
```

**Fix Permissions:**
```bash
sudo chown -R root:root /opt/rocketvps/vault
sudo chmod 700 /opt/rocketvps/vault
sudo chmod 600 /opt/rocketvps/vault/*.enc
```

---

### Credentials Not Auto-Saving

**Check Integration:**
```bash
./rocketvps vault integration-status
```

**Fix:**
```bash
# Ensure vault is unlocked before domain setup
./rocketvps vault unlock

# Then set up domain
./rocketvps domain add
```

---

## Best Practices

### Master Password

✅ **DO:**
- Use 12+ characters
- Mix uppercase, lowercase, numbers, symbols
- Use unique password (not used elsewhere)
- Store securely offline
- Change periodically (every 6-12 months)

❌ **DON'T:**
- Use common words or patterns
- Share with anyone
- Write in plain text files
- Use same password for multiple systems

---

### Regular Maintenance

#### Weekly:
```bash
# Rotate high-risk passwords
./rocketvps vault rotate --domain=public-site.com

# Review access logs
./rocketvps vault logs --last=100
```

#### Monthly:
```bash
# Backup vault
./rocketvps vault backup --encrypt

# Audit stored credentials
./rocketvps vault audit
```

#### Quarterly:
```bash
# Change master password
./rocketvps vault change-master-password

# Clean old entries
./rocketvps vault clean --archived
```

---

### Backup Strategy

**1. Automated Backups:**
```bash
# Add to crontab
0 2 * * * /opt/rocketvps/rocketvps vault backup --auto
```

**2. Offsite Backup:**
```bash
# Copy to remote server
scp /opt/rocketvps/vault/backup_*.enc user@backup-server:/backups/
```

**3. Test Restores:**
```bash
# Quarterly restore test
./rocketvps vault restore-test /path/to/backup
```

---

### Access Control

**Limit Root Access:**
```bash
# Create vault admin user
useradd vaultadmin
usermod -aG rocketvps vaultadmin

# Set sudo access
echo "vaultadmin ALL=(root) /opt/rocketvps/rocketvps vault *" >> /etc/sudoers
```

**Audit Trail:**
```bash
# Enable detailed logging
echo "VERBOSE_LOGGING=true" >> /opt/rocketvps/vault/config.conf
```

---

### Emergency Procedures

#### Suspected Breach:

**Immediate Actions:**
1. Lock vault immediately
   ```bash
   ./rocketvps vault lock --force
   ```

2. Review access logs
   ```bash
   ./rocketvps vault logs --all
   ```

3. Rotate all passwords
   ```bash
   ./rocketvps vault rotate --all --force
   ```

4. Change master password
   ```bash
   ./rocketvps vault change-master-password
   ```

5. Check server logs
   ```bash
   grep "vault" /var/log/syslog
   grep "vault" /var/log/auth.log
   ```

---

## Quick Reference Card

### Common Commands

```bash
# Initialize vault
./rocketvps vault init

# Unlock/Lock
./rocketvps vault unlock
./rocketvps vault lock

# View credentials
./rocketvps vault list
./rocketvps vault show example.com

# Search
./rocketvps vault search wordpress

# Export
./rocketvps vault export example.com --format=json

# Rotate passwords
./rocketvps vault rotate example.com

# Backup
./rocketvps vault backup

# Status
./rocketvps vault status
```

---

### File Locations

```
/opt/rocketvps/vault/
├── master.key.enc          # Encrypted master key
├── credentials.db.enc      # Encrypted credentials
├── access.log              # Access audit log
├── config.conf             # Vault configuration
└── backups/                # Automatic backups
    └── backup_*.enc

/opt/rocketvps/config/vault/
├── session.lock            # Active session
└── lockout                 # Lockout timestamp
```

---

### Support

**Need Help?**

- Documentation: `/opt/rocketvps/docs/VAULT_USER_GUIDE.md`
- Technical Support: Open issue on GitHub
- Emergency: Check `/var/log/rocketvps/vault.log`

**Report Security Issues:**
- Email: security@rocketvps.example
- PGP Key: Available on website

---

**RocketVPS v2.2.0** | Last Updated: 2024-01-15
