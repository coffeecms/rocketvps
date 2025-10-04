#!/bin/bash

################################################################################
# RocketVPS - WordPress Management Module
# Tự động cài đặt WordPress với Nginx tối ưu và bảo mật
################################################################################

# WordPress Configuration
WP_CLI_URL="https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar"
WORDPRESS_DOMAINS_FILE="${CONFIG_DIR}/wordpress_domains.list"

# Install WP-CLI
install_wp_cli() {
    if command -v wp &> /dev/null; then
        print_info "WP-CLI is already installed"
        wp --version
        return 0
    fi
    
    print_info "Installing WP-CLI..."
    
    curl -O "$WP_CLI_URL"
    chmod +x wp-cli.phar
    mv wp-cli.phar /usr/local/bin/wp
    
    if command -v wp &> /dev/null; then
        print_success "WP-CLI installed successfully"
        wp --version
    else
        print_error "Failed to install WP-CLI"
        return 1
    fi
}

# Install WordPress on domain
install_wordpress() {
    print_header "Install WordPress on Domain"
    
    # Check if WP-CLI is installed
    if ! command -v wp &> /dev/null; then
        print_info "WP-CLI not found, installing..."
        install_wp_cli
    fi
    
    # List available domains
    if [ ! -f "$DOMAIN_LIST_FILE" ] || [ ! -s "$DOMAIN_LIST_FILE" ]; then
        print_error "No domains found. Please add a domain first."
        press_any_key
        return
    fi
    
    print_info "Available domains:"
    cat -n "$DOMAIN_LIST_FILE"
    
    echo ""
    read -p "Enter domain name: " domain
    
    if [ -z "$domain" ]; then
        print_error "Domain name is required"
        press_any_key
        return
    fi
    
    # Check if domain exists
    if ! grep -q "^${domain}$" "$DOMAIN_LIST_FILE"; then
        print_error "Domain not found in domain list"
        press_any_key
        return
    fi
    
    # Check if WordPress already installed
    DOMAIN_ROOT="/var/www/${domain}"
    
    if [ -f "${DOMAIN_ROOT}/wp-config.php" ]; then
        print_warning "WordPress is already installed on this domain"
        read -p "Do you want to reinstall? (yes/no): " reinstall
        if [ "$reinstall" != "yes" ]; then
            return
        fi
        
        # Backup existing WordPress
        print_info "Backing up existing WordPress..."
        tar -czf "${BACKUP_DIR}/wordpress_${domain}_$(date +%Y%m%d_%H%M%S).tar.gz" "$DOMAIN_ROOT"
        print_success "Backup created"
    fi
    
    # Create domain directory if not exists
    mkdir -p "$DOMAIN_ROOT"
    
    # Get WordPress information
    echo ""
    print_info "WordPress Configuration"
    echo ""
    
    read -p "Site Title: " site_title
    read -p "Admin Username: " admin_user
    read -s -p "Admin Password: " admin_pass
    echo ""
    read -p "Admin Email: " admin_email
    
    # Database configuration
    echo ""
    print_info "Database Configuration"
    echo ""
    
    # Check if MySQL is installed
    if ! command -v mysql &> /dev/null; then
        print_error "MySQL/MariaDB is not installed"
        print_info "Please install database first: Menu → 6) Database Management"
        press_any_key
        return
    fi
    
    # Generate database credentials
    DB_NAME="wp_$(echo $domain | sed 's/\./_/g' | cut -c1-20)_$(date +%s | tail -c 5)"
    DB_USER="wp_$(date +%s | tail -c 8)"
    DB_PASS=$(openssl rand -base64 16 | tr -d "=+/" | cut -c1-16)
    
    print_info "Database will be created:"
    echo "  Database: ${DB_NAME}"
    echo "  User: ${DB_USER}"
    echo "  Password: ${DB_PASS}"
    echo ""
    
    read -p "Continue with these credentials? (y/n): " confirm_db
    
    if [[ ! "$confirm_db" =~ ^[Yy]$ ]]; then
        read -p "Enter database name: " DB_NAME
        read -p "Enter database user: " DB_USER
        read -s -p "Enter database password: " DB_PASS
        echo ""
    fi
    
    # Create database
    print_info "Creating database..."
    
    mysql -e "CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" 2>/dev/null
    mysql -e "CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';" 2>/dev/null
    mysql -e "GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'localhost';" 2>/dev/null
    mysql -e "FLUSH PRIVILEGES;" 2>/dev/null
    
    if [ $? -eq 0 ]; then
        print_success "Database created successfully"
    else
        print_error "Failed to create database"
        press_any_key
        return
    fi
    
    # Download WordPress
    print_info "Downloading WordPress..."
    
    cd "$DOMAIN_ROOT"
    
    # Remove existing files if reinstalling
    if [ "$reinstall" = "yes" ]; then
        rm -rf ./*
    fi
    
    sudo -u www-data wp core download --allow-root 2>/dev/null || wp core download --allow-root
    
    if [ $? -ne 0 ]; then
        print_error "Failed to download WordPress"
        press_any_key
        return
    fi
    
    print_success "WordPress downloaded"
    
    # Create wp-config.php
    print_info "Configuring WordPress..."
    
    sudo -u www-data wp config create \
        --dbname="$DB_NAME" \
        --dbuser="$DB_USER" \
        --dbpass="$DB_PASS" \
        --dbhost="localhost" \
        --dbcharset="utf8mb4" \
        --allow-root 2>/dev/null || \
    wp config create \
        --dbname="$DB_NAME" \
        --dbuser="$DB_USER" \
        --dbpass="$DB_PASS" \
        --dbhost="localhost" \
        --dbcharset="utf8mb4" \
        --allow-root
    
    # Add security keys
    wp config shuffle-salts --allow-root
    
    # Install WordPress
    print_info "Installing WordPress..."
    
    SITE_URL="http://${domain}"
    
    sudo -u www-data wp core install \
        --url="$SITE_URL" \
        --title="$site_title" \
        --admin_user="$admin_user" \
        --admin_password="$admin_pass" \
        --admin_email="$admin_email" \
        --allow-root 2>/dev/null || \
    wp core install \
        --url="$SITE_URL" \
        --title="$site_title" \
        --admin_user="$admin_user" \
        --admin_password="$admin_pass" \
        --admin_email="$admin_email" \
        --allow-root
    
    if [ $? -ne 0 ]; then
        print_error "Failed to install WordPress"
        press_any_key
        return
    fi
    
    # Set correct permissions
    chown -R www-data:www-data "$DOMAIN_ROOT"
    find "$DOMAIN_ROOT" -type d -exec chmod 755 {} \;
    find "$DOMAIN_ROOT" -type f -exec chmod 644 {} \;
    
    print_success "WordPress installed successfully!"
    
    # Save credentials
    CREDENTIALS_FILE="${CONFIG_DIR}/wordpress_${domain}_credentials.txt"
    cat > "$CREDENTIALS_FILE" <<EOF
WordPress Installation Credentials
Domain: ${domain}
Install Date: $(date)

WordPress Admin:
- URL: ${SITE_URL}/wp-admin
- Username: ${admin_user}
- Password: ${admin_pass}
- Email: ${admin_email}

Database:
- Name: ${DB_NAME}
- User: ${DB_USER}
- Password: ${DB_PASS}
- Host: localhost

Document Root: ${DOMAIN_ROOT}
EOF
    
    chmod 600 "$CREDENTIALS_FILE"
    
    # Add to WordPress domains list
    if ! grep -q "^${domain}$" "$WORDPRESS_DOMAINS_FILE" 2>/dev/null; then
        echo "$domain" >> "$WORDPRESS_DOMAINS_FILE"
    fi
    
    # Ask about Nginx optimization
    echo ""
    print_info "WordPress installed successfully!"
    echo ""
    echo "Next steps:"
    echo "  1) Configure Nginx for WordPress (Recommended)"
    echo "  2) Install SSL certificate"
    echo "  3) Apply security settings"
    echo ""
    
    read -p "Do you want to configure Nginx optimization now? (y/n): " config_nginx
    
    if [[ "$config_nginx" =~ ^[Yy]$ ]]; then
        configure_wordpress_nginx "$domain"
    fi
    
    echo ""
    print_success "Installation complete!"
    echo ""
    print_info "Credentials saved to: ${CREDENTIALS_FILE}"
    echo ""
    print_info "Access your WordPress:"
    echo "  Frontend: ${SITE_URL}"
    echo "  Admin: ${SITE_URL}/wp-admin"
    echo "  Username: ${admin_user}"
    echo ""
    
    log_action "WordPress installed on domain: ${domain}"
    press_any_key
}

# Configure Nginx for WordPress
configure_wordpress_nginx() {
    local domain=$1
    
    if [ -z "$domain" ]; then
        print_header "Configure WordPress Nginx"
        
        # List WordPress domains
        if [ ! -f "$WORDPRESS_DOMAINS_FILE" ] || [ ! -s "$WORDPRESS_DOMAINS_FILE" ]; then
            print_error "No WordPress installations found"
            press_any_key
            return
        fi
        
        print_info "WordPress domains:"
        cat -n "$WORDPRESS_DOMAINS_FILE"
        
        echo ""
        read -p "Enter domain name: " domain
    fi
    
    if [ -z "$domain" ]; then
        print_error "Domain name is required"
        press_any_key
        return
    fi
    
    # Check if domain has WordPress
    if [ ! -f "/var/www/${domain}/wp-config.php" ]; then
        print_error "WordPress not found on this domain"
        press_any_key
        return
    fi
    
    # Security mode selection
    echo ""
    print_info "Select Nginx Security Mode:"
    echo ""
    echo "  1) Advanced Security (Recommended)"
    echo "     - Block wp-config.php, xmlrpc.php"
    echo "     - Disable file editing"
    echo "     - Restrict wp-admin access"
    echo "     - Rate limiting"
    echo "     - Security headers"
    echo ""
    echo "  2) No Additional Security"
    echo "     - Basic WordPress configuration only"
    echo "     - Performance optimization"
    echo ""
    
    read -p "Enter choice [1-2]: " security_mode
    
    VHOST_FILE="${NGINX_VHOST_DIR}/${domain}"
    
    if [ ! -f "$VHOST_FILE" ]; then
        print_error "Nginx vhost file not found: ${VHOST_FILE}"
        press_any_key
        return
    fi
    
    # Backup current config
    cp "$VHOST_FILE" "${BACKUP_DIR}/${domain}_$(date +%Y%m%d_%H%M%S).conf"
    
    # Detect PHP version
    PHP_VERSION=$(php -v 2>/dev/null | head -1 | cut -d' ' -f2 | cut -d'.' -f1,2)
    if [ -z "$PHP_VERSION" ]; then
        PHP_VERSION="8.1"
    fi
    
    PHP_SOCKET="/var/run/php/php${PHP_VERSION}-fpm.sock"
    
    # Generate Nginx configuration based on security mode
    if [ "$security_mode" = "1" ]; then
        # Advanced Security Mode
        print_info "Applying Advanced Security configuration..."
        
        cat > "$VHOST_FILE" <<EOF
server {
    listen 80;
    listen [::]:80;
    server_name ${domain} www.${domain};
    
    root /var/www/${domain};
    index index.php index.html index.htm;
    
    # Security Headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;
    
    # Rate Limiting
    limit_req zone=one burst=20 nodelay;
    limit_conn addr 10;
    
    # Disable access to hidden files
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }
    
    # Disable access to sensitive files
    location ~* /(?:uploads|files)/.*\.php$ {
        deny all;
    }
    
    location = /xmlrpc.php {
        deny all;
        access_log off;
        log_not_found off;
    }
    
    location = /wp-config.php {
        deny all;
        access_log off;
        log_not_found off;
    }
    
    location ~* ^/wp-content/.*\.(txt|md|exe|sh|bak|inc|pot|po|mo|log|sql)$ {
        deny all;
    }
    
    # Restrict wp-admin access (optional: add IP whitelist)
    location ~ ^/wp-admin/(.*\.php)$ {
        # allow YOUR_IP_HERE;
        # deny all;
        
        try_files \$uri =404;
        fastcgi_pass unix:${PHP_SOCKET};
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
        
        # Security params
        fastcgi_param PHP_VALUE "upload_max_filesize=256M \n post_max_size=256M";
        fastcgi_param PHP_ADMIN_VALUE "open_basedir=/var/www/${domain}:/tmp:/var/tmp:/dev/urandom";
    }
    
    # WordPress permalinks
    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }
    
    # PHP handling
    location ~ \.php$ {
        try_files \$uri =404;
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass unix:${PHP_SOCKET};
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
        
        # FastCGI cache (optional)
        # fastcgi_cache_bypass \$skip_cache;
        # fastcgi_no_cache \$skip_cache;
        # fastcgi_cache fastcgi_cache;
        # fastcgi_cache_valid 200 60m;
        
        # Security params
        fastcgi_param PHP_VALUE "upload_max_filesize=256M \n post_max_size=256M";
        fastcgi_param PHP_ADMIN_VALUE "open_basedir=/var/www/${domain}:/tmp:/var/tmp:/dev/urandom";
    }
    
    # Static files caching
    location ~* \.(jpg|jpeg|gif|png|webp|svg|ico|css|js|woff|woff2|ttf|eot)$ {
        expires 365d;
        add_header Cache-Control "public, immutable";
        access_log off;
    }
    
    # Deny access to readme files
    location ~* ^.+(readme|license|changelog)\.(txt|html)$ {
        deny all;
    }
    
    # Logs
    access_log /var/log/nginx/${domain}_access.log;
    error_log /var/log/nginx/${domain}_error.log;
}
EOF
        
        print_success "Advanced Security configuration applied"
        
        # Add wp-config.php hardening
        WP_CONFIG="/var/www/${domain}/wp-config.php"
        
        if [ -f "$WP_CONFIG" ]; then
            # Disable file editing
            if ! grep -q "DISALLOW_FILE_EDIT" "$WP_CONFIG"; then
                sed -i "/\/\* That's all, stop editing/i define('DISALLOW_FILE_EDIT', true);" "$WP_CONFIG"
                print_success "Disabled file editing in WordPress"
            fi
            
            # Limit post revisions
            if ! grep -q "WP_POST_REVISIONS" "$WP_CONFIG"; then
                sed -i "/\/\* That's all, stop editing/i define('WP_POST_REVISIONS', 3);" "$WP_CONFIG"
            fi
            
            # Auto-save interval
            if ! grep -q "AUTOSAVE_INTERVAL" "$WP_CONFIG"; then
                sed -i "/\/\* That's all, stop editing/i define('AUTOSAVE_INTERVAL', 300);" "$WP_CONFIG"
            fi
        fi
        
    else
        # No Additional Security Mode
        print_info "Applying Basic configuration..."
        
        cat > "$VHOST_FILE" <<EOF
server {
    listen 80;
    listen [::]:80;
    server_name ${domain} www.${domain};
    
    root /var/www/${domain};
    index index.php index.html index.htm;
    
    # WordPress permalinks
    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }
    
    # PHP handling
    location ~ \.php$ {
        try_files \$uri =404;
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass unix:${PHP_SOCKET};
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
        
        fastcgi_param PHP_VALUE "upload_max_filesize=256M \n post_max_size=256M";
    }
    
    # Static files caching
    location ~* \.(jpg|jpeg|gif|png|webp|svg|ico|css|js|woff|woff2|ttf|eot)$ {
        expires 30d;
        add_header Cache-Control "public";
        access_log off;
    }
    
    # Deny access to hidden files
    location ~ /\. {
        deny all;
    }
    
    # Logs
    access_log /var/log/nginx/${domain}_access.log;
    error_log /var/log/nginx/${domain}_error.log;
}
EOF
        
        print_success "Basic configuration applied"
    fi
    
    # Test Nginx configuration
    nginx -t
    
    if [ $? -eq 0 ]; then
        systemctl reload nginx
        print_success "Nginx configuration reloaded successfully"
        
        echo ""
        print_info "WordPress Nginx configuration completed!"
        
        if [ "$security_mode" = "1" ]; then
            echo ""
            print_info "Security features enabled:"
            echo "  ✓ xmlrpc.php blocked"
            echo "  ✓ wp-config.php protected"
            echo "  ✓ File editing disabled"
            echo "  ✓ Security headers added"
            echo "  ✓ Rate limiting enabled"
            echo "  ✓ Sensitive files blocked"
            echo ""
            print_warning "Note: wp-admin IP restriction is commented out"
            print_info "Edit ${VHOST_FILE} to enable IP whitelist for wp-admin"
        fi
        
    else
        print_error "Nginx configuration test failed"
        print_warning "Restoring backup..."
        cp "${BACKUP_DIR}/${domain}_$(date +%Y%m%d)*.conf" "$VHOST_FILE"
        systemctl reload nginx
    fi
    
    log_action "WordPress Nginx configured for domain: ${domain}, security mode: ${security_mode}"
    press_any_key
}

# List WordPress installations
list_wordpress_sites() {
    print_header "WordPress Installations"
    
    if [ ! -f "$WORDPRESS_DOMAINS_FILE" ] || [ ! -s "$WORDPRESS_DOMAINS_FILE" ]; then
        print_info "No WordPress installations found"
        press_any_key
        return
    fi
    
    echo ""
    print_info "WordPress Sites:"
    echo ""
    
    while IFS= read -r domain; do
        WP_ROOT="/var/www/${domain}"
        
        if [ -f "${WP_ROOT}/wp-config.php" ]; then
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "Domain: ${domain}"
            
            # Get WordPress version
            WP_VERSION=$(sudo -u www-data wp core version --path="$WP_ROOT" --allow-root 2>/dev/null || wp core version --path="$WP_ROOT" --allow-root 2>/dev/null)
            echo "Version: ${WP_VERSION:-Unknown}"
            
            # Get site URL
            SITE_URL=$(sudo -u www-data wp option get siteurl --path="$WP_ROOT" --allow-root 2>/dev/null || wp option get siteurl --path="$WP_ROOT" --allow-root 2>/dev/null)
            echo "URL: ${SITE_URL:-http://$domain}"
            
            # Check if SSL enabled
            if echo "$SITE_URL" | grep -q "https://"; then
                echo "SSL: ✓ Enabled"
            else
                echo "SSL: ✗ Not configured"
            fi
            
            # Check credentials file
            CRED_FILE="${CONFIG_DIR}/wordpress_${domain}_credentials.txt"
            if [ -f "$CRED_FILE" ]; then
                echo "Credentials: ${CRED_FILE}"
            fi
            
            # Check security mode
            VHOST_FILE="${NGINX_VHOST_DIR}/${domain}"
            if [ -f "$VHOST_FILE" ]; then
                if grep -q "DISALLOW_FILE_EDIT" "$VHOST_FILE" 2>/dev/null || grep -q "Security Headers" "$VHOST_FILE"; then
                    echo "Security: ✓ Advanced"
                else
                    echo "Security: Basic"
                fi
            fi
            
            echo ""
        fi
    done < "$WORDPRESS_DOMAINS_FILE"
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    press_any_key
}

# Update WordPress
update_wordpress() {
    print_header "Update WordPress"
    
    if [ ! -f "$WORDPRESS_DOMAINS_FILE" ] || [ ! -s "$WORDPRESS_DOMAINS_FILE" ]; then
        print_error "No WordPress installations found"
        press_any_key
        return
    fi
    
    print_info "WordPress domains:"
    cat -n "$WORDPRESS_DOMAINS_FILE"
    
    echo ""
    read -p "Enter domain name (or 'all' for all sites): " domain
    
    if [ "$domain" = "all" ]; then
        while IFS= read -r d; do
            WP_ROOT="/var/www/${d}"
            if [ -f "${WP_ROOT}/wp-config.php" ]; then
                print_info "Updating ${d}..."
                cd "$WP_ROOT"
                wp core update --allow-root
                wp plugin update --all --allow-root
                wp theme update --all --allow-root
                print_success "${d} updated"
            fi
        done < "$WORDPRESS_DOMAINS_FILE"
    else
        WP_ROOT="/var/www/${domain}"
        if [ ! -f "${WP_ROOT}/wp-config.php" ]; then
            print_error "WordPress not found on this domain"
            press_any_key
            return
        fi
        
        print_info "Updating WordPress..."
        cd "$WP_ROOT"
        
        # Backup before update
        print_info "Creating backup..."
        tar -czf "${BACKUP_DIR}/wordpress_${domain}_pre_update_$(date +%Y%m%d_%H%M%S).tar.gz" "$WP_ROOT"
        
        # Update core
        wp core update --allow-root
        
        # Update plugins
        print_info "Updating plugins..."
        wp plugin update --all --allow-root
        
        # Update themes
        print_info "Updating themes..."
        wp theme update --all --allow-root
        
        print_success "WordPress updated successfully"
    fi
    
    log_action "WordPress updated: ${domain}"
    press_any_key
}

# Remove WordPress
remove_wordpress() {
    print_header "Remove WordPress"
    
    if [ ! -f "$WORDPRESS_DOMAINS_FILE" ] || [ ! -s "$WORDPRESS_DOMAINS_FILE" ]; then
        print_error "No WordPress installations found"
        press_any_key
        return
    fi
    
    print_info "WordPress domains:"
    cat -n "$WORDPRESS_DOMAINS_FILE"
    
    echo ""
    read -p "Enter domain name: " domain
    
    if [ -z "$domain" ]; then
        print_error "Domain name is required"
        press_any_key
        return
    fi
    
    WP_ROOT="/var/www/${domain}"
    
    if [ ! -f "${WP_ROOT}/wp-config.php" ]; then
        print_error "WordPress not found on this domain"
        press_any_key
        return
    fi
    
    print_warning "This will remove WordPress and its database!"
    print_warning "Domain: ${domain}"
    print_warning "Path: ${WP_ROOT}"
    echo ""
    
    read -p "Are you sure? (yes/no): " confirm
    
    if [ "$confirm" != "yes" ]; then
        print_info "Cancelled"
        return
    fi
    
    # Backup before removal
    print_info "Creating final backup..."
    tar -czf "${BACKUP_DIR}/wordpress_${domain}_final_$(date +%Y%m%d_%H%M%S).tar.gz" "$WP_ROOT"
    
    # Get database credentials
    cd "$WP_ROOT"
    DB_NAME=$(wp config get DB_NAME --allow-root 2>/dev/null)
    DB_USER=$(wp config get DB_USER --allow-root 2>/dev/null)
    
    # Remove database
    if [ -n "$DB_NAME" ]; then
        print_info "Removing database: ${DB_NAME}"
        mysql -e "DROP DATABASE IF EXISTS \`${DB_NAME}\`;" 2>/dev/null
        
        if [ -n "$DB_USER" ]; then
            mysql -e "DROP USER IF EXISTS '${DB_USER}'@'localhost';" 2>/dev/null
        fi
        
        print_success "Database removed"
    fi
    
    # Remove WordPress files
    print_info "Removing WordPress files..."
    rm -rf "$WP_ROOT"
    
    # Remove from list
    sed -i "/^${domain}$/d" "$WORDPRESS_DOMAINS_FILE"
    
    # Remove credentials file
    rm -f "${CONFIG_DIR}/wordpress_${domain}_credentials.txt"
    
    print_success "WordPress removed successfully"
    print_info "Backup saved to: ${BACKUP_DIR}/wordpress_${domain}_final_*.tar.gz"
    
    log_action "WordPress removed from domain: ${domain}"
    press_any_key
}

# WordPress security hardening
wordpress_security_hardening() {
    print_header "WordPress Security Hardening"
    
    if [ ! -f "$WORDPRESS_DOMAINS_FILE" ] || [ ! -s "$WORDPRESS_DOMAINS_FILE" ]; then
        print_error "No WordPress installations found"
        press_any_key
        return
    fi
    
    print_info "WordPress domains:"
    cat -n "$WORDPRESS_DOMAINS_FILE"
    
    echo ""
    read -p "Enter domain name: " domain
    
    if [ -z "$domain" ]; then
        print_error "Domain name is required"
        press_any_key
        return
    fi
    
    WP_ROOT="/var/www/${domain}"
    WP_CONFIG="${WP_ROOT}/wp-config.php"
    
    if [ ! -f "$WP_CONFIG" ]; then
        print_error "WordPress not found on this domain"
        press_any_key
        return
    fi
    
    # Backup wp-config.php
    cp "$WP_CONFIG" "${BACKUP_DIR}/wp-config_${domain}_$(date +%Y%m%d_%H%M%S).php"
    
    print_info "Applying security hardening..."
    
    cd "$WP_ROOT"
    
    # 1. Disable file editing
    if ! grep -q "DISALLOW_FILE_EDIT" "$WP_CONFIG"; then
        sed -i "/\/\* That's all, stop editing/i define('DISALLOW_FILE_EDIT', true);" "$WP_CONFIG"
        print_success "✓ Disabled file editing"
    fi
    
    # 2. Disable plugin/theme installation
    if ! grep -q "DISALLOW_FILE_MODS" "$WP_CONFIG"; then
        sed -i "/\/\* That's all, stop editing/i define('DISALLOW_FILE_MODS', true);" "$WP_CONFIG"
        print_success "✓ Disabled plugin/theme installation"
    fi
    
    # 3. Limit post revisions
    if ! grep -q "WP_POST_REVISIONS" "$WP_CONFIG"; then
        sed -i "/\/\* That's all, stop editing/i define('WP_POST_REVISIONS', 3);" "$WP_CONFIG"
        print_success "✓ Limited post revisions to 3"
    fi
    
    # 4. Set auto-save interval
    if ! grep -q "AUTOSAVE_INTERVAL" "$WP_CONFIG"; then
        sed -i "/\/\* That's all, stop editing/i define('AUTOSAVE_INTERVAL', 300);" "$WP_CONFIG"
        print_success "✓ Set auto-save interval to 5 minutes"
    fi
    
    # 5. Disable debug mode (if enabled)
    sed -i "s/define('WP_DEBUG', true)/define('WP_DEBUG', false)/g" "$WP_CONFIG"
    print_success "✓ Disabled debug mode"
    
    # 6. Set correct file permissions
    print_info "Setting correct file permissions..."
    chown -R www-data:www-data "$WP_ROOT"
    find "$WP_ROOT" -type d -exec chmod 755 {} \;
    find "$WP_ROOT" -type f -exec chmod 644 {} \;
    chmod 600 "$WP_CONFIG"
    print_success "✓ File permissions set"
    
    # 7. Remove default plugins
    print_info "Checking for unused plugins..."
    wp plugin delete hello akismet --allow-root 2>/dev/null
    
    # 8. Update security keys
    print_info "Regenerating security keys..."
    wp config shuffle-salts --allow-root
    print_success "✓ Security keys regenerated"
    
    echo ""
    print_success "Security hardening completed!"
    
    log_action "WordPress security hardening applied: ${domain}"
    press_any_key
}

# WordPress menu
wordpress_menu() {
    while true; do
        show_header
        echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║                 WORDPRESS MANAGEMENT MENU                     ║${NC}"
        echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo "  1) Install WP-CLI"
        echo "  2) Install WordPress on Domain"
        echo "  3) Configure WordPress Nginx (Security)"
        echo "  4) List WordPress Installations"
        echo "  5) Update WordPress (Core/Plugins/Themes)"
        echo "  6) WordPress Security Hardening"
        echo "  7) Remove WordPress from Domain"
        echo ""
        echo "  0) Back to Main Menu"
        echo ""
        echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
        
        read -p "Enter your choice [0-7]: " choice
        
        case $choice in
            1) install_wp_cli ;;
            2) install_wordpress ;;
            3) configure_wordpress_nginx ;;
            4) list_wordpress_sites ;;
            5) update_wordpress ;;
            6) wordpress_security_hardening ;;
            7) remove_wordpress ;;
            0) return ;;
            *)
                print_error "Invalid choice"
                sleep 1
                ;;
        esac
    done
}
