#!/bin/bash

################################################################################
# RocketVPS - Gitea Version Control Module
# Description: Git-based version control system for domain management
################################################################################

# Gitea configuration
GITEA_USER="git"
GITEA_HOME="/home/git"
GITEA_CUSTOM="${GITEA_HOME}/gitea/custom"
GITEA_WORK_DIR="${GITEA_HOME}/gitea"
GITEA_REPO_ROOT="${GITEA_HOME}/gitea-repositories"
GITEA_CONFIG="${GITEA_CUSTOM}/conf/app.ini"
GITEA_PORT="3000"
GITEA_DB_NAME="gitea"
GITEA_DB_USER="gitea"
GITEA_AUTO_COMMIT_CONFIG="${INSTALL_DIR}/config/gitea_auto_commit.conf"
GITEA_IGNORE_PATTERNS="${INSTALL_DIR}/config/gitea_ignore_patterns.conf"

# Menu
gitea_menu() {
    while true; do
        clear
        print_header "Gitea Version Control Management"
        
        echo -e "${CYAN}Current Status:${NC}"
        if systemctl is-active --quiet gitea 2>/dev/null; then
            echo -e "  Status: ${GREEN}● Running${NC}"
            echo -e "  URL: ${CYAN}http://$(hostname -I | awk '{print $1}'):${GITEA_PORT}${NC}"
        else
            echo -e "  Status: ${RED}○ Not Running${NC}"
        fi
        echo ""
        
        echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
        echo ""
        echo "  ${YELLOW}Installation & Configuration${NC}"
        echo "    1. Install Gitea"
        echo "    2. Configure Gitea"
        echo "    3. Start/Stop/Restart Gitea"
        echo ""
        echo "  ${YELLOW}Repository Management${NC}"
        echo "    4. Create Repository for Domain"
        echo "    5. Auto-Create Repositories for All Domains"
        echo "    6. List All Repositories"
        echo "    7. Delete Repository"
        echo ""
        echo "  ${YELLOW}Auto Commit Configuration${NC}"
        echo "    8. Setup Auto Commit for Domain"
        echo "    9. Configure File Patterns to Commit"
        echo "    10. Configure File Patterns to Ignore"
        echo "    11. List Auto Commit Status"
        echo "    12. Disable Auto Commit for Domain"
        echo ""
        echo "  ${YELLOW}Version & Restore${NC}"
        echo "    13. View Domain Commit History"
        echo "    14. Restore Domain to Specific Version"
        echo "    15. Compare Versions"
        echo "    16. Create Manual Backup Point"
        echo ""
        echo "  ${YELLOW}Advanced${NC}"
        echo "    17. Backup All Gitea Data"
        echo "    18. View Gitea Logs"
        echo "    19. Update Gitea"
        echo ""
        echo "  0. Back to Main Menu"
        echo ""
        echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
        echo ""
        
        read -p "Choose option [0-19]: " choice
        
        case $choice in
            1) install_gitea ;;
            2) configure_gitea ;;
            3) control_gitea_service ;;
            4) create_domain_repository ;;
            5) auto_create_all_domain_repos ;;
            6) list_gitea_repositories ;;
            7) delete_gitea_repository ;;
            8) setup_auto_commit_domain ;;
            9) configure_commit_patterns ;;
            10) configure_ignore_patterns ;;
            11) list_auto_commit_status ;;
            12) disable_auto_commit_domain ;;
            13) view_domain_commit_history ;;
            14) restore_domain_version ;;
            15) compare_domain_versions ;;
            16) create_manual_backup_point ;;
            17) backup_gitea_data ;;
            18) view_gitea_logs ;;
            19) update_gitea ;;
            0) break ;;
            *) print_error "Invalid option" ;;
        esac
        
        echo ""
        read -p "Press Enter to continue..."
    done
}

# Install Gitea
install_gitea() {
    clear
    print_header "Install Gitea"
    
    if command -v gitea &> /dev/null; then
        print_warning "Gitea is already installed"
        gitea --version
        return 0
    fi
    
    print_info "Installing Gitea..."
    
    # Detect latest version
    print_info "Detecting latest Gitea version..."
    GITEA_VERSION=$(curl -s https://api.github.com/repos/go-gitea/gitea/releases/latest | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/')
    
    if [ -z "$GITEA_VERSION" ]; then
        GITEA_VERSION="1.21.0"
        print_warning "Could not detect latest version, using v${GITEA_VERSION}"
    else
        print_success "Latest version: v${GITEA_VERSION}"
    fi
    
    # Create git user
    if ! id -u git >/dev/null 2>&1; then
        print_info "Creating git user..."
        useradd -m -d ${GITEA_HOME} -s /bin/bash ${GITEA_USER}
    fi
    
    # Download Gitea binary
    print_info "Downloading Gitea v${GITEA_VERSION}..."
    wget -O /tmp/gitea https://dl.gitea.io/gitea/${GITEA_VERSION}/gitea-${GITEA_VERSION}-linux-amd64
    
    if [ $? -ne 0 ]; then
        print_error "Failed to download Gitea"
        return 1
    fi
    
    # Install binary
    print_info "Installing Gitea binary..."
    chmod +x /tmp/gitea
    mv /tmp/gitea /usr/local/bin/gitea
    
    # Create directory structure
    print_info "Creating directory structure..."
    mkdir -p ${GITEA_WORK_DIR}
    mkdir -p ${GITEA_CUSTOM}/conf
    mkdir -p ${GITEA_REPO_ROOT}
    mkdir -p /var/log/gitea
    
    # Set permissions
    chown -R ${GITEA_USER}:${GITEA_USER} ${GITEA_HOME}
    chown -R ${GITEA_USER}:${GITEA_USER} /var/log/gitea
    
    # Install database
    if [[ "$OS" == "ubuntu" || "$OS" == "debian" ]]; then
        apt-get install -y sqlite3 git
    elif [[ "$OS" == "centos" || "$OS" == "rhel" ]]; then
        yum install -y sqlite git
    fi
    
    # Create systemd service
    print_info "Creating systemd service..."
    cat > /etc/systemd/system/gitea.service <<EOF
[Unit]
Description=Gitea (Git with a cup of tea)
After=syslog.target
After=network.target

[Service]
Type=simple
User=${GITEA_USER}
Group=${GITEA_USER}
WorkingDirectory=${GITEA_WORK_DIR}
ExecStart=/usr/local/bin/gitea web --config ${GITEA_CONFIG}
Restart=always
Environment=USER=${GITEA_USER} HOME=${GITEA_HOME} GITEA_WORK_DIR=${GITEA_WORK_DIR}

[Install]
WantedBy=multi-user.target
EOF
    
    # Create initial configuration
    configure_gitea_initial
    
    # Enable and start service
    systemctl daemon-reload
    systemctl enable gitea
    systemctl start gitea
    
    # Wait for service to start
    sleep 5
    
    if systemctl is-active --quiet gitea; then
        print_success "Gitea installed successfully!"
        echo ""
        print_info "Access Gitea at: http://$(hostname -I | awk '{print $1}'):${GITEA_PORT}"
        print_info "Complete setup through web interface"
        print_warning "Default admin will be created automatically"
    else
        print_error "Gitea service failed to start"
        print_info "Check logs: journalctl -u gitea -n 50"
        return 1
    fi
    
    log_action "Gitea v${GITEA_VERSION} installed"
}

# Configure Gitea Initial Settings
configure_gitea_initial() {
    print_info "Creating initial configuration..."
    
    # Generate random secret
    SECRET_KEY=$(openssl rand -base64 32)
    INTERNAL_TOKEN=$(openssl rand -base64 32)
    
    cat > ${GITEA_CONFIG} <<EOF
APP_NAME = RocketVPS Gitea
RUN_USER = ${GITEA_USER}
RUN_MODE = prod

[server]
PROTOCOL = http
DOMAIN = localhost
ROOT_URL = http://localhost:${GITEA_PORT}/
HTTP_ADDR = 0.0.0.0
HTTP_PORT = ${GITEA_PORT}
DISABLE_SSH = false
SSH_PORT = 22
LFS_START_SERVER = true
OFFLINE_MODE = false

[database]
DB_TYPE = sqlite3
PATH = ${GITEA_WORK_DIR}/data/gitea.db
LOG_SQL = false

[repository]
ROOT = ${GITEA_REPO_ROOT}
DEFAULT_BRANCH = main
ENABLE_PUSH_CREATE_USER = true
ENABLE_PUSH_CREATE_ORG = true

[security]
INSTALL_LOCK = true
SECRET_KEY = ${SECRET_KEY}
INTERNAL_TOKEN = ${INTERNAL_TOKEN}

[service]
DISABLE_REGISTRATION = false
REQUIRE_SIGNIN_VIEW = false
REGISTER_EMAIL_CONFIRM = false
ENABLE_NOTIFY_MAIL = false
DEFAULT_KEEP_EMAIL_PRIVATE = false
DEFAULT_ALLOW_CREATE_ORGANIZATION = true
NO_REPLY_ADDRESS = noreply.localhost

[mailer]
ENABLED = false

[log]
MODE = file
LEVEL = Info
ROOT_PATH = /var/log/gitea

[session]
PROVIDER = file

[picture]
DISABLE_GRAVATAR = true
ENABLE_FEDERATED_AVATAR = false

[openid]
ENABLE_OPENID_SIGNIN = false
ENABLE_OPENID_SIGNUP = false

[other]
SHOW_FOOTER_VERSION = true
EOF
    
    chown ${GITEA_USER}:${GITEA_USER} ${GITEA_CONFIG}
    print_success "Initial configuration created"
}

# Configure Gitea
configure_gitea() {
    clear
    print_header "Configure Gitea"
    
    echo "1. Change HTTP Port (current: ${GITEA_PORT})"
    echo "2. Configure Nginx Reverse Proxy"
    echo "3. Enable SSH Access"
    echo "4. Configure Email Notifications"
    echo "5. Edit Configuration File Manually"
    echo "0. Back"
    echo ""
    
    read -p "Choose option: " choice
    
    case $choice in
        1) configure_gitea_port ;;
        2) configure_gitea_nginx_proxy ;;
        3) configure_gitea_ssh ;;
        4) configure_gitea_email ;;
        5) nano ${GITEA_CONFIG} ;;
        0) return ;;
    esac
}

# Create Repository for Domain
create_domain_repository() {
    clear
    print_header "Create Repository for Domain"
    
    # Get domains
    if [ ! -f "${INSTALL_DIR}/config/domains.list" ]; then
        print_error "No domains found"
        return 1
    fi
    
    mapfile -t domains < "${INSTALL_DIR}/config/domains.list"
    
    if [ ${#domains[@]} -eq 0 ]; then
        print_error "No domains configured"
        return 1
    fi
    
    echo "Available domains:"
    for i in "${!domains[@]}"; do
        echo "  $((i+1)). ${domains[$i]}"
    done
    echo ""
    
    read -p "Select domain number: " domain_choice
    
    if [[ ! "$domain_choice" =~ ^[0-9]+$ ]] || [ "$domain_choice" -lt 1 ] || [ "$domain_choice" -gt ${#domains[@]} ]; then
        print_error "Invalid selection"
        return 1
    fi
    
    domain="${domains[$((domain_choice-1))]}"
    domain_clean=$(echo "$domain" | tr '.' '_')
    
    print_info "Creating repository for: ${domain}"
    
    # Get domain root directory
    if [ -d "/var/www/${domain}" ]; then
        domain_root="/var/www/${domain}"
    elif [ -d "/var/www/html/${domain}" ]; then
        domain_root="/var/www/html/${domain}"
    else
        read -p "Enter domain root directory: " domain_root
        if [ ! -d "$domain_root" ]; then
            print_error "Directory does not exist: $domain_root"
            return 1
        fi
    fi
    
    # Initialize git repository
    print_info "Initializing git repository..."
    cd "$domain_root"
    
    if [ -d ".git" ]; then
        print_warning "Git repository already exists"
    else
        sudo -u ${GITEA_USER} git init
        sudo -u ${GITEA_USER} git config user.name "RocketVPS"
        sudo -u ${GITEA_USER} git config user.email "rocketvps@${domain}"
        
        # Create .gitignore
        create_default_gitignore "$domain_root"
        
        # Initial commit
        sudo -u ${GITEA_USER} git add -A
        sudo -u ${GITEA_USER} git commit -m "🚀 Initial commit by RocketVPS - Domain setup"
    fi
    
    # Create bare repository in Gitea
    repo_path="${GITEA_REPO_ROOT}/${GITEA_USER}/${domain_clean}.git"
    
    if [ -d "$repo_path" ]; then
        print_warning "Gitea repository already exists"
    else
        print_info "Creating bare repository in Gitea..."
        sudo -u ${GITEA_USER} mkdir -p "$repo_path"
        cd "$repo_path"
        sudo -u ${GITEA_USER} git init --bare
        
        # Add remote and push
        cd "$domain_root"
        sudo -u ${GITEA_USER} git remote add origin "$repo_path" 2>/dev/null || true
        sudo -u ${GITEA_USER} git push -u origin main 2>/dev/null || sudo -u ${GITEA_USER} git push -u origin master
    fi
    
    # Save domain-repo mapping
    echo "${domain}|${domain_root}|${repo_path}" >> "${INSTALL_DIR}/config/gitea_repos.conf"
    
    print_success "Repository created for ${domain}"
    print_info "Local: ${domain_root}/.git"
    print_info "Gitea: ${repo_path}"
    
    log_action "Created Gitea repository for domain: ${domain}"
}

# Auto-create repositories for all domains
auto_create_all_domain_repos() {
    clear
    print_header "Auto-Create Repositories for All Domains"
    
    if [ ! -f "${INSTALL_DIR}/config/domains.list" ]; then
        print_error "No domains found"
        return 1
    fi
    
    mapfile -t domains < "${INSTALL_DIR}/config/domains.list"
    
    if [ ${#domains[@]} -eq 0 ]; then
        print_error "No domains configured"
        return 1
    fi
    
    print_info "Found ${#domains[@]} domain(s)"
    read -p "Create repositories for all domains? [y/N]: " confirm
    
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        print_warning "Cancelled"
        return 0
    fi
    
    created=0
    skipped=0
    
    for domain in "${domains[@]}"; do
        domain_clean=$(echo "$domain" | tr '.' '_')
        repo_path="${GITEA_REPO_ROOT}/${GITEA_USER}/${domain_clean}.git"
        
        if [ -d "$repo_path" ]; then
            print_warning "Skipped (exists): ${domain}"
            ((skipped++))
            continue
        fi
        
        # Find domain root
        if [ -d "/var/www/${domain}" ]; then
            domain_root="/var/www/${domain}"
        elif [ -d "/var/www/html/${domain}" ]; then
            domain_root="/var/www/html/${domain}"
        else
            print_warning "Skipped (no directory): ${domain}"
            ((skipped++))
            continue
        fi
        
        print_info "Creating repository for: ${domain}"
        
        # Initialize git
        cd "$domain_root"
        if [ ! -d ".git" ]; then
            sudo -u ${GITEA_USER} git init
            sudo -u ${GITEA_USER} git config user.name "RocketVPS"
            sudo -u ${GITEA_USER} git config user.email "rocketvps@${domain}"
            create_default_gitignore "$domain_root"
            sudo -u ${GITEA_USER} git add -A
            sudo -u ${GITEA_USER} git commit -m "🚀 Initial commit by RocketVPS - Domain setup"
        fi
        
        # Create bare repo
        sudo -u ${GITEA_USER} mkdir -p "$repo_path"
        cd "$repo_path"
        sudo -u ${GITEA_USER} git init --bare
        
        cd "$domain_root"
        sudo -u ${GITEA_USER} git remote add origin "$repo_path" 2>/dev/null || true
        sudo -u ${GITEA_USER} git push -u origin main 2>/dev/null || sudo -u ${GITEA_USER} git push -u origin master
        
        echo "${domain}|${domain_root}|${repo_path}" >> "${INSTALL_DIR}/config/gitea_repos.conf"
        
        print_success "Created: ${domain}"
        ((created++))
    done
    
    echo ""
    print_success "Created: ${created} repositories"
    print_info "Skipped: ${skipped} repositories"
    
    log_action "Auto-created ${created} Gitea repositories"
}

# Setup auto commit for domain
setup_auto_commit_domain() {
    clear
    print_header "Setup Auto Commit for Domain"
    
    # Get domains with repos
    if [ ! -f "${INSTALL_DIR}/config/gitea_repos.conf" ]; then
        print_error "No repositories found. Create repositories first."
        return 1
    fi
    
    mapfile -t repos < "${INSTALL_DIR}/config/gitea_repos.conf"
    
    echo "Repositories:"
    for i in "${!repos[@]}"; do
        domain=$(echo "${repos[$i]}" | cut -d'|' -f1)
        echo "  $((i+1)). ${domain}"
    done
    echo ""
    
    read -p "Select repository number: " repo_choice
    
    if [[ ! "$repo_choice" =~ ^[0-9]+$ ]] || [ "$repo_choice" -lt 1 ] || [ "$repo_choice" -gt ${#repos[@]} ]; then
        print_error "Invalid selection"
        return 1
    fi
    
    repo_info="${repos[$((repo_choice-1))]}"
    domain=$(echo "$repo_info" | cut -d'|' -f1)
    domain_root=$(echo "$repo_info" | cut -d'|' -f2)
    
    print_info "Setting up auto-commit for: ${domain}"
    
    # Get commit frequency
    echo ""
    echo "Select commit frequency:"
    echo "1. Every 24 hours (default)"
    echo "2. Every 12 hours"
    echo "3. Every 6 hours"
    echo "4. Custom (in hours)"
    read -p "Choose [1-4]: " freq_choice
    
    case $freq_choice in
        1) commit_hours=24 ;;
        2) commit_hours=12 ;;
        3) commit_hours=6 ;;
        4) 
            read -p "Enter hours between commits: " commit_hours
            if [[ ! "$commit_hours" =~ ^[0-9]+$ ]]; then
                print_error "Invalid hours"
                return 1
            fi
            ;;
        *) commit_hours=24 ;;
    esac
    
    # Get file patterns
    echo ""
    print_info "Configure file patterns to commit"
    read -p "Include all files? [Y/n]: " include_all
    
    if [[ "$include_all" =~ ^[Nn]$ ]]; then
        read -p "Enter file extensions to include (comma-separated, e.g., php,js,css,html): " extensions
        file_pattern="-name '*.${extensions//,/' -o -name '*.}'"
    else
        file_pattern="*"
    fi
    
    # Create auto-commit script
    script_path="${INSTALL_DIR}/scripts/auto_commit_${domain//\./_}.sh"
    mkdir -p "${INSTALL_DIR}/scripts"
    
    cat > "$script_path" <<'SCRIPT_EOF'
#!/bin/bash

DOMAIN="DOMAIN_PLACEHOLDER"
DOMAIN_ROOT="DOMAIN_ROOT_PLACEHOLDER"
GITEA_USER="git"

# Random commit messages
MESSAGES=(
    "📝 Auto-update: Content changes detected"
    "🔄 Automatic sync: Files updated"
    "✨ Auto-commit: New changes saved"
    "🚀 Scheduled update: Changes committed"
    "💾 Auto-backup: Latest changes saved"
    "📦 Automatic commit: Content updated"
    "🔧 Routine update: Files synchronized"
    "⚡ Quick sync: Changes committed"
    "🎯 Scheduled commit: Updates saved"
    "🌟 Auto-save: New content backed up"
)

# Get random message
RANDOM_MSG="${MESSAGES[$RANDOM % ${#MESSAGES[@]}]}"

cd "$DOMAIN_ROOT" || exit 1

# Check for changes
if ! sudo -u ${GITEA_USER} git diff-index --quiet HEAD --; then
    # Add changes
    sudo -u ${GITEA_USER} git add -A
    
    # Commit with random message
    sudo -u ${GITEA_USER} git commit -m "${RANDOM_MSG} - $(date +'%Y-%m-%d %H:%M:%S')"
    
    # Push to Gitea
    sudo -u ${GITEA_USER} git push origin main 2>/dev/null || sudo -u ${GITEA_USER} git push origin master 2>/dev/null
    
    echo "✓ Changes committed for ${DOMAIN}"
else
    echo "ℹ No changes detected for ${DOMAIN}"
fi
SCRIPT_EOF
    
    # Replace placeholders
    sed -i "s|DOMAIN_PLACEHOLDER|${domain}|g" "$script_path"
    sed -i "s|DOMAIN_ROOT_PLACEHOLDER|${domain_root}|g" "$script_path"
    
    chmod +x "$script_path"
    
    # Create cron job
    cron_time="0 */${commit_hours} * * *"
    
    (crontab -l 2>/dev/null | grep -v "auto_commit_${domain//\./_}.sh"; echo "${cron_time} ${script_path} >> ${INSTALL_DIR}/logs/gitea_auto_commit.log 2>&1") | crontab -
    
    # Save configuration
    echo "${domain}|${domain_root}|${commit_hours}|${file_pattern}|enabled" >> "${GITEA_AUTO_COMMIT_CONFIG}"
    
    print_success "Auto-commit configured for ${domain}"
    print_info "Frequency: Every ${commit_hours} hours"
    print_info "Script: ${script_path}"
    
    log_action "Setup auto-commit for domain: ${domain} (every ${commit_hours}h)"
}

# Configure file patterns to commit
configure_commit_patterns() {
    clear
    print_header "Configure File Patterns to Commit"
    
    print_info "Configure which file types to include in commits"
    echo ""
    echo "Common patterns:"
    echo "  Web: *.php *.html *.css *.js *.json"
    echo "  WordPress: *.php *.css *.js wp-content/themes/* wp-content/plugins/*"
    echo "  Laravel: *.php *.blade.php *.js *.css *.env.example"
    echo "  Images: *.jpg *.jpeg *.png *.gif *.svg *.webp"
    echo ""
    
    read -p "Enter file extensions to include (comma-separated): " extensions
    
    if [ -z "$extensions" ]; then
        print_error "No extensions specified"
        return 1
    fi
    
    # Save to config
    echo "INCLUDE_EXTENSIONS=${extensions}" > "${INSTALL_DIR}/config/gitea_commit_patterns.conf"
    
    print_success "File patterns configured"
    print_info "Extensions: ${extensions}"
}

# Configure ignore patterns
configure_ignore_patterns() {
    clear
    print_header "Configure File Patterns to Ignore"
    
    print_info "Files matching these patterns will NOT be committed"
    echo ""
    
    read -p "Use default ignore patterns? [Y/n]: " use_default
    
    if [[ ! "$use_default" =~ ^[Nn]$ ]]; then
        cat > "${GITEA_IGNORE_PATTERNS}" <<'EOF'
# Logs
*.log
logs/
*.log.*

# Cache
cache/
*.cache
tmp/
temp/

# System files
.DS_Store
Thumbs.db
desktop.ini

# Dependencies
node_modules/
vendor/
bower_components/

# Backups
*.bak
*.backup
*.old
*~

# Database
*.sql
*.sqlite
*.db

# Sensitive
.env
*.key
*.pem
*.crt
config/database.php
wp-config.php
EOF
        print_success "Default ignore patterns configured"
    else
        read -p "Enter patterns to ignore (one per line, empty line to finish): " 
        > "${GITEA_IGNORE_PATTERNS}"
        while true; do
            read -p "> " pattern
            if [ -z "$pattern" ]; then
                break
            fi
            echo "$pattern" >> "${GITEA_IGNORE_PATTERNS}"
        done
        print_success "Custom ignore patterns saved"
    fi
    
    print_info "Patterns saved to: ${GITEA_IGNORE_PATTERNS}"
}

# Create default .gitignore
create_default_gitignore() {
    local dir="$1"
    
    cat > "${dir}/.gitignore" <<'EOF'
# RocketVPS Auto-Generated .gitignore

# Logs
*.log
logs/
error_log
access_log

# Cache
cache/
*.cache
wp-content/cache/
tmp/

# Uploads (optional - comment out if you want to track uploads)
# uploads/
# wp-content/uploads/

# System
.DS_Store
Thumbs.db
desktop.ini

# Dependencies
node_modules/
vendor/

# Backups
*.bak
*.backup
*.sql
*.tar.gz
*.zip

# Sensitive
.env
*.key
*.pem
config/database.php

# IDE
.vscode/
.idea/
*.swp
*~
EOF
}

# View domain commit history
view_domain_commit_history() {
    clear
    print_header "View Domain Commit History"
    
    # Get domains with repos
    if [ ! -f "${INSTALL_DIR}/config/gitea_repos.conf" ]; then
        print_error "No repositories found"
        return 1
    fi
    
    mapfile -t repos < "${INSTALL_DIR}/config/gitea_repos.conf"
    
    echo "Repositories:"
    for i in "${!repos[@]}"; do
        domain=$(echo "${repos[$i]}" | cut -d'|' -f1)
        echo "  $((i+1)). ${domain}"
    done
    echo ""
    
    read -p "Select repository number: " repo_choice
    
    if [[ ! "$repo_choice" =~ ^[0-9]+$ ]] || [ "$repo_choice" -lt 1 ] || [ "$repo_choice" -gt ${#repos[@]} ]; then
        print_error "Invalid selection"
        return 1
    fi
    
    repo_info="${repos[$((repo_choice-1))]}"
    domain=$(echo "$repo_info" | cut -d'|' -f1)
    domain_root=$(echo "$repo_info" | cut -d'|' -f2)
    
    clear
    print_header "Commit History: ${domain}"
    
    cd "$domain_root"
    
    echo ""
    echo -e "${CYAN}Last 20 commits:${NC}"
    echo ""
    
    git log --oneline --decorate --graph -n 20 --pretty=format:"%C(yellow)%h%C(reset) - %C(cyan)%ad%C(reset) : %s %C(green)(%cr)%C(reset)" --date=format:'%Y-%m-%d %H:%M'
    
    echo ""
    echo ""
    print_info "Total commits: $(git rev-list --count HEAD)"
    
    echo ""
    read -p "View detailed commit? [commit hash or 'n']: " commit_hash
    
    if [[ "$commit_hash" != "n" && ! -z "$commit_hash" ]]; then
        clear
        git show "$commit_hash" --stat
    fi
}

# Restore domain to specific version
restore_domain_version() {
    clear
    print_header "Restore Domain to Specific Version"
    
    print_warning "⚠️  This will restore your domain files to a previous version!"
    print_warning "⚠️  Current files will be backed up first."
    echo ""
    
    # Get domains with repos
    if [ ! -f "${INSTALL_DIR}/config/gitea_repos.conf" ]; then
        print_error "No repositories found"
        return 1
    fi
    
    mapfile -t repos < "${INSTALL_DIR}/config/gitea_repos.conf"
    
    echo "Repositories:"
    for i in "${!repos[@]}"; do
        domain=$(echo "${repos[$i]}" | cut -d'|' -f1)
        echo "  $((i+1)). ${domain}"
    done
    echo ""
    
    read -p "Select repository number: " repo_choice
    
    if [[ ! "$repo_choice" =~ ^[0-9]+$ ]] || [ "$repo_choice" -lt 1 ] || [ "$repo_choice" -gt ${#repos[@]} ]; then
        print_error "Invalid selection"
        return 1
    fi
    
    repo_info="${repos[$((repo_choice-1))]}"
    domain=$(echo "$repo_info" | cut -d'|' -f1)
    domain_root=$(echo "$repo_info" | cut -d'|' -f2)
    
    cd "$domain_root"
    
    # Show recent commits
    echo ""
    echo -e "${CYAN}Recent versions:${NC}"
    echo ""
    git log --oneline --decorate -n 15 --pretty=format:"%C(yellow)%h%C(reset) - %C(cyan)%ad%C(reset) : %s" --date=format:'%Y-%m-%d %H:%M'
    
    echo ""
    echo ""
    read -p "Enter commit hash to restore (or 'HEAD~N' for N commits back): " version
    
    if [ -z "$version" ]; then
        print_error "No version specified"
        return 1
    fi
    
    # Verify commit exists
    if ! git rev-parse --verify "$version" &>/dev/null; then
        print_error "Invalid commit: $version"
        return 1
    fi
    
    # Show what will be restored
    echo ""
    print_info "Commit details:"
    git show "$version" --stat --pretty=format:"%C(yellow)Commit: %h%C(reset)%nDate: %ad%nMessage: %s%n"
    
    echo ""
    read -p "Restore to this version? [y/N]: " confirm
    
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        print_warning "Cancelled"
        return 0
    fi
    
    # Create backup of current state
    backup_dir="${INSTALL_DIR}/backups/gitea_restore_backup_$(date +%Y%m%d_%H%M%S)"
    print_info "Creating backup of current state..."
    mkdir -p "$backup_dir"
    tar -czf "${backup_dir}/${domain}_before_restore.tar.gz" -C "$(dirname $domain_root)" "$(basename $domain_root)" 2>/dev/null
    
    # Restore
    print_info "Restoring to version: $version"
    
    # Stop web server temporarily
    systemctl stop nginx
    
    # Checkout version
    git checkout "$version" -- .
    
    # Reset to commit if requested
    read -p "Reset branch to this commit (removes newer commits)? [y/N]: " reset_confirm
    if [[ "$reset_confirm" =~ ^[Yy]$ ]]; then
        git reset --hard "$version"
        print_warning "Branch reset to: $version"
    fi
    
    # Fix permissions
    chown -R www-data:www-data "$domain_root"
    find "$domain_root" -type d -exec chmod 755 {} \;
    find "$domain_root" -type f -exec chmod 644 {} \;
    
    # Start web server
    systemctl start nginx
    
    print_success "Domain restored to version: $version"
    print_info "Backup saved to: ${backup_dir}/${domain}_before_restore.tar.gz"
    
    log_action "Restored domain ${domain} to version: $version"
}

# Compare versions
compare_domain_versions() {
    clear
    print_header "Compare Domain Versions"
    
    # Get domains with repos
    if [ ! -f "${INSTALL_DIR}/config/gitea_repos.conf" ]; then
        print_error "No repositories found"
        return 1
    fi
    
    mapfile -t repos < "${INSTALL_DIR}/config/gitea_repos.conf"
    
    echo "Repositories:"
    for i in "${!repos[@]}"; do
        domain=$(echo "${repos[$i]}" | cut -d'|' -f1)
        echo "  $((i+1)). ${domain}"
    done
    echo ""
    
    read -p "Select repository number: " repo_choice
    
    if [[ ! "$repo_choice" =~ ^[0-9]+$ ]] || [ "$repo_choice" -lt 1 ] || [ "$repo_choice" -gt ${#repos[@]} ]; then
        print_error "Invalid selection"
        return 1
    fi
    
    repo_info="${repos[$((repo_choice-1))]}"
    domain=$(echo "$repo_info" | cut -d'|' -f1)
    domain_root=$(echo "$repo_info" | cut -d'|' -f2)
    
    cd "$domain_root"
    
    # Show commits
    echo ""
    echo -e "${CYAN}Recent versions:${NC}"
    echo ""
    git log --oneline -n 10
    
    echo ""
    read -p "Enter first version (commit hash): " version1
    read -p "Enter second version (commit hash): " version2
    
    if [ -z "$version1" ] || [ -z "$version2" ]; then
        print_error "Both versions required"
        return 1
    fi
    
    clear
    print_header "Comparing: ${version1} vs ${version2}"
    echo ""
    
    # Show diff
    git diff "$version1" "$version2" --stat
    
    echo ""
    read -p "Show detailed differences? [y/N]: " show_detail
    
    if [[ "$show_detail" =~ ^[Yy]$ ]]; then
        git diff "$version1" "$version2" | less
    fi
}

# List repositories
list_gitea_repositories() {
    clear
    print_header "Gitea Repositories"
    
    if [ ! -f "${INSTALL_DIR}/config/gitea_repos.conf" ]; then
        print_error "No repositories found"
        return 1
    fi
    
    echo -e "${CYAN}Configured Repositories:${NC}"
    echo ""
    
    count=0
    while IFS='|' read -r domain domain_root repo_path; do
        ((count++))
        echo -e "${GREEN}$count. ${domain}${NC}"
        echo "   Root: ${domain_root}"
        echo "   Repo: ${repo_path}"
        
        if [ -d "$domain_root/.git" ]; then
            cd "$domain_root"
            commits=$(git rev-list --count HEAD 2>/dev/null || echo "0")
            last_commit=$(git log -1 --format="%ar" 2>/dev/null || echo "Never")
            echo "   Commits: ${commits}"
            echo "   Last commit: ${last_commit}"
        fi
        echo ""
    done < "${INSTALL_DIR}/config/gitea_repos.conf"
    
    print_info "Total repositories: ${count}"
}

# List auto-commit status
list_auto_commit_status() {
    clear
    print_header "Auto-Commit Status"
    
    if [ ! -f "${GITEA_AUTO_COMMIT_CONFIG}" ]; then
        print_warning "No auto-commit configured"
        return 0
    fi
    
    echo -e "${CYAN}Auto-Commit Configuration:${NC}"
    echo ""
    
    count=0
    while IFS='|' read -r domain domain_root commit_hours file_pattern status; do
        ((count++))
        
        if [ "$status" == "enabled" ]; then
            status_icon="${GREEN}✓ Enabled${NC}"
        else
            status_icon="${RED}✗ Disabled${NC}"
        fi
        
        echo -e "${GREEN}$count. ${domain}${NC} - ${status_icon}"
        echo "   Frequency: Every ${commit_hours} hours"
        echo "   Pattern: ${file_pattern}"
        
        # Show next run time
        next_run=$(crontab -l 2>/dev/null | grep "auto_commit_${domain//\./_}.sh" | awk '{print $1, $2, $3, $4, $5}')
        if [ ! -z "$next_run" ]; then
            echo "   Schedule: ${next_run}"
        fi
        echo ""
    done < "${GITEA_AUTO_COMMIT_CONFIG}"
    
    print_info "Total configured: ${count}"
}

# Control Gitea service
control_gitea_service() {
    clear
    print_header "Gitea Service Control"
    
    echo "1. Start Gitea"
    echo "2. Stop Gitea"
    echo "3. Restart Gitea"
    echo "4. View Status"
    echo "0. Back"
    echo ""
    
    read -p "Choose option: " choice
    
    case $choice in
        1)
            systemctl start gitea
            print_success "Gitea started"
            ;;
        2)
            systemctl stop gitea
            print_success "Gitea stopped"
            ;;
        3)
            systemctl restart gitea
            print_success "Gitea restarted"
            ;;
        4)
            systemctl status gitea
            ;;
        0) return ;;
    esac
}

# Create manual backup point
create_manual_backup_point() {
    clear
    print_header "Create Manual Backup Point"
    
    # Get domains with repos
    if [ ! -f "${INSTALL_DIR}/config/gitea_repos.conf" ]; then
        print_error "No repositories found"
        return 1
    fi
    
    mapfile -t repos < "${INSTALL_DIR}/config/gitea_repos.conf"
    
    echo "Repositories:"
    for i in "${!repos[@]}"; do
        domain=$(echo "${repos[$i]}" | cut -d'|' -f1)
        echo "  $((i+1)). ${domain}"
    done
    echo "  0. All domains"
    echo ""
    
    read -p "Select option: " choice
    
    if [ "$choice" == "0" ]; then
        # Backup all
        read -p "Enter backup description: " description
        
        for repo in "${repos[@]}"; do
            domain=$(echo "$repo" | cut -d'|' -f1)
            domain_root=$(echo "$repo" | cut -d'|' -f2)
            
            cd "$domain_root"
            sudo -u ${GITEA_USER} git add -A
            sudo -u ${GITEA_USER} git commit -m "💾 Manual backup: ${description} - $(date +'%Y-%m-%d %H:%M:%S')" 2>/dev/null || true
            sudo -u ${GITEA_USER} git push origin main 2>/dev/null || sudo -u ${GITEA_USER} git push origin master 2>/dev/null
            
            print_success "Backed up: ${domain}"
        done
    else
        if [[ ! "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt ${#repos[@]} ]; then
            print_error "Invalid selection"
            return 1
        fi
        
        repo_info="${repos[$((choice-1))]}"
        domain=$(echo "$repo_info" | cut -d'|' -f1)
        domain_root=$(echo "$repo_info" | cut -d'|' -f2)
        
        read -p "Enter backup description: " description
        
        cd "$domain_root"
        sudo -u ${GITEA_USER} git add -A
        sudo -u ${GITEA_USER} git commit -m "💾 Manual backup: ${description} - $(date +'%Y-%m-%d %H:%M:%S')"
        sudo -u ${GITEA_USER} git push origin main 2>/dev/null || sudo -u ${GITEA_USER} git push origin master 2>/dev/null
        
        print_success "Manual backup created for: ${domain}"
    fi
    
    log_action "Created manual backup point"
}

# Disable auto-commit for domain
disable_auto_commit_domain() {
    clear
    print_header "Disable Auto-Commit"
    
    if [ ! -f "${GITEA_AUTO_COMMIT_CONFIG}" ]; then
        print_error "No auto-commit configured"
        return 1
    fi
    
    mapfile -t configs < "${GITEA_AUTO_COMMIT_CONFIG}"
    
    echo "Auto-commit enabled domains:"
    for i in "${!configs[@]}"; do
        domain=$(echo "${configs[$i]}" | cut -d'|' -f1)
        status=$(echo "${configs[$i]}" | cut -d'|' -f5)
        if [ "$status" == "enabled" ]; then
            echo "  $((i+1)). ${domain}"
        fi
    done
    echo ""
    
    read -p "Select domain number to disable: " choice
    
    if [[ ! "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt ${#configs[@]} ]; then
        print_error "Invalid selection"
        return 1
    fi
    
    config="${configs[$((choice-1))]}"
    domain=$(echo "$config" | cut -d'|' -f1)
    
    # Remove from crontab
    crontab -l 2>/dev/null | grep -v "auto_commit_${domain//\./_}.sh" | crontab -
    
    # Update config
    sed -i "/${domain}/s/enabled$/disabled/" "${GITEA_AUTO_COMMIT_CONFIG}"
    
    print_success "Auto-commit disabled for: ${domain}"
    log_action "Disabled auto-commit for domain: ${domain}"
}

# Backup Gitea data
backup_gitea_data() {
    clear
    print_header "Backup Gitea Data"
    
    backup_file="${INSTALL_DIR}/backups/gitea_backup_$(date +%Y%m%d_%H%M%S).tar.gz"
    
    print_info "Creating Gitea backup..."
    
    mkdir -p "${INSTALL_DIR}/backups"
    
    # Stop Gitea
    systemctl stop gitea
    
    # Backup
    tar -czf "$backup_file" \
        -C / \
        "${GITEA_HOME#/}" \
        "etc/systemd/system/gitea.service" \
        2>/dev/null
    
    # Start Gitea
    systemctl start gitea
    
    print_success "Backup created: $backup_file"
    print_info "Size: $(du -h $backup_file | awk '{print $1}')"
    
    log_action "Created Gitea backup"
}

# View Gitea logs
view_gitea_logs() {
    clear
    print_header "Gitea Logs"
    
    echo "1. Service logs (systemd)"
    echo "2. Gitea application logs"
    echo "3. Auto-commit logs"
    echo "0. Back"
    echo ""
    
    read -p "Choose option: " choice
    
    case $choice in
        1) journalctl -u gitea -n 100 -f ;;
        2) tail -f /var/log/gitea/gitea.log 2>/dev/null || print_error "Log file not found" ;;
        3) tail -f "${INSTALL_DIR}/logs/gitea_auto_commit.log" 2>/dev/null || print_error "Log file not found" ;;
        0) return ;;
    esac
}

# Update Gitea
update_gitea() {
    clear
    print_header "Update Gitea"
    
    print_warning "This will update Gitea to the latest version"
    
    current_version=$(gitea --version 2>/dev/null | awk '{print $3}')
    print_info "Current version: ${current_version}"
    
    # Get latest version
    latest_version=$(curl -s https://api.github.com/repos/go-gitea/gitea/releases/latest | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/')
    print_info "Latest version: ${latest_version}"
    
    if [ "$current_version" == "$latest_version" ]; then
        print_success "Already up to date"
        return 0
    fi
    
    read -p "Update to v${latest_version}? [y/N]: " confirm
    
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        return 0
    fi
    
    print_info "Downloading Gitea v${latest_version}..."
    wget -O /tmp/gitea https://dl.gitea.io/gitea/${latest_version}/gitea-${latest_version}-linux-amd64
    
    if [ $? -ne 0 ]; then
        print_error "Failed to download"
        return 1
    fi
    
    # Stop service
    systemctl stop gitea
    
    # Backup old binary
    cp /usr/local/bin/gitea /usr/local/bin/gitea.backup
    
    # Install new version
    chmod +x /tmp/gitea
    mv /tmp/gitea /usr/local/bin/gitea
    
    # Start service
    systemctl start gitea
    
    print_success "Gitea updated to v${latest_version}"
    log_action "Updated Gitea to v${latest_version}"
}

# Delete repository
delete_gitea_repository() {
    clear
    print_header "Delete Repository"
    
    print_warning "⚠️  This will delete the repository from Gitea"
    print_warning "⚠️  Local git history will be preserved"
    echo ""
    
    if [ ! -f "${INSTALL_DIR}/config/gitea_repos.conf" ]; then
        print_error "No repositories found"
        return 1
    fi
    
    mapfile -t repos < "${INSTALL_DIR}/config/gitea_repos.conf"
    
    echo "Repositories:"
    for i in "${!repos[@]}"; do
        domain=$(echo "${repos[$i]}" | cut -d'|' -f1)
        echo "  $((i+1)). ${domain}"
    done
    echo ""
    
    read -p "Select repository to delete: " choice
    
    if [[ ! "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt ${#repos[@]} ]; then
        print_error "Invalid selection"
        return 1
    fi
    
    repo_info="${repos[$((choice-1))]}"
    domain=$(echo "$repo_info" | cut -d'|' -f1)
    repo_path=$(echo "$repo_info" | cut -d'|' -f3)
    
    read -p "Delete repository for ${domain}? [y/N]: " confirm
    
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        return 0
    fi
    
    # Remove bare repository
    rm -rf "$repo_path"
    
    # Remove from config
    sed -i "/^${domain}|/d" "${INSTALL_DIR}/config/gitea_repos.conf"
    
    # Remove auto-commit
    crontab -l 2>/dev/null | grep -v "auto_commit_${domain//\./_}.sh" | crontab -
    sed -i "/^${domain}|/d" "${GITEA_AUTO_COMMIT_CONFIG}" 2>/dev/null || true
    
    print_success "Repository deleted: ${domain}"
    log_action "Deleted Gitea repository: ${domain}"
}
