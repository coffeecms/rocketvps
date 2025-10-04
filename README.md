# 🚀 RocketVPS

**Professional VPS Management System for Linux**

RocketVPS is a comprehensive, user-friendly command-line tool designed to simplify and streamline VPS server management. Whether you're managing a single website or multiple domains, RocketVPS provides all the essential tools you need in one place.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-2.1.0-green.svg)](https://github.com/yourusername/rocketvps)
[![Bash](https://img.shields.io/badge/bash-4.0%2B-blue.svg)](https://www.gnu.org/software/bash/)

## 🎉 What's New in v2.1.0

**Auto Database Setup Features:**

- 🔄 **Auto-Install Databases** - Automatic MySQL, PostgreSQL, and ProxySQL installation on first run
- 🎲 **Auto-Create Database Accounts** - Automatic database creation for every new domain
- 🔐 **Secure by Default** - Random passwords, proper permissions, credential storage
- 📊 **Full Integration** - Seamless integration with MySQL, PostgreSQL, and ProxySQL
- 📝 **Complete Information Display** - All credentials shown on screen and saved securely

## 🎉 What's New in v2.0.0

**Major Enterprise Features Added:**

- 🐳 **Docker Management** - Full container orchestration
- 📧 **Mail Server (Mailu)** - Complete email solution
- 🤖 **n8n Automation** - Workflow automation platform
- 📊 **Redash BI** - Business intelligence & data visualization
- 🗃️ **SQL Version Control** - Database schema tracking & migrations
- 🐍 **Python Multi-Version** - pyenv-based Python management
- 🔍 **Milvus Vector Database** - AI/ML vector search engine
- 🔀 **ProxySQL** - High-performance MySQL proxy with load balancing & query caching

## ✨ Features

### 🐳 Docker Management (NEW in v2.0!)
- **Installation & Setup**
  - Docker CE installation (Ubuntu/Debian/CentOS/RHEL)
  - Docker Compose standalone installation
  - User permission management
  - Hello-world verification

- **Container Operations**
  - List all containers (running/stopped)
  - Start, stop, restart, remove containers
  - View container logs (real-time)
  - Execute commands in containers
  - Container resource usage monitoring

- **Image Management**
  - List, pull, remove images
  - Image pruning (cleanup unused)
  - Multi-registry support

- **Volume & Network**
  - Volume management (list, remove)
  - Network management (list, create)
  - Docker system pruning
  - Resource statistics

### 📧 Mail Server Management (NEW in v2.0!)
- **Mailu Mail Server** (Recommended)
  - Docker-based deployment
  - Complete mail stack (SMTP, IMAP, Webmail)
  - Anti-spam (Rspamd)
  - Webmail (Roundcube)
  - Admin panel
  
- **BillionMail Support**
  - Alternative mail server option
  - Easy installation via GitHub repo

- **Features**
  - Domain configuration
  - User management (add, delete, list)
  - Mail aliases
  - SSL certificate setup
  - Backup/restore mail data
  - Log viewing
  - Webmail access

### 🤖 n8n Automation Platform (NEW in v2.0!)
- **Installation & Deployment**
  - Docker-based n8n deployment
  - SSL/HTTPS configuration
  - Nginx reverse proxy
  - Automatic domain setup

- **Configuration**
  - Domain & SSL management
  - Webhook configuration
  - Timezone settings
  - Execution timeout customization
  - Basic authentication

- **Management**
  - Start, stop, restart services
  - View logs and status
  - Backup/restore workflows
  - Export/import workflows
  - Password management

### 📊 Redash BI Platform (NEW in v2.0!)
- **Setup**
  - Docker Compose deployment
  - PostgreSQL + Redis stack
  - Admin user creation
  - SSL certificate integration

- **Data Sources**
  - MySQL, PostgreSQL support
  - MongoDB, Redis connectors
  - Custom data source setup
  - Connection testing

- **User Management**
  - Create users (admin/regular)
  - Reset passwords
  - User listing
  - Role management

- **Features**
  - SMTP configuration (email alerts)
  - OAuth/SAML authentication
  - Database backup/restore
  - Query logging
  - Dashboard management

### 🗃️ SQL Version Control (NEW in v2.0!)
- **Based on infostreams/db**
  - Git-based schema tracking
  - MySQL/PostgreSQL support
  - Schema capture & history

- **Features**
  - Initialize database tracking
  - Capture schema snapshots
  - View schema history (git log)
  - Compare schemas (diff)
  - Generate migration scripts

- **Migration Management**
  - Create migrations
  - Apply/rollback migrations
  - Migration status tracking
  - Migration log

- **Database Operations**
  - Add/remove database connections
  - Sync databases
  - Export/import schemas
  - Backup all schemas

### 🐍 Python Multi-Version Management (NEW in v2.0!)
- **pyenv Integration**
  - Install/uninstall pyenv
  - Python 2.7 - 3.12 support
  - System-wide or local versions
  - Per-domain Python versions

- **Version Management**
  - Install multiple Python versions
  - Switch global Python version
  - Set local version per directory
  - List installed versions

- **Virtual Environments**
  - Create virtualenvs
  - Activate/deactivate environments
  - List all virtualenvs
  - Remove environments

- **Package Management**
  - Install packages via pip
  - List installed packages
  - Update pip
  - Create requirements.txt
  - Freeze dependencies

### 🔍 Milvus Vector Database (NEW in v2.0!)
- **Deployment Options**
  - Standalone mode (Docker)
  - Cluster mode (production)
  - Attu web UI included
  - MinIO object storage

- **Collection Management**
  - Create/drop collections
  - List collections
  - Collection info & stats
  - Load/release to memory

- **Index & Search**
  - Vector index creation
  - Similarity search (L2, IP, COSINE)
  - Query operations
  - Insert/delete data

- **Administration**
  - System metrics
  - Connection testing
  - Backup/restore data
  - Log viewing
  - Python SDK (pymilvus) integration

### 🔀 ProxySQL - MySQL Proxy (NEW in v2.0!)
- **Installation & Setup**
  - Official repository installation (Ubuntu/Debian/CentOS/RHEL)
  - Automatic configuration
  - Secure admin credentials (random password)
  - MySQL client compatibility

- **Backend Server Management**
  - Add MySQL servers (master/slave)
  - Configure server groups
  - Server health monitoring
  - Load balancing weights
  - Connection pool management

- **User & Authentication**
  - Add MySQL users to proxy
  - User privilege configuration
  - Connection limits per user
  - Default hostgroup assignment

- **Query Rules & Routing**
  - Read/Write split configuration
  - Query routing rules
  - Query rewriting
  - Query caching (TTL-based)
  - Query blocking/filtering

- **Monitoring & Statistics**
  - Real-time connection stats
  - Query performance metrics
  - Slow query analysis
  - Backend server status
  - Error logging

- **Advanced Features**
  - Query cache configuration
  - Connection pool tuning
  - Load balancing algorithms
  - Admin interface management
  - Configuration backup/restore
  - Hot reload without downtime

### 🌐 Nginx Management
- **Auto-install** latest Nginx version
- **Seamless upgrades** without data loss
- **Optimized configuration** for performance
- **Easy restart/reload** operations

### 🌍 Domain Management
- Add, edit, and delete domains
- Multiple site types support:
  - Static HTML
  - PHP applications
  - WordPress (optimized)
  - Laravel (optimized)
  - Node.js reverse proxy
- Automatic virtual host configuration
- **🆕 Auto phpMyAdmin Setup** - Tự động cài đặt phpMyAdmin với credentials ngẫu nhiên
- **🆕 Complete Info Display** - Hiển thị đầy đủ thông tin domain, directory, phpMyAdmin sau khi setup
- **🆕 Auto Database Creation** - Tự động tạo MySQL, PostgreSQL, ProxySQL database cho mỗi domain
- **🆕 Credential Management** - Hiển thị và lưu trữ tất cả thông tin database credentials
- **🆕 Security by Default** - HTTP Auth, random URL, secure credentials storage

### 🔒 SSL Management (Let's Encrypt)
- Easy SSL certificate installation
- **Automatic renewal** every 7 days
- Multiple domain support
- Force HTTPS redirect

### ⚡ Cache Management (Redis)
- Install/upgrade Redis server
- Optimized configuration templates
- Connection management
- Cache flushing tools

### 🐘 PHP Management
- **Multi-version PHP** support (7.4, 8.0, 8.1, 8.2, 8.3)
- Switch PHP versions per domain
- Install PHP extensions
- Optimize PHP-FPM configuration
- OPcache configuration

### 💾 Database Management
- Support for MariaDB, MySQL, and PostgreSQL
- Create/delete databases and users
- **Automated backups** (local, Google Drive, S3)
- Database optimization tools
- Secure installation
- **🆕 Auto-Install Databases** - Automatic MySQL, PostgreSQL, ProxySQL installation on first run
- **🆕 Auto-Create for Domains** - Automatic database/user creation for every new domain
- **🆕 Domain Database Management** - List, view, delete domain databases
- **🆕 Credential Storage** - Secure storage of all database credentials
- **🆕 ProxySQL Integration** - Automatic user setup in ProxySQL for load balancing

### 📁 FTP Management
- Add/edit/delete FTP users per domain
- Secure vsftpd configuration
- User permission management
- SSL/TLS support

### 🛡️ CSF Firewall Management
- Easy CSF installation
- Block/unblock IP addresses
- Bulk IP management
- Port management
- Security rules configuration

### 🔐 Permission Management
- Automatic permission detection
- WordPress-specific permissions
- Laravel-specific permissions
- Custom CHMOD support
- Recursive operations

### 💾 Backup & Restore
- **Local backups**
- **Google Drive integration**
- **Amazon S3 integration**
- Domain-specific or full backups
- Scheduled automatic backups
- Easy restoration

### ⏰ Cronjob Management
- Add/edit/delete cronjobs
- Predefined templates:
  - Cache clearing
  - SSL renewal
  - Database optimization
  - Log cleanup
  - System updates

### 🔒 Security Enhancement

#### Three-Tier Security System

**1. Basic Security**
- SSH key authentication
- Firewall enabled
- Automatic security updates

**2. Medium Security** (Recommended)
- All Basic features
- Fail2Ban protection
- Root login disabled
- Enhanced SSH security
- Database hardening

**3. Advanced Security**
- All Medium features
- ModSecurity WAF
- Intrusion detection
- Advanced firewall rules
- Regular security audits

Additional Security Features:
- SSH hardening
- Fail2Ban setup
- Malware scanning (ClamAV)
- Security audit tools
- Auto-update configuration

### 🔄 Gitea Version Control (NEW!)

**Professional Git-based version control for your domains:**

- **Automatic Repository Creation**
  - Create Git repositories for all managed domains
  - Initialize with proper .gitignore templates
  - Automatic initial commit

- **Smart Auto-Commit System**
  - Schedule automatic commits every 24 hours (configurable: 6h, 12h, 24h, custom)
  - Random commit messages for natural versioning
  - Configurable file patterns to include/exclude
  - Filter by file extensions (php, js, css, html, etc.)

- **Version Management**
  - View complete commit history
  - Compare any two versions
  - Restore to any previous version
  - Create manual backup points

- **Advanced Features**
  - Browse versions through Gitea web interface
  - Git-based backup system
  - Automated daily snapshots
  - Zero-downtime restores
  - Selective file restoration

- **File Pattern Control**
  - Include specific file types
  - Exclude temporary files, logs, cache
  - WordPress/Laravel-specific templates
  - Custom .gitignore patterns

### ⚙️ VPS Optimization (NEW!)

**Automatic VPS resource optimization based on your server specifications:**

- **Smart SWAP Configuration**
  - Auto-detect optimal SWAP size based on RAM
  - RAM ≤ 2GB: SWAP = RAM × 2
  - 2GB < RAM ≤ 8GB: SWAP = RAM
  - 8GB < RAM ≤ 16GB: SWAP = RAM / 2
  - RAM > 16GB: SWAP = 8GB
  - Optimized swappiness and cache pressure settings

- **MySQL/MariaDB Optimization**
  - Auto-configure InnoDB buffer pool (70% of RAM)
  - Optimize connection pool based on RAM
  - Query cache configuration
  - Thread cache optimization
  - Performance schema enabled

- **Nginx Optimization**
  - Worker processes = CPU cores
  - Worker connections based on RAM
  - FastCGI cache configuration
  - Gzip compression optimization
  - Buffer and timeout tuning

- **PostgreSQL Optimization**
  - Shared buffers = 25% of RAM
  - Effective cache size = 75% of RAM
  - Connection pool optimization
  - WAL configuration
  - Parallel workers based on CPU cores

- **One-Click Full Optimization**
  - Optimize all services at once
  - Automatic backup before changes
  - Configuration restore capability
  - Real-time optimization status

### 🗄️ phpMyAdmin Management (NEW!)

**Easy web-based database management for all your domains:**

- **Simple Installation**
  - Auto-download latest stable version
  - Automatic dependency installation
  - Secure default configuration
  - One-click setup

- **Per-Domain Setup**
  - Add phpMyAdmin to any domain
  - Custom access paths (/phpmyadmin, /pma, /database, or custom)
  - Multiple domains support
  - Independent configurations

- **Security Features**
  - IP whitelist support
  - HTTP Basic Authentication
  - Session timeout configuration
  - Blowfish secret encryption
  - Disable root login option
  - Two-factor authentication support

- **Management Tools**
  - Easy update to latest version
  - Remove from specific domains
  - List all configured domains
  - Security hardening wizard
  - Complete uninstallation

- **Advanced Configuration**
  - Custom authentication per domain
  - Multiple security layers
  - Session management
  - Access control lists
  - Automatic security updates

### 📝 WordPress Management (NEW!)

**One-click WordPress installation with optimized Nginx configuration:**

- **Auto WordPress Installation**
  - Install WP-CLI automatically
  - Download latest WordPress version
  - Auto-create database and user
  - Configure wp-config.php with security keys
  - Set correct file permissions
  - Save credentials securely

- **Two Security Modes**
  - **Advanced Security Mode** (Recommended)
    - Block xmlrpc.php attacks
    - Protect wp-config.php
    - Disable file editing via dashboard
    - Restrict wp-admin access (IP whitelist ready)
    - Rate limiting enabled
    - Security headers (X-Frame-Options, CSP, etc.)
    - Block sensitive file access
    - PHP open_basedir restriction
  
  - **Basic Mode**
    - Standard WordPress configuration
    - Performance optimization only
    - Basic file protection
    - No additional restrictions

- **WordPress Management**
  - List all WordPress installations
  - Update core, plugins, themes
  - Security hardening wizard
  - Remove WordPress completely
  - Automatic backups before changes
  - Credentials management

- **Nginx Optimization**
  - WordPress-specific permalinks
  - FastCGI cache ready
  - Static file caching (365 days)
  - Gzip compression
  - PHP-FPM optimization
  - Custom upload limits (256MB)

## 📋 Requirements

### Operating System
- Ubuntu 18.04+ / 20.04+ / 22.04+
- Debian 9+ / 10+ / 11+
- CentOS 7+ / 8+
- RHEL 7+ / 8+

### System Requirements
- Root or sudo access
- Minimum 1GB RAM
- Minimum 10GB disk space
- Internet connection

### Pre-installed Software
- Bash 4.0+
- curl or wget
- tar and gzip

## 🚀 Quick Installation

### One-Line Installation

```bash
curl -sSL https://raw.githubusercontent.com/yourusername/rocketvps/main/install.sh | sudo bash
```

Or with wget:

```bash
wget -qO- https://raw.githubusercontent.com/yourusername/rocketvps/main/install.sh | sudo bash
```

### Manual Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/rocketvps.git
cd rocketvps

# Make install script executable
chmod +x install.sh

# Run installer
sudo ./install.sh
```

## 📖 Usage

**🆕 Global Command Available!** After installation, you can run `rocketvps` from anywhere:

```bash
# Run from any directory - no need to cd to /opt/rocketvps
rocketvps
```

Or with sudo (required for most operations):

```bash
sudo rocketvps
```

The installer automatically creates a symlink: `/usr/local/bin/rocketvps` → `/opt/rocketvps/rocketvps.sh`

### Quick Start Guide

1. **Install Nginx**
   - Choose option `1` → `1`

2. **Add Your First Domain** 🆕 **with Auto phpMyAdmin**
   - Choose option `2` → `1`
   - Enter domain name (e.g., `example.com`)
   - Select site type (PHP/WordPress/Laravel)
   - ✨ **phpMyAdmin auto-setup** for PHP-based sites
   - 📋 **Complete info displayed** including credentials, directories, DNS config

3. **Install SSL Certificate**
   - Choose option `3` → `2`
   - Select domain
   - Enter email address

4. **Setup Auto-Renewal**
   - Choose option `3` → `5`

5. **Apply Security Settings**
   - Choose option `12` → `1`
   - Select security level

## 📁 Directory Structure

```
/opt/rocketvps/
├── rocketvps.sh          # Main script
├── modules/              # Feature modules
│   ├── nginx.sh
│   ├── domain.sh
│   ├── ssl.sh
│   ├── cache.sh
│   ├── php.sh
│   ├── database.sh
│   ├── ftp.sh
│   ├── csf.sh
│   ├── permission.sh
│   ├── backup.sh
│   ├── cronjob.sh
│   ├── security.sh
│   ├── gitea.sh          # NEW: Gitea version control
│   ├── optimize.sh       # NEW: VPS optimization
│   ├── phpmyadmin.sh     # NEW: phpMyAdmin management
│   ├── wordpress.sh      # NEW: WordPress management
│   └── utils.sh
├── config/               # Configuration files
│   ├── domains.list
│   ├── php_versions.conf
│   ├── database.conf
│   ├── cloud_backup.conf
│   ├── gitea_repos.conf              # NEW: Gitea repositories
│   ├── gitea_auto_commit.conf        # NEW: Auto-commit settings
│   ├── gitea_ignore_patterns.conf    # NEW: Ignore patterns
│   └── phpmyadmin_domains.list       # NEW: phpMyAdmin domains
├── backups/              # Local backups
├── scripts/              # Auto-generated scripts
│   └── auto_commit_*.sh  # NEW: Auto-commit scripts
└── logs/                 # Log files
    ├── rocketvps.log
    ├── ssl_renewal.log
    ├── auto_backup.log
    └── gitea_auto_commit.log  # NEW: Gitea commit log
```

## 🔧 Configuration

### Cloud Backup Setup

#### Google Drive (via rclone)

1. Navigate to: Menu → Database Management → Configure Cloud Backup
2. Select Google Drive
3. Configure rclone:
   ```bash
   rclone config
   ```
4. Follow prompts to authorize Google Drive
5. Return to RocketVPS and enter remote name

#### Amazon S3

1. Navigate to: Menu → Database Management → Configure Cloud Backup
2. Select Amazon S3
3. Enter:
   - S3 bucket name
   - AWS Access Key ID
   - AWS Secret Access Key
   - AWS Region

### PHP Multi-Version

Example workflow:

```bash
# Install PHP 8.2
7. **Setup Firewall**
   ```
   rocketvps → 8 → 1
   ```

8. **Setup Gitea Version Control (NEW!)**
   ```
   rocketvps → 13 → 1 (Install Gitea)
   rocketvps → 13 → 5 (Auto-create repos for all domains)
   rocketvps → 13 → 8 (Setup auto-commit)
   ```

## 📁 Directory Structure

# Install PHP 7.4
rocketvps → 5 → 1 → 1

# Set PHP 8.2 for specific domain
rocketvps → 5 → 4 → domain.com → 8.2

# Set PHP 7.4 as default
rocketvps → 5 → 3 → 7.4
```

## 📊 Features Comparison

| Feature | RocketVPS | cPanel | Plesk | Manual |
|---------|-----------|--------|-------|--------|
| Free | ✅ | ❌ | ❌ | ✅ |
| Multi-PHP | ✅ | ✅ | ✅ | ⚠️ |
| Auto SSL Renewal | ✅ | ✅ | ✅ | ⚠️ |
| Cloud Backup | ✅ | ✅ | ✅ | ❌ |
| Security Tiers | ✅ | ⚠️ | ⚠️ | ❌ |
| Easy to Use | ✅ | ✅ | ✅ | ❌ |
| Lightweight | ✅ | ❌ | ❌ | ✅ |
| Open Source | ✅ | ❌ | ❌ | ✅ |

## 📚 Documentation

Comprehensive guides available for all features:

### Core Guides
- **[DOMAIN_AUTO_SETUP_GUIDE.md](DOMAIN_AUTO_SETUP_GUIDE.md)** 🆕 - Auto domain setup với phpMyAdmin tự động
- **[PHPMYADMIN_GUIDE.md](PHPMYADMIN_GUIDE.md)** - phpMyAdmin management chi tiết
- **[WORDPRESS_GUIDE.md](WORDPRESS_GUIDE.md)** - WordPress management với 2 security modes
- **[VPS_OPTIMIZATION_GUIDE.md](VPS_OPTIMIZATION_GUIDE.md)** - VPS optimization (SWAP, MySQL, Nginx, PostgreSQL)
- **[GITEA_GUIDE.md](GITEA_GUIDE.md)** - Version control với Gitea + auto-commit

### Quick Links
- **Global Command**: Just type `rocketvps` from anywhere
- **Auto phpMyAdmin**: Automatic setup when adding PHP domains
- **Complete Info Display**: All domain info shown after setup (URLs, credentials, DNS config)

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

### Development Setup

```bash
git clone https://github.com/yourusername/rocketvps.git
cd rocketvps

# Make changes
# Test your changes

# Commit and push
git add .
git commit -m "Description of changes"
git push origin main
```

## 🐛 Bug Reports

If you discover any bugs, please create an issue on GitHub with:
- OS version
- RocketVPS version
- Steps to reproduce
- Expected vs actual behavior

## 📝 Changelog

### Version 1.4.0 (2025-10-04) 🆕 NEW!
- **Global Command**: Type `rocketvps` from any directory
- **Auto phpMyAdmin Setup**: Automatic phpMyAdmin configuration when adding PHP domains
  - Random secure URL path (e.g., `/phpmyadmin_a3f2e1`)
  - Random username and password generation
  - HTTP Basic Authentication
  - Secure credentials storage
- **Complete Domain Info Display**: Show all info after domain setup
  - Domain name and alternatives
  - Directory structure
  - phpMyAdmin access (URL, username, password)
  - Server IP and ports
  - DNS configuration guide
  - Quick commands reference
- **Credentials Management**: Auto-save credentials to secure files
- **Domain Info Files**: Complete domain information saved for future reference

### Version 1.3.0 (2025-10-04)
- WordPress Management module with WP-CLI
- Two WordPress security modes (Advanced/Basic)
- Auto WordPress installation
- WordPress update management
- Security hardening wizard

### Version 1.2.0 (2025-10-03)
- VPS Optimization module (SWAP, MySQL, Nginx, PostgreSQL)
- phpMyAdmin Management module
- Auto-optimization based on VPS specs

### Version 1.1.0 (2025-10-03)
- Gitea Version Control integration
- Auto-commit functionality
- Repository management

### Version 1.0.0 (2025-10-03)
- Initial release
- Nginx management
- Domain management with multiple site types
- SSL management with auto-renewal
- Redis cache management
- Multi-version PHP support
- Database management (MariaDB/MySQL/PostgreSQL)
- FTP management
- CSF Firewall management
- Permission management
- Backup & Restore (Local/Google Drive/S3)
- Cronjob management
- Three-tier security system
- Malware scanning
- Security auditing

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Nginx team for the excellent web server
- Let's Encrypt for free SSL certificates
- ConfigServer for CSF Firewall
- The open-source community

## 📧 Contact

- **GitHub**: [@yourusername](https://github.com/yourusername)
- **Issues**: [GitHub Issues](https://github.com/yourusername/rocketvps/issues)
- **Email**: your.email@example.com

## ⭐ Support

If you find RocketVPS helpful, please give it a star on GitHub!

---

**Made with ❤️ for the DevOps community**

🚀 **RocketVPS** - Professional VPS Management Made Simple
