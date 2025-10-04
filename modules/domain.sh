#!/bin/bash

################################################################################
# RocketVPS - Domain Management Module
################################################################################

# Domain menu
domain_menu() {
    while true; do
        show_header
        echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║                   DOMAIN MANAGEMENT                           ║${NC}"
        echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo "  1) Add New Domain"
        echo "  2) List All Domains"
        echo "  3) Edit Domain Configuration"
        echo "  4) Delete Domain"
        echo "  5) Enable Domain"
        echo "  6) Disable Domain"
        echo "  7) View Domain Configuration"
        echo "  8) Test Domain Configuration"
        echo ""
        echo "  0) Back to Main Menu"
        echo ""
        echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
        
        read -p "Enter your choice [0-8]: " domain_choice
        
        case $domain_choice in
            1) add_domain ;;
            2) list_domains ;;
            3) edit_domain ;;
            4) delete_domain ;;
            5) enable_domain ;;
            6) disable_domain ;;
            7) view_domain_config ;;
            8) test_domain_config ;;
            0) return ;;
            *)
                print_error "Invalid choice"
                sleep 2
                ;;
        esac
    done
}

# Add new domain
add_domain() {
    show_header
    echo -e "${CYAN}Add New Domain${NC}"
    echo ""
    
    read -p "Enter domain name (e.g., example.com): " domain_name
    
    if [ -z "$domain_name" ]; then
        print_error "Domain name cannot be empty"
        press_any_key
        return
    fi
    
    # Check if domain already exists
    if [ -f "${NGINX_VHOST_DIR}/${domain_name}" ]; then
        print_error "Domain $domain_name already exists"
        press_any_key
        return
    fi
    
    read -p "Enter root directory (default: /var/www/${domain_name}/public_html): " root_dir
    root_dir=${root_dir:-/var/www/${domain_name}/public_html}
    
    echo ""
    echo "Select site type:"
    echo "1) Static HTML"
    echo "2) PHP"
    echo "3) PHP with FastCGI Cache"
    echo "4) WordPress"
    echo "5) Laravel"
    echo "6) Node.js Proxy"
    read -p "Enter choice [1-6]: " site_type
    
    # Create root directory
    mkdir -p "$root_dir"
    
    # Create appropriate configuration
    case $site_type in
        1) create_static_vhost "$domain_name" "$root_dir" ;;
        2) create_php_vhost "$domain_name" "$root_dir" ;;
        3) create_php_cache_vhost "$domain_name" "$root_dir" ;;
        4) create_wordpress_vhost "$domain_name" "$root_dir" ;;
        5) create_laravel_vhost "$domain_name" "$root_dir" ;;
        6) 
            read -p "Enter Node.js application port: " node_port
            create_nodejs_vhost "$domain_name" "$root_dir" "$node_port"
            ;;
        *)
            print_error "Invalid site type"
            press_any_key
            return
            ;;
    esac
    
    # Set permissions
    chown -R www-data:www-data "$root_dir"
    chmod -R 755 "$root_dir"
    
    # Enable site
    ln -sf "${NGINX_VHOST_DIR}/${domain_name}" "${NGINX_ENABLED_DIR}/${domain_name}"
    
    # Add to domain list
    echo "$domain_name|$root_dir|$(date +%Y-%m-%d)" >> "${DOMAIN_LIST_FILE}"
    
    # Create default index file
    if [ "$site_type" -le 4 ]; then
        create_default_index "$root_dir" "$domain_name"
    fi
    
    # Test and reload Nginx
    if nginx -t; then
        systemctl reload nginx
        print_success "Domain $domain_name added successfully"
        
        # Auto-setup phpMyAdmin for PHP-based sites
        if [ "$site_type" -ge 2 ] && [ "$site_type" -le 5 ]; then
            echo ""
            print_info "Setting up phpMyAdmin for ${domain_name}..."
            sleep 1
            
            if auto_setup_phpmyadmin_for_domain "$domain_name" "$root_dir"; then
                print_success "phpMyAdmin configured automatically"
            else
                print_warning "phpMyAdmin setup skipped (not installed or failed)"
            fi
        fi
        
        # Auto-create database accounts for domain
        echo ""
        print_info "Creating database accounts for ${domain_name}..."
        sleep 1
        
        if auto_create_domain_databases "$domain_name"; then
            print_success "Database accounts created successfully"
        else
            print_warning "Database creation skipped or failed"
        fi
        
        # Display complete domain information
        sleep 1
        display_domain_complete_info "$domain_name" "$root_dir"
        
        # Display database credentials
        echo ""
        display_domain_database_info "$domain_name"
    else
        print_error "Nginx configuration test failed"
        rm -f "${NGINX_VHOST_DIR}/${domain_name}"
        rm -f "${NGINX_ENABLED_DIR}/${domain_name}"
        press_any_key
    fi
}

# Create static HTML vhost
create_static_vhost() {
    local domain=$1
    local root=$2
    
    cat > "${NGINX_VHOST_DIR}/${domain}" <<EOF
server {
    listen 80;
    listen [::]:80;
    
    server_name ${domain} www.${domain};
    root ${root};
    index index.html index.htm;
    
    access_log /var/log/nginx/${domain}_access.log;
    error_log /var/log/nginx/${domain}_error.log;
    
    location / {
        try_files \$uri \$uri/ =404;
    }
    
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|svg|woff|woff2|ttf|eot)$ {
        expires 365d;
        add_header Cache-Control "public, immutable";
    }
    
    location ~ /\.ht {
        deny all;
    }
}
EOF
}

# Create PHP vhost
create_php_vhost() {
    local domain=$1
    local root=$2
    
    # Detect PHP-FPM socket
    local php_socket=$(find /var/run/php/ -name "php*-fpm.sock" | head -1)
    if [ -z "$php_socket" ]; then
        php_socket="/var/run/php/php-fpm.sock"
    fi
    
    cat > "${NGINX_VHOST_DIR}/${domain}" <<EOF
server {
    listen 80;
    listen [::]:80;
    
    server_name ${domain} www.${domain};
    root ${root};
    index index.php index.html index.htm;
    
    access_log /var/log/nginx/${domain}_access.log;
    error_log /var/log/nginx/${domain}_error.log;
    
    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }
    
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:${php_socket};
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }
    
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|svg|woff|woff2|ttf|eot)$ {
        expires 365d;
        add_header Cache-Control "public, immutable";
    }
    
    location ~ /\.ht {
        deny all;
    }
}
EOF
}

# Create PHP with cache vhost
create_php_cache_vhost() {
    local domain=$1
    local root=$2
    
    local php_socket=$(find /var/run/php/ -name "php*-fpm.sock" | head -1)
    if [ -z "$php_socket" ]; then
        php_socket="/var/run/php/php-fpm.sock"
    fi
    
    cat > "${NGINX_VHOST_DIR}/${domain}" <<EOF
server {
    listen 80;
    listen [::]:80;
    
    server_name ${domain} www.${domain};
    root ${root};
    index index.php index.html index.htm;
    
    access_log /var/log/nginx/${domain}_access.log;
    error_log /var/log/nginx/${domain}_error.log;
    
    set \$skip_cache 0;
    
    # POST requests and URL with query string should always go to PHP
    if (\$request_method = POST) {
        set \$skip_cache 1;
    }
    if (\$query_string != "") {
        set \$skip_cache 1;
    }
    
    # Don't cache URIs containing the following segments
    if (\$request_uri ~* "/wp-admin/|/xmlrpc.php|wp-.*.php|/feed/|index.php|sitemap(_index)?.xml") {
        set \$skip_cache 1;
    }
    
    # Don't use cache for logged in users or recent commenters
    if (\$http_cookie ~* "comment_author|wordpress_[a-f0-9]+|wp-postpass|wordpress_no_cache|wordpress_logged_in") {
        set \$skip_cache 1;
    }
    
    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }
    
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:${php_socket};
        fastcgi_cache fastcgi_cache;
        fastcgi_cache_valid 200 60m;
        fastcgi_cache_bypass \$skip_cache;
        fastcgi_no_cache \$skip_cache;
        add_header X-FastCGI-Cache \$upstream_cache_status;
    }
    
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|svg|woff|woff2|ttf|eot)$ {
        expires 365d;
        add_header Cache-Control "public, immutable";
    }
    
    location ~ /\.ht {
        deny all;
    }
}
EOF
}

# Create WordPress vhost
create_wordpress_vhost() {
    local domain=$1
    local root=$2
    
    local php_socket=$(find /var/run/php/ -name "php*-fpm.sock" | head -1)
    if [ -z "$php_socket" ]; then
        php_socket="/var/run/php/php-fpm.sock"
    fi
    
    cat > "${NGINX_VHOST_DIR}/${domain}" <<EOF
server {
    listen 80;
    listen [::]:80;
    
    server_name ${domain} www.${domain};
    root ${root};
    index index.php;
    
    access_log /var/log/nginx/${domain}_access.log;
    error_log /var/log/nginx/${domain}_error.log;
    
    client_max_body_size 100M;
    
    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }
    
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:${php_socket};
    }
    
    # WordPress: deny access to wp-config.php
    location ~* wp-config.php {
        deny all;
    }
    
    # WordPress: deny access to .htaccess files
    location ~ /\.ht {
        deny all;
    }
    
    # WordPress: deny access to wp-content/uploads PHP files
    location ~* ^/wp-content/uploads/.*\.php$ {
        deny all;
    }
    
    # Cache static files
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|svg|woff|woff2|ttf|eot)$ {
        expires 365d;
        add_header Cache-Control "public, immutable";
    }
}
EOF
}

# Create Laravel vhost
create_laravel_vhost() {
    local domain=$1
    local root=$2
    
    local php_socket=$(find /var/run/php/ -name "php*-fpm.sock" | head -1)
    if [ -z "$php_socket" ]; then
        php_socket="/var/run/php/php-fpm.sock"
    fi
    
    cat > "${NGINX_VHOST_DIR}/${domain}" <<EOF
server {
    listen 80;
    listen [::]:80;
    
    server_name ${domain} www.${domain};
    root ${root}/public;
    index index.php;
    
    access_log /var/log/nginx/${domain}_access.log;
    error_log /var/log/nginx/${domain}_error.log;
    
    client_max_body_size 100M;
    
    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }
    
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:${php_socket};
    }
    
    location ~ /\.(?!well-known).* {
        deny all;
    }
}
EOF
}

# Create Node.js proxy vhost
create_nodejs_vhost() {
    local domain=$1
    local root=$2
    local port=$3
    
    cat > "${NGINX_VHOST_DIR}/${domain}" <<EOF
server {
    listen 80;
    listen [::]:80;
    
    server_name ${domain} www.${domain};
    
    access_log /var/log/nginx/${domain}_access.log;
    error_log /var/log/nginx/${domain}_error.log;
    
    location / {
        proxy_pass http://127.0.0.1:${port};
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF
}

# Create default index file
create_default_index() {
    local root=$1
    local domain=$2
    
    cat > "${root}/index.html" <<EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Welcome to ${domain}</title>
    <style>
        body { font-family: Arial, sans-serif; text-align: center; margin-top: 50px; }
        h1 { color: #2c3e50; }
        p { color: #7f8c8d; }
        .logo { font-size: 60px; }
    </style>
</head>
<body>
    <div class="logo">🚀</div>
    <h1>Welcome to ${domain}</h1>
    <p>This site is powered by RocketVPS</p>
    <p>Site created on $(date)</p>
</body>
</html>
EOF
}

# List all domains
list_domains() {
    show_header
    echo -e "${CYAN}All Managed Domains:${NC}"
    echo ""
    
    if [ ! -s "${DOMAIN_LIST_FILE}" ]; then
        print_warning "No domains found"
        press_any_key
        return
    fi
    
    echo -e "${GREEN}Domain Name                 | Root Directory                    | Date Added${NC}"
    echo "─────────────────────────────────────────────────────────────────────────────────"
    
    while IFS='|' read -r domain root date_added; do
        printf "%-27s | %-33s | %s\n" "$domain" "$root" "$date_added"
    done < "${DOMAIN_LIST_FILE}"
    
    echo ""
    press_any_key
}

# Edit domain configuration
edit_domain() {
    list_domains
    echo ""
    read -p "Enter domain name to edit: " domain_name
    
    if [ ! -f "${NGINX_VHOST_DIR}/${domain_name}" ]; then
        print_error "Domain $domain_name not found"
        press_any_key
        return
    fi
    
    # Open in default editor
    ${EDITOR:-nano} "${NGINX_VHOST_DIR}/${domain_name}"
    
    # Test configuration
    if nginx -t; then
        systemctl reload nginx
        print_success "Domain $domain_name updated successfully"
    else
        print_error "Configuration test failed. Please fix errors."
    fi
    
    press_any_key
}

# Delete domain
delete_domain() {
    list_domains
    echo ""
    read -p "Enter domain name to delete: " domain_name
    
    if [ ! -f "${NGINX_VHOST_DIR}/${domain_name}" ]; then
        print_error "Domain $domain_name not found"
        press_any_key
        return
    fi
    
    print_warning "This will delete the domain configuration (not the files)"
    read -p "Are you sure? (yes/no): " confirm
    
    if [ "$confirm" != "yes" ]; then
        print_info "Deletion cancelled"
        press_any_key
        return
    fi
    
    # Backup configuration
    cp "${NGINX_VHOST_DIR}/${domain_name}" "${BACKUP_DIR}/${domain_name}_$(date +%Y%m%d_%H%M%S).conf"
    
    # Remove configuration
    rm -f "${NGINX_VHOST_DIR}/${domain_name}"
    rm -f "${NGINX_ENABLED_DIR}/${domain_name}"
    
    # Remove from domain list
    sed -i "/^${domain_name}|/d" "${DOMAIN_LIST_FILE}"
    
    # Reload Nginx
    if nginx -t; then
        systemctl reload nginx
        print_success "Domain $domain_name deleted successfully"
        print_info "Configuration backup saved to ${BACKUP_DIR}/"
    fi
    
    press_any_key
}

# Enable domain
enable_domain() {
    list_domains
    echo ""
    read -p "Enter domain name to enable: " domain_name
    
    if [ ! -f "${NGINX_VHOST_DIR}/${domain_name}" ]; then
        print_error "Domain $domain_name not found"
        press_any_key
        return
    fi
    
    ln -sf "${NGINX_VHOST_DIR}/${domain_name}" "${NGINX_ENABLED_DIR}/${domain_name}"
    
    if nginx -t; then
        systemctl reload nginx
        print_success "Domain $domain_name enabled"
    else
        print_error "Configuration test failed"
    fi
    
    press_any_key
}

# Disable domain
disable_domain() {
    list_domains
    echo ""
    read -p "Enter domain name to disable: " domain_name
    
    if [ ! -f "${NGINX_ENABLED_DIR}/${domain_name}" ]; then
        print_error "Domain $domain_name is not enabled"
        press_any_key
        return
    fi
    
    rm -f "${NGINX_ENABLED_DIR}/${domain_name}"
    
    if nginx -t; then
        systemctl reload nginx
        print_success "Domain $domain_name disabled"
    else
        print_error "Configuration test failed"
    fi
    
    press_any_key
}

# View domain configuration
view_domain_config() {
    list_domains
    echo ""
    read -p "Enter domain name to view: " domain_name
    
    if [ ! -f "${NGINX_VHOST_DIR}/${domain_name}" ]; then
        print_error "Domain $domain_name not found"
        press_any_key
        return
    fi
    
    show_header
    echo -e "${CYAN}Configuration for ${domain_name}:${NC}"
    echo ""
    cat "${NGINX_VHOST_DIR}/${domain_name}"
    echo ""
    press_any_key
}

# Test domain configuration
test_domain_config() {
    list_domains
    echo ""
    read -p "Enter domain name to test: " domain_name
    
    if [ ! -f "${NGINX_VHOST_DIR}/${domain_name}" ]; then
        print_error "Domain $domain_name not found"
        press_any_key
        return
    fi
    
    print_info "Testing configuration for $domain_name..."
    nginx -t -c /etc/nginx/nginx.conf
    
    press_any_key
}

# Auto setup phpMyAdmin for domain (called after domain creation)
auto_setup_phpmyadmin_for_domain() {
    local domain=$1
    local root_dir=$2
    
    # Check if phpMyAdmin is installed
    if [ ! -d "/usr/share/phpmyadmin" ]; then
        print_warning "phpMyAdmin not installed, skipping auto-setup"
        return 1
    fi
    
    print_info "Auto-configuring phpMyAdmin for ${domain}..."
    
    # Generate random credentials
    local pma_username="admin_$(openssl rand -hex 4)"
    local pma_password=$(openssl rand -base64 16 | tr -d "=+/" | cut -c1-16)
    local pma_path="/phpmyadmin_$(openssl rand -hex 3)"
    
    # Create htpasswd directory and file
    local htpasswd_dir="/etc/nginx/htpasswd"
    mkdir -p "$htpasswd_dir"
    local htpasswd_file="${htpasswd_dir}/${domain}_phpmyadmin"
    
    # Generate htpasswd entry
    echo "${pma_username}:$(openssl passwd -apr1 ${pma_password})" > "$htpasswd_file"
    chmod 644 "$htpasswd_file"
    
    # Get PHP-FPM socket
    local php_socket=$(find /var/run/php/ -name "php*-fpm.sock" | head -1)
    if [ -z "$php_socket" ]; then
        php_socket="/var/run/php/php-fpm.sock"
    fi
    
    # Backup vhost file
    cp "${NGINX_VHOST_DIR}/${domain}" "${BACKUP_DIR}/${domain}_before_pma_$(date +%Y%m%d_%H%M%S).conf"
    
    # Create phpMyAdmin location block
    local pma_block="
    # phpMyAdmin - Auto-configured by RocketVPS
    # Access URL: http://${domain}${pma_path}
    # Username: ${pma_username}
    # Password: ${pma_password}
    location ${pma_path} {
        alias /usr/share/phpmyadmin;
        index index.php;
        
        # HTTP Basic Authentication
        auth_basic \"Database Administration\";
        auth_basic_user_file ${htpasswd_file};
        
        location ~ ^${pma_path}/(.+\\.php)\$ {
            alias /usr/share/phpmyadmin/\$1;
            include fastcgi_params;
            fastcgi_pass unix:${php_socket};
            fastcgi_param SCRIPT_FILENAME \$request_filename;
            fastcgi_index index.php;
        }
        
        location ~* ^${pma_path}/(.+\\.(jpg|jpeg|gif|css|png|js|ico|html|xml|txt))\$ {
            alias /usr/share/phpmyadmin/\$1;
            expires 30d;
        }
    }
    
    location ~ ^${pma_path}/(.+)\$ {
        deny all;
    }"
    
    # Insert phpMyAdmin block before the last closing brace
    sed -i "/^}$/i \\${pma_block}" "${NGINX_VHOST_DIR}/${domain}"
    
    # Test Nginx configuration
    if nginx -t >/dev/null 2>&1; then
        systemctl reload nginx
        
        # Save credentials to file
        local credentials_file="${CONFIG_DIR}/phpmyadmin_${domain}_credentials.txt"
        cat > "$credentials_file" <<EOF
phpMyAdmin Credentials for ${domain}
Generated: $(date '+%Y-%m-%d %H:%M:%S')
========================================

Domain: ${domain}
Access URL: http://${domain}${pma_path}

Username: ${pma_username}
Password: ${pma_password}

HTTP Auth File: ${htpasswd_file}

⚠ IMPORTANT: Keep these credentials secure!
========================================
EOF
        chmod 600 "$credentials_file"
        
        # Add to phpMyAdmin domains list
        local pma_domains_file="${CONFIG_DIR}/phpmyadmin_domains.list"
        echo "${domain}|${pma_path}|${pma_username}|${credentials_file}" >> "$pma_domains_file"
        
        print_success "phpMyAdmin auto-configured successfully"
        return 0
    else
        print_error "Nginx configuration test failed, reverting..."
        cp "${BACKUP_DIR}/${domain}_before_pma_$(date +%Y%m%d)*.conf" "${NGINX_VHOST_DIR}/${domain}" 2>/dev/null
        systemctl reload nginx
        return 1
    fi
}

# Display complete domain information (called after domain creation)
display_domain_complete_info() {
    local domain=$1
    local root_dir=$2
    local credentials_file="${CONFIG_DIR}/phpmyadmin_${domain}_credentials.txt"
    
    # Get server IP
    local server_ip=$(hostname -I | awk '{print $1}')
    if [ -z "$server_ip" ]; then
        server_ip=$(curl -s ifconfig.me 2>/dev/null || echo "N/A")
    fi
    
    # Clear screen for clean display
    show_header
    
    echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║           DOMAIN SETUP COMPLETED SUCCESSFULLY! 🎉            ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Domain Information
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}📌 DOMAIN INFORMATION${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${GREEN}Domain Name:${NC}           ${domain}"
    echo -e "${GREEN}Alternative:${NC}           www.${domain}"
    echo ""
    
    # Directory Information
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}📁 DIRECTORY STRUCTURE${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${GREEN}Root Directory:${NC}        ${root_dir}"
    echo -e "${GREEN}Website Files:${NC}         ${root_dir}/"
    echo -e "${GREEN}Upload Files:${NC}          ${root_dir}/uploads/ (create if needed)"
    echo -e "${GREEN}Nginx Config:${NC}          ${NGINX_VHOST_DIR}/${domain}"
    echo -e "${GREEN}Access Logs:${NC}           /var/log/nginx/${domain}_access.log"
    echo -e "${GREEN}Error Logs:${NC}            /var/log/nginx/${domain}_error.log"
    echo ""
    
    # phpMyAdmin Information
    if [ -f "$credentials_file" ]; then
        echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
        echo -e "${YELLOW}🔐 PHPMYADMIN ACCESS (Auto-configured)${NC}"
        echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
        echo ""
        
        # Extract info from credentials file
        local pma_url=$(grep "Access URL:" "$credentials_file" | awk '{print $3}')
        local pma_username=$(grep "Username:" "$credentials_file" | awk '{print $2}')
        local pma_password=$(grep "Password:" "$credentials_file" | awk '{print $2}')
        
        echo -e "${GREEN}Access URL:${NC}            ${pma_url}"
        echo -e "${GREEN}Username:${NC}              ${pma_username}"
        echo -e "${GREEN}Password:${NC}              ${pma_password}"
        echo -e "${GREEN}Credentials File:${NC}      ${credentials_file}"
        echo ""
        echo -e "${YELLOW}⚠  Note: Save these credentials securely!${NC}"
        echo ""
    fi
    
    # Server Information
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}🖥  SERVER INFORMATION${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${GREEN}Server IP:${NC}             ${server_ip}"
    echo -e "${GREEN}HTTP Port:${NC}             80"
    echo -e "${GREEN}HTTPS Port:${NC}            443 (after SSL setup)"
    echo ""
    
    # DNS Configuration Guide
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}🌐 DNS CONFIGURATION REQUIRED${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${YELLOW}Add these DNS records at your domain registrar:${NC}"
    echo ""
    echo -e "  ${GREEN}Record Type    Name    Value${NC}"
    echo -e "  ──────────────────────────────────────────"
    echo -e "  A              @       ${server_ip}"
    echo -e "  A              www     ${server_ip}"
    echo -e "  CNAME          www     ${domain}"
    echo ""
    echo -e "${YELLOW}DNS propagation may take 5-60 minutes${NC}"
    echo ""
    
    # Quick Access Commands
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}⚡ QUICK COMMANDS${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${GREEN}Upload files via FTP:${NC}"
    echo -e "  Host: ${server_ip}"
    echo -e "  Directory: ${root_dir}"
    echo ""
    echo -e "${GREEN}View files:${NC}            ${CYAN}ls -lah ${root_dir}${NC}"
    echo -e "${GREEN}Edit Nginx config:${NC}     ${CYAN}nano ${NGINX_VHOST_DIR}/${domain}${NC}"
    echo -e "${GREEN}Test Nginx config:${NC}     ${CYAN}nginx -t${NC}"
    echo -e "${GREEN}Reload Nginx:${NC}          ${CYAN}systemctl reload nginx${NC}"
    echo -e "${GREEN}View access logs:${NC}      ${CYAN}tail -f /var/log/nginx/${domain}_access.log${NC}"
    echo -e "${GREEN}View error logs:${NC}       ${CYAN}tail -f /var/log/nginx/${domain}_error.log${NC}"
    echo ""
    
    # Next Steps
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}📋 RECOMMENDED NEXT STEPS${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "  ${GREEN}1.${NC} Configure DNS records (see above)"
    echo -e "  ${GREEN}2.${NC} Upload your website files to: ${root_dir}"
    echo -e "  ${GREEN}3.${NC} Install SSL certificate (Menu → 3 → SSL Management)"
    echo -e "  ${GREEN}4.${NC} Setup FTP access (Menu → 7 → FTP Management)"
    echo -e "  ${GREEN}5.${NC} Configure firewall (Menu → 8 → CSF Firewall)"
    echo -e "  ${GREEN}6.${NC} Setup automatic backups (Menu → 10 → Backup & Restore)"
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
    
    # Save info to file
    local info_file="${CONFIG_DIR}/domain_${domain}_info.txt"
    cat > "$info_file" <<EOF
Domain Setup Information for ${domain}
Generated: $(date '+%Y-%m-%d %H:%M:%S')
========================================

DOMAIN INFORMATION
------------------
Domain: ${domain}
Alternative: www.${domain}

DIRECTORY STRUCTURE
------------------
Root Directory: ${root_dir}
Website Files: ${root_dir}/
Nginx Config: ${NGINX_VHOST_DIR}/${domain}
Access Logs: /var/log/nginx/${domain}_access.log
Error Logs: /var/log/nginx/${domain}_error.log

SERVER INFORMATION
------------------
Server IP: ${server_ip}
HTTP Port: 80
HTTPS Port: 443 (after SSL)

DNS CONFIGURATION
------------------
A      @    ${server_ip}
A      www  ${server_ip}
CNAME  www  ${domain}

========================================
EOF
    
    echo -e "${GREEN}✓ Complete information saved to:${NC} ${info_file}"
    echo ""
    
    press_any_key
}
