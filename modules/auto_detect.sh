#!/bin/bash

# ==============================================================================
# RocketVPS v2.2.0 - Auto-Detect & Auto-Configure System (Phase 2 Week 7-8)
# ==============================================================================
# File: modules/auto_detect.sh
# Description: Intelligent site type detection and automatic configuration
# Version: 2.2.0
# Author: RocketVPS Team
# ==============================================================================

# Source required modules
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/utils.sh" 2>/dev/null || true

# ==============================================================================
# CONFIGURATION
# ==============================================================================

AUTO_DETECT_DIR="/opt/rocketvps/auto_detect"
AUTO_DETECT_CACHE="${AUTO_DETECT_DIR}/cache"

# ==============================================================================
# INITIALIZATION
# ==============================================================================

auto_detect_init() {
    mkdir -p "${AUTO_DETECT_DIR}"
    mkdir -p "${AUTO_DETECT_CACHE}"
    chmod 700 "${AUTO_DETECT_DIR}"
    chmod 700 "${AUTO_DETECT_CACHE}"
}

# ==============================================================================
# SITE TYPE DETECTION
# ==============================================================================

# Detect site type
detect_site_type() {
    local domain="$1"
    local web_root="/var/www/${domain}"
    
    if [[ ! -d "$web_root" ]]; then
        echo "UNKNOWN"
        return 1
    fi
    
    # Check for WordPress
    if [[ -f "${web_root}/wp-config.php" ]]; then
        echo "WORDPRESS"
        return 0
    fi
    
    # Check for Laravel
    if [[ -f "${web_root}/artisan" ]] && [[ -f "${web_root}/composer.json" ]]; then
        if grep -q "laravel/framework" "${web_root}/composer.json" 2>/dev/null; then
            echo "LARAVEL"
            return 0
        fi
    fi
    
    # Check for Node.js
    if [[ -f "${web_root}/package.json" ]]; then
        # Check for common Node.js frameworks
        if grep -qE "express|next|nuxt|react|vue" "${web_root}/package.json" 2>/dev/null; then
            echo "NODEJS"
            return 0
        fi
    fi
    
    # Check for Static HTML
    if [[ -f "${web_root}/index.html" ]] || [[ -f "${web_root}/index.htm" ]]; then
        # No dynamic files found
        if [[ ! -f "${web_root}/index.php" ]] && \
           [[ ! -f "${web_root}/package.json" ]] && \
           [[ ! -f "${web_root}/composer.json" ]]; then
            echo "STATIC"
            return 0
        fi
    fi
    
    # Check for Generic PHP
    if [[ -f "${web_root}/index.php" ]] || [[ -f "${web_root}/composer.json" ]]; then
        echo "PHP"
        return 0
    fi
    
    echo "UNKNOWN"
    return 1
}

# Detect site framework details
detect_site_framework() {
    local domain="$1"
    local site_type=$(detect_site_type "$domain")
    local web_root="/var/www/${domain}"
    local framework_info=""
    
    case "$site_type" in
        WORDPRESS)
            # Detect WordPress version
            if [[ -f "${web_root}/wp-includes/version.php" ]]; then
                local wp_version=$(grep "wp_version =" "${web_root}/wp-includes/version.php" | cut -d"'" -f2)
                framework_info="WordPress ${wp_version}"
            else
                framework_info="WordPress"
            fi
            ;;
        LARAVEL)
            # Detect Laravel version
            if [[ -f "${web_root}/composer.json" ]]; then
                local laravel_version=$(grep '"laravel/framework"' "${web_root}/composer.json" | cut -d'"' -f4)
                framework_info="Laravel ${laravel_version}"
            else
                framework_info="Laravel"
            fi
            ;;
        NODEJS)
            # Detect Node.js framework
            if [[ -f "${web_root}/package.json" ]]; then
                local framework=$(grep -oE '"(next|nuxt|express|react|vue)"' "${web_root}/package.json" 2>/dev/null | head -1 | tr -d '"')
                framework_info="Node.js (${framework})"
            else
                framework_info="Node.js"
            fi
            ;;
        PHP)
            # Detect PHP framework
            if [[ -f "${web_root}/composer.json" ]]; then
                local framework=$(grep -oE '"(symfony|codeigniter|yii|cakephp)"' "${web_root}/composer.json" 2>/dev/null | head -1 | tr -d '"')
                if [[ -n "$framework" ]]; then
                    framework_info="PHP (${framework})"
                else
                    framework_info="Generic PHP"
                fi
            else
                framework_info="Generic PHP"
            fi
            ;;
        STATIC)
            framework_info="Static HTML"
            ;;
        *)
            framework_info="Unknown"
            ;;
    esac
    
    echo "$framework_info"
}

# Detect PHP version requirement
detect_php_version() {
    local domain="$1"
    local web_root="/var/www/${domain}"
    local site_type=$(detect_site_type "$domain")
    
    case "$site_type" in
        WORDPRESS)
            # WordPress recommendations
            echo "8.1"  # WordPress recommends PHP 8.1+
            ;;
        LARAVEL)
            # Check composer.json for PHP version
            if [[ -f "${web_root}/composer.json" ]]; then
                local php_req=$(grep '"php"' "${web_root}/composer.json" | cut -d'"' -f4 | sed 's/[^0-9.]//g')
                if [[ -n "$php_req" ]]; then
                    echo "${php_req}"
                else
                    echo "8.2"  # Laravel 10+ requires PHP 8.2
                fi
            else
                echo "8.2"
            fi
            ;;
        PHP)
            # Generic PHP - check composer.json
            if [[ -f "${web_root}/composer.json" ]]; then
                local php_req=$(grep '"php"' "${web_root}/composer.json" | cut -d'"' -f4 | sed 's/[^0-9.]//g')
                [[ -n "$php_req" ]] && echo "${php_req}" || echo "8.1"
            else
                echo "8.1"
            fi
            ;;
        *)
            echo "8.1"  # Default
            ;;
    esac
}

# ==============================================================================
# CONFIGURATION EXTRACTION
# ==============================================================================

# Extract database configuration
extract_database_config() {
    local domain="$1"
    local web_root="/var/www/${domain}"
    local site_type=$(detect_site_type "$domain")
    
    local db_name=""
    local db_user=""
    local db_pass=""
    local db_host="localhost"
    local db_port="3306"
    
    case "$site_type" in
        WORDPRESS)
            if [[ -f "${web_root}/wp-config.php" ]]; then
                db_name=$(grep "DB_NAME" "${web_root}/wp-config.php" 2>/dev/null | cut -d"'" -f4 | head -1)
                db_user=$(grep "DB_USER" "${web_root}/wp-config.php" 2>/dev/null | cut -d"'" -f4 | head -1)
                db_pass=$(grep "DB_PASSWORD" "${web_root}/wp-config.php" 2>/dev/null | cut -d"'" -f4 | head -1)
                db_host=$(grep "DB_HOST" "${web_root}/wp-config.php" 2>/dev/null | cut -d"'" -f4 | head -1)
            fi
            ;;
        LARAVEL|PHP)
            if [[ -f "${web_root}/.env" ]]; then
                db_name=$(grep "^DB_DATABASE=" "${web_root}/.env" 2>/dev/null | cut -d"=" -f2 | tr -d '"' | head -1)
                db_user=$(grep "^DB_USERNAME=" "${web_root}/.env" 2>/dev/null | cut -d"=" -f2 | tr -d '"' | head -1)
                db_pass=$(grep "^DB_PASSWORD=" "${web_root}/.env" 2>/dev/null | cut -d"=" -f2 | tr -d '"' | head -1)
                db_host=$(grep "^DB_HOST=" "${web_root}/.env" 2>/dev/null | cut -d"=" -f2 | tr -d '"' | head -1)
                db_port=$(grep "^DB_PORT=" "${web_root}/.env" 2>/dev/null | cut -d"=" -f2 | tr -d '"' | head -1)
            fi
            ;;
    esac
    
    # Default values if not found
    [[ -z "$db_host" ]] && db_host="localhost"
    [[ -z "$db_port" ]] && db_port="3306"
    
    cat <<EOF
{
    "db_name": "${db_name}",
    "db_user": "${db_user}",
    "db_pass": "${db_pass}",
    "db_host": "${db_host}",
    "db_port": "${db_port}"
}
EOF
}

# Extract Node.js configuration
extract_nodejs_config() {
    local domain="$1"
    local web_root="/var/www/${domain}"
    
    local node_version=""
    local npm_version=""
    local start_command=""
    local port="3000"
    
    if [[ -f "${web_root}/package.json" ]]; then
        # Get Node.js version requirement
        node_version=$(grep '"node"' "${web_root}/package.json" 2>/dev/null | cut -d'"' -f4 || echo "18")
        
        # Get start command
        start_command=$(grep '"start"' "${web_root}/package.json" 2>/dev/null | cut -d'"' -f4 || echo "npm start")
        
        # Try to detect port from common files
        if [[ -f "${web_root}/.env" ]]; then
            port=$(grep "^PORT=" "${web_root}/.env" 2>/dev/null | cut -d"=" -f2 | head -1)
        fi
        [[ -z "$port" ]] && port="3000"
    fi
    
    cat <<EOF
{
    "node_version": "${node_version}",
    "start_command": "${start_command}",
    "port": "${port}"
}
EOF
}

# ==============================================================================
# AUTO-CONFIGURATION
# ==============================================================================

# Generate Nginx configuration based on site type
generate_nginx_config() {
    local domain="$1"
    local site_type=$(detect_site_type "$domain")
    local php_version=$(detect_php_version "$domain")
    local web_root="/var/www/${domain}"
    
    case "$site_type" in
        WORDPRESS)
            cat <<EOF
server {
    listen 80;
    listen [::]:80;
    server_name ${domain} www.${domain};
    root ${web_root};
    index index.php index.html;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/x-javascript application/xml+rss application/json;

    # WordPress specific
    location = /favicon.ico {
        log_not_found off;
        access_log off;
    }

    location = /robots.txt {
        allow all;
        log_not_found off;
        access_log off;
    }

    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php${php_version}-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
        expires 1y;
        log_not_found off;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF
            ;;
        LARAVEL)
            cat <<EOF
server {
    listen 80;
    listen [::]:80;
    server_name ${domain} www.${domain};
    root ${web_root}/public;
    index index.php index.html;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/x-javascript application/xml+rss application/json;

    # Laravel specific
    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php${php_version}-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$realpath_root\$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
        expires 1y;
        log_not_found off;
    }

    location ~ /\.(?!well-known).* {
        deny all;
    }
}
EOF
            ;;
        NODEJS)
            local nodejs_config=$(extract_nodejs_config "$domain")
            local port=$(echo "$nodejs_config" | grep '"port"' | cut -d'"' -f4)
            
            cat <<EOF
server {
    listen 80;
    listen [::]:80;
    server_name ${domain} www.${domain};

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/x-javascript application/xml+rss application/json;

    # Proxy to Node.js app
    location / {
        proxy_pass http://localhost:${port};
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
        root ${web_root}/public;
        expires 1y;
        log_not_found off;
    }
}
EOF
            ;;
        STATIC)
            cat <<EOF
server {
    listen 80;
    listen [::]:80;
    server_name ${domain} www.${domain};
    root ${web_root};
    index index.html index.htm;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/x-javascript application/xml+rss application/json;

    location / {
        try_files \$uri \$uri/ =404;
    }

    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        log_not_found off;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF
            ;;
        PHP)
            cat <<EOF
server {
    listen 80;
    listen [::]:80;
    server_name ${domain} www.${domain};
    root ${web_root};
    index index.php index.html;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/x-javascript application/xml+rss application/json;

    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php${php_version}-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
        expires 1y;
        log_not_found off;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF
            ;;
    esac
}

# Auto-configure domain
auto_configure_domain() {
    local domain="$1"
    
    log_section "Auto-Configuring Domain: ${domain}"
    
    # Detect site type
    local site_type=$(detect_site_type "$domain")
    log_info "Detected site type: ${site_type}"
    
    # Detect framework
    local framework=$(detect_site_framework "$domain")
    log_info "Framework: ${framework}"
    
    # Generate Nginx config
    log_info "Generating Nginx configuration..."
    local nginx_config=$(generate_nginx_config "$domain")
    echo "$nginx_config" > "/etc/nginx/sites-available/${domain}"
    
    # Enable site
    if [[ ! -L "/etc/nginx/sites-enabled/${domain}" ]]; then
        ln -s "/etc/nginx/sites-available/${domain}" "/etc/nginx/sites-enabled/${domain}"
    fi
    
    # Test and reload Nginx
    if nginx -t 2>/dev/null; then
        systemctl reload nginx
        log_success "Nginx configured and reloaded"
    else
        log_error "Nginx configuration test failed"
        return 1
    fi
    
    # Fix permissions
    log_info "Fixing permissions..."
    fix_permissions "$domain"
    
    # Setup cache if applicable
    if [[ "$site_type" == "WORDPRESS" ]] || [[ "$site_type" == "LARAVEL" ]]; then
        log_info "Setting up cache..."
        setup_cache "$domain" "$site_type"
    fi
    
    log_success "Auto-configuration completed for ${domain}"
}

# Fix file permissions
fix_permissions() {
    local domain="$1"
    local web_root="/var/www/${domain}"
    local site_type=$(detect_site_type "$domain")
    
    # Set directory permissions
    find "${web_root}" -type d -exec chmod 755 {} \; 2>/dev/null
    
    # Set file permissions
    find "${web_root}" -type f -exec chmod 644 {} \; 2>/dev/null
    
    # Site-specific permissions
    case "$site_type" in
        WORDPRESS)
            # WordPress uploads directory
            if [[ -d "${web_root}/wp-content/uploads" ]]; then
                chmod -R 775 "${web_root}/wp-content/uploads"
            fi
            
            # WordPress cache directory
            if [[ -d "${web_root}/wp-content/cache" ]]; then
                chmod -R 775 "${web_root}/wp-content/cache"
            fi
            ;;
        LARAVEL)
            # Laravel storage and cache
            if [[ -d "${web_root}/storage" ]]; then
                chmod -R 775 "${web_root}/storage"
            fi
            
            if [[ -d "${web_root}/bootstrap/cache" ]]; then
                chmod -R 775 "${web_root}/bootstrap/cache"
            fi
            ;;
    esac
    
    # Set ownership
    chown -R www-data:www-data "${web_root}" 2>/dev/null
}

# Setup cache
setup_cache() {
    local domain="$1"
    local site_type="$2"
    
    case "$site_type" in
        WORDPRESS)
            # Check if Redis is available
            if command -v redis-cli >/dev/null 2>&1; then
                log_info "Redis available - can install object cache plugin"
            fi
            ;;
        LARAVEL)
            # Check if Redis is available
            if command -v redis-cli >/dev/null 2>&1; then
                log_info "Redis available - update .env for cache driver"
            fi
            ;;
    esac
}

# ==============================================================================
# BULK AUTO-DETECTION
# ==============================================================================

# Auto-detect all domains
auto_detect_all_domains() {
    log_section "Auto-Detecting All Domains"
    
    local domains=()
    if [[ -d "/var/www" ]]; then
        for domain_dir in /var/www/*/; do
            if [[ -d "$domain_dir" ]]; then
                local domain=$(basename "$domain_dir")
                if [[ "$domain" != "html" ]] && [[ "$domain" != "default" ]]; then
                    domains+=("$domain")
                fi
            fi
        done
    fi
    
    if [[ ${#domains[@]} -eq 0 ]]; then
        log_info "No domains found"
        return 0
    fi
    
    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║          Auto-Detection Report"
    echo "╠════════════════════════════════════════════════════════════╣"
    echo "║"
    
    for domain in "${domains[@]}"; do
        local site_type=$(detect_site_type "$domain")
        local framework=$(detect_site_framework "$domain")
        local php_version=$(detect_php_version "$domain")
        
        echo "║  Domain: ${domain}"
        echo "║    Type: ${site_type}"
        echo "║    Framework: ${framework}"
        echo "║    Recommended PHP: ${php_version}"
        
        # Database info
        if [[ "$site_type" != "STATIC" ]] && [[ "$site_type" != "UNKNOWN" ]]; then
            local db_config=$(extract_database_config "$domain")
            local db_name=$(echo "$db_config" | grep '"db_name"' | cut -d'"' -f4)
            if [[ -n "$db_name" ]]; then
                echo "║    Database: ${db_name}"
            fi
        fi
        
        echo "║"
    done
    
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
}

# ==============================================================================
# EXPORTS
# ==============================================================================

auto_detect_init

export -f detect_site_type
export -f detect_site_framework
export -f detect_php_version
export -f extract_database_config
export -f extract_nodejs_config
export -f generate_nginx_config
export -f auto_configure_domain
export -f fix_permissions
export -f auto_detect_all_domains

log_success "Auto-Detect module loaded successfully"
