# 🔄 Smart Restore System - Design Document

**Version:** 2.2.0 Phase 1B  
**Date:** October 4, 2025  
**Status:** Design Phase

---

## 📋 OVERVIEW

Smart Restore là hệ thống phục hồi thông minh với khả năng preview, rollback tự động khi thất bại, và incremental restore cho phép phục hồi từng phần (files/database/config) một cách an toàn.

---

## 🎯 OBJECTIVES

### Primary Goals
1. **Safe Restore** - Phục hồi an toàn với snapshot trước khi restore
2. **Auto Rollback** - Tự động rollback khi restore thất bại
3. **Preview Before Restore** - Xem nội dung backup trước khi restore
4. **Incremental Restore** - Chọn restore từng phần (files/DB/config)
5. **Progress Tracking** - Hiển thị tiến trình restore realtime

### Safety Goals
1. Pre-restore validation
2. Automatic snapshots
3. Rollback on failure
4. Disk space verification
5. Service status checks

---

## 🏗️ ARCHITECTURE

### Component Structure

```
/opt/rocketvps/
├── modules/
│   ├── restore.sh              (Restore core module)
│   └── restore_ui.sh           (Restore UI module)
├── backups/
│   └── [domain]/
│       ├── backup_20251004_030000.tar.gz
│       ├── backup_20251003_030000.tar.gz
│       └── .backup_index.json  (Backup metadata)
├── snapshots/
│   └── [domain]/
│       └── pre_restore_20251004_100000/
│           ├── files.tar.gz
│           ├── database.sql.gz
│           └── config.tar.gz
└── restore_logs/
    └── [domain]/
        └── restore_20251004_100000.log
```

### Restore Workflow

```
┌─────────────────────────────────────────────────────────────┐
│  1. SELECT RESTORE POINT                                    │
│     - List available backups                                │
│     - Show backup details (date, size, content)             │
└────────────┬────────────────────────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────────────────────┐
│  2. PREVIEW BACKUP CONTENT                                  │
│     - Show files list                                       │
│     - Show database structure                               │
│     - Show configuration files                              │
│     - Estimate restore time                                 │
└────────────┬────────────────────────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────────────────────┐
│  3. SELECT RESTORE TYPE                                     │
│     [✓] Full Restore (files + database + config)            │
│     [ ] Files Only                                          │
│     [ ] Database Only                                       │
│     [ ] Configuration Only                                  │
│     [ ] Selective Restore (choose specific items)           │
└────────────┬────────────────────────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────────────────────┐
│  4. PRE-RESTORE VALIDATION                                  │
│     ✓ Check disk space                                      │
│     ✓ Verify backup integrity                               │
│     ✓ Check service status                                  │
│     ✓ Detect conflicts                                      │
│     ✓ Create safety snapshot                                │
└────────────┬────────────────────────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────────────────────┐
│  5. CONFIRM RESTORE                                         │
│     ⚠ WARNING DISPLAY                                       │
│     - Current state will be replaced                        │
│     - Safety snapshot created                               │
│     - Rollback available                                    │
│     - Estimated time: X minutes                             │
│                                                             │
│     Type 'YES' to confirm: ____                             │
└────────────┬────────────────────────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────────────────────┐
│  6. EXECUTE RESTORE                                         │
│     [=========>         ] 45% Restoring files...            │
│     ✓ Files restored: 1,234 files                           │
│     ✓ Database restored: 45 tables                          │
│     ⏳ Restoring configuration...                            │
└────────────┬────────────────────────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────────────────────┐
│  7. VERIFICATION                                            │
│     ✓ Verify file integrity                                 │
│     ✓ Test database connection                              │
│     ✓ Check service status                                  │
│     ✓ Validate configuration                                │
└────────────┬────────────────────────────────────────────────┘
             │
             ▼
        ┌────┴────┐
        │         │
   SUCCESS      FAILURE
        │         │
        ▼         ▼
  ┌─────────┐   ┌──────────────────┐
  │ CLEANUP │   │ AUTO ROLLBACK    │
  │         │   │ Restore from     │
  │ Remove  │   │ safety snapshot  │
  │ snapshot│   └──────────────────┘
  └─────────┘
```

---

## 🔍 FEATURES

### 1. Backup Preview 👁️

**Show backup details before restore:**

```bash
╔════════════════════════════════════════════════════════════════╗
║              BACKUP PREVIEW                                    ║
║              example.com - 2025-10-04 03:00:00                 ║
╚════════════════════════════════════════════════════════════════╝

📊 BACKUP INFORMATION
   Backup Date:        2025-10-04 03:00:00
   Backup Size:        245 MB
   Compression:        gzip
   Integrity:          ✓ Valid

📁 FILES (1,234 files)
   /var/www/example.com/
   ├── public/               (456 files, 123 MB)
   ├── wp-content/           (678 files, 98 MB)
   │   ├── plugins/          (123 files, 45 MB)
   │   ├── themes/           (234 files, 23 MB)
   │   └── uploads/          (321 files, 30 MB)
   ├── wp-admin/             (56 files, 12 MB)
   └── wp-includes/          (44 files, 10 MB)

🗄️  DATABASE (mysql)
   Database:           example_com
   Tables:             45 tables
   Size:               23 MB
   Records:            ~10,000 rows
   
   Key tables:
   - wp_posts          (1,234 rows)
   - wp_users          (45 rows)
   - wp_options        (567 rows)
   - wp_postmeta       (3,456 rows)

⚙️  CONFIGURATION
   - nginx.conf        (example.com.conf)
   - PHP-FPM pool      (example.com.conf)
   - SSL certificates  (cert.pem, key.pem)
   - Cron jobs         (backup script)

⏱️  RESTORE ESTIMATE
   Files:              ~5 minutes
   Database:           ~2 minutes
   Configuration:      ~1 minute
   Total:              ~8 minutes

💾 REQUIRED SPACE
   Current Used:       300 MB
   Backup Size:        245 MB
   Safety Snapshot:    300 MB
   Total Required:     545 MB
   Available:          5.2 GB ✓

Press any key to continue...
```

### 2. Incremental Restore 📦

**Restore individual components:**

```bash
╔════════════════════════════════════════════════════════════════╗
║              SELECT RESTORE COMPONENTS                         ║
╚════════════════════════════════════════════════════════════════╝

Choose what to restore:

  [✓] 1. Files (1,234 files, 234 MB)
      └─ All website files and directories

  [✓] 2. Database (45 tables, 23 MB)
      └─ Complete database with all data

  [✓] 3. Configuration (4 files)
      └─ Nginx, PHP-FPM, SSL, Cron

  [ ] 4. Custom Selection
      └─ Choose specific files/tables

────────────────────────────────────────────────────────────────

Selected: Full Restore (all components)
Estimated time: ~8 minutes

[C] Continue  [A] Advanced Options  [Q] Cancel
```

**Advanced Selection:**

```bash
╔════════════════════════════════════════════════════════════════╗
║              CUSTOM RESTORE SELECTION                          ║
╚════════════════════════════════════════════════════════════════╝

📁 FILES
  [✓] wp-content/uploads/    (321 files, 30 MB)
  [✓] wp-content/themes/     (234 files, 23 MB)
  [ ] wp-content/plugins/    (123 files, 45 MB)
  [✓] wp-config.php          (1 file, 3 KB)
  [ ] .htaccess              (1 file, 2 KB)

🗄️  DATABASE TABLES
  [✓] wp_posts               (1,234 rows)
  [✓] wp_postmeta            (3,456 rows)
  [ ] wp_users               (45 rows)
  [ ] wp_usermeta            (234 rows)
  [✓] wp_options             (567 rows)
  [✓] wp_comments            (890 rows)

⚙️  CONFIGURATION
  [ ] Nginx config
  [ ] PHP-FPM config
  [✓] SSL certificates
  [ ] Cron jobs

────────────────────────────────────────────────────────────────

Selected: 3 file groups, 4 tables, 1 config
Estimated time: ~4 minutes

[C] Continue  [R] Reset  [Q] Cancel
```

### 3. Safety Snapshot 📸

**Automatic snapshot before restore:**

```bash
╔════════════════════════════════════════════════════════════════╗
║              CREATING SAFETY SNAPSHOT                          ║
╚════════════════════════════════════════════════════════════════╝

⏳ Creating pre-restore snapshot for rollback protection...

[=========>         ] 45% Snapshotting files...

✓ Files snapshotted:        1,234 files (234 MB)
✓ Database exported:        45 tables (23 MB)
✓ Configuration saved:      4 files (12 KB)

Snapshot saved to:
/opt/rocketvps/snapshots/example.com/pre_restore_20251004_100000/

This snapshot will be used for automatic rollback if restore fails.

Press any key to continue...
```

### 4. Progress Tracking 📊

**Real-time progress display:**

```bash
╔════════════════════════════════════════════════════════════════╗
║              RESTORE IN PROGRESS                               ║
║              example.com - 2025-10-04 03:00:00                 ║
╚════════════════════════════════════════════════════════════════╝

Overall Progress: [=============>      ] 65%

┌──────────────────────────────────────────────────────────────┐
│ PHASE 1: FILES                                         ✓ DONE │
│ [==========================] 100%                             │
│ Restored: 1,234 files (234 MB)                                │
│ Duration: 5m 23s                                              │
└──────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────┐
│ PHASE 2: DATABASE                                    ⏳ ACTIVE │
│ [================>         ] 65%                              │
│ Restored: 29/45 tables (15 MB / 23 MB)                        │
│ Current: wp_postmeta (1,234 rows)                             │
│ Elapsed: 1m 30s | Remaining: ~1m                              │
└──────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────┐
│ PHASE 3: CONFIGURATION                               ⏸ PENDING │
│ [                          ] 0%                               │
│ Items: 4 configuration files                                  │
└──────────────────────────────────────────────────────────────┘

⏱️  Elapsed: 6m 53s | Estimated remaining: ~2m

💾 Disk I/O: 45 MB/s (Read: 40 MB/s, Write: 5 MB/s)
🔄 Safety snapshot available for rollback

[Ctrl+C to cancel - rollback will be triggered automatically]
```

### 5. Automatic Rollback 🔙

**Rollback triggered on failure:**

```bash
╔════════════════════════════════════════════════════════════════╗
║              RESTORE FAILED - AUTOMATIC ROLLBACK               ║
╚════════════════════════════════════════════════════════════════╝

✗ RESTORE FAILURE DETECTED
   Phase: Database restore
   Error: MySQL connection failed
   Time: 2025-10-04 10:15:32

⏳ Initiating automatic rollback...

[=========>         ] 45% Rolling back changes...

✓ Files restored from snapshot:     1,234 files
✓ Database restored from snapshot:  45 tables
✓ Configuration restored:            4 files

✓ ROLLBACK SUCCESSFUL

Your domain has been restored to the state before the restore attempt.
All changes have been reverted successfully.

Error details saved to:
/opt/rocketvps/restore_logs/example.com/restore_20251004_101532_failed.log

Press any key to continue...
```

### 6. Verification System ✅

**Post-restore verification:**

```bash
╔════════════════════════════════════════════════════════════════╗
║              VERIFYING RESTORED SYSTEM                         ║
╚════════════════════════════════════════════════════════════════╝

Running comprehensive verification...

┌──────────────────────────────────────────────────────────────┐
│ FILE INTEGRITY                                         ✓ PASS │
│ ✓ All 1,234 files restored successfully                      │
│ ✓ File permissions correct (644/755)                          │
│ ✓ Ownership correct (www-data:www-data)                       │
│ ✓ Disk space sufficient (4.8 GB remaining)                    │
└──────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────┐
│ DATABASE INTEGRITY                                     ✓ PASS │
│ ✓ Database connection successful                              │
│ ✓ All 45 tables restored                                      │
│ ✓ Table structure valid                                       │
│ ✓ No corrupted records found                                  │
└──────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────┐
│ CONFIGURATION                                          ✓ PASS │
│ ✓ Nginx configuration valid                                   │
│ ✓ PHP-FPM pool active                                         │
│ ✓ SSL certificates valid                                      │
│ ✓ Cron jobs scheduled                                         │
└──────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────┐
│ SERVICE STATUS                                         ✓ PASS │
│ ✓ Nginx: running                                              │
│ ✓ PHP-FPM: running                                            │
│ ✓ MySQL: running                                              │
│ ✓ Website accessible (HTTP 200)                               │
└──────────────────────────────────────────────────────────────┘

✅ ALL VERIFICATION CHECKS PASSED

Your domain has been successfully restored and verified.

Press any key to continue...
```

---

## 🔧 CORE FUNCTIONS

### Restore Core Functions

```bash
# List available backups
restore_list_backups(domain)
  - Scan backup directory
  - Parse backup metadata
  - Sort by date (newest first)
  - Display backup info

# Preview backup content
restore_preview_backup(backup_file)
  - Extract backup metadata
  - List files and directories
  - Show database structure
  - Display configuration files
  - Calculate restore time
  - Check disk space

# Validate restore prerequisites
restore_validate_prerequisites(domain, backup_file)
  - Check disk space
  - Verify backup integrity
  - Check service status
  - Detect conflicts
  - Generate warnings

# Create safety snapshot
restore_create_snapshot(domain)
  - Snapshot files
  - Export database
  - Backup configuration
  - Save to snapshot directory
  - Return snapshot path

# Execute full restore
restore_execute_full(domain, backup_file, snapshot_path)
  - Extract backup
  - Restore files
  - Restore database
  - Restore configuration
  - Set permissions
  - Restart services
  - Verify restore

# Execute incremental restore
restore_execute_incremental(domain, backup_file, components)
  - Extract selected components
  - Restore files (if selected)
  - Restore database tables (if selected)
  - Restore config files (if selected)
  - Set permissions
  - Verify restore

# Rollback to snapshot
restore_rollback(domain, snapshot_path)
  - Restore files from snapshot
  - Restore database from snapshot
  - Restore configuration
  - Set permissions
  - Restart services
  - Clean up snapshot

# Verify restored system
restore_verify(domain)
  - Check file integrity
  - Test database connection
  - Validate configuration
  - Check service status
  - Test website access
  - Return verification results

# Clean up after restore
restore_cleanup(domain, snapshot_path, success)
  - Remove temporary files
  - Remove snapshot (if success)
  - Log restore operation
  - Send notification
```

---

## 🛡️ SAFETY MEASURES

### 1. Pre-Restore Validation

```bash
✓ Disk Space Check
  - Current usage
  - Backup size
  - Snapshot size
  - Total required
  - Available space

✓ Backup Integrity
  - File checksums
  - Archive validity
  - Compression test
  - Metadata validation

✓ Service Status
  - Nginx running
  - PHP-FPM running
  - MySQL running
  - Redis running (if used)

✓ Conflict Detection
  - Existing files
  - Database exists
  - Port conflicts
  - Permission issues
```

### 2. Rollback Triggers

```bash
Automatic rollback on:
  - Database restore failure
  - File restoration error
  - Disk space exhausted
  - Service crash
  - Verification failure
  - User cancellation (Ctrl+C)
  - Timeout exceeded
```

### 3. Safety Limits

```bash
# Restore timeout
RESTORE_TIMEOUT=1800  # 30 minutes

# Max retries
MAX_RETRIES=3

# Snapshot retention
SNAPSHOT_RETENTION=24  # hours

# Verification timeout
VERIFY_TIMEOUT=300  # 5 minutes
```

---

## 📈 PERFORMANCE

### Expected Performance

```bash
# Small website (< 100 MB)
Files:          1-2 minutes
Database:       < 1 minute
Configuration:  < 30 seconds
Total:          2-3 minutes

# Medium website (100-500 MB)
Files:          5-10 minutes
Database:       2-3 minutes
Configuration:  < 1 minute
Total:          8-14 minutes

# Large website (> 500 MB)
Files:          15-30 minutes
Database:       5-10 minutes
Configuration:  1-2 minutes
Total:          21-42 minutes
```

### Optimization Strategies

```bash
1. Parallel Processing
   - Extract backup in parallel
   - Restore files and DB concurrently
   - Use pigz for faster decompression

2. Incremental Restore
   - Only restore changed files
   - Skip unchanged database records
   - Smart diff for configuration

3. Progress Caching
   - Resume interrupted restores
   - Skip already restored items
   - Checkpoint system
```

---

## 🧪 TESTING SCENARIOS

### Test Cases

1. **Full Restore**
   - [ ] Restore complete backup
   - [ ] Verify all files restored
   - [ ] Verify database restored
   - [ ] Verify configuration restored
   - [ ] Website accessible

2. **Incremental Restore**
   - [ ] Files only
   - [ ] Database only
   - [ ] Configuration only
   - [ ] Custom selection

3. **Rollback**
   - [ ] Automatic rollback on failure
   - [ ] Manual rollback trigger
   - [ ] Verify rollback complete
   - [ ] System state preserved

4. **Safety**
   - [ ] Disk space check
   - [ ] Backup integrity validation
   - [ ] Service status verification
   - [ ] Conflict detection

5. **Progress & UI**
   - [ ] Progress tracking
   - [ ] Real-time updates
   - [ ] Cancel handling
   - [ ] Error messages

---

## 📅 IMPLEMENTATION PLAN

### Phase 1B.4: Core Restore (2 hours)
- Create restore.sh module
- Implement list/preview functions
- Implement snapshot creation
- Implement full restore
- Implement verification

### Phase 1B.5: Advanced Restore (1 hour)
- Implement incremental restore
- Implement rollback system
- Implement progress tracking
- Error handling

### Phase 1B.6: UI (1 hour)
- Create restore_ui.sh
- Interactive menus
- Progress display
- Confirmation dialogs

### Phase 1B.7: Testing (0.5 hours)
- Test all restore types
- Test rollback scenarios
- Performance testing
- Bug fixes

**Total Estimated Time: 4.5 hours**

---

## 🎯 SUCCESS CRITERIA

- ✅ Preview backup before restore
- ✅ Incremental restore working
- ✅ Safety snapshot created
- ✅ Automatic rollback on failure
- ✅ Progress tracking realtime
- ✅ All verifications pass
- ✅ Performance < 30 minutes for large sites
- ✅ Zero data loss on rollback
- ✅ Complete error logging
- ✅ User-friendly interface

---

**Status:** Ready for Implementation  
**Next Step:** Create restore.sh module
