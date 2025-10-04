# 🔄 Gitea Version Control Guide for RocketVPS

## Overview

RocketVPS now includes integrated **Gitea** - a lightweight Git service that provides professional version control for all your managed domains. This feature automatically tracks changes, creates commits, and allows you to restore to any previous version.

## 🎯 Key Features

### 1. Automatic Repository Management
- Create Git repositories for all domains with one click
- Automatic initialization with proper .gitignore
- Git-based version history

### 2. Smart Auto-Commit System
- Scheduled automatic commits (6h, 12h, 24h, or custom)
- Random natural commit messages
- Configurable file patterns
- Filter by file extensions

### 3. Version Control
- View complete commit history
- Compare versions side-by-side
- Restore to any previous version
- Zero-downtime restoration

### 4. File Pattern Control
- Include specific file types
- Exclude logs, cache, temporary files
- WordPress/Laravel templates
- Custom .gitignore patterns

---

## 📖 Quick Start Guide

### Step 1: Install Gitea

```bash
rocketvps
→ 13 (Gitea Version Control)
→ 1 (Install Gitea)
```

**What happens:**
- Downloads latest Gitea version
- Creates git user and directories
- Configures SQLite database
- Creates systemd service
- Starts Gitea on port 3000

**Access Gitea Web Interface:**
```
http://your-server-ip:3000
```

### Step 2: Create Repositories

**Option A: Create for Single Domain**
```bash
rocketvps → 13 → 4
```
- Select domain from list
- Repository created automatically
- Initial commit with all files

**Option B: Auto-Create for All Domains**
```bash
rocketvps → 13 → 5
```
- Scans all configured domains
- Creates repository for each
- Initializes with proper .gitignore

### Step 3: Setup Auto-Commit

```bash
rocketvps → 13 → 8
```

**Configuration:**
1. Select domain
2. Choose commit frequency:
   - Every 24 hours (recommended)
   - Every 12 hours
   - Every 6 hours
   - Custom interval
3. Configure file patterns (optional)

**Auto-Commit Features:**
- Random commit messages
- Only commits if changes detected
- Automatic push to Gitea
- Logged to `/opt/rocketvps/logs/gitea_auto_commit.log`

---

## 🔧 Detailed Configuration

### Configure File Patterns to Commit

```bash
rocketvps → 13 → 9
```

**Examples:**

**Web Files:**
```
php,html,css,js,json
```

**WordPress:**
```
php,css,js,jpg,png,gif,svg
```

**Laravel:**
```
php,blade.php,js,css,env.example
```

### Configure Ignore Patterns

```bash
rocketvps → 13 → 10
```

**Default Ignore Patterns:**
```
*.log
logs/
cache/
tmp/
node_modules/
vendor/
*.bak
*.sql
.env
*.key
```

**Custom Patterns:**
- Add one pattern per line
- Supports wildcards (*.log, temp/*)
- Standard .gitignore syntax

---

## 📊 Version Management

### View Commit History

```bash
rocketvps → 13 → 13
```

**Output Example:**
```
abc1234 - 2025-10-03 14:30 : ✨ Auto-commit: New changes saved (2 hours ago)
def5678 - 2025-10-03 12:00 : 📝 Auto-update: Content changes detected (4 hours ago)
ghi9012 - 2025-10-03 10:00 : 💾 Manual backup: Before major update (6 hours ago)
```

**Features:**
- Last 20 commits displayed
- Color-coded output
- Timestamp and relative time
- Commit message preview

### Restore to Previous Version

```bash
rocketvps → 13 → 14
```

**Process:**
1. Select domain
2. View recent commits
3. Enter commit hash (e.g., `abc1234`) or reference (e.g., `HEAD~3`)
4. Preview changes
5. Confirm restoration
6. Automatic backup created
7. Files restored
8. Permissions fixed

**Safety Features:**
- Automatic backup before restore
- Nginx stopped during restore
- Permissions automatically fixed
- Zero-downtime restoration

**Restore Options:**
- `abc1234` - Specific commit hash
- `HEAD~1` - Previous commit (1 back)
- `HEAD~5` - 5 commits back
- `main` - Latest version

### Compare Versions

```bash
rocketvps → 13 → 15
```

**Usage:**
1. Select domain
2. Enter first version (commit hash)
3. Enter second version (commit hash)
4. View file changes summary
5. Optional: View detailed differences

**Output:**
```
Modified files:
  wp-content/themes/mytheme/style.css     | 15 +++++++--------
  wp-content/plugins/myplugin/plugin.php  | 42 ++++++++++++++++++++++++
  index.php                               |  3 +-
  
3 files changed, 52 insertions(+), 11 deletions(-)
```

### Create Manual Backup Point

```bash
rocketvps → 13 → 16
```

**Use Cases:**
- Before major updates
- Before plugin/theme changes
- After important content updates
- Before testing new features

**Process:**
1. Select domain (or all domains)
2. Enter backup description
3. Immediate commit created
4. Pushed to Gitea

**Example Commit Messages:**
```
💾 Manual backup: Before WordPress 6.4 update - 2025-10-03 15:30:00
💾 Manual backup: After site redesign - 2025-10-03 15:30:00
💾 Manual backup: Before plugin installation - 2025-10-03 15:30:00
```

---

## 🎨 Commit Message Templates

The auto-commit system uses random messages for natural versioning:

```
📝 Auto-update: Content changes detected
🔄 Automatic sync: Files updated
✨ Auto-commit: New changes saved
🚀 Scheduled update: Changes committed
💾 Auto-backup: Latest changes saved
📦 Automatic commit: Content updated
🔧 Routine update: Files synchronized
⚡ Quick sync: Changes committed
🎯 Scheduled commit: Updates saved
🌟 Auto-save: New content backed up
```

---

## 🗂️ Repository Structure

Each domain gets its own repository:

```
/home/git/gitea-repositories/
└── git/
    ├── example_com.git/        # example.com repository
    ├── myblog_com.git/          # myblog.com repository
    └── myshop_org.git/          # myshop.org repository
```

Each domain directory maintains local git:

```
/var/www/example.com/
├── .git/                   # Local git repository
├── .gitignore              # Ignore patterns
├── index.php
├── wp-content/
└── ... (other files)
```

---

## 📋 Common Workflows

### Workflow 1: Setup New Domain with Version Control

```bash
# 1. Add domain
rocketvps → 2 → 1

# 2. Create repository
rocketvps → 13 → 4

# 3. Setup auto-commit
rocketvps → 13 → 8

# Done! Domain is now version controlled
```

### Workflow 2: Restore After Bad Update

```bash
# 1. View commit history
rocketvps → 13 → 13

# 2. Find commit before update (e.g., abc1234)

# 3. Restore to that version
rocketvps → 13 → 14
# Enter: abc1234

# Done! Site restored to working state
```

### Workflow 3: Compare Before/After Changes

```bash
# 1. Create backup before changes
rocketvps → 13 → 16
# Note the commit hash (e.g., abc1234)

# 2. Make your changes

# 3. Auto-commit will capture changes
# (or create manual backup)

# 4. Compare versions
rocketvps → 13 → 15
# First version: abc1234
# Second version: HEAD (current)

# Review all changes
```

### Workflow 4: Regular Maintenance Backups

```bash
# Setup once:
rocketvps → 13 → 8
# Select: Every 24 hours

# System automatically:
# - Commits changes daily
# - Uses random commit messages
# - Pushes to Gitea
# - Logs all activity

# No manual intervention needed!
```

---

## 🔍 Monitoring & Management

### View Auto-Commit Status

```bash
rocketvps → 13 → 11
```

**Output:**
```
Auto-Commit Configuration:

1. example.com - ✓ Enabled
   Frequency: Every 24 hours
   Pattern: *
   Schedule: 0 */24 * * *

2. myblog.com - ✓ Enabled
   Frequency: Every 12 hours
   Pattern: *.php,*.css,*.js
   Schedule: 0 */12 * * *
```

### View Gitea Logs

```bash
rocketvps → 13 → 18
```

**Log Types:**
1. Service logs (systemd)
2. Gitea application logs
3. Auto-commit logs

**Auto-Commit Log Example:**
```
[2025-10-03 14:00:01] ✓ Changes committed for example.com
[2025-10-03 14:00:05] ℹ No changes detected for myblog.com
[2025-10-03 14:00:10] ✓ Changes committed for myshop.org
```

### Disable Auto-Commit

```bash
rocketvps → 13 → 12
```

**Process:**
1. Select domain
2. Confirm disable
3. Cron job removed
4. Status set to disabled

**Note:** Repository and history remain intact.

---

## 🌐 Gitea Web Interface

### Access Gitea

```
URL: http://your-server-ip:3000
```

### Setup Nginx Reverse Proxy

```bash
rocketvps → 13 → 2 → 2
```

**After setup:**
```
URL: http://git.yourdomain.com
```

### Web Interface Features

**Repository Browser:**
- View all repositories
- Browse files and directories
- View commit history
- Compare commits
- Download archives

**Code Viewer:**
- Syntax highlighting
- Line numbers
- Blame view
- Raw file access

**Commit History:**
- Visual timeline
- Commit messages
- File changes
- Author information

---

## 🔒 Security Considerations

### Repository Access

**Default Security:**
- Repositories owned by `git` user
- Read-only access from web interface
- Local access requires sudo

**Best Practices:**
1. Don't commit sensitive files (.env, database.php)
2. Use .gitignore for passwords/keys
3. Regular backup of Gitea data
4. Keep Gitea updated

### Sensitive Files

**Automatically Ignored:**
```
.env
*.key
*.pem
wp-config.php
config/database.php
```

**Manual Exclusion:**
```bash
rocketvps → 13 → 10
# Add your patterns
```

---

## 💡 Tips & Tricks

### Tip 1: Quick Restore

For quick restore to previous state:
```bash
# Restore to 1 commit back
Enter: HEAD~1

# Restore to 3 commits back
Enter: HEAD~3
```

### Tip 2: Find Specific Change

```bash
# View history
rocketvps → 13 → 13

# Search for date/time
# Copy commit hash

# View details
# Enter commit hash when prompted
```

### Tip 3: Pre-Update Backups

Always create manual backup before major changes:
```bash
rocketvps → 13 → 16
# Description: "Before WordPress update to 6.4"
```

### Tip 4: Multiple Commit Frequencies

Different domains can have different frequencies:
- E-commerce: Every 6 hours
- Blog: Every 24 hours
- Static: Every 48 hours (custom)

### Tip 5: Exclude Large Files

For sites with many images/videos:
```bash
rocketvps → 13 → 9
# Include: php,css,js,html
# This excludes images/videos from commits
```

---

## 🛠️ Advanced Usage

### Manual Git Operations

Access domain repository:
```bash
cd /var/www/example.com
sudo -u git git log
sudo -u git git status
```

### Custom Commit

```bash
cd /var/www/example.com
sudo -u git git add specific-file.php
sudo -u git git commit -m "Updated specific file"
sudo -u git git push origin main
```

### View Repository Size

```bash
du -sh /home/git/gitea-repositories/git/*.git
```

### Cleanup Old Commits

Git automatically manages space, but for manual cleanup:
```bash
cd /var/www/example.com
sudo -u git git gc --aggressive --prune=now
```

---

## 🔧 Troubleshooting

### Problem: Auto-commit not working

**Solution:**
```bash
# Check cron job
crontab -l | grep auto_commit

# Check logs
tail -f /opt/rocketvps/logs/gitea_auto_commit.log

# Re-setup
rocketvps → 13 → 12 (disable)
rocketvps → 13 → 8  (re-enable)
```

### Problem: Repository not showing in Gitea

**Solution:**
```bash
# Check repository exists
ls -la /home/git/gitea-repositories/git/

# Restart Gitea
rocketvps → 13 → 3 → 3
```

### Problem: Permission denied

**Solution:**
```bash
# Fix ownership
chown -R git:git /home/git/gitea-repositories/
chown -R git:git /var/www/your-domain/.git
```

### Problem: Restore failed

**Solution:**
```bash
# Check backup was created
ls -la /opt/rocketvps/backups/gitea_restore_backup_*

# Manual restore from backup
tar -xzf backup-file.tar.gz -C /var/www/

# Fix permissions
rocketvps → 9 → 7
```

---

## 📊 Best Practices

### 1. Commit Frequency

**Recommended:**
- **Development sites**: Every 6 hours
- **Production sites**: Every 24 hours
- **Static sites**: Every 48 hours

### 2. File Patterns

**Include:**
- Source code (.php, .js, .css)
- Templates (.html, .blade.php)
- Configuration (non-sensitive)

**Exclude:**
- Logs (*.log)
- Cache (cache/, tmp/)
- Large media (videos, backups)
- Sensitive (.env, *.key)

### 3. Manual Backups

Create manual backups:
- Before major updates
- After significant content changes
- Before testing new features
- Before configuration changes

### 4. Regular Monitoring

Check auto-commit status weekly:
```bash
rocketvps → 13 → 11
```

Review logs monthly:
```bash
rocketvps → 13 → 18 → 3
```

### 5. Backup Gitea

Monthly Gitea backup:
```bash
rocketvps → 13 → 17
```

---

## 📈 Performance Considerations

### Disk Space

**Typical Usage:**
- Small site (< 100MB): ~10MB per month
- Medium site (100-500MB): ~50MB per month
- Large site (> 500MB): ~100MB+ per month

**Optimization:**
- Exclude large media files
- Use .gitignore effectively
- Run `git gc` periodically

### Resource Usage

**Gitea Service:**
- RAM: ~100MB
- CPU: Minimal (< 1%)
- Disk I/O: Low

**Auto-Commit:**
- Runs in background
- Minimal resource usage
- Non-blocking

---

## 🎓 Learning Resources

### Understanding Git

- **Commits**: Snapshots of your files
- **Repository**: Storage for all commits
- **Branch**: Line of development (default: main)
- **Push**: Send commits to Gitea
- **Checkout**: Switch to different version

### RocketVPS Git Workflow

```
Your Files → Git Add → Git Commit → Git Push → Gitea Repository
                ↓                        ↓
           Auto-detect changes      Store history
```

### Helpful Git Commands

```bash
# View history
git log --oneline

# Check status
git status

# View changes
git diff

# View specific commit
git show <commit-hash>
```

---

## 📞 Support

### Getting Help

**Documentation:**
- This guide
- RocketVPS main documentation
- Gitea official docs

**Logs:**
```bash
# Auto-commit logs
tail -f /opt/rocketvps/logs/gitea_auto_commit.log

# Gitea logs
journalctl -u gitea -f
```

**GitHub Issues:**
https://github.com/yourusername/rocketvps/issues

---

## 🎉 Summary

Gitea integration in RocketVPS provides:

✅ **Automatic version control** for all domains  
✅ **Smart auto-commit** system  
✅ **Easy restoration** to any previous version  
✅ **Zero-downtime** operations  
✅ **Professional Git hosting** with web interface  
✅ **Customizable** commit patterns  
✅ **Comprehensive** logging and monitoring  

**Start using Gitea version control today!**

```bash
rocketvps → 13 → 1  # Install Gitea
rocketvps → 13 → 5  # Create repositories
rocketvps → 13 → 8  # Setup auto-commit
```

---

**🚀 RocketVPS Gitea - Professional Version Control Made Simple**
