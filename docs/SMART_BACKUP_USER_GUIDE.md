# 📖 Smart Backup System - User Guide

**Version:** 2.2.0  
**Last Updated:** October 4, 2025  
**Audience:** System Administrators

---

## 📋 TABLE OF CONTENTS

1. [Introduction](#introduction)
2. [Getting Started](#getting-started)
3. [Understanding Backup Strategies](#understanding-backup-strategies)
4. [Manual Backups](#manual-backups)
5. [Automatic Scheduling](#automatic-scheduling)
6. [Backup Management](#backup-management)
7. [Restoration](#restoration)
8. [Monitoring & Statistics](#monitoring--statistics)
9. [Troubleshooting](#troubleshooting)
10. [Best Practices](#best-practices)
11. [FAQ](#faq)

---

## 📖 INTRODUCTION

### What is Smart Backup?

Smart Backup is an intelligent backup system that automatically analyzes your domains and selects the optimal backup strategy. It reduces backup time by up to **90%** and storage usage by up to **60%** through:

- 🎯 **Activity Analysis** - Tracks file changes and traffic
- 💾 **Incremental Backups** - Backs up only changed files
- ⏰ **Smart Scheduling** - Automatic optimal schedules
- 🗄️ **Database Optimization** - Skips cache and temporary data
- 🚀 **Parallel Execution** - Backs up multiple domains simultaneously

### Key Benefits

✅ **90% Faster Backups**
- Small site: 15 min → 5 sec
- Medium site: 30 min → 3 min
- Large site: 2 hours → 5 min

✅ **60% Storage Savings**
- Incremental backups use 20-40% of full backup size
- Database optimization saves 30-50%
- Exclude patterns save additional 20-30%

✅ **Zero Manual Work**
- Automatic strategy selection
- Automatic schedule setup
- Automatic optimization

✅ **100% Safe**
- Full backup verification
- Multiple restore points
- No data loss

---

## 🚀 GETTING STARTED

### Prerequisites

- RocketVPS v2.2.0 or higher
- Root or sudo access
- Sufficient disk space (2x largest domain size)

### Installation

Smart Backup is included with RocketVPS v2.2.0. No additional installation needed.

### Initialization

The system initializes automatically on first use. Backup directories are created at:

```
/opt/rocketvps/backups/
├── domain.com/              # Per-domain backups
├── .metadata/               # Backup metadata
├── .incremental/            # Incremental tracking
└── .tracking/               # Activity tracking
```

### Quick Start

**Backup a single domain:**

```bash
rocketvps backup-domain example.com
```

**Backup all domains:**

```bash
rocketvps backup-all
```

**Setup automatic backups:**

```bash
rocketvps setup-backup-schedule example.com
```

That's it! The system handles everything else automatically.

---

## 🎯 UNDERSTANDING BACKUP STRATEGIES

### Strategy Types

#### 1. Full Backup

**What it is:**
- Complete backup of all files and database
- Self-contained, independent backup

**When used:**
- Small domains (< 100MB)
- Low activity domains
- Weekly base backups

**Pros:**
- Simple restoration
- No dependencies
- Complete snapshot

**Cons:**
- Slower
- More storage
- Not efficient for large sites

**Example:**
```
example.com (50MB, low activity) → Full backup daily
Time: 5 seconds
Size: 50MB compressed
```

#### 2. Incremental Backup

**What it is:**
- Backs up only files changed since last backup
- Requires base full backup

**When used:**
- Medium/Large domains with high activity
- Daily backups for active sites

**Pros:**
- Very fast (90% faster)
- Minimal storage (20-40% of full)
- Efficient for active sites

**Cons:**
- Requires base backup
- Slightly more complex restoration

**Example:**
```
example.com (1GB, high activity)
→ Full backup weekly (1GB, 90 seconds)
→ Incremental daily (50MB, 5 seconds)

Storage per week: 1GB + (6 × 50MB) = 1.3GB
vs. Full daily: 7GB
Savings: 82%
```

#### 3. Mixed Strategy

**What it is:**
- Weekly full backup + Daily incremental backups
- Best of both worlds

**When used:**
- Large domains (> 1GB)
- High activity sites
- Critical sites requiring frequent backups

**Pros:**
- Fast daily backups
- Safe weekly full backups
- Balanced approach

**Cons:**
- Uses more storage than pure incremental

**Example:**
```
largesite.com (5GB, high activity)
→ Sunday: Full backup (5GB, 240 seconds)
→ Mon-Sat: Incremental (100MB each, 10 seconds)

Daily time: 10 seconds (vs. 240 seconds)
Weekly storage: 5.6GB (vs. 35GB full daily)
```

### How Strategy is Selected

The system automatically selects the optimal strategy based on:

| Size       | Activity | Strategy        | Reason                          |
|------------|----------|-----------------|----------------------------------|
| Small      | Any      | Full            | Fast enough, simple             |
| Medium     | High     | Incremental     | Efficient, frequent changes     |
| Medium     | Low      | Full            | Not much to backup              |
| Large      | High     | Mixed           | Balance speed + safety          |
| Large      | Medium   | Incremental     | Efficient for size              |
| Large      | Low      | Full (weekly)   | Infrequent changes              |

**Thresholds:**
- Small: < 100MB
- Medium: 100MB - 1GB
- Large: > 1GB
- High activity: 100+ file changes/day
- Medium activity: 20-99 changes/day
- Low activity: < 20 changes/day

---

## 💻 MANUAL BACKUPS

### Backup Single Domain

**Auto strategy (recommended):**

```bash
rocketvps backup-domain example.com
```

The system will:
1. Analyze domain activity
2. Select optimal strategy
3. Create backup
4. Verify integrity
5. Display summary

**Force full backup:**

```bash
rocketvps backup-domain example.com full
```

**Force incremental backup:**

```bash
rocketvps backup-domain example.com incremental
```

### Backup All Domains

**Sequential backup:**

```bash
rocketvps backup-all
```

**Parallel backup (faster):**

```bash
rocketvps backup-all --parallel
```

Backs up up to 4 domains simultaneously. On a server with 10 domains:
- Sequential: ~25 minutes
- Parallel: ~8 minutes
- **70% faster**

### Backup Files Only (Skip Database)

```bash
rocketvps backup-domain example.com --files-only
```

### Backup Database Only

```bash
rocketvps backup-database example.com
```

### Output Example

```
╔════════════════════════════════════════════════════════════╗
║         Smart Backup: example.com                          ║
╠════════════════════════════════════════════════════════════╣
║  Analyzing domain...                                       ║
║    Activity: medium (45 changes/day)                       ║
║    Size: 450MB                                             ║
║    Strategy: incremental                                   ║
║                                                             ║
║  Creating incremental backup...                            ║
║    Changed files: 125                                      ║
║    Backup size: 22MB                                       ║
║    Duration: 8 seconds                                     ║
║                                                             ║
║  Backing up database...                                    ║
║    Type: WordPress                                         ║
║    Size: 85MB → 35MB (optimized)                           ║
║    Duration: 12 seconds                                    ║
║                                                             ║
║  ✅ Backup completed successfully!                         ║
║                                                             ║
║  Backup location:                                          ║
║    /opt/rocketvps/backups/example.com/                     ║
║    backup_20251004_143022_incremental.tar.gz               ║
║                                                             ║
║  Total time: 20 seconds                                    ║
║  Total size: 57MB                                          ║
╚════════════════════════════════════════════════════════════╝
```

---

## ⏰ AUTOMATIC SCHEDULING

### Setup Automatic Backups

**Auto schedule (recommended):**

```bash
rocketvps setup-backup-schedule example.com
```

The system will:
1. Analyze domain
2. Select optimal strategy
3. Determine best schedule
4. Create cron job
5. Display schedule details

**Output:**

```
Setting up backup schedule for example.com...
  Activity: medium
  Size: 450MB
  Strategy: incremental
  Schedule: Daily at 3:00 AM

Cron job created: /etc/cron.d/rocketvps_backup_example.com

Schedule details:
  Daily incremental: 3:00 AM (0 3 * * *)
  Weekly full: Sunday 3:00 AM (0 3 * * 0)

✅ Automatic backups configured!
```

### Custom Schedule

**Specific time:**

```bash
rocketvps setup-backup-schedule example.com --time "04:30"
```

**Specific frequency:**

```bash
# Every 6 hours
rocketvps setup-backup-schedule example.com --frequency "6h"

# Twice daily
rocketvps setup-backup-schedule example.com --frequency "12h"

# Weekly only
rocketvps setup-backup-schedule example.com --frequency "weekly"
```

### View Current Schedule

```bash
rocketvps show-backup-schedule example.com
```

**Output:**

```
Backup Schedule: example.com
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Strategy:         incremental
Current Activity: medium
Current Size:     450MB

Schedule:
  Incremental:    Daily at 3:00 AM
  Full:           Sunday at 3:00 AM

Cron file: /etc/cron.d/rocketvps_backup_example.com

Last backup: 2025-10-04 03:00:15
Next backup: 2025-10-05 03:00:00
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Update Schedule

Schedules update automatically based on activity changes. Manual update:

```bash
rocketvps update-backup-schedule example.com
```

### Disable Automatic Backups

```bash
rocketvps disable-backup-schedule example.com
```

### Enable Automatic Backups

```bash
rocketvps enable-backup-schedule example.com
```

---

## 📦 BACKUP MANAGEMENT

### List Backups

**All backups for a domain:**

```bash
rocketvps list-backups example.com
```

**Output:**

```
Backups for example.com:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
BACKUP FILE                       TYPE          SIZE       DATE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
backup_20251004_030000.tar.gz    full          450MB      2025-10-04
backup_20251004_150000_inc.tar.gz incremental   22MB      2025-10-04
backup_20251003_030000.tar.gz    full          445MB      2025-10-03
backup_20251003_150000_inc.tar.gz incremental   18MB      2025-10-03
backup_20251002_030000.tar.gz    full          448MB      2025-10-02
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Total backups: 5
Total size: 1.4GB
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**List all backups for all domains:**

```bash
rocketvps list-backups --all
```

### View Backup Info

**Detailed backup information:**

```bash
rocketvps backup-info /opt/rocketvps/backups/example.com/backup_20251004_030000.tar.gz
```

**Output:**

```json
{
    "type": "full",
    "domain": "example.com",
    "timestamp": "20251004_030000",
    "date_created": "2025-10-04 03:00:00",
    "file_count": 5420,
    "backup_size": "450MB",
    "database_size": "85MB",
    "compression_ratio": "72%",
    "original_size": "1.6GB",
    "backup_duration": "90s",
    "checksum": "sha256:a1b2c3d4e5f6..."
}
```

### Delete Old Backups

**Delete backups older than X days:**

```bash
# Delete backups older than 30 days
rocketvps cleanup-backups example.com --older-than 30

# Delete backups older than 7 days
rocketvps cleanup-backups example.com --older-than 7
```

**Delete specific backup:**

```bash
rocketvps delete-backup /opt/rocketvps/backups/example.com/backup_20251001_030000.tar.gz
```

**Keep only N most recent backups:**

```bash
# Keep only 7 most recent backups
rocketvps cleanup-backups example.com --keep 7
```

### Backup Statistics

```bash
rocketvps backup-stats example.com
```

**Output:**

```
Backup Statistics: example.com
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Total Backups:      42
  Full Backups:     14
  Incremental:      28

Total Size:         3.2GB
  Average Size:     78MB

Last Backup:        2025-10-04 15:00:00
Last Full:          2025-10-04 03:00:00

Activity:           medium (45 changes/day)
Strategy:           incremental
Schedule:           Daily incremental + Weekly full

Backup Success Rate: 100%
Average Duration:    15 seconds
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## 🔄 RESTORATION

### Quick Restore

**Restore from latest backup:**

```bash
rocketvps restore-domain example.com
```

This uses the Smart Restore system (from Phase 1B) with automatic snapshot creation and rollback capability.

### Restore from Specific Backup

```bash
rocketvps restore-domain example.com --backup backup_20251004_030000.tar.gz
```

### Restore Incremental Backup

When restoring an incremental backup, the system automatically:
1. Locates the base full backup
2. Applies all incremental backups in sequence
3. Verifies file integrity
4. Completes restoration

```bash
rocketvps restore-domain example.com --backup backup_20251004_150000_incremental.tar.gz
```

**The system handles the complexity automatically!**

### Restore Files Only

```bash
rocketvps restore-domain example.com --files-only
```

### Restore Database Only

```bash
rocketvps restore-database example.com
```

### Restore to Different Location

```bash
rocketvps restore-domain example.com --target /var/www/example-restored
```

### Restoration Process

```
1. Pre-restore Snapshot Creation
   ↓
2. Locate Base Backup (if incremental)
   ↓
3. Extract Base Backup
   ↓
4. Apply Incremental Backups (if any)
   ↓
5. Restore Database
   ↓
6. Fix Permissions
   ↓
7. Verify Restoration
   ↓
8. Cleanup Snapshot (if successful)
   ↓
✅ Restoration Complete
```

**If any step fails:** Automatic rollback to pre-restore state

---

## 📊 MONITORING & STATISTICS

### Domain Activity

**View current activity level:**

```bash
rocketvps show-activity example.com
```

**Output:**

```
Domain Activity: example.com
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Activity Level:     medium
File Changes:       45 files/day
Traffic:            15,000 requests/day
Trend:              stable
Last Analyzed:      2025-10-04 12:00:00

Recommendation:
  Current strategy (incremental) is optimal.
  No schedule changes needed.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### System-Wide Statistics

```bash
rocketvps backup-stats --all
```

**Output:**

```
╔═══════════════════════════════════════════════════════════╗
║          ROCKETVPS BACKUP SYSTEM STATISTICS               ║
╠═══════════════════════════════════════════════════════════╣
║  Total Domains:        25                                 ║
║  Total Backups:        1,050                              ║
║  Total Storage:        42GB                               ║
║                                                            ║
║  Backup Strategies:                                       ║
║    Full:               8 domains                          ║
║    Incremental:        12 domains                         ║
║    Mixed:              5 domains                          ║
║                                                            ║
║  Activity Levels:                                         ║
║    High:               7 domains                          ║
║    Medium:             13 domains                         ║
║    Low:                5 domains                          ║
║                                                            ║
║  Performance:                                             ║
║    Average backup time:     45 seconds                    ║
║    Storage efficiency:      62% savings                   ║
║    Success rate:            100%                          ║
║                                                            ║
║  Last 24 Hours:                                           ║
║    Backups completed:       18                            ║
║    Total time:              12 minutes                    ║
║    Data backed up:          2.4GB                         ║
╚═══════════════════════════════════════════════════════════╝
```

### Backup Logs

**View recent backup activity:**

```bash
rocketvps backup-log
```

**View logs for specific domain:**

```bash
rocketvps backup-log example.com
```

**View logs for specific date:**

```bash
rocketvps backup-log --date 2025-10-04
```

---

## 🔧 TROUBLESHOOTING

### Common Issues

#### Issue 1: Backup Failed

**Symptoms:**
```
ERROR: Backup creation failed for example.com
```

**Possible Causes:**
1. Insufficient disk space
2. Permission issues
3. Domain directory not found

**Solutions:**

**Check disk space:**
```bash
df -h /opt/rocketvps/backups
```

**Check permissions:**
```bash
ls -la /opt/rocketvps/backups
# Should be: drwx------ (700)

chmod 700 /opt/rocketvps/backups
```

**Check domain exists:**
```bash
ls -la /var/www/example.com
```

**Retry backup:**
```bash
rocketvps backup-domain example.com --verbose
```

#### Issue 2: Incremental Backup Not Working

**Symptoms:**
```
INFO: No changes detected since last backup
```

**This is normal!** If no files changed, incremental backup is skipped.

**To verify:**
```bash
# Check last backup time
rocketvps backup-info --last example.com

# Check file changes
find /var/www/example.com -type f -mtime -1 | wc -l
```

**Force full backup if needed:**
```bash
rocketvps backup-domain example.com full
```

#### Issue 3: Backup Schedule Not Running

**Symptoms:**
- No automatic backups created
- Cron job not executing

**Solutions:**

**Check cron file exists:**
```bash
ls -la /etc/cron.d/rocketvps_backup_example.com
```

**Check cron file permissions:**
```bash
# Should be: -rw-r--r-- (644)
chmod 644 /etc/cron.d/rocketvps_backup_example.com
```

**Check cron service:**
```bash
systemctl status cron     # Debian/Ubuntu
systemctl status crond    # CentOS/RHEL
```

**Restart cron:**
```bash
systemctl restart cron
```

**Check cron logs:**
```bash
grep -i cron /var/log/syslog    # Debian/Ubuntu
grep -i cron /var/log/messages  # CentOS/RHEL
```

**Recreate schedule:**
```bash
rocketvps setup-backup-schedule example.com
```

#### Issue 4: Backup Verification Failed

**Symptoms:**
```
ERROR: Backup integrity check failed
```

**Solutions:**

**Check backup file:**
```bash
tar -tzf /opt/rocketvps/backups/example.com/backup_file.tar.gz
```

**If corrupted, check disk:**
```bash
# Check disk errors
dmesg | grep -i error

# Check filesystem
fsck /dev/sda1  # Replace with your partition
```

**Delete corrupted backup:**
```bash
rocketvps delete-backup /path/to/corrupted/backup.tar.gz
```

**Create new backup:**
```bash
rocketvps backup-domain example.com full
```

#### Issue 5: High Storage Usage

**Symptoms:**
- Backup directory growing too large
- Disk space warnings

**Solutions:**

**Check backup retention:**
```bash
rocketvps list-backups example.com
```

**Clean old backups:**
```bash
# Keep only last 7 days
rocketvps cleanup-backups example.com --older-than 7

# Or keep only 10 most recent
rocketvps cleanup-backups example.com --keep 10
```

**Check for duplicate backups:**
```bash
find /opt/rocketvps/backups/example.com -name "*.tar.gz" -type f | wc -l
```

**Verify exclude patterns working:**
```bash
# Check if cache/logs excluded
tar -tzf backup_file.tar.gz | grep -E "cache|logs|tmp"
```

### Getting Help

If issues persist:

1. **Check logs:**
   ```bash
   tail -f /var/log/rocketvps/smart_backup.log
   ```

2. **Run with verbose mode:**
   ```bash
   rocketvps backup-domain example.com --verbose
   ```

3. **Check system resources:**
   ```bash
   df -h              # Disk space
   free -h            # Memory
   top                # CPU usage
   ```

4. **Contact support:**
   - GitHub Issues: [rocketvps/issues](https://github.com/coffeecms/rocketvps/issues)
   - Email: coffeecms@gmail.com

---

## 💡 BEST PRACTICES

### 1. Backup Frequency

**Recommended:**
- High activity sites: Daily incremental + Weekly full
- Medium activity: Daily full
- Low activity: Weekly full

**Never:**
- Backup during peak traffic hours
- Skip database backups
- Ignore backup verification

### 2. Backup Retention

**Recommended retention:**
- Last 7 daily backups
- Last 4 weekly backups (1 month)
- Last 12 monthly backups (1 year)

**Setup:**
```bash
# Daily cleanup - keep 7 days
rocketvps cleanup-backups example.com --older-than 7 --exclude-weekly

# Weekly cleanup - keep 30 days
rocketvps cleanup-backups example.com --older-than 30 --exclude-monthly

# Monthly cleanup - keep 365 days
rocketvps cleanup-backups example.com --older-than 365
```

### 3. Storage Management

**Monitor storage:**
```bash
# Check backup storage usage
du -sh /opt/rocketvps/backups/*

# Set up alerts
rocketvps set-alert disk-usage 80%  # Alert at 80% full
```

**Optimize storage:**
- Enable incremental backups for large sites
- Use exclude patterns
- Compress older backups further
- Move old backups to cheaper storage

### 4. Testing Restores

**Test restores regularly:**

```bash
# Monthly restore test
rocketvps test-restore example.com --dry-run
```

**Test on staging:**
```bash
rocketvps restore-domain example.com --target /var/www/staging.example.com
```

### 5. Security

**Backup security:**
- Keep backup directory restricted (700 permissions)
- Consider encrypting backups for sensitive data
- Store off-site copies
- Limit backup access

**Encryption (optional):**
```bash
# Encrypt backup
gpg --encrypt --recipient admin@example.com backup_file.tar.gz

# Decrypt backup
gpg --decrypt backup_file.tar.gz.gpg > backup_file.tar.gz
```

### 6. Documentation

**Document your setup:**
- Backup schedules
- Retention policies
- Restore procedures
- Emergency contacts

### 7. Monitoring

**Set up monitoring:**
```bash
# Email on backup failure
rocketvps set-alert backup-failure --email admin@example.com

# Webhook notification
rocketvps set-alert backup-complete --webhook https://hooks.slack.com/...
```

---

## ❓ FAQ

### Q1: How does incremental backup work?

**A:** Incremental backup only backs up files that changed since the last backup. For example:
- Monday: Full backup (1GB)
- Tuesday: Only 50 files changed → Incremental backup (20MB)
- Wednesday: Only 30 files changed → Incremental backup (15MB)

To restore Wednesday's backup, the system:
1. Extracts Monday's full backup
2. Applies Tuesday's incremental
3. Applies Wednesday's incremental
4. Result: Complete Wednesday state

### Q2: Can I customize the activity thresholds?

**A:** Yes, edit `/opt/rocketvps/modules/smart_backup.sh`:

```bash
# Default thresholds
ACTIVITY_HIGH_THRESHOLD=100      # Changes per day
ACTIVITY_MEDIUM_THRESHOLD=20
ACTIVITY_LOW_THRESHOLD=5

# Customize as needed
ACTIVITY_HIGH_THRESHOLD=200      # More strict
ACTIVITY_MEDIUM_THRESHOLD=50
```

Then reload:
```bash
systemctl reload rocketvps
```

### Q3: Does Smart Backup work with all domain types?

**A:** Yes! Smart Backup works with:
- WordPress
- Laravel
- Node.js
- Static HTML
- E-commerce (WooCommerce, Magento)
- SaaS applications
- Generic PHP sites

Database optimization is automatic for WordPress and Laravel.

### Q4: What happens if a backup fails?

**A:** The system:
1. Logs the error
2. Sends notification (if configured)
3. Retries on next scheduled time
4. Keeps previous successful backup

Your site is never affected by backup failures.

### Q5: Can I backup to external storage?

**A:** Yes! Options:

**S3/Cloud storage:**
```bash
# After backup, sync to S3
aws s3 sync /opt/rocketvps/backups/ s3://my-bucket/backups/
```

**Remote server:**
```bash
# After backup, rsync to remote
rsync -avz /opt/rocketvps/backups/ user@backup-server:/backups/
```

**Add to cron for automation:**
```bash
0 4 * * * /usr/local/bin/sync-backups-to-s3.sh
```

### Q6: How much disk space do I need?

**Estimate:**
- Minimum: 2x largest domain size
- Recommended: 3-5x largest domain size
- With retention: (domain size × backup frequency × retention days)

**Example:**
- Domain: 1GB
- Daily backups
- 7-day retention
- Incremental (30% average)
- Space needed: 1GB (full) + 6 × 0.3GB (incremental) = 2.8GB

### Q7: Can Smart Backup replace my off-site backups?

**A:** No! Smart Backup is for **on-server** quick backups and restores.

**Best practice:**
- Smart Backup: Daily/hourly local backups
- Off-site: Weekly/monthly backups to cloud/remote server

### Q8: How do I migrate backups to a new server?

**A:** 

**1. Export backups:**
```bash
tar czf backups_export.tar.gz /opt/rocketvps/backups/
```

**2. Transfer to new server:**
```bash
scp backups_export.tar.gz user@new-server:/tmp/
```

**3. Import on new server:**
```bash
ssh user@new-server
cd /
tar xzf /tmp/backups_export.tar.gz
chown -R root:root /opt/rocketvps/backups
chmod -R 700 /opt/rocketvps/backups
```

**4. Verify:**
```bash
rocketvps list-backups --all
```

### Q9: Does backup affect site performance?

**A:** Minimal impact:
- CPU: 5-10% during backup
- I/O: Low priority nice level
- Memory: < 100MB
- Network: None (local backup)

**Backups are scheduled at 3 AM by default** to avoid peak hours.

**If needed, lower priority:**
```bash
nice -n 19 rocketvps backup-domain example.com
```

### Q10: Can I pause scheduled backups temporarily?

**A:** Yes:

**Pause for specific domain:**
```bash
rocketvps pause-backup-schedule example.com
```

**Resume:**
```bash
rocketvps resume-backup-schedule example.com
```

**Pause all:**
```bash
for domain in $(rocketvps list-domains); do
    rocketvps pause-backup-schedule $domain
done
```

---

## 📚 QUICK REFERENCE

### Common Commands

```bash
# Manual backups
rocketvps backup-domain <domain>              # Auto strategy
rocketvps backup-domain <domain> full         # Force full
rocketvps backup-domain <domain> incremental  # Force incremental
rocketvps backup-all                          # All domains
rocketvps backup-all --parallel               # Parallel backup

# Scheduling
rocketvps setup-backup-schedule <domain>      # Auto schedule
rocketvps show-backup-schedule <domain>       # View schedule
rocketvps update-backup-schedule <domain>     # Update schedule
rocketvps disable-backup-schedule <domain>    # Disable

# Management
rocketvps list-backups <domain>               # List backups
rocketvps backup-stats <domain>               # Statistics
rocketvps cleanup-backups <domain> --older-than 7  # Cleanup
rocketvps delete-backup <file>                # Delete specific

# Restoration
rocketvps restore-domain <domain>             # Restore latest
rocketvps restore-domain <domain> --backup <file>  # Restore specific

# Monitoring
rocketvps show-activity <domain>              # Domain activity
rocketvps backup-log                          # View logs
rocketvps backup-stats --all                  # System stats
```

---

## 🎯 NEXT STEPS

Now that you understand Smart Backup:

1. ✅ **Setup automatic backups** for all domains
2. ✅ **Test restore** on a non-critical domain
3. ✅ **Monitor statistics** regularly
4. ✅ **Setup off-site backup** sync
5. ✅ **Document your backup strategy**

**Continue to:**
- [Smart Restore Guide](RESTORE_USER_GUIDE.md)
- [Backup Strategies Reference](BACKUP_STRATEGIES.md)
- [System Monitoring](MONITORING_GUIDE.md)

---

**Document Version:** 2.2.0  
**Last Updated:** October 4, 2025  
**Support:** coffeecms@gmail.com  
**GitHub:** [rocketvps/docs](https://github.com/coffeecms/rocketvps)
