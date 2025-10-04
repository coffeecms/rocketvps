#!/bin/bash

################################################################################
# RocketVPS - SSL Management Module
################################################################################

# SSL menu
ssl_menu() {
    while true; do
        show_header
        echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║                    SSL MANAGEMENT                             ║${NC}"
        echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo "  1) Install Certbot (Let's Encrypt)"
        echo "  2) Install SSL for Domain"
        echo "  3) Renew SSL Certificates"
        echo "  4) List All SSL Certificates"
        echo "  5) Setup Auto-Renewal (Every 7 Days)"
        echo "  6) Remove SSL from Domain"
        echo "  7) Force Renew SSL"
        echo "  8) Check SSL Status"
        echo ""
        echo "  0) Back to Main Menu"
        echo ""
        echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
        
        read -p "Enter your choice [0-8]: " ssl_choice
        
        case $ssl_choice in
            1) install_certbot ;;
            2) install_ssl_domain ;;
            3) renew_ssl_certificates ;;
            4) list_ssl_certificates ;;
            5) setup_ssl_auto_renewal ;;
            6) remove_ssl_domain ;;
            7) force_renew_ssl ;;
            8) check_ssl_status ;;
            0) return ;;
            *)
                print_error "Invalid choice"
                sleep 2
                ;;
        esac
    done
}

# Install Certbot
install_certbot() {
    print_info "Installing Certbot (Let's Encrypt)..."
    
    if command -v certbot &> /dev/null; then
        print_warning "Certbot is already installed"
        certbot --version
        press_any_key
        return
    fi
    
    if [[ "$OS" == "ubuntu" || "$OS" == "debian" ]]; then
        apt-get update
        apt-get install -y certbot python3-certbot-nginx
    elif [[ "$OS" == "centos" || "$OS" == "rhel" ]]; then
        yum install -y certbot python3-certbot-nginx
    fi
    
    if command -v certbot &> /dev/null; then
        print_success "Certbot installed successfully"
        certbot --version
    else
        print_error "Certbot installation failed"
    fi
    
    press_any_key
}

# Install SSL for domain
install_ssl_domain() {
    if ! command -v certbot &> /dev/null; then
        print_error "Certbot is not installed. Please install it first."
        press_any_key
        return
    fi
    
    # List available domains
    show_header
    echo -e "${CYAN}Available Domains:${NC}"
    echo ""
    
    if [ ! -s "${DOMAIN_LIST_FILE}" ]; then
        print_warning "No domains found. Please add a domain first."
        press_any_key
        return
    fi
    
    local domain_index=1
    declare -A domain_array
    
    while IFS='|' read -r domain root date_added; do
        echo "  $domain_index) $domain"
        domain_array[$domain_index]=$domain
        ((domain_index++))
    done < "${DOMAIN_LIST_FILE}"
    
    echo ""
    read -p "Select domain number (or enter domain name): " domain_input
    
    # Check if input is a number or domain name
    if [[ "$domain_input" =~ ^[0-9]+$ ]] && [ -n "${domain_array[$domain_input]}" ]; then
        domain_name="${domain_array[$domain_input]}"
    else
        domain_name="$domain_input"
    fi
    
    if [ -z "$domain_name" ]; then
        print_error "Invalid domain selection"
        press_any_key
        return
    fi
    
    # Check if domain configuration exists
    if [ ! -f "${NGINX_VHOST_DIR}/${domain_name}" ]; then
        print_error "Domain configuration not found for $domain_name"
        press_any_key
        return
    fi
    
    read -p "Include www subdomain? (yes/no): " include_www
    
    print_info "Installing SSL certificate for $domain_name..."
    
    # Email for Let's Encrypt notifications
    read -p "Enter email address for SSL notifications: " ssl_email
    
    if [ "$include_www" = "yes" ]; then
        certbot --nginx -d "$domain_name" -d "www.$domain_name" --non-interactive --agree-tos -m "$ssl_email" --redirect
    else
        certbot --nginx -d "$domain_name" --non-interactive --agree-tos -m "$ssl_email" --redirect
    fi
    
    if [ $? -eq 0 ]; then
        print_success "SSL certificate installed successfully for $domain_name"
        print_info "HTTPS redirect has been enabled automatically"
        
        # Add SSL info to domain list
        sed -i "s|^${domain_name}|.*|${domain_name}|$(grep "^${domain_name}|" "${DOMAIN_LIST_FILE}" | cut -d'|' -f2-)|SSL|$(date +%Y-%m-%d)|" "${DOMAIN_LIST_FILE}" 2>/dev/null || true
    else
        print_error "SSL certificate installation failed"
        print_info "Make sure:"
        print_info "1. Domain DNS is pointing to this server"
        print_info "2. Port 80 and 443 are open"
        print_info "3. Nginx is running"
    fi
    
    press_any_key
}

# Renew SSL certificates
renew_ssl_certificates() {
    if ! command -v certbot &> /dev/null; then
        print_error "Certbot is not installed"
        press_any_key
        return
    fi
    
    print_info "Renewing all SSL certificates..."
    
    certbot renew --nginx
    
    if [ $? -eq 0 ]; then
        print_success "SSL certificates renewed successfully"
        systemctl reload nginx
    else
        print_warning "Some certificates may not need renewal yet"
    fi
    
    press_any_key
}

# List all SSL certificates
list_ssl_certificates() {
    if ! command -v certbot &> /dev/null; then
        print_error "Certbot is not installed"
        press_any_key
        return
    fi
    
    show_header
    echo -e "${CYAN}All SSL Certificates:${NC}"
    echo ""
    
    certbot certificates
    
    echo ""
    press_any_key
}

# Setup SSL auto-renewal
setup_ssl_auto_renewal() {
    if ! command -v certbot &> /dev/null; then
        print_error "Certbot is not installed. Please install it first."
        press_any_key
        return
    fi
    
    print_info "Setting up SSL auto-renewal (every 7 days)..."
    
    # Create renewal script
    cat > "${SSL_RENEWAL_SCRIPT}" <<'EOF'
#!/bin/bash

# RocketVPS SSL Auto-Renewal Script
LOG_FILE="/opt/rocketvps/logs/ssl_renewal.log"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting SSL renewal check..." >> "$LOG_FILE"

# Renew certificates
certbot renew --nginx --quiet >> "$LOG_FILE" 2>&1

if [ $? -eq 0 ]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] SSL renewal check completed successfully" >> "$LOG_FILE"
    systemctl reload nginx >> "$LOG_FILE" 2>&1
else
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] SSL renewal check failed" >> "$LOG_FILE"
fi

echo "" >> "$LOG_FILE"
EOF
    
    chmod +x "${SSL_RENEWAL_SCRIPT}"
    
    # Add to crontab (every 7 days at 3 AM)
    local cron_job="0 3 */7 * * ${SSL_RENEWAL_SCRIPT}"
    
    # Check if cron job already exists
    if crontab -l 2>/dev/null | grep -q "${SSL_RENEWAL_SCRIPT}"; then
        print_warning "SSL auto-renewal is already configured"
    else
        (crontab -l 2>/dev/null; echo "$cron_job") | crontab -
        print_success "SSL auto-renewal configured successfully"
        print_info "Certificates will be checked and renewed every 7 days at 3 AM"
    fi
    
    # Test the renewal process
    print_info "Testing renewal process..."
    certbot renew --dry-run
    
    if [ $? -eq 0 ]; then
        print_success "Renewal test passed"
    else
        print_warning "Renewal test failed. Please check configuration."
    fi
    
    press_any_key
}

# Remove SSL from domain
remove_ssl_domain() {
    if ! command -v certbot &> /dev/null; then
        print_error "Certbot is not installed"
        press_any_key
        return
    fi
    
    show_header
    echo -e "${CYAN}SSL Certificates:${NC}"
    echo ""
    
    certbot certificates
    
    echo ""
    read -p "Enter domain name to remove SSL: " domain_name
    
    if [ -z "$domain_name" ]; then
        print_error "Domain name cannot be empty"
        press_any_key
        return
    fi
    
    print_warning "This will remove the SSL certificate for $domain_name"
    read -p "Are you sure? (yes/no): " confirm
    
    if [ "$confirm" != "yes" ]; then
        print_info "Operation cancelled"
        press_any_key
        return
    fi
    
    certbot delete --cert-name "$domain_name"
    
    if [ $? -eq 0 ]; then
        print_success "SSL certificate removed for $domain_name"
        
        # Restore HTTP-only configuration
        if [ -f "${NGINX_VHOST_DIR}/${domain_name}" ]; then
            print_info "You may need to manually update Nginx configuration"
        fi
        
        systemctl reload nginx
    else
        print_error "Failed to remove SSL certificate"
    fi
    
    press_any_key
}

# Force renew SSL
force_renew_ssl() {
    if ! command -v certbot &> /dev/null; then
        print_error "Certbot is not installed"
        press_any_key
        return
    fi
    
    show_header
    echo -e "${CYAN}SSL Certificates:${NC}"
    echo ""
    
    certbot certificates
    
    echo ""
    read -p "Enter domain name to force renew (or 'all' for all): " domain_name
    
    if [ -z "$domain_name" ]; then
        print_error "Domain name cannot be empty"
        press_any_key
        return
    fi
    
    print_info "Force renewing SSL certificate..."
    
    if [ "$domain_name" = "all" ]; then
        certbot renew --force-renewal --nginx
    else
        certbot renew --cert-name "$domain_name" --force-renewal --nginx
    fi
    
    if [ $? -eq 0 ]; then
        print_success "SSL certificate renewed successfully"
        systemctl reload nginx
    else
        print_error "Failed to renew SSL certificate"
    fi
    
    press_any_key
}

# Check SSL status
check_ssl_status() {
    show_header
    echo -e "${CYAN}SSL Status Check:${NC}"
    echo ""
    
    if ! command -v certbot &> /dev/null; then
        print_error "Certbot is not installed"
        press_any_key
        return
    fi
    
    # List all certificates with expiry dates
    certbot certificates
    
    echo ""
    echo -e "${CYAN}Auto-Renewal Status:${NC}"
    
    if crontab -l 2>/dev/null | grep -q "ssl_renewal.sh"; then
        print_success "Auto-renewal is ENABLED"
        echo ""
        echo "Renewal schedule:"
        crontab -l | grep "ssl_renewal.sh"
    else
        print_warning "Auto-renewal is NOT configured"
    fi
    
    echo ""
    
    # Check renewal log
    if [ -f "${LOG_DIR}/ssl_renewal.log" ]; then
        echo -e "${CYAN}Last Renewal Attempts:${NC}"
        tail -n 20 "${LOG_DIR}/ssl_renewal.log"
    fi
    
    echo ""
    press_any_key
}
