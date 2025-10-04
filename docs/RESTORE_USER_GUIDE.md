# RocketVPS v2.2.0 - Smart Restore User Guide

## Table of Contents
1. [Overview](#overview)
2. [Before You Start](#before-you-start)
3. [Backup Preview](#backup-preview)
4. [Full Restore](#full-restore)
5. [Incremental Restore](#incremental-restore)
6. [Safety Features](#safety-features)
7. [Snapshot Management](#snapshot-management)
8. [Troubleshooting](#troubleshooting)
9. [Best Practices](#best-practices)

---

## Overview

**Smart Restore** is an intelligent backup restoration system with built-in safety features, automatic rollback, and comprehensive verification.

### Key Features

- **📋 Backup Preview**: Analyze backup contents before restore
- **⚡ Full Restore**: Complete site restoration in one operation
- **🎯 Incremental Restore**: Restore only specific components
- **🛡️ Safety Snapshots**: Automatic pre-restore snapshots
- **↩️ Automatic Rollback**: Instant rollback on failure
- **✅ Verification**: 4-tier post-restore validation
- **📊 Progress Tracking**: Real-time restore progress
- **📝 Detailed Logging**: Complete restore history

### What Can Be Restored

**Files:**
- Web application files (PHP, HTML, JS, CSS)
- Media files (images, videos, documents)
- Configuration files
- Logs and data files

**Database:**
- MySQL/MariaDB databases
- Complete schema and data
- Database users and permissions

**Configuration:**
- Nginx virtual host configuration
- PHP-FPM pool configuration
- SSL certificates
- Cron jobs

---

## Before You Start

### Prerequisites Check

Before performing any restore, ensure:

✅ **Sufficient Disk Space**
- At least 2x backup size free
- Space for safety snapshot
- Space for temporary extraction

```bash
# Check available space
df -h /var/www
df -h /tmp
```

✅ **Services Running**
```bash
# Check service status
systemctl status nginx
systemctl status php8.2-fpm
systemctl status mysql
```

✅ **Backup Integrity**
```bash
# Verify backup file
./rocketvps restore verify backup_20240115_120000.tar.gz
```

✅ **No Active Users**
- Notify users of maintenance
- Put site in maintenance mode
- Clear active sessions

---

### Understanding Backup Structure

RocketVPS backups follow this structure:

```
backup_20240115_120000.tar.gz
├── backup.meta              # Metadata JSON
├── files/                   # Web files
│   ├── public/
│   ├── app/
│   └── storage/
├── database/                # Database dumps
│   └── database.sql.gz
└── config/                  # Configuration
    ├── nginx.conf
    └── php-fpm.conf
```

**Metadata Example:**
```json
{
  "domain": "example.com",
  "timestamp": "2024-01-15 12:00:00",
  "type": "full",
  "size": 52428800,
  "files_count": 1542,
  "database": {
    "name": "wpdb_example",
    "tables": 12,
    "size": 10485760
  }
}
```

---

## Backup Preview

### Why Preview First?

**Before restoring**, always preview the backup to:
- Verify backup contents
- Check backup date and size
- Estimate restore time
- Confirm adequate disk space
- Review what will be restored

---

### Accessing Backup Preview

#### From Menu:
```
Main Menu → Smart Restore → Preview Backup
```

#### Steps:
1. Select domain
2. Choose backup from list
3. View detailed preview

---

### Preview Display

```
╔═══════════════════════════════════════════════════════════════╗
║              BACKUP PREVIEW: example.com                      ║
╚═══════════════════════════════════════════════════════════════╝

BACKUP INFORMATION
  Backup File:      backup_20240115_120000.tar.gz
  Created:          2024-01-15 12:00:00 (5 days ago)
  Size:             50.0 MB
  Integrity:        ✓ Valid (checksum verified)
  
FILE BREAKDOWN
  Total Files:      1,542 files
  
  PHP Files:        385 files (12.5 MB)
  JavaScript:       124 files (5.2 MB)
  CSS:              89 files (2.1 MB)
  Images:           856 files (28.4 MB)
  Other:            88 files (1.8 MB)
  
  Top Directories:
    /wp-content/uploads      805 files (25.6 MB)
    /wp-content/plugins      512 files (15.2 MB)
    /wp-content/themes       225 files (9.2 MB)

DATABASE
  Database Name:    wpdb_example
  Size:             10.0 MB (compressed: 2.5 MB)
  Tables:           12 tables
  Estimated Rows:   ~15,400 rows
  
  Top Tables:
    wp_posts          5,240 rows (4.2 MB)
    wp_postmeta      8,120 rows (3.1 MB)
    wp_comments      1,850 rows (1.5 MB)

CONFIGURATION
  Nginx Config:     ✓ Present
  PHP-FPM Pool:     ✓ Present
  SSL Certificate:  ✓ Present
  Cron Jobs:        2 jobs

RESTORE ESTIMATES
  Extraction Time:  ~30 seconds
  File Restore:     ~45 seconds
  Database Import:  ~25 seconds
  Configuration:    ~10 seconds
  Total Time:       ~2 minutes
  
  Disk Space Required:
    Temporary:      150 MB
    Snapshot:       50 MB
    Total:          200 MB
    
  Available Space:  2.5 GB ✓ Sufficient

WARNINGS
  ⚠ This will overwrite existing files
  ⚠ Current database will be replaced
  ⚠ Backup is 5 days old - verify if correct version

Actions:
  [F] Full Restore  [I] Incremental Restore  [Q] Quit
```

---

### Interpreting Preview Data

#### File Breakdown

**Large Image Count?**
- Expect longer restore time
- May need more disk space
- Consider incremental restore if only code changed

**Many PHP Files?**
- Quick restore
- Check PHP version compatibility

**Old Backup?**
- ⚠ Verify this is the correct backup
- Check if newer backups exist
- Consider if data will be lost

#### Database Analysis

**Large Database?**
- Will take longer to import
- Ensure MySQL has enough memory
- Check for timeout issues

**Many Tables?**
- Normal for WordPress/Laravel
- May have custom tables
- Verify all tables needed

#### Warnings

🟡 **Informational**
- Backup age
- Minor disk space concerns

🟠 **Caution**
- Potential data loss
- Version mismatches

🔴 **Critical**
- Insufficient disk space
- Corrupted backup
- Missing components

---

## Full Restore

### What Is Full Restore?

**Full Restore** restores **everything** from the backup:
- ✅ All files and directories
- ✅ Complete database
- ✅ All configurations
- ✅ Services restarted

**Use When:**
- Complete site disaster recovery
- Moving to new server
- Rolling back major changes
- Recovering from hack/corruption

---

### Performing Full Restore

#### From Menu:
```
Main Menu → Smart Restore → Restore Domain
```

#### Steps:

**1. Select Domain**
```
Available Domains:
  1. example.com (5 backups)
  2. mysite.com (12 backups)
  3. testsite.local (3 backups)

Select domain: 1
```

**2. Choose Backup**
```
Available Backups for example.com:

  #   Date                 Size      Age      Integrity
  ─────────────────────────────────────────────────────
  1   2024-01-15 12:00    50.0 MB   5 days   ✓ Valid
  2   2024-01-14 12:00    49.8 MB   6 days   ✓ Valid
  3   2024-01-13 12:00    49.5 MB   7 days   ✓ Valid
  4   2024-01-12 12:00    48.9 MB   8 days   ✓ Valid
  5   2024-01-11 12:00    48.2 MB   9 days   ✓ Valid

Select backup (or P to preview): 1
```

**3. View Preview**
```
[Backup Preview Display - see previous section]

Proceed with Full Restore? [y/n]: 
```

**4. Final Confirmation**
```
╔═══════════════════════════════════════════════════════════════╗
║                    ⚠ FINAL WARNING ⚠                          ║
╚═══════════════════════════════════════════════════════════════╝

This will PERMANENTLY REPLACE:
  • All files in /var/www/example.com
  • Database: wpdb_example
  • Nginx configuration
  • PHP-FPM pool configuration

Current data will be backed up to safety snapshot:
  Location: /opt/rocketvps/snapshots/example.com/pre_restore_20240120_143000

You can rollback if restore fails or if you change your mind.

Type 'YES' to confirm full restore: YES
```

---

### Restore Process

Once confirmed, restore proceeds in **5 phases**:

#### Phase 1: Creating Safety Snapshot (20s)
```
Phase 1/5: Creating Safety Snapshot
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 100%

✓ Files backed up: 50.0 MB
✓ Database backed up: 10.0 MB
✓ Configuration backed up

Snapshot saved to: /opt/rocketvps/snapshots/example.com/pre_restore_20240120_143000
```

#### Phase 2: Extracting Backup (30s)
```
Phase 2/5: Extracting Backup
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 100%

✓ Extracted 1,542 files
✓ Extracted database dump
✓ Extracted configuration

Temporary location: /tmp/rocketvps_restore/example.com_20240120_143030
```

#### Phase 3: Restoring Files (45s)
```
Phase 3/5: Restoring Files
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 65%

Copying: wp-content/uploads/2024/01/image.jpg
Progress: 1,000 / 1,542 files

...

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 100%

✓ Restored 1,542 files
✓ Set permissions: www-data:www-data
✓ Set file permissions: 644
✓ Set directory permissions: 755
```

#### Phase 4: Restoring Database (25s)
```
Phase 4/5: Restoring Database
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 100%

✓ Dropped existing database
✓ Created new database
✓ Imported database dump (10.0 MB)
✓ Verified 12 tables
✓ Estimated 15,400 rows imported
```

#### Phase 5: Restoring Configuration (10s)
```
Phase 5/5: Restoring Configuration
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 100%

✓ Restored Nginx configuration
✓ Restored PHP-FPM pool configuration
✓ Tested Nginx configuration: OK
✓ Restarted nginx: active
✓ Restarted php8.2-fpm: active
```

---

### Verification

After restore, system performs **4-tier verification**:

```
╔═══════════════════════════════════════════════════════════════╗
║                    VERIFICATION REPORT                        ║
╚═══════════════════════════════════════════════════════════════╝

FILE INTEGRITY ✓
  Expected Files:    1,542
  Restored Files:    1,542
  Permissions:       ✓ Correct
  Ownership:         ✓ Correct (www-data:www-data)

DATABASE INTEGRITY ✓
  Connection:        ✓ Connected
  Database Exists:   ✓ Yes
  Expected Tables:   12
  Found Tables:      12
  Table Structure:   ✓ Valid

CONFIGURATION ✓
  Nginx Config:      ✓ Valid syntax
  Nginx Running:     ✓ Active
  PHP-FPM Config:    ✓ Valid
  PHP-FPM Running:   ✓ Active
  SSL Certificate:   ✓ Valid (expires 2024-06-15)

SERVICES ✓
  Nginx:             ✓ Running
  PHP-FPM:           ✓ Running
  MySQL:             ✓ Running
  Redis:             ✓ Running

═══════════════════════════════════════════════════════════════

✅ RESTORE COMPLETED SUCCESSFULLY

Domain:           example.com
Restore Time:     2 minutes 10 seconds
Restored Files:   1,542 files (50.0 MB)
Database:         wpdb_example (10.0 MB, 12 tables)

Test your site: https://example.com
```

---

### Success!

Your site is now restored. **Next steps:**

1. **Test Site Functionality**
   ```bash
   curl -I https://example.com
   ```

2. **Check Admin Access**
   - Login to admin panel
   - Verify settings
   - Test core features

3. **Clean Up**
   ```bash
   # Remove snapshot after verification
   ./rocketvps restore cleanup example.com
   ```

4. **Update Vault** (if passwords changed)
   ```bash
   ./rocketvps vault update example.com
   ```

---

## Incremental Restore

### What Is Incremental Restore?

**Incremental Restore** allows you to restore **specific components** only:

- ✅ Files only (without database)
- ✅ Database only (without files)
- ✅ Configuration only
- ✅ Any combination

**Use When:**
- Only files/database corrupted
- Testing partial restore
- Selective component updates
- Faster restore needed

---

### Performing Incremental Restore

#### From Menu:
```
Main Menu → Smart Restore → Restore Domain → Incremental Restore
```

After selecting domain and backup, choose components:

```
╔═══════════════════════════════════════════════════════════════╗
║              INCREMENTAL RESTORE: example.com                 ║
╚═══════════════════════════════════════════════════════════════╝

Select components to restore:

  ☑ Files (1,542 files, 50.0 MB)
  ☑ Database (wpdb_example, 10.0 MB)
  ☑ Configuration (nginx, php-fpm)

Estimate: 2 minutes 10 seconds

Actions:
  [Space] Toggle selection
  [A] Select All
  [N] Select None
  [C] Continue
  [Q] Quit

Current selection: All components
```

---

### Component Options

#### Files Only
```
Selected: Files

What will be restored:
  ✓ All web application files
  ✓ Media files (images, videos)
  ✓ Logs and data files
  
What will NOT be restored:
  ✗ Database (current database unchanged)
  ✗ Configuration (current config unchanged)

⚠ Note: If files expect different database schema, site may break!

Estimated time: 1 minute 15 seconds
```

#### Database Only
```
Selected: Database

What will be restored:
  ✓ Complete database dump
  ✓ All tables and data
  ✓ Database users
  
What will NOT be restored:
  ✗ Files (current files unchanged)
  ✗ Configuration (current config unchanged)

⚠ Note: If files don't match database version, site may break!

Estimated time: 25 seconds
```

#### Configuration Only
```
Selected: Configuration

What will be restored:
  ✓ Nginx virtual host config
  ✓ PHP-FPM pool config
  ✓ SSL certificates
  
What will NOT be restored:
  ✗ Files (current files unchanged)
  ✗ Database (current database unchanged)

⚠ Note: Services will be restarted!

Estimated time: 10 seconds
```

---

### Mixed Selection Example

```
Selected: Files + Database (without Configuration)

What will be restored:
  ✓ All web application files
  ✓ Complete database
  
What will NOT be restored:
  ✗ Configuration (current nginx/php-fpm unchanged)

Benefits:
  • Faster than full restore
  • Current optimized configs preserved
  • Good for rolling back code/data changes

Estimated time: 1 minute 40 seconds

Proceed? [y/n]: y
```

---

### Incremental Restore Process

Process is similar to full restore, but skips unselected components:

```
Phase 1/3: Creating Safety Snapshot
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 100%
✓ Snapshot created

Phase 2/3: Restoring Files
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 100%
✓ Restored 1,542 files

Phase 3/3: Restoring Database
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 100%
✓ Restored database

⊗ Skipped: Configuration (not selected)

✅ INCREMENTAL RESTORE COMPLETED
Restore Time: 1 minute 42 seconds
```

---

## Safety Features

### Automatic Safety Snapshot

Before **every** restore (full or incremental), system creates safety snapshot:

```
Creating Safety Snapshot...

Snapshot Contents:
  ✓ files.tar.gz          (50.0 MB) - All current files
  ✓ database.sql.gz       (2.5 MB)  - Current database dump
  ✓ config/nginx.conf               - Current nginx config
  ✓ config/php-fpm.conf             - Current PHP-FPM config

Snapshot Location:
  /opt/rocketvps/snapshots/example.com/pre_restore_20240120_143000

Retention: 24 hours (auto-cleanup)
```

**Why?**
- Instant rollback if restore fails
- Manual rollback if you change your mind
- Multiple restore attempts without data loss

---

### Automatic Rollback

System automatically rolls back if:

❌ **Extraction Failure**
```
Phase 2/5: Extracting Backup
✗ ERROR: Backup archive corrupted

AUTOMATIC ROLLBACK INITIATED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 100%

✓ Restored from snapshot
✓ All services running
✓ Site unchanged

No changes were made to your site.
```

❌ **File Restore Failure**
```
Phase 3/5: Restoring Files
✗ ERROR: Insufficient disk space

AUTOMATIC ROLLBACK INITIATED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 100%

✓ Restored files from snapshot
✓ Site unchanged
```

❌ **Database Import Failure**
```
Phase 4/5: Restoring Database
✗ ERROR: Database import failed (syntax error at line 1523)

AUTOMATIC ROLLBACK INITIATED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 100%

✓ Restored database from snapshot
✓ Restored files from snapshot
✓ All services running
✓ Site unchanged
```

❌ **Verification Failure**
```
Verification: Database Integrity
✗ ERROR: Expected 12 tables, found 10

AUTOMATIC ROLLBACK INITIATED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 100%

✓ Restored from snapshot
✓ Site unchanged
```

---

### Manual Rollback

If restore succeeds but you want to undo:

```bash
./rocketvps restore rollback example.com
```

**Steps:**

1. **Select Snapshot**
```
Available Snapshots for example.com:

  #   Created              Type          Size
  ────────────────────────────────────────────
  1   2024-01-20 14:30    pre_restore   52.5 MB
  2   2024-01-19 10:15    pre_restore   51.8 MB

Select snapshot: 1
```

2. **Confirm Rollback**
```
⚠ This will replace current site with snapshot!

Snapshot Details:
  Created:   2024-01-20 14:30:00
  Files:     50.0 MB
  Database:  2.5 MB
  Age:       15 minutes

Type 'ROLLBACK' to confirm: ROLLBACK
```

3. **Rollback Process**
```
Rolling back to snapshot...
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 100%

✓ Files restored
✓ Database restored
✓ Configuration restored
✓ Services restarted

✅ ROLLBACK COMPLETED
Site restored to state at 2024-01-20 14:30:00
```

---

## Snapshot Management

### Viewing Snapshots

```
Main Menu → Smart Restore → Manage Snapshots
```

**Snapshot List:**
```
╔═══════════════════════════════════════════════════════════════╗
║                   SNAPSHOT MANAGEMENT                         ║
╚═══════════════════════════════════════════════════════════════╝

Domain: example.com

  #   Created              Age        Size      Status
  ──────────────────────────────────────────────────────────────
  1   2024-01-20 14:30    2 hours    52.5 MB   ✓ Valid
  2   2024-01-20 10:15    6 hours    51.9 MB   ✓ Valid
  3   2024-01-19 16:45    22 hours   51.2 MB   ⚠ Expires soon
  4   2024-01-18 14:20    2 days     50.8 MB   ✗ Expired

Total: 4 snapshots (206.4 MB)
Expired: 1 snapshot (50.8 MB)

Actions:
  [C] Clean Expired
  [D] Delete Snapshot
  [R] Rollback to Snapshot
  [Q] Quit
```

---

### Cleaning Snapshots

**Automatic Cleanup:**
- Snapshots older than 24 hours auto-delete
- Runs during daily maintenance
- Configurable retention period

**Manual Cleanup:**
```
Action: C (Clean Expired)

Cleaning expired snapshots...

Deleting: pre_restore_20240118_142000 (2 days old)
  ✓ Deleted files (50.8 MB freed)

Cleanup Summary:
  Deleted: 1 snapshot
  Space Freed: 50.8 MB
  Remaining: 3 snapshots (155.6 MB)
```

---

### Deleting Specific Snapshot

```
Action: D (Delete)

Select snapshot to delete: 2

⚠ Warning: Cannot undo deletion!

Snapshot: pre_restore_20240120_101500
Created: 2024-01-20 10:15:00
Size: 51.9 MB

Delete this snapshot? [y/n]: y

✓ Snapshot deleted
✓ Space freed: 51.9 MB
```

---

### Snapshot Retention Settings

Edit configuration:
```bash
nano /opt/rocketvps/config/restore.conf
```

```bash
# Snapshot retention (hours)
SNAPSHOT_RETENTION=24        # Default: 24 hours

# Maximum snapshots per domain
MAX_SNAPSHOTS=5              # Default: 5

# Auto-cleanup enabled
AUTO_CLEANUP=true            # Default: true
```

---

## Troubleshooting

### Restore Fails Immediately

**Error: "Backup file not found"**

Check backup location:
```bash
ls -la /opt/rocketvps/backups/example.com/
```

If missing:
```bash
# List all backups
./rocketvps backup list

# Check backup directory
./rocketvps backup config
```

---

**Error: "Insufficient disk space"**

Check space:
```bash
df -h
```

Free space:
```bash
# Clean old backups
./rocketvps backup clean

# Clean snapshots
./rocketvps restore cleanup --all

# Clean temp files
rm -rf /tmp/rocketvps_restore/*
```

---

**Error: "Backup integrity check failed"**

Backup corrupted. Try:
```bash
# Re-download backup (if from remote)
./rocketvps backup download example.com backup_20240115_120000

# Use older backup
./rocketvps restore list example.com
```

---

### Restore Hangs or Freezes

**During extraction:**
```bash
# Check if process running
ps aux | grep tar

# Check system load
top

# If hung, kill and retry
killall tar
./rocketvps restore retry example.com
```

**During database import:**
```bash
# Check MySQL process
ps aux | grep mysql

# Check MySQL logs
tail -f /var/log/mysql/error.log

# If timeout, increase limit
mysql -u root -p -e "SET GLOBAL max_allowed_packet=1073741824;"
```

---

### Restore Completes but Site Broken

**Check restore log:**
```bash
./rocketvps restore logs example.com
```

**Common issues:**

**1. Permission Problems**
```bash
# Fix ownership
chown -R www-data:www-data /var/www/example.com

# Fix permissions
find /var/www/example.com -type d -exec chmod 755 {} \;
find /var/www/example.com -type f -exec chmod 644 {} \;
```

**2. Database Connection**
```bash
# Test connection
mysql -u wpuser_example -p wpdb_example

# Update wp-config.php if needed
nano /var/www/example.com/wp-config.php
```

**3. Nginx Configuration**
```bash
# Test config
nginx -t

# Reload nginx
systemctl reload nginx

# Check error log
tail -f /var/log/nginx/error.log
```

**4. PHP Errors**
```bash
# Check PHP-FPM
systemctl status php8.2-fpm

# Check PHP error log
tail -f /var/log/php8.2-fpm.log
```

---

### Rollback Fails

**Error: "Snapshot not found"**
```bash
# List snapshots
ls -la /opt/rocketvps/snapshots/example.com/

# If missing, use backup instead
./rocketvps restore list example.com
```

**Error: "Rollback partially completed"**
```bash
# Check what was rolled back
./rocketvps restore status example.com

# Manual fix
# 1. Restore files
tar xzf /opt/rocketvps/snapshots/example.com/pre_restore_*/files.tar.gz -C /var/www/example.com

# 2. Restore database
gunzip < /opt/rocketvps/snapshots/example.com/pre_restore_*/database.sql.gz | mysql -u root -p wpdb_example
```

---

## Best Practices

### Before Restore

✅ **1. Always Preview First**
```bash
./rocketvps restore preview example.com backup_20240115_120000.tar.gz
```

✅ **2. Verify Backup Integrity**
```bash
./rocketvps restore verify backup_20240115_120000.tar.gz
```

✅ **3. Check Disk Space**
```bash
df -h
# Need: 2x backup size + snapshot size
```

✅ **4. Put Site in Maintenance Mode**
```bash
# WordPress
wp maintenance-mode activate

# Or create maintenance page
echo "Under Maintenance" > /var/www/example.com/maintenance.html
```

✅ **5. Notify Users**
- Email/SMS notification
- Status page update
- Expected downtime

---

### During Restore

✅ **Monitor Progress**
```bash
# Watch restore log
tail -f /opt/rocketvps/restore_logs/example.com/restore_*.log

# Monitor system resources
htop
```

✅ **Don't Interrupt**
- Let restore complete
- Automatic rollback handles failures
- Interrupting may corrupt site

---

### After Restore

✅ **1. Verify Functionality**
```bash
# Test homepage
curl -I https://example.com

# Test admin
curl -I https://example.com/wp-admin

# Test API endpoints
curl https://example.com/api/health
```

✅ **2. Check Logs**
```bash
# Nginx access log
tail -f /var/log/nginx/example.com.access.log

# Nginx error log
tail -f /var/log/nginx/example.com.error.log

# PHP errors
tail -f /var/log/php8.2-fpm.log
```

✅ **3. Test Core Features**
- Login/logout
- Database queries
- File uploads
- Email sending
- Payment processing (if applicable)

✅ **4. Clean Up**
```bash
# Remove snapshot after verification (24h+ after restore)
./rocketvps restore cleanup example.com

# Remove maintenance mode
wp maintenance-mode deactivate
```

✅ **5. Update Documentation**
- Record restore date/time
- Note any issues encountered
- Update runbook if needed

---

### Backup Strategy Integration

**Regular Backups:**
```bash
# Daily automated backups
./rocketvps backup schedule example.com daily

# Retention policy
./rocketvps backup retention 7  # Keep 7 days
```

**Pre-Change Backups:**
```bash
# Before major updates
./rocketvps backup create example.com --label="pre-update"

# Before plugin installs
./rocketvps backup create example.com --label="pre-plugin"
```

**Test Restores:**
```bash
# Monthly restore test
./rocketvps restore test example.com

# Validate backup integrity
./rocketvps backup validate --all
```

---

### Emergency Procedures

**Complete Site Failure:**

1. **Assess Situation**
   ```bash
   ./rocketvps status example.com
   ```

2. **Check Latest Backup**
   ```bash
   ./rocketvps restore list example.com
   ./rocketvps restore preview example.com latest
   ```

3. **Perform Full Restore**
   ```bash
   ./rocketvps restore full example.com latest
   ```

4. **Verify and Test**
   ```bash
   ./rocketvps restore verify example.com
   ```

---

**Partial Corruption:**

1. **Identify Affected Component**
   - Files only? → Incremental restore (files)
   - Database only? → Incremental restore (database)
   - Config only? → Incremental restore (config)

2. **Restore Specific Component**
   ```bash
   ./rocketvps restore incremental example.com --files-only
   ```

3. **Test Affected Areas**

---

## Quick Reference Card

### Common Commands

```bash
# List backups
./rocketvps restore list DOMAIN

# Preview backup
./rocketvps restore preview DOMAIN BACKUP_FILE

# Full restore
./rocketvps restore full DOMAIN BACKUP_FILE

# Incremental restore
./rocketvps restore incremental DOMAIN BACKUP_FILE

# List snapshots
./rocketvps restore snapshots DOMAIN

# Rollback
./rocketvps restore rollback DOMAIN

# View logs
./rocketvps restore logs DOMAIN

# Cleanup
./rocketvps restore cleanup DOMAIN
```

---

### Keyboard Shortcuts (Menu)

```
F - Full Restore
I - Incremental Restore
P - Preview Backup
V - View Logs
S - Manage Snapshots
R - Rollback
Q - Quit
```

---

### File Locations

```
/opt/rocketvps/backups/[domain]/
├── backup_YYYYMMDD_HHMMSS.tar.gz    # Backup archives
└── backup_YYYYMMDD_HHMMSS.meta      # Metadata

/opt/rocketvps/snapshots/[domain]/
└── pre_restore_YYYYMMDD_HHMMSS/     # Safety snapshots
    ├── files.tar.gz
    ├── database.sql.gz
    └── config/

/opt/rocketvps/restore_logs/[domain]/
└── restore_YYYYMMDD_HHMMSS.log      # Restore logs

/tmp/rocketvps_restore/
└── [domain]_YYYYMMDD_HHMMSS/        # Temp extraction
```

---

### Restore Time Estimates

| Site Size | Files       | Database | Time     |
|-----------|-------------|----------|----------|
| Small     | < 100 MB    | < 50 MB  | 1-2 min  |
| Medium    | 100-500 MB  | 50-200MB | 2-5 min  |
| Large     | 500MB-2GB   | 200MB-1GB| 5-15 min |
| Huge      | > 2 GB      | > 1 GB   | 15-30min |

---

### Support

**Need Help?**

- Documentation: `/opt/rocketvps/docs/RESTORE_USER_GUIDE.md`
- Restore Logs: `/opt/rocketvps/restore_logs/`
- Technical Support: Open issue on GitHub

**Report Issues:**
- Email: support@rocketvps.example
- Include: Domain, backup file, error logs

---

**RocketVPS v2.2.0** | Last Updated: 2024-01-15
