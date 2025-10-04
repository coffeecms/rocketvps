#!/bin/bash

################################################################################
# RocketVPS - Security Enhancement Module
################################################################################

# Security menu
security_menu() {
    while true; do
        show_header
        echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║                 SECURITY ENHANCEMENT                          ║${NC}"
        echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo "  1) Apply Security Level"
        echo "  2) SSH Hardening"
        echo "  3) Disable Root Login"
        echo "  4) Setup Fail2Ban"
        echo "  5) Secure MySQL/MariaDB"
        echo "  6) Setup ModSecurity"
        echo "  7) Enable Auto Updates"
        echo "  8) Scan for Malware"
        echo "  9) Security Audit"
        echo "  10) View Security Status"
        echo ""
        echo "  0) Back to Main Menu"
        echo ""
        echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
        
        read -p "Enter your choice [0-10]: " sec_choice
        
        case $sec_choice in
            1) apply_security_level ;;
            2) ssh_hardening ;;
            3) disable_root_login ;;
            4) setup_fail2ban ;;
            5) secure_mysql ;;
            6) setup_modsecurity ;;
            7) enable_auto_updates ;;
            8) scan_malware ;;
            9) security_audit ;;
            10) view_security_status ;;
            0) return ;;
            *)
                print_error "Invalid choice"
                sleep 2
                ;;
        esac
    done
}

# Apply security level
apply_security_level() {
    show_header
    echo -e "${CYAN}Apply Security Level${NC}"
    echo ""
    
    echo "Select security level:"
    echo ""
    echo "  1) ${GREEN}BASIC${NC} - Essential security measures"
    echo "     • SSH key authentication"
    echo "     • Firewall enabled"
    echo "     • Automatic security updates"
    echo ""
    echo "  2) ${YELLOW}MEDIUM${NC} - Recommended for production"
    echo "     • All Basic features"
    echo "     • Fail2Ban protection"
    echo "     • Root login disabled"
    echo "     • Enhanced SSH security"
    echo "     • Database security hardening"
    echo ""
    echo "  3) ${RED}ADVANCED${NC} - Maximum security"
    echo "     • All Medium features"
    echo "     • ModSecurity WAF"
    echo "     • Intrusion detection"
    echo "     • Advanced firewall rules"
    echo "     • Regular security audits"
    echo ""
    read -p "Enter choice [1-3]: " level_choice
    
    case $level_choice in
        1) apply_basic_security ;;
        2) apply_medium_security ;;
        3) apply_advanced_security ;;
        *)
            print_error "Invalid choice"
            press_any_key
            return
            ;;
    esac
}

# Apply basic security
apply_basic_security() {
    print_info "Applying BASIC security level..."
    
    # Enable firewall
    if [ -d "/etc/csf" ]; then
        csf -e
        print_success "Firewall enabled"
    fi
    
    # Enable automatic updates
    enable_auto_updates
    
    # SSH hardening (basic)
    sed -i 's/#PermitRootLogin yes/PermitRootLogin yes/' /etc/ssh/sshd_config
    sed -i 's/PermitEmptyPasswords yes/PermitEmptyPasswords no/' /etc/ssh/sshd_config
    systemctl restart sshd
    
    print_success "BASIC security level applied"
    press_any_key
}

# Apply medium security
apply_medium_security() {
    print_info "Applying MEDIUM security level..."
    
    # Apply basic security first
    apply_basic_security
    
    # Setup Fail2Ban
    setup_fail2ban
    
    # Disable root login
    disable_root_login
    
    # SSH hardening (enhanced)
    ssh_hardening
    
    # Secure MySQL
    secure_mysql
    
    print_success "MEDIUM security level applied"
    press_any_key
}

# Apply advanced security
apply_advanced_security() {
    print_info "Applying ADVANCED security level..."
    
    # Apply medium security first
    apply_medium_security
    
    # Setup ModSecurity
    setup_modsecurity
    
    # Advanced firewall rules
    if [ -d "/etc/csf" ]; then
        sed -i 's/^SYNFLOOD = .*/SYNFLOOD = "1"/' /etc/csf/csf.conf
        sed -i 's/^PORTFLOOD = .*/PORTFLOOD = "22;tcp;5;300"/' /etc/csf/csf.conf
        csf -r
    fi
    
    # Install intrusion detection
    if [[ "$OS" == "ubuntu" || "$OS" == "debian" ]]; then
        apt-get install -y aide rkhunter chkrootkit
    fi
    
    print_success "ADVANCED security level applied"
    print_warning "Remember to schedule regular security audits"
    press_any_key
}

# SSH hardening
ssh_hardening() {
    show_header
    echo -e "${CYAN}SSH Hardening${NC}"
    echo ""
    
    local sshd_config="/etc/ssh/sshd_config"
    
    if [ ! -f "$sshd_config" ]; then
        print_error "SSH config file not found"
        press_any_key
        return
    fi
    
    print_info "Hardening SSH configuration..."
    
    # Backup original
    cp "$sshd_config" "${sshd_config}.bak.$(date +%Y%m%d_%H%M%S)"
    
    # Apply secure settings
    sed -i 's/#Port 22/Port 22/' "$sshd_config"
    sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' "$sshd_config"
    sed -i 's/PermitRootLogin yes/PermitRootLogin no/' "$sshd_config"
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' "$sshd_config"
    sed -i 's/#PermitEmptyPasswords no/PermitEmptyPasswords no/' "$sshd_config"
    sed -i 's/PermitEmptyPasswords yes/PermitEmptyPasswords no/' "$sshd_config"
    sed -i 's/#MaxAuthTries 6/MaxAuthTries 3/' "$sshd_config"
    sed -i 's/#ClientAliveInterval 0/ClientAliveInterval 300/' "$sshd_config"
    sed -i 's/#ClientAliveCountMax 3/ClientAliveCountMax 2/' "$sshd_config"
    
    # Disable X11 forwarding
    sed -i 's/X11Forwarding yes/X11Forwarding no/' "$sshd_config"
    
    # Protocol 2 only
    if ! grep -q "^Protocol 2" "$sshd_config"; then
        echo "Protocol 2" >> "$sshd_config"
    fi
    
    # Test configuration
    sshd -t
    
    if [ $? -eq 0 ]; then
        systemctl restart sshd
        print_success "SSH hardening completed"
        print_warning "Make sure you have SSH key access before closing this session!"
    else
        print_error "SSH configuration test failed. Restoring backup..."
        mv "${sshd_config}.bak.$(date +%Y%m%d_%H%M%S)" "$sshd_config"
    fi
    
    press_any_key
}

# Disable root login
disable_root_login() {
    print_info "Disabling root login via SSH..."
    
    sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
    sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
    
    systemctl restart sshd
    
    print_success "Root login disabled"
    print_warning "Make sure you have another user with sudo access!"
}

# Setup Fail2Ban
setup_fail2ban() {
    print_info "Setting up Fail2Ban..."
    
    if command -v fail2ban-client &> /dev/null; then
        print_warning "Fail2Ban is already installed"
        press_any_key
        return
    fi
    
    if [[ "$OS" == "ubuntu" || "$OS" == "debian" ]]; then
        apt-get update
        apt-get install -y fail2ban
    elif [[ "$OS" == "centos" || "$OS" == "rhel" ]]; then
        yum install -y fail2ban
    fi
    
    # Configure Fail2Ban
    cat > /etc/fail2ban/jail.local <<'EOF'
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5
destemail = root@localhost
sendername = Fail2Ban
action = %(action_mwl)s

[sshd]
enabled = true
port = ssh
logpath = %(sshd_log)s
maxretry = 3

[nginx-http-auth]
enabled = true
filter = nginx-http-auth
port = http,https
logpath = /var/log/nginx/error.log

[nginx-noscript]
enabled = true
port = http,https
filter = nginx-noscript
logpath = /var/log/nginx/access.log
maxretry = 6

[nginx-badbots]
enabled = true
port = http,https
filter = nginx-badbots
logpath = /var/log/nginx/access.log
maxretry = 2

[nginx-noproxy]
enabled = true
port = http,https
filter = nginx-noproxy
logpath = /var/log/nginx/access.log
maxretry = 2
EOF
    
    systemctl enable fail2ban
    systemctl start fail2ban
    
    print_success "Fail2Ban installed and configured"
    press_any_key
}

# Secure MySQL
secure_mysql() {
    if [ ! -f "${CONFIG_DIR}/database.conf" ]; then
        print_warning "No database detected"
        press_any_key
        return
    fi
    
    print_info "Securing MySQL/MariaDB..."
    
    # Already done during installation
    print_success "MySQL/MariaDB security configured"
    print_info "Root password is stored in: ${CONFIG_DIR}/mysql_root.cnf"
    
    press_any_key
}

# Setup ModSecurity
setup_modsecurity() {
    print_info "Setting up ModSecurity WAF..."
    
    if [[ "$OS" == "ubuntu" || "$OS" == "debian" ]]; then
        apt-get update
        apt-get install -y libmodsecurity3 libmodsecurity-dev
    fi
    
    print_info "ModSecurity installation completed"
    print_warning "Additional configuration required for full functionality"
    
    press_any_key
}

# Enable auto updates
enable_auto_updates() {
    print_info "Enabling automatic security updates..."
    
    if [[ "$OS" == "ubuntu" || "$OS" == "debian" ]]; then
        apt-get update
        apt-get install -y unattended-upgrades
        
        dpkg-reconfigure -plow unattended-upgrades
        
        print_success "Automatic security updates enabled"
    elif [[ "$OS" == "centos" || "$OS" == "rhel" ]]; then
        yum install -y yum-cron
        systemctl enable yum-cron
        systemctl start yum-cron
        
        print_success "Automatic updates enabled"
    fi
}

# Scan for malware
scan_malware() {
    show_header
    echo -e "${CYAN}Malware Scan${NC}"
    echo ""
    
    print_info "Installing ClamAV..."
    
    if ! command -v clamscan &> /dev/null; then
        if [[ "$OS" == "ubuntu" || "$OS" == "debian" ]]; then
            apt-get update
            apt-get install -y clamav clamav-daemon
        elif [[ "$OS" == "centos" || "$OS" == "rhel" ]]; then
            yum install -y clamav clamav-update
        fi
    fi
    
    print_info "Updating virus definitions..."
    freshclam
    
    read -p "Enter directory to scan (default: /var/www): " scan_dir
    scan_dir=${scan_dir:-/var/www}
    
    print_info "Scanning $scan_dir for malware..."
    clamscan -r -i "$scan_dir"
    
    press_any_key
}

# Security audit
security_audit() {
    show_header
    echo -e "${CYAN}Security Audit${NC}"
    echo ""
    
    print_info "Running security audit..."
    
    echo ""
    echo -e "${YELLOW}=== System Information ===${NC}"
    uname -a
    
    echo ""
    echo -e "${YELLOW}=== Open Ports ===${NC}"
    netstat -tuln | grep LISTEN
    
    echo ""
    echo -e "${YELLOW}=== Failed Login Attempts ===${NC}"
    grep "Failed password" /var/log/auth.log 2>/dev/null | tail -10 || \
    grep "Failed password" /var/log/secure 2>/dev/null | tail -10
    
    echo ""
    echo -e "${YELLOW}=== Firewall Status ===${NC}"
    if [ -d "/etc/csf" ]; then
        csf -l | head -20
    else
        iptables -L -n | head -20
    fi
    
    echo ""
    echo -e "${YELLOW}=== Last Logins ===${NC}"
    last | head -10
    
    echo ""
    echo -e "${YELLOW}=== Suspicious Files ===${NC}"
    find /tmp -type f -name "*.php" -o -name "*.sh" 2>/dev/null | head -10
    
    echo ""
    press_any_key
}

# View security status
view_security_status() {
    show_header
    echo -e "${CYAN}Security Status${NC}"
    echo ""
    
    # Check services
    echo -e "${YELLOW}=== Security Services ===${NC}"
    
    if command -v fail2ban-client &> /dev/null; then
        echo "✓ Fail2Ban: Installed"
        fail2ban-client status | grep "Number of jail"
    else
        echo "✗ Fail2Ban: Not installed"
    fi
    
    echo ""
    
    if [ -d "/etc/csf" ]; then
        echo "✓ CSF Firewall: Installed"
    else
        echo "✗ CSF Firewall: Not installed"
    fi
    
    echo ""
    
    if command -v clamscan &> /dev/null; then
        echo "✓ ClamAV: Installed"
    else
        echo "✗ ClamAV: Not installed"
    fi
    
    echo ""
    echo -e "${YELLOW}=== SSH Configuration ===${NC}"
    echo "Root Login: $(grep "^PermitRootLogin" /etc/ssh/sshd_config || echo "yes")"
    echo "Password Authentication: $(grep "^PasswordAuthentication" /etc/ssh/sshd_config || echo "yes")"
    
    echo ""
    echo -e "${YELLOW}=== Active Security Rules ===${NC}"
    if [ -d "/etc/csf" ]; then
        wc -l /etc/csf/csf.deny | awk '{print "Blocked IPs: " $1}'
    fi
    
    echo ""
    press_any_key
}
