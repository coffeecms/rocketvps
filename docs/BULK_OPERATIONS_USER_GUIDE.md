# RocketVPS v2.2.0 - Bulk Operations User Guide

## Document Information
- **Version**: 2.2.0
- **Phase**: Phase 2 Week 9-10
- **Date**: October 4, 2025
- **For**: System Administrators

---

## Table of Contents

1. [Introduction](#1-introduction)
2. [Getting Started](#2-getting-started)
3. [Bulk Backup Operations](#3-bulk-backup-operations)
4. [Bulk Restore Operations](#4-bulk-restore-operations)
5. [Bulk Configuration Operations](#5-bulk-configuration-operations)
6. [Bulk Health Check Operations](#6-bulk-health-check-operations)
7. [Domain Filtering](#7-domain-filtering)
8. [Progress Tracking](#8-progress-tracking)
9. [Result Reports](#9-result-reports)
10. [Troubleshooting](#10-troubleshooting)
11. [Best Practices](#11-best-practices)
12. [FAQ](#12-faq)
13. [Quick Reference](#13-quick-reference)

---

## 1. Introduction

### 1.1 What is Bulk Operations?

The Bulk Operations Module allows you to perform operations on multiple domains simultaneously, saving time and reducing manual effort.

**Key Capabilities**:
- ✅ Backup 50+ domains in minutes instead of hours
- ✅ Restore multiple domains with one command
- ✅ Update configurations across all domains
- ✅ Check health of all domains in parallel
- ✅ Filter domains by pattern, type, or size
- ✅ Track progress in real-time
- ✅ Get comprehensive JSON reports

### 1.2 Who Should Use This?

**Perfect For**:
- Hosting providers managing multiple client sites
- Agencies managing 10+ WordPress/Laravel sites
- DevOps teams maintaining production/staging environments
- System administrators performing routine maintenance

**Use Cases**:
- Nightly backups of all domains
- Bulk SSL certificate renewal before expiry
- Mass configuration updates (e.g., Nginx optimization)
- Monthly health audits
- Disaster recovery testing

### 1.3 Key Benefits

| Benefit | Example |
|---------|---------|
| **Time Savings** | Backup 50 domains in 20 min vs 75 min (3.75x faster) |
| **Automation** | Schedule via cron for hands-off operation |
| **Reliability** | Continues on failure, logs all errors |
| **Visibility** | Real-time progress bars and detailed reports |
| **Scalability** | Handles 200+ domains efficiently |

---

## 2. Getting Started

### 2.1 Prerequisites

Before using bulk operations, ensure:

1. **RocketVPS Installed**:
   ```bash
   ls /opt/rocketvps/modules/bulk_operations.sh
   ```

2. **Required Modules Available**:
   - Smart Backup module
   - Restore module
   - Health Monitoring module
   - Auto-Detect module

3. **Sufficient Disk Space**:
   ```bash
   df -h /opt/rocketvps/backup
   # Need: 2x total size of all domains
   ```

4. **System Resources**:
   - CPU: 2+ cores recommended for parallel execution
   - RAM: 2 GB+ free
   - Network: Stable connection for remote backups

### 2.2 Initial Setup

**Step 1**: Initialize bulk operations:
```bash
source /opt/rocketvps/modules/bulk_operations.sh
bulk_operations_init
```

**Step 2**: Verify domains discovered:
```bash
discover_all_domains
```

Expected output:
```
wordpress1.example.com
wordpress2.example.com
laravel1.example.com
nodejs1.example.com
static1.example.com
```

**Step 3**: Test with a small operation:
```bash
# Health check 1 domain (for testing)
run_domain_health_checks "wordpress1.example.com"
```

### 2.3 Configuration

Edit configuration in `/opt/rocketvps/modules/bulk_operations.sh`:

```bash
# Adjust parallel workers based on CPU cores
BULK_MAX_PARALLEL=4    # 2 cores → 2-4 workers, 4+ cores → 4-8 workers

# Adjust timeout for large domains
BULK_OPERATION_TIMEOUT=3600    # 1 hour (increase for very large domains)
```

**Recommended Settings by Server Specs**:

| Specs | Max Parallel | Timeout |
|-------|--------------|---------|
| 2 CPU, 2 GB RAM | 2 | 1800s |
| 4 CPU, 4 GB RAM | 4 | 3600s |
| 8 CPU, 8 GB RAM | 6 | 3600s |
| 16+ CPU, 16+ GB RAM | 8 | 7200s |

---

## 3. Bulk Backup Operations

### 3.1 Backup All Domains

**Command**:
```bash
bulk_backup_all [backup_type] [parallel]
```

**Parameters**:
- `backup_type`: `auto` (smart), `full`, `incremental` (default: auto)
- `parallel`: Max parallel processes (default: 4)

**Example 1**: Backup all domains (auto mode, 4 parallel):
```bash
source /opt/rocketvps/modules/bulk_operations.sh
bulk_backup_all "auto" 4
```

**Output**:
```
╔════════════════════════════════════════════════════════════╗
║          Bulk Backup: All Domains                          ║
╚════════════════════════════════════════════════════════════╝

Found 50 domains to backup

Progress: 45% (22 success, 3 failed, 2 in progress, 23 pending)
[======================----------------------------] 45%

ETA: 8 minutes 32 seconds
```

**Example 2**: Full backup with 6 parallel workers:
```bash
bulk_backup_all "full" 6
```

**Example 3**: Schedule nightly backups via cron:
```bash
# Add to crontab
0 2 * * * /bin/bash -c 'source /opt/rocketvps/modules/bulk_operations.sh && bulk_backup_all "auto" 4' >> /var/log/rocketvps/bulk_backup.log 2>&1
```

### 3.2 Backup Filtered Domains

**Command**:
```bash
bulk_backup_filtered [filter_type] [filter_value] [backup_type] [parallel]
```

**Filter Types**:
- `pattern`: Regex pattern
- `site_type`: WORDPRESS|LARAVEL|NODEJS|STATIC|PHP
- `size`: Size range in MB (e.g., "0-500")

**Example 1**: Backup all WordPress sites:
```bash
bulk_backup_filtered "site_type" "WORDPRESS" "auto" 4
```

**Example 2**: Backup production domains:
```bash
bulk_backup_filtered "pattern" "^prod" "full" 4
```

**Example 3**: Backup small domains (< 100 MB):
```bash
bulk_backup_filtered "size" "0-100" "auto" 2
```

**Example 4**: Backup all .com domains:
```bash
bulk_backup_filtered "pattern" "\.com$" "auto" 4
```

### 3.3 Understanding Backup Results

**Result File**: `/opt/rocketvps/bulk_operations/results/bulk_backup_YYYYMMDD_HHMMSS.json`

**Example Result**:
```json
{
    "timestamp": 1696435200,
    "date": "2025-10-04 12:00:00",
    "total": 50,
    "success": 47,
    "failed": 3,
    "success_rate": 94,
    "results": [
        {
            "domain": "wordpress1.example.com",
            "status": "success",
            "backup_file": "/opt/rocketvps/backup/wordpress1/backup_20251004.tar.gz",
            "size": 245
        },
        {
            "domain": "broken.example.com",
            "status": "failed",
            "error": "Database connection failed"
        }
    ]
}
```

**Summary Display**:
```
╔════════════════════════════════════════════════════════════╗
║          Bulk Backup Summary                               ║
╠════════════════════════════════════════════════════════════╣
║  Total Domains:    50                                      ║
║  Successful:       47                                      ║
║  Failed:           3                                       ║
║  Success Rate:     94%                                     ║
╚════════════════════════════════════════════════════════════╝
```

---

## 4. Bulk Restore Operations

### 4.1 Restore All Domains

**⚠️ WARNING**: This will restore ALL domains from their latest backups and overwrite existing files!

**Command**:
```bash
bulk_restore_all [restore_type] [parallel]
```

**Example**:
```bash
source /opt/rocketvps/modules/bulk_operations.sh
bulk_restore_all "auto" 4
```

**Interactive Confirmation**:
```
⚠️  WARNING: This will restore ALL domains from their latest backups.
   This operation will overwrite existing files!

Type 'YES' to confirm: YES
```

**Output**:
```
Found 50 domains to restore

Progress: 60% (28 success, 2 failed, 2 in progress, 18 pending)
[==============================--------------------] 60%

ETA: 6 minutes 15 seconds
```

### 4.2 Restore Specific Domains

**Step 1**: Create domain list file:
```bash
cat > restore_list.txt <<EOF
wordpress1.example.com
wordpress2.example.com
laravel1.example.com
EOF
```

**Step 2**: Restore specific domains:
```bash
bulk_restore_specific "restore_list.txt" 4
```

**Use Case**: Restore after accidental deletion:
```bash
# List recently deleted domains
cat > emergency_restore.txt <<EOF
accidentally-deleted1.com
accidentally-deleted2.com
EOF

# Restore immediately
bulk_restore_specific "emergency_restore.txt" 6
```

### 4.3 Restore Verification

After restore, verify:

**Manual Verification**:
```bash
# Check files restored
ls -la /var/www/wordpress1.example.com

# Check site responding
curl -I https://wordpress1.example.com
# Expected: HTTP/1.1 200 OK

# Check database
mysql -u user -p database -e "SELECT COUNT(*) FROM wp_posts;"
```

**Automated Verification** (via health check):
```bash
run_domain_health_checks "wordpress1.example.com"
```

---

## 5. Bulk Configuration Operations

### 5.1 Update Nginx Configurations

Regenerate Nginx configs for all domains based on detected site types.

**Command**:
```bash
bulk_update_nginx_config [parallel]
```

**Example**:
```bash
source /opt/rocketvps/modules/bulk_operations.sh
bulk_update_nginx_config 4
```

**What It Does**:
1. Detects site type (WordPress/Laravel/Node.js/Static/PHP)
2. Generates appropriate Nginx config
3. Tests config: `nginx -t`
4. Applies if test passes
5. Reloads Nginx

**Output**:
```
Updating Nginx configs for 50 domains

Progress: 100% (48 success, 2 failed, 0 in progress, 0 pending)
[==================================================] 100%

✅ Nginx reloaded with new configurations

Bulk Nginx update completed
Results saved to: /opt/rocketvps/bulk_operations/results/bulk_nginx_update_20251004_120000.json
```

**Use Case**: After updating Nginx optimization settings:
```bash
# Update template in modules/auto_detect.sh
vim /opt/rocketvps/modules/auto_detect.sh

# Apply to all domains
bulk_update_nginx_config 4
```

### 5.2 Fix File Permissions

Fix permissions for all domains.

**Command**:
```bash
bulk_fix_permissions [parallel]
```

**Example**:
```bash
bulk_fix_permissions 4
```

**Permissions Applied**:
- Directories: `755` (rwxr-xr-x)
- Files: `644` (rw-r--r--)
- Uploads (WordPress): `775` (rwxrwxr-x)
- Storage (Laravel): `775` (rwxrwxr-x)
- Ownership: `www-data:www-data`

**Output**:
```
Fixing permissions for 50 domains

Progress: 100% (50 success, 0 failed)
[==================================================] 100%

✅ Bulk permissions fix completed
```

**Use Case**: After manual file uploads:
```bash
# Upload files via FTP (wrong permissions)
# Fix permissions
bulk_fix_permissions 4

# Verify
ls -la /var/www/wordpress1.example.com/
```

### 5.3 Renew SSL Certificates

Renew SSL certificates for all domains.

**Command**:
```bash
bulk_renew_ssl [parallel]
```

**Example**:
```bash
bulk_renew_ssl 2    # Limited to 2 for Let's Encrypt rate limits
```

**Output**:
```
Renewing SSL for 50 domains

Progress: 100% (45 success, 5 skipped)
[==================================================] 100%

✅ Nginx reloaded

Bulk SSL renewal completed
```

**Notes**:
- Skips domains without existing SSL
- Respects Let's Encrypt rate limits (50/day)
- Parallel limit: 2 (to avoid rate limiting)

**Use Case**: Monthly SSL renewal before expiry:
```bash
# Check expiring certificates
for domain in $(discover_all_domains); do
    expiry=$(check_ssl_expiry "$domain" | jq -r '.days_until_expiry')
    if [[ $expiry -lt 30 ]]; then
        echo "$domain expires in $expiry days"
    fi
done

# Renew all
bulk_renew_ssl 2
```

---

## 6. Bulk Health Check Operations

### 6.1 Health Check All Domains

**Command**:
```bash
bulk_health_check [parallel]
```

**Example**:
```bash
source /opt/rocketvps/modules/bulk_operations.sh
bulk_health_check 4
```

**Output**:
```
Checking health for 50 domains

Progress: 100% (45 healthy, 5 unhealthy)
[==================================================] 100%

╔═══════════════════════════════════════════════════════════════╗
║              Bulk Health Check Summary                        ║
╠═══════════════════════════════════════════════════════════════╣
║  Total Domains:        50                                     ║
║  Healthy:              45 (90%)                               ║
║  Unhealthy:            5 (10%)                                ║
║                                                               ║
║  Issues Breakdown:                                            ║
║    - SSL Expired:      2 domains                             ║
║    - Database Down:    1 domain                              ║
║    - Disk Full:        1 domain                              ║
║    - HTTP Error:       1 domain                              ║
╚═══════════════════════════════════════════════════════════════╝

Unhealthy Domains:
  1. broken1.example.com - SSL expired (5 days ago)
  2. broken2.example.com - Database connection failed
  3. broken3.example.com - Disk space critical (95% used)
  4. broken4.example.com - HTTP 500 error
  5. broken5.example.com - SSL expired, Database down

✅ Bulk health check completed
Results saved to: /opt/rocketvps/bulk_operations/results/bulk_health_check_20251004_120000.json
```

### 6.2 Health Checks Performed

For each domain:

1. **Site Responding**: HTTP status (200/301/302)
2. **SSL Certificate**: Validity and expiry date
3. **Database**: Connection and accessibility
4. **Disk Space**: Usage percentage
5. **File Permissions**: Correct permissions
6. **Nginx Config**: Valid configuration

### 6.3 Automated Health Checks

**Schedule via cron**:
```bash
# Daily health check at 6 AM
0 6 * * * /bin/bash -c 'source /opt/rocketvps/modules/bulk_operations.sh && bulk_health_check 4' >> /var/log/rocketvps/bulk_health.log 2>&1
```

**Email unhealthy domains**:
```bash
#!/bin/bash
# health_check_email.sh

source /opt/rocketvps/modules/bulk_operations.sh
result_file=$(bulk_health_check 4 | grep "Results saved" | awk '{print $NF}')

# Extract unhealthy domains
unhealthy=$(jq -r '.results[] | select(.status=="unhealthy") | .domain' "$result_file")

if [[ -n "$unhealthy" ]]; then
    echo "Unhealthy domains detected:" | mail -s "Health Check Alert" admin@example.com
    echo "$unhealthy" | mail -s "Unhealthy Domains" admin@example.com
fi
```

---

## 7. Domain Filtering

### 7.1 Filter by Pattern

**Match domain names using regex**:

```bash
# All WordPress domains
all_domains=$(discover_all_domains)
wordpress_domains=$(filter_domains_by_pattern "wordpress" "${all_domains[@]}")

# Production domains
prod_domains=$(filter_domains_by_pattern "^prod" "${all_domains[@]}")

# All .com domains
com_domains=$(filter_domains_by_pattern "\.com$" "${all_domains[@]}")

# Staging domains
staging_domains=$(filter_domains_by_pattern "staging" "${all_domains[@]}")
```

**Common Patterns**:
| Pattern | Matches |
|---------|---------|
| `wordpress` | Any domain containing "wordpress" |
| `^prod` | Domains starting with "prod" |
| `\.com$` | Domains ending with ".com" |
| `^api\.` | Domains starting with "api." |
| `staging\|dev` | Domains containing "staging" or "dev" |

### 7.2 Filter by Site Type

**Filter by detected site type**:

```bash
all_domains=$(discover_all_domains)

# WordPress sites only
wp_domains=$(filter_domains_by_type "WORDPRESS" "${all_domains[@]}")

# Laravel sites only
laravel_domains=$(filter_domains_by_type "LARAVEL" "${all_domains[@]}")

# Node.js sites only
nodejs_domains=$(filter_domains_by_type "NODEJS" "${all_domains[@]}")

# Static HTML sites
static_domains=$(filter_domains_by_type "STATIC" "${all_domains[@]}")
```

**Supported Types**:
- `WORDPRESS`
- `LARAVEL`
- `NODEJS`
- `STATIC`
- `PHP`

### 7.3 Filter by Size

**Filter by disk space usage**:

```bash
all_domains=$(discover_all_domains)

# Small domains (< 100 MB)
small_domains=$(filter_domains_by_size 0 100 "${all_domains[@]}")

# Medium domains (100-1000 MB)
medium_domains=$(filter_domains_by_size 100 1000 "${all_domains[@]}")

# Large domains (> 1000 MB)
large_domains=$(filter_domains_by_size 1000 999999 "${all_domains[@]}")
```

### 7.4 Combined Filtering

**Chain multiple filters**:

```bash
# WordPress production domains under 500 MB
all_domains=$(discover_all_domains)
wp_domains=$(filter_domains_by_type "WORDPRESS" "${all_domains[@]}")
prod_wp=$(filter_domains_by_pattern "^prod" "${wp_domains[@]}")
small_prod_wp=$(filter_domains_by_size 0 500 "${prod_wp[@]}")

# Backup these domains
bulk_backup_filtered "pattern" "^prod.*wordpress" "auto" 4
```

---

## 8. Progress Tracking

### 8.1 Real-Time Progress

**Progress Bar Display**:
```
Progress: 45% (22 success, 3 failed, 2 in progress, 23 pending)
[======================----------------------------] 45%

ETA: 8 minutes 32 seconds
```

**Components**:
- **Percentage**: Overall completion (45%)
- **Success**: Completed successfully (22)
- **Failed**: Completed with errors (3)
- **In Progress**: Currently executing (2)
- **Pending**: Not started yet (23)
- **ETA**: Estimated time remaining

### 8.2 Progress File

**Location**: `/opt/rocketvps/bulk_operations/temp/progress.json`

**Example**:
```json
{
    "operation": "bulk_backup_all",
    "total": 50,
    "completed": 22,
    "failed": 3,
    "in_progress": 2,
    "start_time": 1696435200,
    "status": "running"
}
```

**Monitor Progress Externally**:
```bash
# Watch progress in another terminal
watch -n 1 'jq . /opt/rocketvps/bulk_operations/temp/progress.json'
```

### 8.3 ETA Calculation

**Formula**:
```
elapsed_time = current_time - start_time
completed_items = completed + failed
rate = completed_items / elapsed_time
remaining_items = total - completed_items
eta = remaining_items / rate
```

**Example Calculation**:
- Total: 50 domains
- Completed: 22 success + 3 failed = 25
- Elapsed: 10 minutes = 600 seconds
- Rate: 25 / 600 = 0.0417 domains/second
- Remaining: 50 - 25 = 25
- ETA: 25 / 0.0417 = 600 seconds = 10 minutes

---

## 9. Result Reports

### 9.1 JSON Result File

**Location**: `/opt/rocketvps/bulk_operations/results/[operation]_YYYYMMDD_HHMMSS.json`

**Example**:
```json
{
    "timestamp": 1696435200,
    "date": "2025-10-04 12:00:00",
    "operation": "bulk_backup_all",
    "total": 50,
    "success": 47,
    "failed": 3,
    "success_rate": 94,
    "duration": 1200,
    "results": [
        {
            "domain": "wordpress1.example.com",
            "status": "success",
            "backup_file": "/opt/rocketvps/backup/wordpress1/backup_20251004.tar.gz",
            "size": 245,
            "duration": 23
        },
        {
            "domain": "broken.example.com",
            "status": "failed",
            "error": "Database connection failed"
        }
    ]
}
```

### 9.2 Query Results with jq

**Extract failed domains**:
```bash
result_file="/opt/rocketvps/bulk_operations/results/bulk_backup_20251004_120000.json"

jq -r '.results[] | select(.status=="failed") | .domain' "$result_file"
```

**Extract success rate**:
```bash
jq -r '.success_rate' "$result_file"
```

**Count by status**:
```bash
# Count successful
jq '[.results[] | select(.status=="success")] | length' "$result_file"

# Count failed
jq '[.results[] | select(.status=="failed")] | length' "$result_file"
```

### 9.3 Export to CSV

**Export results to CSV**:
```bash
result_file="/opt/rocketvps/bulk_operations/results/bulk_backup_20251004_120000.json"

jq -r '.results[] | [.domain, .status, .error // ""] | @csv' "$result_file" > report.csv
```

**CSV Output**:
```csv
"wordpress1.example.com","success",""
"wordpress2.example.com","success",""
"broken.example.com","failed","Database connection failed"
```

### 9.4 Email Reports

**Send email report**:
```bash
result_file="/opt/rocketvps/bulk_operations/results/bulk_backup_20251004_120000.json"

# Generate email body
cat <<EOF | mail -s "Bulk Backup Report" admin@example.com
Bulk Backup Report - $(date)

Total: $(jq -r '.total' "$result_file")
Success: $(jq -r '.success' "$result_file")
Failed: $(jq -r '.failed' "$result_file")
Success Rate: $(jq -r '.success_rate' "$result_file")%

Failed Domains:
$(jq -r '.results[] | select(.status=="failed") | "\(.domain): \(.error)"' "$result_file")
EOF
```

---

## 10. Troubleshooting

### 10.1 Bulk Operation Fails to Start

**Symptom**: Operation doesn't start, returns error immediately

**Possible Causes**:
1. No domains found
2. Insufficient permissions
3. Missing dependencies

**Solutions**:

**Check domains exist**:
```bash
discover_all_domains
# Should return list of domains
```

**Check permissions**:
```bash
ls -la /opt/rocketvps/bulk_operations/
# Should be owned by root or current user
```

**Check dependencies**:
```bash
# Check required modules
ls -la /opt/rocketvps/modules/smart_backup.sh
ls -la /opt/rocketvps/modules/health_monitor.sh
```

### 10.2 High Failure Rate

**Symptom**: Many domains failing (> 10%)

**Possible Causes**:
1. Database connection issues
2. Insufficient disk space
3. Timeout too short
4. Network issues

**Solutions**:

**Check database connectivity**:
```bash
# Test MySQL
systemctl status mysql

# Test database for specific domain
mysql -u user -p database -e "SELECT 1;"
```

**Check disk space**:
```bash
df -h /opt/rocketvps/backup
# Need: 2x total size of all domains
```

**Increase timeout**:
```bash
# Edit configuration
vim /opt/rocketvps/modules/bulk_operations.sh

# Change:
BULK_OPERATION_TIMEOUT=7200    # 2 hours
```

**Check network**:
```bash
# Test internet connectivity
ping -c 4 google.com

# Test remote backup destination
ping -c 4 backup-server.example.com
```

### 10.3 Slow Performance

**Symptom**: Operations take longer than expected

**Possible Causes**:
1. Too many parallel workers
2. Insufficient CPU/RAM
3. Slow disk I/O
4. Network bottleneck

**Solutions**:

**Reduce parallel workers**:
```bash
# Instead of 8 workers
bulk_backup_all "auto" 4    # Use 4 workers
```

**Check system resources**:
```bash
# CPU usage
top

# Memory usage
free -h

# Disk I/O
iostat -x 1
```

**Optimize for large domains**:
```bash
# Backup large domains separately with fewer workers
bulk_backup_filtered "size" "1000-999999" "auto" 2
```

### 10.4 Progress Not Updating

**Symptom**: Progress bar stuck, no updates

**Possible Causes**:
1. Progress file locked
2. Process died
3. File permissions issue

**Solutions**:

**Check progress file**:
```bash
cat /opt/rocketvps/bulk_operations/temp/progress.json
```

**Check running processes**:
```bash
ps aux | grep bulk_
```

**Reset progress file**:
```bash
rm /opt/rocketvps/bulk_operations/temp/progress.json
# Restart operation
```

### 10.5 SSL Renewal Rate Limited

**Symptom**: SSL renewal fails with "rate limited" error

**Solution**:
```bash
# Let's Encrypt allows 50 renewals/day
# Reduce parallel workers
bulk_renew_ssl 1    # Use 1 worker

# Or split into batches
# Day 1: First 50 domains
# Day 2: Next 50 domains
```

---

## 11. Best Practices

### 11.1 Backup Best Practices

**✅ DO**:
- Schedule nightly backups via cron
- Test restore monthly
- Keep 7-30 days of backups
- Monitor backup success rate (should be > 95%)
- Use filtered backups for specific needs

**❌ DON'T**:
- Backup during peak traffic hours
- Use too many parallel workers (max 8)
- Forget to verify backups

**Recommended Schedule**:
```bash
# Daily incremental backup at 2 AM
0 2 * * * /bin/bash -c 'source /opt/rocketvps/modules/bulk_operations.sh && bulk_backup_all "auto" 4'

# Weekly full backup on Sunday at 3 AM
0 3 * * 0 /bin/bash -c 'source /opt/rocketvps/modules/bulk_operations.sh && bulk_backup_all "full" 4'

# Monthly backup verification on 1st at 4 AM
0 4 1 * * /bin/bash /opt/rocketvps/scripts/verify_backups.sh
```

### 11.2 Restore Best Practices

**✅ DO**:
- Test restore in staging first
- Verify data integrity after restore
- Keep database connection info handy
- Document restore procedures

**❌ DON'T**:
- Restore in production without testing
- Skip verification after restore
- Restore without confirmation

**Emergency Restore Procedure**:
```bash
# 1. Identify affected domains
cat > emergency.txt <<EOF
critical1.com
critical2.com
EOF

# 2. Test restore in staging
bulk_restore_specific "emergency.txt" 2

# 3. Verify
for domain in $(cat emergency.txt); do
    curl -I "https://${domain}"
done

# 4. If OK, restore in production
bulk_restore_specific "emergency.txt" 4
```

### 11.3 Configuration Best Practices

**✅ DO**:
- Test configuration changes on 1-2 domains first
- Keep backups before bulk config updates
- Schedule config updates during maintenance windows
- Document all changes

**❌ DON'T**:
- Update all configs without testing
- Skip Nginx test (`nginx -t`)
- Update during peak hours

**Safe Configuration Update**:
```bash
# 1. Test on one domain
generate_nginx_config "test.domain" > /etc/nginx/sites-available/test.domain
nginx -t

# 2. If OK, apply to all
bulk_update_nginx_config 4

# 3. Monitor error logs
tail -f /var/log/nginx/error.log
```

### 11.4 Health Check Best Practices

**✅ DO**:
- Schedule daily health checks
- Set up alerts for unhealthy domains
- Track health trends over time
- Act on warnings promptly

**❌ DON'T**:
- Ignore health warnings
- Check too frequently (causes load)
- Skip verification after fixes

**Recommended Health Check Schedule**:
```bash
# Daily health check at 6 AM
0 6 * * * /bin/bash -c 'source /opt/rocketvps/modules/bulk_operations.sh && bulk_health_check 4' >> /var/log/rocketvps/health.log

# Alert on unhealthy domains
0 7 * * * /bin/bash /opt/rocketvps/scripts/health_alert.sh
```

---

## 12. FAQ

### Q1: How many parallel workers should I use?

**A**: Depends on your server specs:
- **2 CPU cores**: 2-4 workers
- **4 CPU cores**: 4-6 workers
- **8+ CPU cores**: 6-8 workers

Start with 4 and adjust based on performance.

### Q2: Can I cancel a running bulk operation?

**A**: Yes, press `Ctrl+C`. Running workers will complete, remaining will be cancelled.

```bash
# Cancel operation
^C

# Clean up
rm /opt/rocketvps/bulk_operations/temp/progress.json
```

### Q3: How do I backup only WordPress sites?

**A**:
```bash
bulk_backup_filtered "site_type" "WORDPRESS" "auto" 4
```

### Q4: Can I run multiple bulk operations simultaneously?

**A**: Not recommended. Operations may conflict. Run sequentially:
```bash
bulk_backup_all "auto" 4
bulk_health_check 4
bulk_update_nginx_config 4
```

### Q5: How much disk space do I need for bulk backups?

**A**: At least 2x the total size of all domains. Check with:
```bash
du -sh /var/www/* | awk '{sum+=$1} END {print sum*2 " GB needed"}'
```

### Q6: Can I filter domains by multiple criteria?

**A**: Yes, chain filters:
```bash
all=$(discover_all_domains)
wordpress=$(filter_domains_by_type "WORDPRESS" "${all[@]}")
small_wp=$(filter_domains_by_size 0 500 "${wordpress[@]}")
```

### Q7: How do I export results to CSV?

**A**:
```bash
result_file="/opt/rocketvps/bulk_operations/results/bulk_backup_20251004.json"
jq -r '.results[] | [.domain, .status, .error // ""] | @csv' "$result_file" > report.csv
```

### Q8: What if bulk restore fails midway?

**A**: Operation continues for remaining domains. Check result JSON for failed domains and retry:
```bash
# Extract failed domains
jq -r '.results[] | select(.status=="failed") | .domain' result.json > retry.txt

# Retry failed
bulk_restore_specific "retry.txt" 4
```

### Q9: Can I schedule bulk operations?

**A**: Yes, via cron:
```bash
crontab -e

# Add:
0 2 * * * /bin/bash -c 'source /opt/rocketvps/modules/bulk_operations.sh && bulk_backup_all "auto" 4'
```

### Q10: How do I monitor bulk operation logs?

**A**:
```bash
# Real-time monitoring
tail -f /opt/rocketvps/bulk_operations/logs/bulk_backup.log

# View results
ls -lh /opt/rocketvps/bulk_operations/results/
```

---

## 13. Quick Reference

### 13.1 Common Commands

```bash
# Source module
source /opt/rocketvps/modules/bulk_operations.sh

# Discover domains
discover_all_domains

# Backup all
bulk_backup_all "auto" 4

# Backup WordPress sites
bulk_backup_filtered "site_type" "WORDPRESS" "auto" 4

# Restore all
bulk_restore_all "auto" 4

# Restore specific
bulk_restore_specific "domains.txt" 4

# Update Nginx
bulk_update_nginx_config 4

# Fix permissions
bulk_fix_permissions 4

# Renew SSL
bulk_renew_ssl 2

# Health check
bulk_health_check 4

# Filter by pattern
filter_domains_by_pattern "wordpress" "${all_domains[@]}"

# Filter by type
filter_domains_by_type "WORDPRESS" "${all_domains[@]}"

# Filter by size
filter_domains_by_size 0 100 "${all_domains[@]}"
```

### 13.2 Result File Locations

```bash
# Results directory
/opt/rocketvps/bulk_operations/results/

# Backup results
/opt/rocketvps/bulk_operations/results/bulk_backup_*.json

# Restore results
/opt/rocketvps/bulk_operations/results/bulk_restore_*.json

# Config results
/opt/rocketvps/bulk_operations/results/bulk_nginx_*.json
/opt/rocketvps/bulk_operations/results/bulk_permissions_*.json
/opt/rocketvps/bulk_operations/results/bulk_ssl_*.json

# Health results
/opt/rocketvps/bulk_operations/results/bulk_health_check_*.json

# Progress file
/opt/rocketvps/bulk_operations/temp/progress.json

# Logs
/opt/rocketvps/bulk_operations/logs/*.log
```

### 13.3 Configuration

```bash
# Configuration file
/opt/rocketvps/modules/bulk_operations.sh

# Key settings
BULK_MAX_PARALLEL=4                 # Max parallel processes
BULK_OPERATION_TIMEOUT=3600         # Timeout per operation (seconds)
```

### 13.4 Real-World Examples

**Example 1: Nightly Backups**
```bash
#!/bin/bash
# /opt/rocketvps/scripts/nightly_backup.sh

source /opt/rocketvps/modules/bulk_operations.sh
bulk_backup_all "auto" 4

# Email report
result=$(ls -t /opt/rocketvps/bulk_operations/results/bulk_backup_*.json | head -1)
success_rate=$(jq -r '.success_rate' "$result")

if [[ $success_rate -lt 95 ]]; then
    echo "Backup success rate: ${success_rate}% (below 95%)" | \
    mail -s "ALERT: Low Backup Success Rate" admin@example.com
fi
```

**Example 2: SSL Renewal Before Expiry**
```bash
#!/bin/bash
# /opt/rocketvps/scripts/renew_expiring_ssl.sh

source /opt/rocketvps/modules/bulk_operations.sh

# Check expiring certificates
expiring_domains=""
for domain in $(discover_all_domains); do
    days=$(check_ssl_expiry "$domain" 2>/dev/null | jq -r '.days_until_expiry' 2>/dev/null)
    if [[ -n "$days" ]] && [[ $days -lt 30 ]]; then
        expiring_domains+="${domain}\n"
    fi
done

if [[ -n "$expiring_domains" ]]; then
    echo -e "$expiring_domains" > /tmp/expiring.txt
    echo "Renewing SSL for expiring domains..."
    bulk_renew_ssl 2
fi
```

**Example 3: Monthly Health Audit**
```bash
#!/bin/bash
# /opt/rocketvps/scripts/monthly_audit.sh

source /opt/rocketvps/modules/bulk_operations.sh

# Health check
bulk_health_check 4

# Generate report
result=$(ls -t /opt/rocketvps/bulk_operations/results/bulk_health_check_*.json | head -1)
total=$(jq -r '.total' "$result")
healthy=$(jq -r '.success' "$result")
unhealthy=$(jq -r '.failed' "$result")

# Email report
cat <<EOF | mail -s "Monthly Health Audit" admin@example.com
Monthly Health Audit Report

Total Domains: $total
Healthy: $healthy ($((healthy * 100 / total))%)
Unhealthy: $unhealthy ($((unhealthy * 100 / total))%)

Unhealthy Domains:
$(jq -r '.results[] | select(.status=="unhealthy") | "\(.domain): \(.error)"' "$result")

Full report: $result
EOF
```

---

**Document Version**: 2.2.0  
**Last Updated**: October 4, 2025  
**For Support**: https://github.com/rocketvps/rocketvps/issues
