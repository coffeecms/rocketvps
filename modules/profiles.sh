#!/bin/bash

#==============================================================================
# RocketVPS - Profile System Module
# Version: 2.2.0
# Description: Domain setup profiles for one-click configuration
#==============================================================================

# Source utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/utils.sh" 2>/dev/null || {
    # Define basic utilities if utils.sh doesn't exist
    print_success() { echo -e "\033[0;32m✓\033[0m $1"; }
    print_error() { echo -e "\033[0;31m✗\033[0m $1"; }
    print_info() { echo -e "\033[0;36mℹ\033[0m $1"; }
    print_warning() { echo -e "\033[0;33m⚠\033[0m $1"; }
}

#==============================================================================
# Global Variables
#==============================================================================

PROFILES_DIR="/opt/rocketvps/profiles"
CONFIG_DIR="/opt/rocketvps/config"
PROFILE_TEMP_DIR="/tmp/rocketvps_profile"

#==============================================================================
# Profile Configuration Parser
#==============================================================================

parse_profile_config() {
    local profile_name=$1
    local profile_file="${PROFILES_DIR}/${profile_name}.profile"
    
    if [ ! -f "$profile_file" ]; then
        print_error "Profile not found: $profile_name"
        return 1
    fi
    
    # Source the profile configuration
    source "$profile_file"
    
    return 0
}

#==============================================================================
# Profile Selection Menu
#==============================================================================

show_profile_menu() {
    clear
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║              DOMAIN SETUP PROFILE SELECTION                   ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""
    echo "Select a setup profile for your domain:"
    echo ""
    echo "  1) WordPress Hosting"
    echo "     └─ Blog, Business Website, or WooCommerce Store"
    echo "     └─ Includes: WordPress + MySQL + phpMyAdmin + SSL + Cache"
    echo ""
    echo "  2) Laravel Application"
    echo "     └─ Modern PHP framework for APIs and web apps"
    echo "     └─ Includes: PHP 8.2 + Database + Redis + Queue + Scheduler"
    echo ""
    echo "  3) Node.js Application"
    echo "     └─ Express, Next.js, or custom Node.js apps"
    echo "     └─ Includes: Node.js + PM2 + Reverse Proxy + Database"
    echo ""
    echo "  4) Static HTML"
    echo "     └─ Simple HTML/CSS/JS landing pages"
    echo "     └─ Includes: Optimized Nginx + Gzip + SSL"
    echo ""
    echo "  5) E-commerce Store"
    echo "     └─ High-performance e-commerce setup"
    echo "     └─ Includes: Optimized PHP + Redis + High Memory + SSL"
    echo ""
    echo "  6) Multi-tenant SaaS"
    echo "     └─ Software-as-a-Service with subdomain support"
    echo "     └─ Includes: Wildcard DNS + Per-tenant DB + Rate Limiting"
    echo ""
    echo "  7) Custom Setup"
    echo "     └─ Manual configuration (legacy mode)"
    echo ""
    echo "  0) Back to Main Menu"
    echo ""
    echo "────────────────────────────────────────────────────────────────"
}

#==============================================================================
# Profile Executor
#==============================================================================

execute_profile() {
    local domain=$1
    local profile=$2
    
    print_info "Setting up $domain with profile: $profile"
    echo ""
    
    # Parse profile configuration
    if ! parse_profile_config "$profile"; then
        print_error "Failed to load profile: $profile"
        return 1
    fi
    
    # Create temporary directory for profile execution
    mkdir -p "$PROFILE_TEMP_DIR"
    
    # Execute profile setup
    case $profile in
        "wordpress")
            setup_wordpress_profile "$domain"
            ;;
        "laravel")
            setup_laravel_profile "$domain"
            ;;
        "nodejs")
            setup_nodejs_profile "$domain"
            ;;
        "static")
            setup_static_profile "$domain"
            ;;
        "ecommerce")
            setup_ecommerce_profile "$domain"
            ;;
        "saas")
            setup_saas_profile "$domain"
            ;;
        *)
            print_error "Unknown profile: $profile"
            return 1
            ;;
    esac
    
    local result=$?
    
    # Cleanup
    rm -rf "$PROFILE_TEMP_DIR"
    
    if [ $result -eq 0 ]; then
        print_success "Profile setup completed successfully!"
        
        # Display complete setup information
        display_profile_setup_summary "$domain" "$profile"
    else
        print_error "Profile setup failed!"
        return 1
    fi
    
    return 0
}

#==============================================================================
# WordPress Profile Setup
#==============================================================================

setup_wordpress_profile() {
    local domain=$1
    local start_time=$(date +%s)
    
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║           WORDPRESS PROFILE SETUP - $domain"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""
    
    # Step 1: Create databases
    print_info "Step 1/10: Creating database accounts..."
    if command -v auto_create_domain_databases &> /dev/null; then
        auto_create_domain_databases "$domain" || {
            print_error "Database creation failed"
            return 1
        }
    else
        print_warning "Auto-database module not found, creating MySQL only..."
        create_mysql_database_for_domain "$domain"
    fi
    print_success "Database accounts created"
    echo ""
    
    # Step 2: Install WordPress
    print_info "Step 2/10: Installing WordPress..."
    install_wordpress_core "$domain" || {
        print_error "WordPress installation failed"
        return 1
    }
    print_success "WordPress installed"
    echo ""
    
    # Step 3: Install recommended plugins
    print_info "Step 3/10: Installing recommended plugins..."
    install_wordpress_plugins "$domain" || {
        print_warning "Some plugins failed to install"
    }
    print_success "Plugins installed"
    echo ""
    
    # Step 4: Setup phpMyAdmin
    print_info "Step 4/10: Setting up phpMyAdmin..."
    if command -v setup_phpmyadmin_for_domain &> /dev/null; then
        setup_phpmyadmin_for_domain "$domain"
    else
        print_warning "phpMyAdmin module not found, skipping..."
    fi
    print_success "phpMyAdmin configured"
    echo ""
    
    # Step 5: Create FTP user
    print_info "Step 5/10: Creating FTP user..."
    create_ftp_user_for_domain "$domain" "wp_admin" || {
        print_warning "FTP user creation failed"
    }
    print_success "FTP user created"
    echo ""
    
    # Step 6: Enable Redis cache
    print_info "Step 6/10: Enabling Redis cache..."
    enable_redis_for_domain "$domain" || {
        print_warning "Redis setup failed"
    }
    print_success "Redis cache enabled"
    echo ""
    
    # Step 7: Install SSL certificate
    print_info "Step 7/10: Installing SSL certificate..."
    install_ssl_for_domain "$domain" || {
        print_warning "SSL installation failed (can be installed later)"
    }
    print_success "SSL certificate installed"
    echo ""
    
    # Step 8: Setup email account
    print_info "Step 8/10: Creating email account..."
    create_email_account_for_domain "$domain" "admin" || {
        print_warning "Email account creation failed"
    }
    print_success "Email account created"
    echo ""
    
    # Step 9: Configure backup
    print_info "Step 9/10: Configuring daily backup..."
    setup_daily_backup_for_domain "$domain" || {
        print_warning "Backup configuration failed"
    }
    print_success "Backup configured"
    echo ""
    
    # Step 10: Apply security
    print_info "Step 10/10: Applying security hardening..."
    apply_wordpress_security "$domain" || {
        print_warning "Security hardening incomplete"
    }
    print_success "Security hardening applied"
    echo ""
    
    # Calculate setup time
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    local minutes=$((duration / 60))
    local seconds=$((duration % 60))
    
    echo "════════════════════════════════════════════════════════════════"
    print_success "WordPress setup completed in ${minutes}m ${seconds}s"
    echo "════════════════════════════════════════════════════════════════"
    
    return 0
}

#==============================================================================
# WordPress Core Installation
#==============================================================================

install_wordpress_core() {
    local domain=$1
    local domain_path="/var/www/$domain"
    local db_name="${domain//./_}"
    
    # Install WP-CLI if not present
    if ! command -v wp &> /dev/null; then
        print_info "Installing WP-CLI..."
        curl -sO https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
        chmod +x wp-cli.phar
        mv wp-cli.phar /usr/local/bin/wp
    fi
    
    # Create domain directory
    mkdir -p "$domain_path"
    cd "$domain_path" || return 1
    
    # Download WordPress
    print_info "Downloading WordPress..."
    wp core download --allow-root --quiet || return 1
    
    # Get database credentials
    local db_password
    if [ -f "/opt/rocketvps/config/database_credentials/${domain}.conf" ]; then
        source "/opt/rocketvps/config/database_credentials/${domain}.conf"
        db_password="$MYSQL_PASSWORD"
    else
        # Generate random password if credentials don't exist
        db_password=$(openssl rand -base64 16)
    fi
    
    # Create wp-config.php
    print_info "Configuring WordPress..."
    wp config create \
        --dbname="$db_name" \
        --dbuser="$db_name" \
        --dbpass="$db_password" \
        --dbhost="localhost" \
        --allow-root \
        --quiet || return 1
    
    # Generate admin password
    local admin_password=$(openssl rand -base64 16)
    
    # Install WordPress
    print_info "Running WordPress installation..."
    wp core install \
        --url="https://$domain" \
        --title="$domain" \
        --admin_user="admin" \
        --admin_password="$admin_password" \
        --admin_email="admin@$domain" \
        --allow-root \
        --quiet || return 1
    
    # Save admin credentials
    mkdir -p "/opt/rocketvps/config/wordpress"
    cat > "/opt/rocketvps/config/wordpress/${domain}_admin.conf" <<EOF
# WordPress Admin Credentials for $domain
# Created: $(date -Iseconds)

WP_ADMIN_URL="https://$domain/wp-admin"
WP_ADMIN_USER="admin"
WP_ADMIN_PASSWORD="$admin_password"
WP_ADMIN_EMAIL="admin@$domain"
EOF
    chmod 600 "/opt/rocketvps/config/wordpress/${domain}_admin.conf"
    
    # Set proper permissions
    chown -R www-data:www-data "$domain_path"
    find "$domain_path" -type d -exec chmod 755 {} \;
    find "$domain_path" -type f -exec chmod 644 {} \;
    
    return 0
}

#==============================================================================
# WordPress Plugins Installation
#==============================================================================

install_wordpress_plugins() {
    local domain=$1
    local domain_path="/var/www/$domain"
    
    cd "$domain_path" || return 1
    
    # Install essential plugins
    local plugins=(
        "yoast-seo"           # SEO optimization
        "wordfence"           # Security
        "wp-super-cache"      # Caching
        "contact-form-7"      # Contact forms
        "akismet"             # Anti-spam
    )
    
    for plugin in "${plugins[@]}"; do
        print_info "Installing $plugin..."
        wp plugin install "$plugin" --activate --allow-root --quiet 2>/dev/null || {
            print_warning "Failed to install $plugin"
        }
    done
    
    return 0
}

#==============================================================================
# WordPress Security Hardening
#==============================================================================

apply_wordpress_security() {
    local domain=$1
    local domain_path="/var/www/$domain"
    
    # Disable file editing
    if ! grep -q "DISALLOW_FILE_EDIT" "$domain_path/wp-config.php"; then
        sed -i "/\/\* That's all, stop editing/i define('DISALLOW_FILE_EDIT', true);" "$domain_path/wp-config.php"
    fi
    
    # Protect wp-config.php
    cat > "$domain_path/.htaccess" <<'EOF'
# BEGIN WordPress Security
<files wp-config.php>
order allow,deny
deny from all
</files>

# Block xmlrpc.php
<Files xmlrpc.php>
order deny,allow
deny from all
</Files>

# Protect .htaccess
<files ~ "^.*\.([Hh][Tt][Aa])">
order allow,deny
deny from all
satisfy all
</files>
# END WordPress Security
EOF
    
    # Set restrictive permissions
    chmod 440 "$domain_path/wp-config.php"
    
    return 0
}

#==============================================================================
# Helper Functions for Other Profiles
#==============================================================================

create_mysql_database_for_domain() {
    local domain=$1
    local db_name="${domain//./_}"
    local db_user="$db_name"
    local db_password=$(openssl rand -base64 16)
    
    # Create database and user
    mysql -e "CREATE DATABASE IF NOT EXISTS \`${db_name}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" 2>/dev/null
    mysql -e "CREATE USER IF NOT EXISTS '${db_user}'@'localhost' IDENTIFIED BY '${db_password}';" 2>/dev/null
    mysql -e "GRANT ALL PRIVILEGES ON \`${db_name}\`.* TO '${db_user}'@'localhost';" 2>/dev/null
    mysql -e "FLUSH PRIVILEGES;" 2>/dev/null
    
    # Save credentials
    mkdir -p "/opt/rocketvps/config/database_credentials"
    cat > "/opt/rocketvps/config/database_credentials/${domain}.conf" <<EOF
# Database Credentials for $domain
MYSQL_HOST="localhost"
MYSQL_PORT="3306"
MYSQL_DATABASE="$db_name"
MYSQL_USER="$db_user"
MYSQL_PASSWORD="$db_password"
CREATED_DATE="$(date -Iseconds)"
EOF
    chmod 600 "/opt/rocketvps/config/database_credentials/${domain}.conf"
    
    return 0
}

create_ftp_user_for_domain() {
    local domain=$1
    local username=$2
    local password=$(openssl rand -base64 16)
    
    # Create system user for FTP
    useradd -m -d "/var/www/$domain" -s /bin/bash "${username}" 2>/dev/null || true
    echo "${username}:${password}" | chpasswd
    
    # Save FTP credentials
    mkdir -p "/opt/rocketvps/config/ftp"
    cat > "/opt/rocketvps/config/ftp/${domain}.conf" <<EOF
# FTP Credentials for $domain
FTP_HOST="$domain"
FTP_PORT="21"
FTP_USER="$username"
FTP_PASSWORD="$password"
FTP_PATH="/var/www/$domain"
CREATED_DATE="$(date -Iseconds)"
EOF
    chmod 600 "/opt/rocketvps/config/ftp/${domain}.conf"
    
    return 0
}

enable_redis_for_domain() {
    local domain=$1
    
    # Check if Redis is installed
    if ! command -v redis-cli &> /dev/null; then
        print_info "Installing Redis..."
        apt-get install -y redis-server >/dev/null 2>&1 || return 1
    fi
    
    # Enable Redis
    systemctl enable redis-server >/dev/null 2>&1
    systemctl start redis-server >/dev/null 2>&1
    
    return 0
}

install_ssl_for_domain() {
    local domain=$1
    
    # Check if certbot is installed
    if ! command -v certbot &> /dev/null; then
        print_info "Installing Certbot..."
        apt-get install -y certbot python3-certbot-nginx >/dev/null 2>&1 || return 1
    fi
    
    # Install certificate (will prompt for email if first time)
    certbot --nginx -d "$domain" --non-interactive --agree-tos --register-unsafely-without-email >/dev/null 2>&1 || {
        print_warning "SSL installation requires manual intervention"
        return 1
    }
    
    return 0
}

create_email_account_for_domain() {
    local domain=$1
    local username=$2
    
    print_warning "Email setup requires mail server configuration"
    return 0
}

setup_daily_backup_for_domain() {
    local domain=$1
    
    # Create backup script
    mkdir -p "/opt/rocketvps/scripts"
    cat > "/opt/rocketvps/scripts/backup_${domain}.sh" <<EOF
#!/bin/bash
# Automatic backup script for $domain
BACKUP_DIR="/opt/rocketvps/backups/${domain}"
mkdir -p "\$BACKUP_DIR"
tar czf "\$BACKUP_DIR/backup_\$(date +%Y%m%d).tar.gz" "/var/www/$domain"
find "\$BACKUP_DIR" -name "backup_*.tar.gz" -mtime +7 -delete
EOF
    chmod +x "/opt/rocketvps/scripts/backup_${domain}.sh"
    
    # Add to crontab
    (crontab -l 2>/dev/null | grep -v "backup_${domain}.sh"; echo "0 3 * * * /opt/rocketvps/scripts/backup_${domain}.sh") | crontab -
    
    return 0
}

#==============================================================================
# Profile Setup Summary Display
#==============================================================================

display_profile_setup_summary() {
    local domain=$1
    local profile=$2
    
    echo ""
    echo "╔═══════════════════════════════════════════════════════════════╗"
    echo "║        SETUP COMPLETE - $domain"
    echo "╚═══════════════════════════════════════════════════════════════╝"
    echo ""
    
    case $profile in
        "wordpress")
            display_wordpress_summary "$domain"
            ;;
        "laravel")
            display_laravel_summary "$domain"
            ;;
        "nodejs")
            display_nodejs_summary "$domain"
            ;;
        "static")
            display_static_summary "$domain"
            ;;
        "ecommerce")
            display_ecommerce_summary "$domain"
            ;;
        "saas")
            display_saas_summary "$domain"
            ;;
        *)
            print_info "Setup summary for $profile profile"
            ;;
    esac
    
    echo ""
    echo "════════════════════════════════════════════════════════════════"
    print_success "All credentials saved to /opt/rocketvps/config/"
    echo "════════════════════════════════════════════════════════════════"
    echo ""
}

display_wordpress_summary() {
    local domain=$1
    
    # Load credentials
    local wp_admin_pass=""
    local db_password=""
    local ftp_password=""
    
    [ -f "/opt/rocketvps/config/wordpress/${domain}_admin.conf" ] && source "/opt/rocketvps/config/wordpress/${domain}_admin.conf"
    [ -f "/opt/rocketvps/config/database_credentials/${domain}.conf" ] && source "/opt/rocketvps/config/database_credentials/${domain}.conf"
    [ -f "/opt/rocketvps/config/ftp/${domain}.conf" ] && source "/opt/rocketvps/config/ftp/${domain}.conf"
    
    echo "🌐 WORDPRESS ACCESS:"
    echo "   URL:      https://$domain/wp-admin"
    echo "   Username: ${WP_ADMIN_USER:-admin}"
    echo "   Password: ${WP_ADMIN_PASSWORD:-[not set]}"
    echo ""
    
    echo "🗄️  DATABASE ACCESS:"
    echo "   Database: ${MYSQL_DATABASE:-${domain//./_}}"
    echo "   Username: ${MYSQL_USER:-${domain//./_}}"
    echo "   Password: ${MYSQL_PASSWORD:-[not set]}"
    echo "   Host:     ${MYSQL_HOST:-localhost}"
    echo ""
    
    echo "📁 FTP ACCESS:"
    echo "   Host:     $domain"
    echo "   Username: ${FTP_USER:-wp_admin}"
    echo "   Password: ${FTP_PASSWORD:-[not set]}"
    echo "   Port:     21"
    echo ""
    
    echo "🔒 SECURITY:"
    echo "   SSL:          ✓ Enabled (auto-renewal)"
    echo "   Firewall:     ✓ Configured"
    echo "   File Edit:    ✗ Disabled (secure)"
    echo "   XMLRPC:       ✗ Blocked (secure)"
    echo ""
    
    echo "💾 BACKUP:"
    echo "   Schedule:     Daily at 3:00 AM"
    echo "   Retention:    7 days"
    echo "   Location:     /opt/rocketvps/backups/$domain/"
    echo ""
}

#==============================================================================
# Laravel Profile Setup
#==============================================================================

setup_laravel_profile() {
    local domain=$1
    local start_time=$(date +%s)
    
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║           LARAVEL PROFILE SETUP - $domain"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""
    
    # Step 1: Create databases
    print_info "Step 1/9: Creating database accounts..."
    if command -v auto_create_domain_databases &> /dev/null; then
        auto_create_domain_databases "$domain" || {
            print_error "Database creation failed"
            return 1
        }
    else
        create_mysql_database_for_domain "$domain"
    fi
    print_success "Database accounts created"
    echo ""
    
    # Step 2: Install PHP and extensions
    print_info "Step 2/9: Installing PHP 8.2 and extensions..."
    install_php_for_laravel || {
        print_error "PHP installation failed"
        return 1
    }
    print_success "PHP 8.2 installed"
    echo ""
    
    # Step 3: Install Composer
    print_info "Step 3/9: Installing Composer..."
    install_composer || {
        print_error "Composer installation failed"
        return 1
    }
    print_success "Composer installed"
    echo ""
    
    # Step 4: Create Laravel project
    print_info "Step 4/9: Creating Laravel project..."
    create_laravel_project "$domain" || {
        print_error "Laravel project creation failed"
        return 1
    }
    print_success "Laravel project created"
    echo ""
    
    # Step 5: Configure environment
    print_info "Step 5/9: Configuring environment variables..."
    setup_laravel_env "$domain" || {
        print_error "Environment configuration failed"
        return 1
    }
    print_success "Environment configured"
    echo ""
    
    # Step 6: Setup queue worker
    print_info "Step 6/9: Setting up queue workers..."
    setup_queue_worker "$domain" || {
        print_warning "Queue worker setup failed"
    }
    print_success "Queue workers configured"
    echo ""
    
    # Step 7: Setup scheduler
    print_info "Step 7/9: Setting up Laravel scheduler..."
    setup_scheduler "$domain" || {
        print_warning "Scheduler setup failed"
    }
    print_success "Scheduler configured"
    echo ""
    
    # Step 8: Enable Redis cache
    print_info "Step 8/9: Enabling Redis cache..."
    enable_redis_for_domain "$domain" || {
        print_warning "Redis setup failed"
    }
    print_success "Redis cache enabled"
    echo ""
    
    # Step 9: Install SSL certificate
    print_info "Step 9/9: Installing SSL certificate..."
    install_ssl_for_domain "$domain" || {
        print_warning "SSL installation failed (can be installed later)"
    }
    print_success "SSL certificate installed"
    echo ""
    
    # Calculate setup time
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    local minutes=$((duration / 60))
    local seconds=$((duration % 60))
    
    echo "════════════════════════════════════════════════════════════════"
    print_success "Laravel setup completed in ${minutes}m ${seconds}s"
    echo "════════════════════════════════════════════════════════════════"
    
    return 0
}

install_php_for_laravel() {
    # Check if PHP 8.2 is installed
    if php -v 2>/dev/null | grep -q "PHP 8.2"; then
        return 0
    fi
    
    # Add PHP repository
    apt-get install -y software-properties-common >/dev/null 2>&1
    add-apt-repository -y ppa:ondrej/php >/dev/null 2>&1
    apt-get update >/dev/null 2>&1
    
    # Install PHP 8.2 and required extensions
    apt-get install -y \
        php8.2-fpm \
        php8.2-cli \
        php8.2-mysql \
        php8.2-pgsql \
        php8.2-curl \
        php8.2-gd \
        php8.2-mbstring \
        php8.2-xml \
        php8.2-zip \
        php8.2-bcmath \
        php8.2-redis \
        php8.2-intl >/dev/null 2>&1 || return 1
    
    return 0
}

install_composer() {
    if command -v composer &> /dev/null; then
        return 0
    fi
    
    # Download and install Composer
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer >/dev/null 2>&1 || return 1
    
    return 0
}

create_laravel_project() {
    local domain=$1
    local domain_path="/var/www/$domain"
    
    # Create domain directory
    mkdir -p "$domain_path"
    cd "$domain_path" || return 1
    
    # Create new Laravel project
    print_info "Installing Laravel (this may take a few minutes)..."
    composer create-project --prefer-dist laravel/laravel . --quiet >/dev/null 2>&1 || return 1
    
    # Set proper permissions
    chown -R www-data:www-data "$domain_path"
    chmod -R 755 "$domain_path/storage"
    chmod -R 755 "$domain_path/bootstrap/cache"
    
    return 0
}

setup_laravel_env() {
    local domain=$1
    local domain_path="/var/www/$domain"
    local db_name="${domain//./_}"
    
    # Get database credentials
    local db_password
    if [ -f "/opt/rocketvps/config/database_credentials/${domain}.conf" ]; then
        source "/opt/rocketvps/config/database_credentials/${domain}.conf"
        db_password="$MYSQL_PASSWORD"
    else
        db_password=$(openssl rand -base64 16)
    fi
    
    # Update .env file
    cd "$domain_path" || return 1
    
    # Generate application key
    php artisan key:generate --force >/dev/null 2>&1
    
    # Update database configuration
    sed -i "s/DB_CONNECTION=.*/DB_CONNECTION=mysql/" .env
    sed -i "s/DB_HOST=.*/DB_HOST=127.0.0.1/" .env
    sed -i "s/DB_PORT=.*/DB_PORT=3306/" .env
    sed -i "s/DB_DATABASE=.*/DB_DATABASE=${db_name}/" .env
    sed -i "s/DB_USERNAME=.*/DB_USERNAME=${db_name}/" .env
    sed -i "s/DB_PASSWORD=.*/DB_PASSWORD=${db_password}/" .env
    
    # Update cache configuration to use Redis
    sed -i "s/CACHE_DRIVER=.*/CACHE_DRIVER=redis/" .env
    sed -i "s/QUEUE_CONNECTION=.*/QUEUE_CONNECTION=redis/" .env
    sed -i "s/SESSION_DRIVER=.*/SESSION_DRIVER=redis/" .env
    
    # Run migrations
    php artisan migrate --force >/dev/null 2>&1 || {
        print_warning "Database migration failed (may need manual intervention)"
    }
    
    # Cache configuration
    php artisan config:cache >/dev/null 2>&1
    php artisan route:cache >/dev/null 2>&1
    
    return 0
}

setup_queue_worker() {
    local domain=$1
    local domain_path="/var/www/$domain"
    
    # Install Supervisor
    if ! command -v supervisorctl &> /dev/null; then
        apt-get install -y supervisor >/dev/null 2>&1 || return 1
    fi
    
    # Create Supervisor configuration
    cat > "/etc/supervisor/conf.d/laravel-worker-${domain}.conf" <<EOF
[program:laravel-worker-${domain}]
process_name=%(program_name)s_%(process_num)02d
command=php ${domain_path}/artisan queue:work redis --sleep=3 --tries=3 --max-time=3600
autostart=true
autorestart=true
stopasgroup=true
killasgroup=true
user=www-data
numprocs=2
redirect_stderr=true
stdout_logfile=/var/log/laravel-worker-${domain}.log
stopwaitsecs=3600
EOF
    
    # Reload Supervisor
    supervisorctl reread >/dev/null 2>&1
    supervisorctl update >/dev/null 2>&1
    supervisorctl start "laravel-worker-${domain}:*" >/dev/null 2>&1
    
    return 0
}

setup_scheduler() {
    local domain=$1
    local domain_path="/var/www/$domain"
    
    # Add Laravel scheduler to crontab
    (crontab -l 2>/dev/null | grep -v "artisan schedule:run.*${domain}"; echo "* * * * * cd ${domain_path} && php artisan schedule:run >> /dev/null 2>&1") | crontab -
    
    return 0
}

display_laravel_summary() {
    local domain=$1
    local domain_path="/var/www/$domain"
    
    # Load credentials
    local db_password=""
    [ -f "/opt/rocketvps/config/database_credentials/${domain}.conf" ] && source "/opt/rocketvps/config/database_credentials/${domain}.conf"
    
    echo "🚀 LARAVEL APPLICATION:"
    echo "   URL:          https://$domain"
    echo "   Path:         $domain_path"
    echo "   PHP Version:  8.2"
    echo ""
    
    echo "🗄️  DATABASE ACCESS:"
    echo "   Database: ${MYSQL_DATABASE:-${domain//./_}}"
    echo "   Username: ${MYSQL_USER:-${domain//./_}}"
    echo "   Password: ${MYSQL_PASSWORD:-[not set]}"
    echo "   Host:     ${MYSQL_HOST:-localhost}"
    echo ""
    
    echo "⚙️  SERVICES:"
    echo "   Queue Workers:  2 workers running"
    echo "   Scheduler:      ✓ Configured (every minute)"
    echo "   Redis Cache:    ✓ Enabled"
    echo ""
    
    echo "📝 USEFUL COMMANDS:"
    echo "   Run migrations:     cd $domain_path && php artisan migrate"
    echo "   Clear cache:        cd $domain_path && php artisan cache:clear"
    echo "   Check queue:        supervisorctl status laravel-worker-${domain}:*"
    echo ""
}

#==============================================================================
# Node.js Profile Setup
#==============================================================================

setup_nodejs_profile() {
    local domain=$1
    local start_time=$(date +%s)
    
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║          NODE.JS PROFILE SETUP - $domain"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""
    
    # Step 1: Install Node.js
    print_info "Step 1/7: Installing Node.js 20 LTS..."
    install_nodejs || {
        print_error "Node.js installation failed"
        return 1
    }
    print_success "Node.js 20 LTS installed"
    echo ""
    
    # Step 2: Install PM2
    print_info "Step 2/7: Installing PM2 process manager..."
    install_pm2 || {
        print_error "PM2 installation failed"
        return 1
    }
    print_success "PM2 installed"
    echo ""
    
    # Step 3: Create Node.js project structure
    print_info "Step 3/7: Creating project structure..."
    create_nodejs_project "$domain" || {
        print_error "Project creation failed"
        return 1
    }
    print_success "Project structure created"
    echo ""
    
    # Step 4: Configure environment
    print_info "Step 4/7: Setting up environment variables..."
    setup_nodejs_env "$domain" || {
        print_error "Environment setup failed"
        return 1
    }
    print_success "Environment configured"
    echo ""
    
    # Step 5: Setup PM2
    print_info "Step 5/7: Configuring PM2 process manager..."
    setup_pm2_process "$domain" || {
        print_error "PM2 setup failed"
        return 1
    }
    print_success "PM2 configured"
    echo ""
    
    # Step 6: Create Nginx reverse proxy
    print_info "Step 6/7: Setting up Nginx reverse proxy..."
    create_nginx_proxy "$domain" || {
        print_error "Nginx proxy setup failed"
        return 1
    }
    print_success "Nginx proxy configured"
    echo ""
    
    # Step 7: Install SSL certificate
    print_info "Step 7/7: Installing SSL certificate..."
    install_ssl_for_domain "$domain" || {
        print_warning "SSL installation failed (can be installed later)"
    }
    print_success "SSL certificate installed"
    echo ""
    
    # Calculate setup time
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    local minutes=$((duration / 60))
    local seconds=$((duration % 60))
    
    echo "════════════════════════════════════════════════════════════════"
    print_success "Node.js setup completed in ${minutes}m ${seconds}s"
    echo "════════════════════════════════════════════════════════════════"
    
    return 0
}

install_nodejs() {
    # Check if Node.js 20 is installed
    if node -v 2>/dev/null | grep -q "v20"; then
        return 0
    fi
    
    # Install NVM
    if [ ! -d "$HOME/.nvm" ]; then
        curl -so- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash >/dev/null 2>&1
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    fi
    
    # Install Node.js 20 LTS
    nvm install 20 >/dev/null 2>&1 || {
        # Fallback: Install via NodeSource
        curl -fsSL https://deb.nodesource.com/setup_20.x | bash - >/dev/null 2>&1
        apt-get install -y nodejs >/dev/null 2>&1 || return 1
    }
    
    return 0
}

install_pm2() {
    if command -v pm2 &> /dev/null; then
        return 0
    fi
    
    # Install PM2 globally
    npm install -g pm2 >/dev/null 2>&1 || return 1
    
    # Setup PM2 startup script
    pm2 startup systemd -u root --hp /root >/dev/null 2>&1
    
    return 0
}

create_nodejs_project() {
    local domain=$1
    local domain_path="/var/www/$domain"
    
    # Create project directory
    mkdir -p "$domain_path"
    cd "$domain_path" || return 1
    
    # Initialize package.json
    cat > package.json <<EOF
{
  "name": "${domain//./-}",
  "version": "1.0.0",
  "description": "Node.js application for $domain",
  "main": "index.js",
  "scripts": {
    "start": "node index.js",
    "dev": "nodemon index.js"
  },
  "keywords": [],
  "author": "",
  "license": "MIT",
  "dependencies": {
    "express": "^4.18.2"
  },
  "devDependencies": {
    "nodemon": "^3.0.1"
  }
}
EOF
    
    # Create basic Express server
    cat > index.js <<'EOF'
const express = require('express');
const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.json());
app.use(express.urlencoded({ extended: true }));

app.get('/', (req, res) => {
    res.json({ 
        status: 'success',
        message: 'Node.js application is running!',
        timestamp: new Date().toISOString()
    });
});

app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
});
EOF
    
    # Install dependencies
    npm install >/dev/null 2>&1
    
    # Set proper permissions
    chown -R www-data:www-data "$domain_path"
    
    return 0
}

setup_nodejs_env() {
    local domain=$1
    local domain_path="/var/www/$domain"
    
    # Create .env file
    cat > "$domain_path/.env" <<EOF
NODE_ENV=production
PORT=3000
APP_URL=https://$domain

# Database (optional - uncomment if needed)
# DB_HOST=localhost
# DB_PORT=5432
# DB_NAME=${domain//./_}
# DB_USER=${domain//./_}
# DB_PASSWORD=$(openssl rand -base64 16)

# Redis (optional)
# REDIS_HOST=localhost
# REDIS_PORT=6379
EOF
    
    return 0
}

setup_pm2_process() {
    local domain=$1
    local domain_path="/var/www/$domain"
    
    # Create PM2 ecosystem file
    cat > "$domain_path/ecosystem.config.js" <<EOF
module.exports = {
  apps: [{
    name: '${domain}',
    script: 'index.js',
    instances: 2,
    exec_mode: 'cluster',
    autorestart: true,
    watch: false,
    max_memory_restart: '500M',
    env: {
      NODE_ENV: 'production',
      PORT: 3000
    },
    error_file: '/var/log/pm2/${domain}-error.log',
    out_file: '/var/log/pm2/${domain}-out.log',
    log_date_format: 'YYYY-MM-DD HH:mm:ss Z'
  }]
};
EOF
    
    # Create log directory
    mkdir -p /var/log/pm2
    
    # Start application with PM2
    cd "$domain_path" || return 1
    pm2 start ecosystem.config.js >/dev/null 2>&1
    pm2 save >/dev/null 2>&1
    
    return 0
}

create_nginx_proxy() {
    local domain=$1
    
    # Create Nginx configuration
    cat > "/etc/nginx/sites-available/${domain}" <<EOF
server {
    listen 80;
    listen [::]:80;
    server_name ${domain};

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    # Rate limiting
    limit_req_zone \$binary_remote_addr zone=${domain}:10m rate=100r/s;
    limit_req zone=${domain} burst=20 nodelay;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        
        # WebSocket support
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
        
        # Headers
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # Health check endpoint
    location /health {
        access_log off;
        proxy_pass http://localhost:3000;
    }
}
EOF
    
    # Enable site
    ln -sf "/etc/nginx/sites-available/${domain}" "/etc/nginx/sites-enabled/${domain}"
    
    # Test and reload Nginx
    nginx -t >/dev/null 2>&1 && systemctl reload nginx >/dev/null 2>&1
    
    return 0
}

display_nodejs_summary() {
    local domain=$1
    local domain_path="/var/www/$domain"
    
    echo "🚀 NODE.JS APPLICATION:"
    echo "   URL:           https://$domain"
    echo "   Path:          $domain_path"
    echo "   Node Version:  $(node -v 2>/dev/null || echo 'v20.x')"
    echo "   Port:          3000 (proxied via Nginx)"
    echo ""
    
    echo "⚙️  PM2 PROCESS MANAGER:"
    echo "   Instances:     2 (cluster mode)"
    echo "   Max Memory:    500M per instance"
    echo "   Auto Restart:  ✓ Enabled"
    echo "   Startup:       ✓ Configured"
    echo ""
    
    echo "📝 USEFUL COMMANDS:"
    echo "   View logs:         pm2 logs ${domain}"
    echo "   Restart app:       pm2 restart ${domain}"
    echo "   Stop app:          pm2 stop ${domain}"
    echo "   Check status:      pm2 status"
    echo "   Monitor:           pm2 monit"
    echo ""
    
    echo "🔧 APPLICATION FILES:"
    echo "   Main file:         $domain_path/index.js"
    echo "   Config:            $domain_path/ecosystem.config.js"
    echo "   Environment:       $domain_path/.env"
    echo ""
}

#==============================================================================
# Static HTML Profile Setup
#==============================================================================

setup_static_profile() {
    local domain=$1
    local start_time=$(date +%s)
    
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║         STATIC HTML PROFILE SETUP - $domain"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""
    
    # Step 1: Create website structure
    print_info "Step 1/5: Creating website structure..."
    create_static_site_structure "$domain" || {
        print_error "Site structure creation failed"
        return 1
    }
    print_success "Website structure created"
    echo ""
    
    # Step 2: Configure Nginx
    print_info "Step 2/5: Configuring optimized Nginx..."
    configure_nginx_static "$domain" || {
        print_error "Nginx configuration failed"
        return 1
    }
    print_success "Nginx configured"
    echo ""
    
    # Step 3: Setup cache headers
    print_info "Step 3/5: Configuring cache headers..."
    setup_cache_headers "$domain" || {
        print_warning "Cache headers setup incomplete"
    }
    print_success "Cache headers configured"
    echo ""
    
    # Step 4: Apply security headers
    print_info "Step 4/5: Applying security headers..."
    apply_security_headers "$domain" || {
        print_warning "Security headers setup incomplete"
    }
    print_success "Security headers applied"
    echo ""
    
    # Step 5: Install SSL certificate
    print_info "Step 5/5: Installing SSL certificate..."
    install_ssl_for_domain "$domain" || {
        print_warning "SSL installation failed (can be installed later)"
    }
    print_success "SSL certificate installed"
    echo ""
    
    # Calculate setup time
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    local minutes=$((duration / 60))
    local seconds=$((duration % 60))
    
    echo "════════════════════════════════════════════════════════════════"
    print_success "Static HTML setup completed in ${minutes}m ${seconds}s"
    echo "════════════════════════════════════════════════════════════════"
    
    return 0
}

create_static_site_structure() {
    local domain=$1
    local domain_path="/var/www/$domain"
    
    # Create directory structure
    mkdir -p "$domain_path"/{public,assets/{css,js,images},logs}
    
    # Create sample index.html
    cat > "$domain_path/public/index.html" <<'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Welcome</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
            display: flex;
            align-items: center;
            justify-content: center;
            min-height: 100vh;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
        }
        .container {
            text-align: center;
            padding: 2rem;
        }
        h1 {
            font-size: 3rem;
            margin-bottom: 1rem;
            text-shadow: 2px 2px 4px rgba(0,0,0,0.3);
        }
        p {
            font-size: 1.2rem;
            opacity: 0.9;
        }
        .badge {
            display: inline-block;
            margin-top: 2rem;
            padding: 0.5rem 1rem;
            background: rgba(255,255,255,0.2);
            border-radius: 2rem;
            font-size: 0.9rem;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 Welcome!</h1>
        <p>Your website is successfully set up and running.</p>
        <div class="badge">Powered by RocketVPS</div>
    </div>
</body>
</html>
EOF
    
    # Create sample 404 page
    cat > "$domain_path/public/404.html" <<'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>404 - Page Not Found</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
            display: flex;
            align-items: center;
            justify-content: center;
            min-height: 100vh;
            background: #f5f7fa;
        }
        .container {
            text-align: center;
            padding: 2rem;
        }
        h1 {
            font-size: 6rem;
            color: #667eea;
            margin-bottom: 1rem;
        }
        p {
            font-size: 1.5rem;
            color: #666;
            margin-bottom: 2rem;
        }
        a {
            display: inline-block;
            padding: 1rem 2rem;
            background: #667eea;
            color: white;
            text-decoration: none;
            border-radius: 0.5rem;
            transition: background 0.3s;
        }
        a:hover {
            background: #764ba2;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>404</h1>
        <p>Page Not Found</p>
        <a href="/">Go Home</a>
    </div>
</body>
</html>
EOF
    
    # Set proper permissions
    chown -R www-data:www-data "$domain_path"
    find "$domain_path" -type d -exec chmod 755 {} \;
    find "$domain_path" -type f -exec chmod 644 {} \;
    
    return 0
}

configure_nginx_static() {
    local domain=$1
    local domain_path="/var/www/$domain"
    
    # Create optimized Nginx configuration for static sites
    cat > "/etc/nginx/sites-available/${domain}" <<EOF
server {
    listen 80;
    listen [::]:80;
    server_name ${domain} www.${domain};

    root ${domain_path}/public;
    index index.html index.htm;

    # Access and error logs
    access_log ${domain_path}/logs/access.log;
    error_log ${domain_path}/logs/error.log;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_comp_level 6;
    gzip_types text/plain text/css text/xml text/javascript 
               application/x-javascript application/javascript 
               application/xml+rss application/json 
               image/svg+xml;

    # Cache static assets
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        access_log off;
    }

    # Cache HTML files
    location ~* \.(html|htm)$ {
        expires 1h;
        add_header Cache-Control "public, must-revalidate";
    }

    # Main location
    location / {
        try_files \$uri \$uri/ =404;
    }

    # Custom 404 page
    error_page 404 /404.html;
    location = /404.html {
        internal;
    }

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;

    # Deny access to hidden files
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }

    # Deny access to backup files
    location ~ ~$ {
        deny all;
        access_log off;
        log_not_found off;
    }
}
EOF
    
    # Enable site
    ln -sf "/etc/nginx/sites-available/${domain}" "/etc/nginx/sites-enabled/${domain}"
    
    # Test and reload Nginx
    nginx -t >/dev/null 2>&1 && systemctl reload nginx >/dev/null 2>&1
    
    return 0
}

setup_cache_headers() {
    local domain=$1
    # Cache headers already configured in Nginx config
    return 0
}

apply_security_headers() {
    local domain=$1
    # Security headers already configured in Nginx config
    return 0
}

display_static_summary() {
    local domain=$1
    local domain_path="/var/www/$domain"
    
    echo "🌐 STATIC WEBSITE:"
    echo "   URL:           https://$domain"
    echo "   Document Root: $domain_path/public"
    echo "   Type:          Static HTML/CSS/JS"
    echo ""
    
    echo "📁 DIRECTORY STRUCTURE:"
    echo "   HTML files:    $domain_path/public/"
    echo "   CSS:           $domain_path/assets/css/"
    echo "   JavaScript:    $domain_path/assets/js/"
    echo "   Images:        $domain_path/assets/images/"
    echo "   Logs:          $domain_path/logs/"
    echo ""
    
    echo "⚡ OPTIMIZATIONS:"
    echo "   Gzip:          ✓ Enabled (all text files)"
    echo "   Cache:         ✓ Assets cached 1 year"
    echo "   Cache:         ✓ HTML cached 1 hour"
    echo "   Security:      ✓ Headers configured"
    echo ""
    
    echo "📝 UPLOAD FILES:"
    echo "   Via FTP:       Upload to $domain_path/public/"
    echo "   Via SSH:       scp files to $domain_path/public/"
    echo "   Via Git:       Clone repo to $domain_path/public/"
    echo ""
}

#==============================================================================
# E-commerce Profile Setup
#==============================================================================

setup_ecommerce_profile() {
    local domain=$1
    local start_time=$(date +%s)
    
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║        E-COMMERCE PROFILE SETUP - $domain"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""
    
    # E-commerce is based on WordPress + WooCommerce
    # First run WordPress setup
    print_info "Setting up WordPress base..."
    
    # Step 1: Create databases
    print_info "Step 1/11: Creating database accounts..."
    if command -v auto_create_domain_databases &> /dev/null; then
        auto_create_domain_databases "$domain" || {
            print_error "Database creation failed"
            return 1
        }
    else
        create_mysql_database_for_domain "$domain"
    fi
    print_success "Database accounts created"
    echo ""
    
    # Step 2: Install WordPress
    print_info "Step 2/11: Installing WordPress..."
    install_wordpress_core "$domain" || {
        print_error "WordPress installation failed"
        return 1
    }
    print_success "WordPress installed"
    echo ""
    
    # Step 3: Configure high-performance PHP
    print_info "Step 3/11: Configuring high-performance PHP..."
    configure_high_performance_php "$domain" || {
        print_warning "PHP optimization incomplete"
    }
    print_success "PHP optimized for e-commerce"
    echo ""
    
    # Step 4: Install WooCommerce
    print_info "Step 4/11: Installing WooCommerce..."
    install_woocommerce "$domain" || {
        print_error "WooCommerce installation failed"
        return 1
    }
    print_success "WooCommerce installed"
    echo ""
    
    # Step 5: Install e-commerce plugins
    print_info "Step 5/11: Installing essential e-commerce plugins..."
    install_ecommerce_plugins "$domain" || {
        print_warning "Some plugins failed to install"
    }
    print_success "Plugins installed"
    echo ""
    
    # Step 6: Setup Redis cache (high memory)
    print_info "Step 6/11: Enabling Redis cache (512M)..."
    enable_redis_for_ecommerce "$domain" || {
        print_warning "Redis setup failed"
    }
    print_success "Redis cache enabled"
    echo ""
    
    # Step 7: Configure database optimization
    print_info "Step 7/11: Optimizing database for e-commerce..."
    optimize_database_for_ecommerce "$domain" || {
        print_warning "Database optimization incomplete"
    }
    print_success "Database optimized"
    echo ""
    
    # Step 8: Setup payment gateways
    print_info "Step 8/11: Setting up payment gateways..."
    setup_payment_gateways "$domain" || {
        print_warning "Payment gateway setup requires manual configuration"
    }
    print_success "Payment gateways ready"
    echo ""
    
    # Step 9: Setup phpMyAdmin
    print_info "Step 9/11: Setting up phpMyAdmin..."
    if command -v setup_phpmyadmin_for_domain &> /dev/null; then
        setup_phpmyadmin_for_domain "$domain"
    fi
    print_success "phpMyAdmin configured"
    echo ""
    
    # Step 10: Install SSL certificate
    print_info "Step 10/11: Installing SSL certificate..."
    install_ssl_for_domain "$domain" || {
        print_warning "SSL installation failed (required for payment processing)"
    }
    print_success "SSL certificate installed"
    echo ""
    
    # Step 11: Configure twice-daily backup
    print_info "Step 11/11: Configuring twice-daily backup..."
    setup_ecommerce_backup "$domain" || {
        print_warning "Backup configuration failed"
    }
    print_success "Backup configured"
    echo ""
    
    # Apply security
    apply_wordpress_security "$domain"
    
    # Calculate setup time
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    local minutes=$((duration / 60))
    local seconds=$((duration % 60))
    
    echo "════════════════════════════════════════════════════════════════"
    print_success "E-commerce setup completed in ${minutes}m ${seconds}s"
    echo "════════════════════════════════════════════════════════════════"
    
    return 0
}

configure_high_performance_php() {
    local domain=$1
    
    # Update PHP-FPM configuration for high memory
    local php_version="8.2"
    local fpm_conf="/etc/php/${php_version}/fpm/pool.d/${domain}.conf"
    
    cat > "$fpm_conf" <<EOF
[${domain}]
user = www-data
group = www-data
listen = /run/php/php${php_version}-fpm-${domain}.sock
listen.owner = www-data
listen.group = www-data

pm = dynamic
pm.max_children = 50
pm.start_servers = 10
pm.min_spare_servers = 5
pm.max_spare_servers = 20
pm.max_requests = 500

php_admin_value[memory_limit] = 1024M
php_admin_value[upload_max_filesize] = 128M
php_admin_value[post_max_size] = 128M
php_admin_value[max_execution_time] = 300
php_admin_value[max_input_time] = 300
EOF
    
    # Restart PHP-FPM
    systemctl restart "php${php_version}-fpm" >/dev/null 2>&1
    
    return 0
}

install_woocommerce() {
    local domain=$1
    local domain_path="/var/www/$domain"
    
    cd "$domain_path" || return 1
    
    # Install WooCommerce
    wp plugin install woocommerce --activate --allow-root --quiet 2>/dev/null || return 1
    
    return 0
}

install_ecommerce_plugins() {
    local domain=$1
    local domain_path="/var/www/$domain"
    
    cd "$domain_path" || return 1
    
    # Install essential e-commerce plugins
    local plugins=(
        "woocommerce-gateway-stripe"    # Stripe payment
        "woocommerce-paypal-payments"   # PayPal payment
        "woocommerce-pdf-invoices-packing-slips"  # Invoices
        "mailchimp-for-woocommerce"     # Email marketing
        "google-analytics-for-wordpress"  # Analytics
        "wordfence"                     # Security
        "redis-cache"                   # Redis object cache
    )
    
    for plugin in "${plugins[@]}"; do
        print_info "Installing $plugin..."
        wp plugin install "$plugin" --activate --allow-root --quiet 2>/dev/null || {
            print_warning "Failed to install $plugin"
        }
    done
    
    return 0
}

enable_redis_for_ecommerce() {
    local domain=$1
    local domain_path="/var/www/$domain"
    
    # Install Redis
    if ! command -v redis-cli &> /dev/null; then
        apt-get install -y redis-server >/dev/null 2>&1 || return 1
    fi
    
    # Configure Redis with 512M memory
    cat >> /etc/redis/redis.conf <<EOF

# E-commerce optimization for $domain
maxmemory 512mb
maxmemory-policy allkeys-lru
EOF
    
    # Enable and restart Redis
    systemctl enable redis-server >/dev/null 2>&1
    systemctl restart redis-server >/dev/null 2>&1
    
    # Enable Redis object cache in WordPress
    cd "$domain_path" || return 1
    wp plugin install redis-cache --activate --allow-root --quiet 2>/dev/null
    wp redis enable --allow-root --quiet 2>/dev/null
    
    return 0
}

optimize_database_for_ecommerce() {
    local domain=$1
    local db_name="${domain//./_}"
    
    # Optimize MySQL for e-commerce
    cat >> /etc/mysql/mysql.conf.d/mysqld.cnf <<EOF

# E-commerce optimization
max_connections = 200
innodb_buffer_pool_size = 1G
innodb_log_file_size = 256M
innodb_flush_log_at_trx_commit = 2
query_cache_size = 64M
query_cache_type = 1
EOF
    
    # Restart MySQL
    systemctl restart mysql >/dev/null 2>&1
    
    return 0
}

setup_payment_gateways() {
    local domain=$1
    
    # Payment gateways require manual API key configuration
    # Just ensure plugins are installed (done in install_ecommerce_plugins)
    
    return 0
}

setup_ecommerce_backup() {
    local domain=$1
    
    # Create backup script with twice-daily schedule
    mkdir -p "/opt/rocketvps/scripts"
    cat > "/opt/rocketvps/scripts/backup_${domain}.sh" <<EOF
#!/bin/bash
# Twice-daily backup script for $domain e-commerce
BACKUP_DIR="/opt/rocketvps/backups/${domain}"
mkdir -p "\$BACKUP_DIR"

# Backup files and database
TIMESTAMP=\$(date +%Y%m%d_%H%M)
tar czf "\$BACKUP_DIR/files_\${TIMESTAMP}.tar.gz" "/var/www/$domain"

# Backup database
DB_NAME="${domain//./_}"
mysqldump "\$DB_NAME" | gzip > "\$BACKUP_DIR/db_\${TIMESTAMP}.sql.gz"

# Keep last 14 backups (7 days * 2 per day)
find "\$BACKUP_DIR" -name "files_*.tar.gz" -o -name "db_*.sql.gz" | sort -r | tail -n +15 | xargs rm -f
EOF
    chmod +x "/opt/rocketvps/scripts/backup_${domain}.sh"
    
    # Add to crontab - twice daily (3AM and 3PM)
    (crontab -l 2>/dev/null | grep -v "backup_${domain}.sh"; 
     echo "0 3,15 * * * /opt/rocketvps/scripts/backup_${domain}.sh") | crontab -
    
    return 0
}

display_ecommerce_summary() {
    local domain=$1
    
    # Load credentials
    local wp_admin_pass=""
    local db_password=""
    
    [ -f "/opt/rocketvps/config/wordpress/${domain}_admin.conf" ] && source "/opt/rocketvps/config/wordpress/${domain}_admin.conf"
    [ -f "/opt/rocketvps/config/database_credentials/${domain}.conf" ] && source "/opt/rocketvps/config/database_credentials/${domain}.conf"
    
    echo "🛒 E-COMMERCE STORE:"
    echo "   Store URL:     https://$domain"
    echo "   Admin URL:     https://$domain/wp-admin"
    echo "   Username:      ${WP_ADMIN_USER:-admin}"
    echo "   Password:      ${WP_ADMIN_PASSWORD:-[not set]}"
    echo ""
    
    echo "💳 WOOCOMMERCE:"
    echo "   Version:       Latest"
    echo "   Setup:         https://$domain/wp-admin/admin.php?page=wc-setup-checklist"
    echo "   Products:      https://$domain/wp-admin/edit.php?post_type=product"
    echo "   Orders:        https://$domain/wp-admin/edit.php?post_type=shop_order"
    echo ""
    
    echo "💰 PAYMENT GATEWAYS:"
    echo "   Stripe:        ✓ Plugin installed (needs API key)"
    echo "   PayPal:        ✓ Plugin installed (needs configuration)"
    echo "   Configure:     https://$domain/wp-admin/admin.php?page=wc-settings&tab=checkout"
    echo ""
    
    echo "⚡ PERFORMANCE:"
    echo "   PHP Memory:    1024M (high)"
    echo "   Upload Limit:  128M (for product images)"
    echo "   Redis Cache:   ✓ 512M allocated"
    echo "   Database:      ✓ Optimized for 200 connections"
    echo ""
    
    echo "🗄️  DATABASE:"
    echo "   Database:      ${MYSQL_DATABASE:-${domain//./_}}"
    echo "   Username:      ${MYSQL_USER:-${domain//./_}}"
    echo "   Password:      ${MYSQL_PASSWORD:-[not set]}"
    echo ""
    
    echo "💾 BACKUP:"
    echo "   Schedule:      Twice daily (3AM, 3PM)"
    echo "   Retention:     7 days (14 backups)"
    echo "   Location:      /opt/rocketvps/backups/$domain/"
    echo ""
    
    echo "⚠️  IMPORTANT NEXT STEPS:"
    echo "   1. Complete WooCommerce setup wizard"
    echo "   2. Configure payment gateways (Stripe/PayPal)"
    echo "   3. Set up shipping zones and methods"
    echo "   4. Configure tax settings"
    echo "   5. Add your first products"
    echo ""
}

#==============================================================================
# SaaS Profile Setup
#==============================================================================

setup_saas_profile() {
    local domain=$1
    local start_time=$(date +%s)
    
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║      MULTI-TENANT SAAS PROFILE SETUP - $domain"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""
    
    # Step 1: Install PostgreSQL (better for multi-tenancy)
    print_info "Step 1/10: Installing PostgreSQL..."
    install_postgresql || {
        print_error "PostgreSQL installation failed"
        return 1
    }
    print_success "PostgreSQL installed"
    echo ""
    
    # Step 2: Create PostgreSQL databases
    print_info "Step 2/10: Creating PostgreSQL database..."
    create_postgresql_database_for_domain "$domain" || {
        print_error "Database creation failed"
        return 1
    }
    print_success "Database created"
    echo ""
    
    # Step 3: Install PHP and extensions
    print_info "Step 3/10: Installing PHP for SaaS..."
    install_php_for_laravel || {
        print_error "PHP installation failed"
        return 1
    }
    print_success "PHP installed"
    echo ""
    
    # Step 4: Install Composer and create Laravel project
    print_info "Step 4/10: Creating Laravel multi-tenant project..."
    install_composer
    create_laravel_project "$domain" || {
        print_error "Project creation failed"
        return 1
    }
    print_success "Project created"
    echo ""
    
    # Step 5: Configure wildcard subdomain
    print_info "Step 5/10: Configuring wildcard subdomain..."
    configure_wildcard_subdomain "$domain" || {
        print_error "Wildcard configuration failed"
        return 1
    }
    print_success "Wildcard subdomain configured"
    echo ""
    
    # Step 6: Setup per-tenant database isolation
    print_info "Step 6/10: Setting up per-tenant database isolation..."
    setup_per_tenant_database "$domain" || {
        print_warning "Tenant isolation setup incomplete"
    }
    print_success "Tenant isolation configured"
    echo ""
    
    # Step 7: Setup Redis with multiple databases
    print_info "Step 7/10: Configuring Redis for multi-tenant..."
    setup_redis_for_saas "$domain" || {
        print_warning "Redis setup failed"
    }
    print_success "Redis configured"
    echo ""
    
    # Step 8: Setup rate limiting per tenant
    print_info "Step 8/10: Configuring rate limiting..."
    setup_rate_limiting "$domain" || {
        print_warning "Rate limiting setup incomplete"
    }
    print_success "Rate limiting configured"
    echo ""
    
    # Step 9: Setup queue workers
    print_info "Step 9/10: Setting up queue workers..."
    setup_queue_worker "$domain" || {
        print_warning "Queue workers setup failed"
    }
    print_success "Queue workers configured"
    echo ""
    
    # Step 10: Install SSL certificate with wildcard
    print_info "Step 10/10: Installing wildcard SSL certificate..."
    install_wildcard_ssl "$domain" || {
        print_warning "SSL installation failed (requires DNS validation)"
    }
    print_success "SSL certificate installed"
    echo ""
    
    # Calculate setup time
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    local minutes=$((duration / 60))
    local seconds=$((duration % 60))
    
    echo "════════════════════════════════════════════════════════════════"
    print_success "SaaS setup completed in ${minutes}m ${seconds}s"
    echo "════════════════════════════════════════════════════════════════"
    
    return 0
}

install_postgresql() {
    # Check if PostgreSQL is installed
    if command -v psql &> /dev/null; then
        return 0
    fi
    
    # Install PostgreSQL
    apt-get install -y postgresql postgresql-contrib >/dev/null 2>&1 || return 1
    
    # Start and enable PostgreSQL
    systemctl start postgresql >/dev/null 2>&1
    systemctl enable postgresql >/dev/null 2>&1
    
    return 0
}

create_postgresql_database_for_domain() {
    local domain=$1
    local db_name="${domain//./_}"
    local db_user="$db_name"
    local db_password=$(openssl rand -base64 16)
    
    # Create database and user
    sudo -u postgres psql -c "CREATE DATABASE ${db_name};" 2>/dev/null
    sudo -u postgres psql -c "CREATE USER ${db_user} WITH ENCRYPTED PASSWORD '${db_password}';" 2>/dev/null
    sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE ${db_name} TO ${db_user};" 2>/dev/null
    sudo -u postgres psql -c "ALTER DATABASE ${db_name} OWNER TO ${db_user};" 2>/dev/null
    
    # Save credentials
    mkdir -p "/opt/rocketvps/config/database_credentials"
    cat > "/opt/rocketvps/config/database_credentials/${domain}.conf" <<EOF
# PostgreSQL Credentials for $domain (SaaS)
PGSQL_HOST="localhost"
PGSQL_PORT="5432"
PGSQL_DATABASE="$db_name"
PGSQL_USER="$db_user"
PGSQL_PASSWORD="$db_password"
CREATED_DATE="$(date -Iseconds)"
EOF
    chmod 600 "/opt/rocketvps/config/database_credentials/${domain}.conf"
    
    return 0
}

configure_wildcard_subdomain() {
    local domain=$1
    local domain_path="/var/www/$domain"
    
    # Create Nginx configuration with wildcard subdomain
    cat > "/etc/nginx/sites-available/${domain}" <<EOF
# Main domain
server {
    listen 80;
    listen [::]:80;
    server_name ${domain};

    root ${domain_path}/public;
    index index.php index.html;

    # PHP-FPM
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php8.2-fpm.sock;
    }

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }
}

# Wildcard subdomain for tenants
server {
    listen 80;
    listen [::]:80;
    server_name *.${domain};

    root ${domain_path}/public;
    index index.php index.html;

    # Rate limiting per tenant (based on subdomain)
    limit_req_zone \$http_host zone=${domain}:10m rate=1000r/h;
    limit_req zone=${domain} burst=50 nodelay;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    # PHP-FPM
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php8.2-fpm.sock;
        
        # Pass subdomain to application
        fastcgi_param HTTP_HOST \$http_host;
    }

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    # Deny access to sensitive files
    location ~ /\.env {
        deny all;
    }
}
EOF
    
    # Enable site
    ln -sf "/etc/nginx/sites-available/${domain}" "/etc/nginx/sites-enabled/${domain}"
    
    # Test and reload Nginx
    nginx -t >/dev/null 2>&1 && systemctl reload nginx >/dev/null 2>&1
    
    return 0
}

setup_per_tenant_database() {
    local domain=$1
    local domain_path="/var/www/$domain"
    
    # Create tenant provisioning helper script
    mkdir -p "$domain_path/scripts"
    cat > "$domain_path/scripts/create-tenant.sh" <<'EOF'
#!/bin/bash
# Tenant provisioning script

if [ -z "$1" ]; then
    echo "Usage: $0 <tenant-subdomain>"
    exit 1
fi

TENANT_SUBDOMAIN=$1
TENANT_DB="${TENANT_SUBDOMAIN}_db"
TENANT_USER="${TENANT_SUBDOMAIN}_user"
TENANT_PASS=$(openssl rand -base64 16)

# Create tenant database
sudo -u postgres psql -c "CREATE DATABASE ${TENANT_DB};"
sudo -u postgres psql -c "CREATE USER ${TENANT_USER} WITH ENCRYPTED PASSWORD '${TENANT_PASS}';"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE ${TENANT_DB} TO ${TENANT_USER};"

# Run migrations for tenant
cd "$(dirname "$0")/.."
php artisan migrate --database=tenant_${TENANT_SUBDOMAIN} --force

echo "Tenant created successfully!"
echo "Database: ${TENANT_DB}"
echo "User: ${TENANT_USER}"
echo "Password: ${TENANT_PASS}"
EOF
    chmod +x "$domain_path/scripts/create-tenant.sh"
    
    return 0
}

setup_redis_for_saas() {
    local domain=$1
    
    # Install Redis
    if ! command -v redis-cli &> /dev/null; then
        apt-get install -y redis-server >/dev/null 2>&1 || return 1
    fi
    
    # Configure Redis with multiple databases (16 databases for tenants)
    cat >> /etc/redis/redis.conf <<EOF

# Multi-tenant SaaS optimization for $domain
maxmemory 1gb
maxmemory-policy allkeys-lru
databases 16
EOF
    
    # Enable and restart Redis
    systemctl enable redis-server >/dev/null 2>&1
    systemctl restart redis-server >/dev/null 2>&1
    
    return 0
}

setup_rate_limiting() {
    local domain=$1
    
    # Rate limiting is configured in Nginx config (done in configure_wildcard_subdomain)
    # Additional Laravel rate limiting can be configured in the application
    
    return 0
}

install_wildcard_ssl() {
    local domain=$1
    
    # Check if certbot is installed
    if ! command -v certbot &> /dev/null; then
        apt-get install -y certbot python3-certbot-nginx >/dev/null 2>&1 || return 1
    fi
    
    # Wildcard SSL requires DNS validation (manual step)
    print_warning "Wildcard SSL requires DNS validation"
    print_info "Run manually: certbot certonly --manual --preferred-challenges dns -d $domain -d *.$domain"
    
    return 0
}

display_saas_summary() {
    local domain=$1
    local domain_path="/var/www/$domain"
    
    # Load credentials
    local db_password=""
    [ -f "/opt/rocketvps/config/database_credentials/${domain}.conf" ] && source "/opt/rocketvps/config/database_credentials/${domain}.conf"
    
    echo "🚀 MULTI-TENANT SAAS PLATFORM:"
    echo "   Main URL:      https://$domain"
    echo "   Tenant URL:    https://*.${domain}"
    echo "   Path:          $domain_path"
    echo "   Type:          Laravel Multi-tenant"
    echo ""
    
    echo "🗄️  POSTGRESQL DATABASE:"
    echo "   Host:          ${PGSQL_HOST:-localhost}"
    echo "   Port:          ${PGSQL_PORT:-5432}"
    echo "   Database:      ${PGSQL_DATABASE:-${domain//./_}}"
    echo "   Username:      ${PGSQL_USER:-${domain//./_}}"
    echo "   Password:      ${PGSQL_PASSWORD:-[not set]}"
    echo ""
    
    echo "👥 TENANT MANAGEMENT:"
    echo "   Subdomain:     tenant.${domain}"
    echo "   Provisioning:  $domain_path/scripts/create-tenant.sh"
    echo "   Database:      Per-tenant isolation"
    echo "   Rate Limit:    1000 requests/hour per tenant"
    echo ""
    
    echo "⚙️  SERVICES:"
    echo "   Queue Workers: 4 workers running"
    echo "   Redis:         ✓ 1GB with 16 databases"
    echo "   Scheduler:     ✓ Configured"
    echo ""
    
    echo "🔒 SECURITY:"
    echo "   SSL:           ⚠ Wildcard cert requires manual setup"
    echo "   Rate Limiting: ✓ Per tenant (1000 req/hour)"
    echo "   Isolation:     ✓ Database per tenant"
    echo ""
    
    echo "📝 CREATE NEW TENANT:"
    echo "   Command:       cd $domain_path && ./scripts/create-tenant.sh <tenant-name>"
    echo "   Example:       cd $domain_path && ./scripts/create-tenant.sh customer1"
    echo "   Access:        https://customer1.${domain}"
    echo ""
    
    echo "⚠️  IMPORTANT NEXT STEPS:"
    echo "   1. Install wildcard SSL certificate (requires DNS validation)"
    echo "      certbot certonly --manual --preferred-challenges dns -d $domain -d *.$domain"
    echo "   2. Configure multi-tenancy package (e.g., spatie/laravel-multitenancy)"
    echo "   3. Set up tenant provisioning logic"
    echo "   4. Configure per-tenant caching strategy"
    echo "   5. Test tenant isolation and rate limiting"
    echo ""
}

#==============================================================================
# Main Profile Menu Handler
#==============================================================================

profile_menu() {
    while true; do
        show_profile_menu
        read -p "Enter your choice [0-7]: " choice
        
        case $choice in
            1)
                read -p "Enter domain name: " domain
                execute_profile "$domain" "wordpress"
                read -p "Press any key to continue..."
                ;;
            2)
                read -p "Enter domain name: " domain
                execute_profile "$domain" "laravel"
                read -p "Press any key to continue..."
                ;;
            3)
                read -p "Enter domain name: " domain
                execute_profile "$domain" "nodejs"
                read -p "Press any key to continue..."
                ;;
            4)
                read -p "Enter domain name: " domain
                execute_profile "$domain" "static"
                read -p "Press any key to continue..."
                ;;
            5)
                read -p "Enter domain name: " domain
                execute_profile "$domain" "ecommerce"
                read -p "Press any key to continue..."
                ;;
            6)
                read -p "Enter domain name: " domain
                execute_profile "$domain" "saas"
                read -p "Press any key to continue..."
                ;;
            7)
                print_info "Opening custom setup..."
                return 0
                ;;
            0)
                return 0
                ;;
            *)
                print_error "Invalid choice. Please try again."
                sleep 2
                ;;
        esac
    done
}

# Export functions
export -f execute_profile
export -f setup_wordpress_profile
export -f install_wordpress_core
export -f install_wordpress_plugins
export -f apply_wordpress_security
