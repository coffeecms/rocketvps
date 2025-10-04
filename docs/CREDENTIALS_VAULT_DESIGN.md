# 🔐 Credentials Vault - Design Document

**Version:** 2.2.0 Phase 1B  
**Date:** October 4, 2025  
**Status:** Design Phase

---

## 📋 OVERVIEW

Credentials Vault là hệ thống quản lý credentials tập trung với mã hóa AES-256, cho phép lưu trữ và truy xuất an toàn tất cả credentials của các domains và services.

---

## 🎯 OBJECTIVES

### Primary Goals
1. **Centralized Storage** - Tất cả credentials ở một nơi
2. **Strong Encryption** - AES-256-CBC với master password
3. **Easy Access** - Interface thân thiện để xem/quản lý
4. **Auto-Integration** - Tự động lưu credentials từ profiles
5. **Secure Export** - Export credentials an toàn khi cần

### Security Goals
1. Master password protection
2. No plaintext storage
3. Access logging
4. Session timeout
5. Brute-force protection

---

## 🏗️ ARCHITECTURE

### Component Structure

```
/opt/rocketvps/
├── modules/
│   └── vault.sh                    (Vault core module)
├── vault/
│   ├── master.key.enc              (Encrypted master key)
│   ├── credentials.db.enc          (Encrypted credentials database)
│   ├── access.log                  (Access audit log)
│   └── config.conf                 (Vault configuration)
└── config/
    └── vault/
        └── session.lock            (Active session lock)
```

### Data Flow

```
┌─────────────────┐
│  Profile Setup  │
│  (WordPress,    │
│   Laravel, etc) │
└────────┬────────┘
         │
         ▼
┌─────────────────────────────────┐
│  Auto-Save Credentials          │
│  - Domain info                  │
│  - Admin credentials            │
│  - Database credentials         │
│  - FTP credentials              │
│  - SSL info                     │
└────────┬────────────────────────┘
         │
         ▼
┌─────────────────────────────────┐
│  Credentials Vault              │
│  ┌───────────────────────────┐  │
│  │ Master Password Lock      │  │
│  └───────────────────────────┘  │
│  ┌───────────────────────────┐  │
│  │ AES-256 Encryption        │  │
│  └───────────────────────────┘  │
│  ┌───────────────────────────┐  │
│  │ Encrypted Storage         │  │
│  └───────────────────────────┘  │
└────────┬────────────────────────┘
         │
         ▼
┌─────────────────────────────────┐
│  User Access                    │
│  - View credentials             │
│  - Search domains               │
│  - Export (encrypted)           │
│  - Update credentials           │
│  - Rotate passwords             │
└─────────────────────────────────┘
```

---

## 🔒 SECURITY DESIGN

### Encryption Scheme

**Master Password → Key Derivation → Encryption Key**

```bash
# Step 1: User enters master password
MASTER_PASSWORD="user_password"

# Step 2: Generate salt (random 32 bytes)
SALT=$(openssl rand -hex 32)

# Step 3: Derive encryption key using PBKDF2
# Iterations: 100,000 (OWASP recommendation)
ENCRYPTION_KEY=$(echo -n "$MASTER_PASSWORD" | \
  openssl enc -pbkdf2 -salt -S $SALT -iter 100000 -md sha256)

# Step 4: Encrypt credentials with AES-256-CBC
echo "$CREDENTIALS_JSON" | \
  openssl enc -aes-256-cbc -pbkdf2 -iter 100000 \
  -pass pass:"$ENCRYPTION_KEY" -out credentials.db.enc
```

### Master Password Requirements

```bash
Minimum length: 12 characters
Must contain:
  - Uppercase letters (A-Z)
  - Lowercase letters (a-z)
  - Numbers (0-9)
  - Special characters (!@#$%^&*)
  
Example: MyV@ultP@ss2025!
```

### Session Management

```bash
# Session timeout: 15 minutes
SESSION_TIMEOUT=900

# Session lock file
/opt/rocketvps/config/vault/session.lock
  - Created on vault unlock
  - Contains: PID, timestamp, username
  - Auto-removed on timeout
  - Manual lock on exit
```

### Access Control

```bash
# File permissions
vault/master.key.enc          600 (rw-------)
vault/credentials.db.enc      600 (rw-------)
vault/access.log              640 (rw-r-----)
vault/config.conf             600 (rw-------)

# Directory permissions
vault/                        700 (rwx------)
```

---

## 💾 DATA STRUCTURE

### Credentials Database Schema

```json
{
  "version": "1.0",
  "created": "2025-10-04T10:00:00Z",
  "last_modified": "2025-10-04T10:00:00Z",
  "domains": {
    "example.com": {
      "profile": "wordpress",
      "created_date": "2025-10-04T10:00:00Z",
      "status": "active",
      "domain_info": {
        "domain": "example.com",
        "document_root": "/var/www/example.com",
        "php_version": "8.2",
        "ssl_enabled": true,
        "ssl_expiry": "2026-01-04"
      },
      "admin": {
        "url": "https://example.com/wp-admin",
        "username": "admin",
        "password": "encrypted_password_here",
        "email": "admin@example.com"
      },
      "database": {
        "type": "mysql",
        "host": "localhost",
        "port": "3306",
        "database": "example_com",
        "username": "example_com",
        "password": "encrypted_password_here"
      },
      "ftp": {
        "host": "example.com",
        "port": "21",
        "username": "wp_admin",
        "password": "encrypted_password_here",
        "path": "/var/www/example.com"
      },
      "services": {
        "redis": {
          "enabled": true,
          "host": "localhost",
          "port": "6379"
        },
        "backup": {
          "enabled": true,
          "schedule": "daily",
          "retention": "7 days",
          "last_backup": "2025-10-04T03:00:00Z"
        }
      }
    }
  }
}
```

### Access Log Format

```log
2025-10-04 10:00:00 | USER:root | ACTION:unlock_vault | STATUS:success | IP:127.0.0.1
2025-10-04 10:05:00 | USER:root | ACTION:view_credentials | DOMAIN:example.com | STATUS:success
2025-10-04 10:10:00 | USER:root | ACTION:export_credentials | DOMAIN:example.com | STATUS:success
2025-10-04 10:15:00 | USER:root | ACTION:lock_vault | STATUS:success
```

---

## 🎨 USER INTERFACE

### Main Vault Menu

```
╔════════════════════════════════════════════════════════════════╗
║              CREDENTIALS VAULT                                 ║
║              Status: 🔒 Locked                                 ║
╚════════════════════════════════════════════════════════════════╝

  1) Unlock Vault
     └─ Enter master password to access credentials

  2) View All Credentials
     └─ Display all domains with credentials

  3) Search Credentials
     └─ Search by domain name or profile type

  4) View Domain Details
     └─ Show complete credentials for a domain

  5) Export Credentials
     └─ Export encrypted credentials (requires master password)

  6) Change Master Password
     └─ Update vault master password

  7) Rotate Domain Passwords
     └─ Auto-generate and update passwords

  8) View Access Log
     └─ Show recent vault access history

  9) Vault Settings
     └─ Configure timeout, auto-lock, etc.

  0) Lock Vault and Exit

────────────────────────────────────────────────────────────────
```

### Unlock Sequence

```
╔════════════════════════════════════════════════════════════════╗
║              UNLOCK CREDENTIALS VAULT                          ║
╚════════════════════════════════════════════════════════════════╝

🔐 Enter Master Password: ************

⏳ Verifying password...
⏳ Decrypting credentials database...
⏳ Loading credentials...

✅ Vault unlocked successfully!

📊 Summary:
   - Total Domains: 5
   - Active Domains: 4
   - Disabled Domains: 1
   - Last Access: 2025-10-04 09:00:00

⏰ Session will auto-lock in 15 minutes of inactivity

Press any key to continue...
```

### View Credentials Display

```
╔════════════════════════════════════════════════════════════════╗
║              ALL CREDENTIALS                                   ║
╚════════════════════════════════════════════════════════════════╝

DOMAIN                         PROFILE          STATUS    CREATED
────────────────────────────────────────────────────────────────
myblog.com                     wordpress        ✓ active  2025-10-01
api.myapp.com                  laravel          ✓ active  2025-10-02
shop.mystore.com               ecommerce        ✓ active  2025-10-03
app.mysite.com                 nodejs           ✓ active  2025-10-04
landing.site.com               static           ✗ disabled 2025-10-01

Total: 5 domains | Active: 4 | Disabled: 1

Enter domain name to view details (or 'q' to quit): _
```

### Domain Details View

```
╔════════════════════════════════════════════════════════════════╗
║              CREDENTIALS DETAILS - myblog.com                  ║
╚════════════════════════════════════════════════════════════════╝

🌐 DOMAIN INFORMATION
   Domain:         myblog.com
   Profile:        wordpress
   Status:         active
   Created:        2025-10-01 10:30:00
   Document Root:  /var/www/myblog.com

🔐 ADMIN ACCESS
   URL:            https://myblog.com/wp-admin
   Username:       admin
   Password:       Xk9$mP2#vL8@qW4z [Click to copy]
   Email:          admin@myblog.com

🗄️  DATABASE ACCESS
   Type:           MySQL
   Host:           localhost:3306
   Database:       myblog_com
   Username:       myblog_com
   Password:       aB3$nR7#kT9@pQ2x [Click to copy]

📁 FTP ACCESS
   Host:           myblog.com:21
   Username:       wp_admin
   Password:       qW4$eR8#tY3@uI5o [Click to copy]
   Path:           /var/www/myblog.com

⚙️  SERVICES
   Redis:          ✓ Enabled (localhost:6379)
   SSL:            ✓ Enabled (expires: 2026-01-01)
   Backup:         ✓ Daily at 3AM (last: 2025-10-04 03:00)

────────────────────────────────────────────────────────────────
Actions:
  [C] Copy all credentials  [E] Export  [U] Update  [R] Rotate passwords  [Q] Back

Your choice: _
```

---

## 🔧 FUNCTIONS

### Core Functions

```bash
# Initialize vault (first time setup)
vault_init()
  - Generate master password
  - Create encryption key
  - Initialize database
  - Set permissions

# Unlock vault
vault_unlock()
  - Prompt master password
  - Verify password
  - Decrypt database
  - Create session lock
  - Set auto-lock timer

# Lock vault
vault_lock()
  - Clear session
  - Remove session lock
  - Clear memory
  - Log access

# Add credentials
vault_add_credentials(domain, profile, data)
  - Validate data
  - Encrypt passwords
  - Update database
  - Log action

# Get credentials
vault_get_credentials(domain)
  - Verify session
  - Decrypt database
  - Return credentials
  - Log access

# Search credentials
vault_search(query)
  - Verify session
  - Search domains
  - Search profiles
  - Return matches

# Export credentials
vault_export(domain, format)
  - Verify session
  - Encrypt export
  - Create export file
  - Log export

# Update credentials
vault_update(domain, field, value)
  - Verify session
  - Update database
  - Re-encrypt
  - Log update

# Rotate passwords
vault_rotate_passwords(domain)
  - Generate new passwords
  - Update services
  - Update vault
  - Log rotation

# Change master password
vault_change_master_password()
  - Verify old password
  - Set new password
  - Re-encrypt database
  - Log change
```

---

## 📊 FEATURES

### 1. Auto-Save from Profiles ✨

**Integration with profile system:**

```bash
# In profiles.sh - after domain setup
source modules/vault.sh

# Save WordPress credentials
vault_add_credentials "$domain" "wordpress" '{
  "admin": {
    "url": "https://'$domain'/wp-admin",
    "username": "admin",
    "password": "'$WP_ADMIN_PASSWORD'",
    "email": "admin@'$domain'"
  },
  "database": {
    "type": "mysql",
    "host": "localhost",
    "database": "'$db_name'",
    "username": "'$db_user'",
    "password": "'$db_password'"
  },
  "ftp": {
    "username": "wp_admin",
    "password": "'$ftp_password'"
  }
}'
```

### 2. Search and Filter 🔍

```bash
# Search by domain
vault_search "myblog"

# Search by profile
vault_search "wordpress"

# Search by status
vault_search "active"

# Search by date
vault_search "2025-10"
```

### 3. Export Formats 📤

```bash
# JSON export (encrypted)
vault_export "myblog.com" "json"

# CSV export (encrypted)
vault_export "myblog.com" "csv"

# Plain text (requires confirmation)
vault_export "myblog.com" "txt"

# Backup format (encrypted)
vault_export "all" "backup"
```

### 4. Password Rotation 🔄

```bash
# Rotate single domain
vault_rotate_passwords "myblog.com"
  - Generate new admin password
  - Generate new database password
  - Generate new FTP password
  - Update all services
  - Update vault

# Rotate all domains
vault_rotate_passwords "all"
  - Process each domain
  - Generate new passwords
  - Update services
  - Update vault
  - Generate report
```

### 5. Access Audit 📋

```bash
# View recent access
vault_view_log 10

# Search log
vault_search_log "export"

# Export log
vault_export_log "2025-10"
```

---

## 🔐 SECURITY MEASURES

### 1. Brute-Force Protection

```bash
# Max failed attempts: 5
MAX_ATTEMPTS=5

# Lockout duration: 15 minutes
LOCKOUT_DURATION=900

# After 5 failed attempts:
- Lock vault for 15 minutes
- Log security event
- Send alert (if configured)
```

### 2. Session Security

```bash
# Session timeout: 15 minutes
SESSION_TIMEOUT=900

# Auto-lock on:
- Timeout (15 min inactivity)
- User logout
- System reboot
- Process termination
```

### 3. Encryption Standards

```bash
# Algorithm: AES-256-CBC
# Key derivation: PBKDF2
# Iterations: 100,000
# Salt: Random 32 bytes
# IV: Random 16 bytes
```

### 4. Access Control

```bash
# Root only access
# File permissions: 600
# Directory permissions: 700
# No network access
# Local only
```

---

## 📈 PERFORMANCE

### Expected Performance

```bash
# Unlock vault: < 1 second
# View credentials: < 0.5 seconds
# Search: < 0.5 seconds
# Add credentials: < 0.5 seconds
# Update credentials: < 1 second
# Rotate passwords: < 5 seconds per domain
# Export: < 2 seconds
```

### Scalability

```bash
# Supports: 1,000+ domains
# Database size: ~1KB per domain
# Max database size: ~10MB (10,000 domains)
# Memory usage: < 10MB
# CPU usage: < 5%
```

---

## 🧪 TESTING SCENARIOS

### Test Cases

1. **Initial Setup**
   - [ ] Create master password
   - [ ] Initialize vault
   - [ ] Verify encryption

2. **Unlock/Lock**
   - [ ] Unlock with correct password
   - [ ] Fail with wrong password
   - [ ] Auto-lock after timeout
   - [ ] Manual lock

3. **CRUD Operations**
   - [ ] Add credentials
   - [ ] View credentials
   - [ ] Update credentials
   - [ ] Delete credentials

4. **Security**
   - [ ] Brute-force protection
   - [ ] Session timeout
   - [ ] Access logging
   - [ ] Encryption verification

5. **Integration**
   - [ ] Auto-save from WordPress
   - [ ] Auto-save from Laravel
   - [ ] Auto-save from all profiles
   - [ ] Search and retrieve

---

## 📅 IMPLEMENTATION PLAN

### Phase 1B.1: Core Vault (2 hours)
- Create vault.sh module
- Implement encryption/decryption
- Implement master password
- Create database structure

### Phase 1B.2: UI and Management (1.5 hours)
- Create vault menu
- Implement view functions
- Implement search
- Implement export

### Phase 1B.3: Integration (1 hour)
- Integrate with profiles
- Auto-save credentials
- Test all profiles
- Update documentation

### Phase 1B.4: Testing (0.5 hours)
- Test all functions
- Security testing
- Performance testing
- Bug fixes

**Total Estimated Time: 5 hours**

---

## 🎯 SUCCESS CRITERIA

- ✅ AES-256 encryption working
- ✅ Master password protection
- ✅ Auto-save from all profiles
- ✅ Search and filter working
- ✅ Export functionality
- ✅ Session management
- ✅ Access logging
- ✅ Performance < 1 second
- ✅ Security best practices
- ✅ Complete documentation

---

**Status:** Ready for Implementation  
**Next Step:** Create vault.sh module
