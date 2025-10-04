#!/bin/bash

################################################################################
# RocketVPS - phpMyAdmin Management Module
# Cài đặt và quản lý phpMyAdmin cho các domain
################################################################################

# Configuration
PHPMYADMIN_VERSION="latest"
PHPMYADMIN_DIR="/usr/share/phpmyadmin"
PHPMYADMIN_CONFIG="${PHPMYADMIN_DIR}/config.inc.php"
PHPMYADMIN_DOMAINS_FILE="${CONFIG_DIR}/phpmyadmin_domains.list"

# Install phpMyAdmin
install_phpmyadmin() {
    print_header "Install phpMyAdmin"
    
    # Check if already installed
    if [ -d "$PHPMYADMIN_DIR" ]; then
        print_warning "phpMyAdmin is already installed"
        read -p "Do you want to reinstall? (y/n): " reinstall
        if [[ ! "$reinstall" =~ ^[Yy]$ ]]; then
            return
        fi
        rm -rf "$PHPMYADMIN_DIR"
    fi
    
    print_info "Installing phpMyAdmin..."
    
    # Install dependencies
    apt-get update
    apt-get install -y wget unzip php-mbstring php-zip php-gd php-json php-curl
    
    # Get latest version
    print_info "Downloading latest phpMyAdmin..."
    cd /tmp
    
    # Download phpMyAdmin
    LATEST_URL=$(curl -s https://www.phpmyadmin.net/downloads/ | grep -oP 'https://files.phpmyadmin.net/phpMyAdmin/[0-9.]+/phpMyAdmin-[0-9.]+-all-languages.zip' | head -1)
    
    if [ -z "$LATEST_URL" ]; then
        # Fallback to a known stable version
        LATEST_URL="https://files.phpmyadmin.net/phpMyAdmin/5.2.1/phpMyAdmin-5.2.1-all-languages.zip"
    fi
    
    wget -O phpmyadmin.zip "$LATEST_URL"
    
    if [ $? -ne 0 ]; then
        print_error "Failed to download phpMyAdmin"
        press_any_key
        return
    fi
    
    # Extract
    unzip -q phpmyadmin.zip
    
    # Move to installation directory
    EXTRACTED_DIR=$(ls -d phpMyAdmin-*-all-languages | head -1)
    mv "$EXTRACTED_DIR" "$PHPMYADMIN_DIR"
    
    # Create tmp directory
    mkdir -p "${PHPMYADMIN_DIR}/tmp"
    chmod 777 "${PHPMYADMIN_DIR}/tmp"
    
    # Generate blowfish secret
    BLOWFISH_SECRET=$(openssl rand -base64 32)
    
    # Create configuration
    cat > "$PHPMYADMIN_CONFIG" <<EOF
<?php
/**
 * phpMyAdmin Configuration - RocketVPS
 * Generated: $(date)
 */

\$cfg['blowfish_secret'] = '${BLOWFISH_SECRET}';

\$i = 0;
\$i++;

\$cfg['Servers'][\$i]['auth_type'] = 'cookie';
\$cfg['Servers'][\$i]['host'] = 'localhost';
\$cfg['Servers'][\$i]['compress'] = false;
\$cfg['Servers'][\$i]['AllowNoPassword'] = false;

\$cfg['UploadDir'] = '';
\$cfg['SaveDir'] = '';
\$cfg['TempDir'] = '${PHPMYADMIN_DIR}/tmp';

// Security
\$cfg['LoginCookieValidity'] = 3600;
\$cfg['LoginCookieStore'] = 0;
\$cfg['LoginCookieDeleteAll'] = true;

// Performance
\$cfg['MaxNavigationItems'] = 50;
\$cfg['MaxTableList'] = 250;

// Features
\$cfg['ShowPhpInfo'] = false;
\$cfg['ShowServerInfo'] = false;
\$cfg['ShowStats'] = false;
EOF

    # Set permissions
    chown -R www-data:www-data "$PHPMYADMIN_DIR"
    chmod -R 755 "$PHPMYADMIN_DIR"
    chmod 644 "$PHPMYADMIN_CONFIG"
    
    # Clean up
    rm -f /tmp/phpmyadmin.zip
    rm -rf "/tmp/${EXTRACTED_DIR}"
    
    print_success "phpMyAdmin installed successfully"
    print_info "Installation directory: ${PHPMYADMIN_DIR}"
    
    # Initialize domains list file
    touch "$PHPMYADMIN_DOMAINS_FILE"
    
    log_action "phpMyAdmin installed to ${PHPMYADMIN_DIR}"
    press_any_key
}

# Add phpMyAdmin to domain
add_phpmyadmin_to_domain() {
    print_header "Add phpMyAdmin to Domain"
    
    # Check if phpMyAdmin is installed
    if [ ! -d "$PHPMYADMIN_DIR" ]; then
        print_error "phpMyAdmin is not installed"
        print_info "Please install phpMyAdmin first (Option 1)"
        press_any_key
        return
    fi
    
    # List domains
    if [ ! -f "$DOMAIN_LIST_FILE" ] || [ ! -s "$DOMAIN_LIST_FILE" ]; then
        print_error "No domains found"
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
    
    # Check if phpMyAdmin already configured for this domain
    if grep -q "^${domain}$" "$PHPMYADMIN_DOMAINS_FILE" 2>/dev/null; then
        print_warning "phpMyAdmin is already configured for this domain"
        read -p "Do you want to reconfigure? (y/n): " reconfigure
        if [[ ! "$reconfigure" =~ ^[Yy]$ ]]; then
            return
        fi
    fi
    
    # Ask for access path
    echo ""
    print_info "Choose phpMyAdmin access path:"
    echo "  1) /phpmyadmin (default)"
    echo "  2) /pma"
    echo "  3) /database"
    echo "  4) Custom path"
    read -p "Enter choice [1-4]: " path_choice
    
    case $path_choice in
        1) ACCESS_PATH="/phpmyadmin" ;;
        2) ACCESS_PATH="/pma" ;;
        3) ACCESS_PATH="/database" ;;
        4) 
            read -p "Enter custom path (e.g., /my-db-admin): " custom_path
            ACCESS_PATH="$custom_path"
            ;;
        *) ACCESS_PATH="/phpmyadmin" ;;
    esac
    
    # Ask for IP whitelist
    echo ""
    read -p "Enable IP whitelist? (y/n): " enable_whitelist
    
    IP_WHITELIST=""
    if [[ "$enable_whitelist" =~ ^[Yy]$ ]]; then
        echo ""
        print_info "Enter allowed IP addresses (one per line, empty line to finish):"
        while true; do
            read -p "IP address: " ip
            if [ -z "$ip" ]; then
                break
            fi
            IP_WHITELIST="${IP_WHITELIST}    allow ${ip};\n"
        done
        IP_WHITELIST="${IP_WHITELIST}    deny all;"
    fi
    
    # Ask for HTTP authentication
    echo ""
    read -p "Enable HTTP Basic Authentication? (y/n): " enable_auth
    
    AUTH_CONFIG=""
    if [[ "$enable_auth" =~ ^[Yy]$ ]]; then
        read -p "Enter username: " auth_user
        read -s -p "Enter password: " auth_pass
        echo ""
        
        # Create htpasswd file
        HTPASSWD_DIR="/etc/nginx/htpasswd"
        mkdir -p "$HTPASSWD_DIR"
        HTPASSWD_FILE="${HTPASSWD_DIR}/${domain}_phpmyadmin"
        
        # Generate htpasswd entry
        echo "${auth_user}:$(openssl passwd -apr1 ${auth_pass})" > "$HTPASSWD_FILE"
        
        AUTH_CONFIG="    auth_basic \"phpMyAdmin Access\";\n    auth_basic_user_file ${HTPASSWD_FILE};"
    fi
    
    # Find Nginx vhost file
    VHOST_FILE="${NGINX_VHOST_DIR}/${domain}"
    
    if [ ! -f "$VHOST_FILE" ]; then
        print_error "Nginx vhost file not found: ${VHOST_FILE}"
        press_any_key
        return
    fi
    
    # Backup vhost file
    cp "$VHOST_FILE" "${BACKUP_DIR}/${domain}_$(date +%Y%m%d_%H%M%S).conf"
    
    # Create phpMyAdmin location block
    PHPMYADMIN_BLOCK="
    # phpMyAdmin Configuration - Added by RocketVPS
    location ${ACCESS_PATH} {
        alias ${PHPMYADMIN_DIR};
        index index.php;
        
${AUTH_CONFIG}
        
$(echo -e "$IP_WHITELIST")
        
        location ~ ^${ACCESS_PATH}/(.+\\.php)\$ {
            alias ${PHPMYADMIN_DIR}/\$1;
            include fastcgi_params;
            fastcgi_pass unix:/var/run/php/php-fpm.sock;
            fastcgi_param SCRIPT_FILENAME \$request_filename;
        }
        
        location ~* ^${ACCESS_PATH}/(.+\\.(jpg|jpeg|gif|css|png|js|ico|html|xml|txt))\$ {
            alias ${PHPMYADMIN_DIR}/\$1;
        }
    }
    
    location ~ ^${ACCESS_PATH}/(.*)\$ {
        deny all;
    }"
    
    # Insert before the last closing brace
    sed -i "/^}$/i ${PHPMYADMIN_BLOCK}" "$VHOST_FILE"
    
    # Test Nginx configuration
    nginx -t
    
    if [ $? -eq 0 ]; then
        systemctl reload nginx
        
        # Add to domains list
        if ! grep -q "^${domain}$" "$PHPMYADMIN_DOMAINS_FILE" 2>/dev/null; then
            echo "$domain" >> "$PHPMYADMIN_DOMAINS_FILE"
        fi
        
        print_success "phpMyAdmin configured for ${domain}"
        print_info "Access URL: http://${domain}${ACCESS_PATH}"
        
        if [[ "$enable_auth" =~ ^[Yy]$ ]]; then
            print_info "HTTP Auth: ${auth_user}"
        fi
        
    else
        print_error "Nginx configuration test failed"
        print_warning "Restoring backup..."
        cp "${BACKUP_DIR}/${domain}_$(date +%Y%m%d)*.conf" "$VHOST_FILE"
        systemctl reload nginx
    fi
    
    log_action "phpMyAdmin configured for domain: ${domain}, path: ${ACCESS_PATH}"
    press_any_key
}

# Remove phpMyAdmin from domain
remove_phpmyadmin_from_domain() {
    print_header "Remove phpMyAdmin from Domain"
    
    # Check if any domains have phpMyAdmin
    if [ ! -f "$PHPMYADMIN_DOMAINS_FILE" ] || [ ! -s "$PHPMYADMIN_DOMAINS_FILE" ]; then
        print_error "No domains with phpMyAdmin configured"
        press_any_key
        return
    fi
    
    print_info "Domains with phpMyAdmin:"
    cat -n "$PHPMYADMIN_DOMAINS_FILE"
    
    echo ""
    read -p "Enter domain name: " domain
    
    if [ -z "$domain" ]; then
        print_error "Domain name is required"
        press_any_key
        return
    fi
    
    # Check if domain has phpMyAdmin
    if ! grep -q "^${domain}$" "$PHPMYADMIN_DOMAINS_FILE"; then
        print_error "phpMyAdmin is not configured for this domain"
        press_any_key
        return
    fi
    
    VHOST_FILE="${NGINX_VHOST_DIR}/${domain}"
    
    if [ ! -f "$VHOST_FILE" ]; then
        print_error "Nginx vhost file not found"
        press_any_key
        return
    fi
    
    # Backup vhost file
    cp "$VHOST_FILE" "${BACKUP_DIR}/${domain}_$(date +%Y%m%d_%H%M%S).conf"
    
    # Remove phpMyAdmin block
    sed -i '/# phpMyAdmin Configuration - Added by RocketVPS/,/^    }$/d' "$VHOST_FILE"
    
    # Remove htpasswd file if exists
    HTPASSWD_FILE="/etc/nginx/htpasswd/${domain}_phpmyadmin"
    if [ -f "$HTPASSWD_FILE" ]; then
        rm -f "$HTPASSWD_FILE"
    fi
    
    # Test Nginx configuration
    nginx -t
    
    if [ $? -eq 0 ]; then
        systemctl reload nginx
        
        # Remove from domains list
        sed -i "/^${domain}$/d" "$PHPMYADMIN_DOMAINS_FILE"
        
        print_success "phpMyAdmin removed from ${domain}"
    else
        print_error "Nginx configuration test failed"
        print_warning "Restoring backup..."
        cp "${BACKUP_DIR}/${domain}_$(date +%Y%m%d)*.conf" "$VHOST_FILE"
        systemctl reload nginx
    fi
    
    log_action "phpMyAdmin removed from domain: ${domain}"
    press_any_key
}

# List domains with phpMyAdmin
list_phpmyadmin_domains() {
    print_header "Domains with phpMyAdmin"
    
    if [ ! -f "$PHPMYADMIN_DOMAINS_FILE" ] || [ ! -s "$PHPMYADMIN_DOMAINS_FILE" ]; then
        print_info "No domains with phpMyAdmin configured"
        press_any_key
        return
    fi
    
    echo ""
    print_info "Configured domains:"
    
    while IFS= read -r domain; do
        VHOST_FILE="${NGINX_VHOST_DIR}/${domain}"
        
        if [ -f "$VHOST_FILE" ]; then
            ACCESS_PATH=$(grep -oP 'location \K[^ ]+' "$VHOST_FILE" | grep -E '/(phpmyadmin|pma|database)' | head -1)
            HAS_AUTH=$(grep -q "auth_basic" "$VHOST_FILE" && echo "Yes" || echo "No")
            
            echo ""
            echo "  Domain: ${domain}"
            echo "  Access: http://${domain}${ACCESS_PATH}"
            echo "  HTTP Auth: ${HAS_AUTH}"
        fi
    done < "$PHPMYADMIN_DOMAINS_FILE"
    
    echo ""
    press_any_key
}

# Update phpMyAdmin
update_phpmyadmin() {
    print_header "Update phpMyAdmin"
    
    if [ ! -d "$PHPMYADMIN_DIR" ]; then
        print_error "phpMyAdmin is not installed"
        press_any_key
        return
    fi
    
    print_warning "This will update phpMyAdmin to the latest version"
    read -p "Continue? (y/n): " confirm
    
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        return
    fi
    
    # Backup current installation
    print_info "Creating backup..."
    tar -czf "${BACKUP_DIR}/phpmyadmin_$(date +%Y%m%d_%H%M%S).tar.gz" "$PHPMYADMIN_DIR"
    
    # Backup config
    cp "$PHPMYADMIN_CONFIG" "${BACKUP_DIR}/phpmyadmin_config_$(date +%Y%m%d_%H%M%S).php"
    
    # Remove old installation but keep config
    rm -rf "${PHPMYADMIN_DIR}"
    
    # Reinstall
    install_phpmyadmin
    
    # Restore config
    LATEST_CONFIG_BACKUP=$(ls -t "${BACKUP_DIR}"/phpmyadmin_config_*.php | head -1)
    if [ -f "$LATEST_CONFIG_BACKUP" ]; then
        cp "$LATEST_CONFIG_BACKUP" "$PHPMYADMIN_CONFIG"
        print_success "Configuration restored"
    fi
    
    print_success "phpMyAdmin updated successfully"
    log_action "phpMyAdmin updated to latest version"
    press_any_key
}

# Uninstall phpMyAdmin
uninstall_phpmyadmin() {
    print_header "Uninstall phpMyAdmin"
    
    if [ ! -d "$PHPMYADMIN_DIR" ]; then
        print_error "phpMyAdmin is not installed"
        press_any_key
        return
    fi
    
    print_warning "This will completely remove phpMyAdmin"
    print_warning "All domain configurations will be removed"
    read -p "Are you sure? (yes/no): " confirm
    
    if [ "$confirm" != "yes" ]; then
        return
    fi
    
    # Remove from all domains
    if [ -f "$PHPMYADMIN_DOMAINS_FILE" ]; then
        while IFS= read -r domain; do
            print_info "Removing phpMyAdmin from ${domain}..."
            
            VHOST_FILE="${NGINX_VHOST_DIR}/${domain}"
            if [ -f "$VHOST_FILE" ]; then
                cp "$VHOST_FILE" "${BACKUP_DIR}/${domain}_$(date +%Y%m%d_%H%M%S).conf"
                sed -i '/# phpMyAdmin Configuration - Added by RocketVPS/,/^    }$/d' "$VHOST_FILE"
            fi
            
            # Remove htpasswd file
            rm -f "/etc/nginx/htpasswd/${domain}_phpmyadmin"
            
        done < "$PHPMYADMIN_DOMAINS_FILE"
        
        # Reload Nginx
        nginx -t && systemctl reload nginx
    fi
    
    # Create final backup
    tar -czf "${BACKUP_DIR}/phpmyadmin_final_$(date +%Y%m%d_%H%M%S).tar.gz" "$PHPMYADMIN_DIR"
    
    # Remove phpMyAdmin
    rm -rf "$PHPMYADMIN_DIR"
    rm -f "$PHPMYADMIN_DOMAINS_FILE"
    
    print_success "phpMyAdmin uninstalled successfully"
    log_action "phpMyAdmin uninstalled"
    press_any_key
}

# Configure phpMyAdmin security
configure_phpmyadmin_security() {
    print_header "phpMyAdmin Security Configuration"
    
    if [ ! -f "$PHPMYADMIN_CONFIG" ]; then
        print_error "phpMyAdmin is not installed"
        press_any_key
        return
    fi
    
    print_info "Security Options:"
    echo ""
    echo "  1) Change Blowfish Secret"
    echo "  2) Disable Root Login"
    echo "  3) Set Cookie Validity (Session Timeout)"
    echo "  4) Enable Two-Factor Authentication"
    echo "  5) Apply All Security Hardening"
    echo ""
    read -p "Enter choice [1-5]: " choice
    
    case $choice in
        1)
            NEW_SECRET=$(openssl rand -base64 32)
            sed -i "s/\$cfg\['blowfish_secret'\] = '.*';/\$cfg['blowfish_secret'] = '${NEW_SECRET}';/" "$PHPMYADMIN_CONFIG"
            print_success "Blowfish secret updated"
            ;;
        2)
            if grep -q "AllowRoot" "$PHPMYADMIN_CONFIG"; then
                sed -i "s/\$cfg\['Servers'\]\[\$i\]\['AllowRoot'\] = .*/\$cfg['Servers'][\$i]['AllowRoot'] = false;/" "$PHPMYADMIN_CONFIG"
            else
                sed -i "/\$cfg\['Servers'\]\[\$i\]\['AllowNoPassword'\]/a \$cfg['Servers'][\$i]['AllowRoot'] = false;" "$PHPMYADMIN_CONFIG"
            fi
            print_success "Root login disabled"
            ;;
        3)
            read -p "Enter session timeout in seconds (default 3600): " timeout
            timeout=${timeout:-3600}
            sed -i "s/\$cfg\['LoginCookieValidity'\] = .*/\$cfg['LoginCookieValidity'] = ${timeout};/" "$PHPMYADMIN_CONFIG"
            print_success "Session timeout set to ${timeout} seconds"
            ;;
        4)
            print_info "Enabling Two-Factor Authentication..."
            sed -i "/\$cfg\['TempDir'\]/a \\\n// Two-Factor Authentication\n\$cfg['TwoFactorAuth'] = true;" "$PHPMYADMIN_CONFIG"
            print_success "Two-factor authentication enabled"
            print_info "Users need to configure 2FA in their account settings"
            ;;
        5)
            # Apply all security measures
            NEW_SECRET=$(openssl rand -base64 32)
            sed -i "s/\$cfg\['blowfish_secret'\] = '.*';/\$cfg['blowfish_secret'] = '${NEW_SECRET}';/" "$PHPMYADMIN_CONFIG"
            
            cat >> "$PHPMYADMIN_CONFIG" <<EOF

// Security Hardening - RocketVPS
\$cfg['Servers'][\$i]['AllowRoot'] = false;
\$cfg['LoginCookieValidity'] = 3600;
\$cfg['LoginCookieStore'] = 0;
\$cfg['LoginCookieDeleteAll'] = true;
\$cfg['ShowPhpInfo'] = false;
\$cfg['ShowServerInfo'] = false;
\$cfg['VersionCheck'] = false;
\$cfg['AllowArbitraryServer'] = false;
\$cfg['ArbitraryServerRegexp'] = '/^localhost$/';
EOF
            print_success "All security hardening applied"
            ;;
    esac
    
    log_action "phpMyAdmin security configured"
    press_any_key
}

# phpMyAdmin menu
phpmyadmin_menu() {
    while true; do
        show_header
        echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║                 PHPMYADMIN MANAGEMENT MENU                    ║${NC}"
        echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo "  1) Install phpMyAdmin"
        echo "  2) Add phpMyAdmin to Domain"
        echo "  3) Remove phpMyAdmin from Domain"
        echo "  4) List Domains with phpMyAdmin"
        echo "  5) Update phpMyAdmin"
        echo "  6) Configure Security Settings"
        echo "  7) Uninstall phpMyAdmin"
        echo ""
        echo "  0) Back to Main Menu"
        echo ""
        echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
        
        read -p "Enter your choice [0-7]: " choice
        
        case $choice in
            1) install_phpmyadmin ;;
            2) add_phpmyadmin_to_domain ;;
            3) remove_phpmyadmin_from_domain ;;
            4) list_phpmyadmin_domains ;;
            5) update_phpmyadmin ;;
            6) configure_phpmyadmin_security ;;
            7) uninstall_phpmyadmin ;;
            0) return ;;
            *)
                print_error "Invalid choice"
                sleep 1
                ;;
        esac
    done
}
