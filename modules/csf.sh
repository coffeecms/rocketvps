#!/bin/bash

################################################################################
# RocketVPS - CSF Firewall Management Module
################################################################################

# CSF menu
csf_menu() {
    while true; do
        show_header
        echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║                 CSF FIREWALL MANAGEMENT                       ║${NC}"
        echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo "  1) Install CSF Firewall"
        echo "  2) Enable CSF"
        echo "  3) Disable CSF"
        echo "  4) Restart CSF"
        echo "  5) Block IP Address"
        echo "  6) Unblock IP Address"
        echo "  7) Unblock All IP Addresses"
        echo "  8) List Blocked IPs"
        echo "  9) Allow Port"
        echo "  10) Block Port"
        echo "  11) Configure CSF"
        echo "  12) View CSF Status"
        echo "  13) Uninstall CSF"
        echo ""
        echo "  0) Back to Main Menu"
        echo ""
        echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
        
        read -p "Enter your choice [0-13]: " csf_choice
        
        case $csf_choice in
            1) install_csf ;;
            2) enable_csf ;;
            3) disable_csf ;;
            4) restart_csf ;;
            5) block_ip ;;
            6) unblock_ip ;;
            7) unblock_all_ips ;;
            8) list_blocked_ips ;;
            9) allow_port ;;
            10) block_port ;;
            11) configure_csf_menu ;;
            12) check_csf_status ;;
            13) uninstall_csf ;;
            0) return ;;
            *)
                print_error "Invalid choice"
                sleep 2
                ;;
        esac
    done
}

# Install CSF
install_csf() {
    print_info "Installing CSF Firewall..."
    
    if [ -d "/etc/csf" ]; then
        print_warning "CSF is already installed"
        csf -v
        press_any_key
        return
    fi
    
    cd /tmp || exit
    
    # Download and install CSF
    wget https://download.configserver.com/csf.tgz
    tar -xzf csf.tgz
    cd csf || exit
    sh install.sh
    
    # Test if CSF can run on this server
    perl /usr/local/csf/bin/csftest.pl
    
    # Configure CSF with optimal settings
    configure_csf_defaults
    
    # Enable CSF
    csf -e
    
    if [ -d "/etc/csf" ]; then
        print_success "CSF installed successfully"
        csf -v
    else
        print_error "CSF installation failed"
    fi
    
    # Cleanup
    cd ..
    rm -rf csf csf.tgz
    
    press_any_key
}

# Configure CSF defaults
configure_csf_defaults() {
    local csf_conf="/etc/csf/csf.conf"
    
    if [ ! -f "$csf_conf" ]; then
        print_error "CSF configuration file not found"
        return
    fi
    
    # Backup original
    cp "$csf_conf" "${csf_conf}.bak.$(date +%Y%m%d_%H%M%S)"
    
    # Set testing mode to 0 (production)
    sed -i 's/^TESTING = "1"/TESTING = "0"/' "$csf_conf"
    
    # Open common web ports
    sed -i 's/^TCP_IN = .*/TCP_IN = "20,21,22,25,53,80,110,143,443,465,587,993,995,3306,5432"/' "$csf_conf"
    sed -i 's/^TCP_OUT = .*/TCP_OUT = "20,21,22,25,53,80,110,113,443,587,993,995"/' "$csf_conf"
    sed -i 's/^UDP_IN = .*/UDP_IN = "20,21,53"/' "$csf_conf"
    sed -i 's/^UDP_OUT = .*/UDP_OUT = "20,21,53,113,123"/' "$csf_conf"
    
    # Enable SYN flood protection
    sed -i 's/^SYNFLOOD = .*/SYNFLOOD = "1"/' "$csf_conf"
    
    # Enable port scan tracking
    sed -i 's/^PS_INTERVAL = .*/PS_INTERVAL = "300"/' "$csf_conf"
    sed -i 's/^PS_LIMIT = .*/PS_LIMIT = "10"/' "$csf_conf"
    
    # Enable connection tracking
    sed -i 's/^CT_LIMIT = .*/CT_LIMIT = "100"/' "$csf_conf"
    
    # Enable login failure detection
    sed -i 's/^LF_SSHD = .*/LF_SSHD = "5"/' "$csf_conf"
    sed -i 's/^LF_FTPD = .*/LF_FTPD = "10"/' "$csf_conf"
    
    print_success "CSF configured with secure defaults"
}

# Enable CSF
enable_csf() {
    if [ ! -d "/etc/csf" ]; then
        print_error "CSF is not installed"
        press_any_key
        return
    fi
    
    print_info "Enabling CSF..."
    csf -e
    
    print_success "CSF enabled"
    press_any_key
}

# Disable CSF
disable_csf() {
    if [ ! -d "/etc/csf" ]; then
        print_error "CSF is not installed"
        press_any_key
        return
    fi
    
    print_warning "Disabling CSF will remove firewall protection"
    read -p "Are you sure? (yes/no): " confirm
    
    if [ "$confirm" = "yes" ]; then
        csf -x
        print_success "CSF disabled"
    else
        print_info "Operation cancelled"
    fi
    
    press_any_key
}

# Restart CSF
restart_csf() {
    if [ ! -d "/etc/csf" ]; then
        print_error "CSF is not installed"
        press_any_key
        return
    fi
    
    print_info "Restarting CSF..."
    csf -r
    
    print_success "CSF restarted"
    press_any_key
}

# Block IP
block_ip() {
    if [ ! -d "/etc/csf" ]; then
        print_error "CSF is not installed"
        press_any_key
        return
    fi
    
    show_header
    echo -e "${CYAN}Block IP Address${NC}"
    echo ""
    
    read -p "Enter IP address to block: " ip_address
    
    if [ -z "$ip_address" ]; then
        print_error "IP address cannot be empty"
        press_any_key
        return
    fi
    
    read -p "Enter reason (optional): " reason
    
    if [ -n "$reason" ]; then
        csf -d "$ip_address" "$reason"
    else
        csf -d "$ip_address"
    fi
    
    print_success "IP $ip_address blocked"
    press_any_key
}

# Unblock IP
unblock_ip() {
    if [ ! -d "/etc/csf" ]; then
        print_error "CSF is not installed"
        press_any_key
        return
    fi
    
    show_header
    echo -e "${CYAN}Unblock IP Address${NC}"
    echo ""
    
    # Show blocked IPs
    echo "Currently blocked IPs:"
    csf -g | grep "DENY" | head -20
    echo ""
    
    read -p "Enter IP address to unblock: " ip_address
    
    if [ -z "$ip_address" ]; then
        print_error "IP address cannot be empty"
        press_any_key
        return
    fi
    
    csf -dr "$ip_address"
    csf -tr "$ip_address"
    
    print_success "IP $ip_address unblocked"
    press_any_key
}

# Unblock all IPs
unblock_all_ips() {
    if [ ! -d "/etc/csf" ]; then
        print_error "CSF is not installed"
        press_any_key
        return
    fi
    
    print_warning "This will remove all blocked IP addresses"
    read -p "Are you sure? (yes/no): " confirm
    
    if [ "$confirm" != "yes" ]; then
        print_info "Operation cancelled"
        press_any_key
        return
    fi
    
    print_info "Removing all blocks..."
    
    # Clear deny list
    > /etc/csf/csf.deny
    
    # Restart CSF
    csf -r
    
    print_success "All IP blocks removed"
    press_any_key
}

# List blocked IPs
list_blocked_ips() {
    if [ ! -d "/etc/csf" ]; then
        print_error "CSF is not installed"
        press_any_key
        return
    fi
    
    show_header
    echo -e "${CYAN}Blocked IP Addresses:${NC}"
    echo ""
    
    if [ -s /etc/csf/csf.deny ]; then
        cat /etc/csf/csf.deny
    else
        print_info "No IPs are currently blocked"
    fi
    
    echo ""
    echo -e "${CYAN}Temporary Blocks:${NC}"
    csf -t | head -30
    
    echo ""
    press_any_key
}

# Allow port
allow_port() {
    if [ ! -d "/etc/csf" ]; then
        print_error "CSF is not installed"
        press_any_key
        return
    fi
    
    show_header
    echo -e "${CYAN}Allow Port${NC}"
    echo ""
    
    read -p "Enter port number: " port_number
    
    if [ -z "$port_number" ]; then
        print_error "Port number cannot be empty"
        press_any_key
        return
    fi
    
    echo "Select protocol:"
    echo "  1) TCP"
    echo "  2) UDP"
    echo "  3) Both"
    read -p "Enter choice: " protocol_choice
    
    local csf_conf="/etc/csf/csf.conf"
    
    case $protocol_choice in
        1)
            sed -i "s/^TCP_IN = \"/TCP_IN = \"${port_number},/" "$csf_conf"
            sed -i "s/^TCP_OUT = \"/TCP_OUT = \"${port_number},/" "$csf_conf"
            ;;
        2)
            sed -i "s/^UDP_IN = \"/UDP_IN = \"${port_number},/" "$csf_conf"
            sed -i "s/^UDP_OUT = \"/UDP_OUT = \"${port_number},/" "$csf_conf"
            ;;
        3)
            sed -i "s/^TCP_IN = \"/TCP_IN = \"${port_number},/" "$csf_conf"
            sed -i "s/^TCP_OUT = \"/TCP_OUT = \"${port_number},/" "$csf_conf"
            sed -i "s/^UDP_IN = \"/UDP_IN = \"${port_number},/" "$csf_conf"
            sed -i "s/^UDP_OUT = \"/UDP_OUT = \"${port_number},/" "$csf_conf"
            ;;
    esac
    
    csf -r
    print_success "Port $port_number allowed"
    press_any_key
}

# Block port
block_port() {
    if [ ! -d "/etc/csf" ]; then
        print_error "CSF is not installed"
        press_any_key
        return
    fi
    
    show_header
    echo -e "${CYAN}Block Port${NC}"
    echo ""
    
    read -p "Enter port number to block: " port_number
    
    if [ -z "$port_number" ]; then
        print_error "Port number cannot be empty"
        press_any_key
        return
    fi
    
    local csf_conf="/etc/csf/csf.conf"
    
    # Remove port from allowed lists
    sed -i "s/,${port_number}//g" "$csf_conf"
    sed -i "s/${port_number},//g" "$csf_conf"
    
    csf -r
    print_success "Port $port_number blocked"
    press_any_key
}

# Configure CSF menu
configure_csf_menu() {
    if [ ! -d "/etc/csf" ]; then
        print_error "CSF is not installed"
        press_any_key
        return
    fi
    
    show_header
    echo -e "${CYAN}Configure CSF${NC}"
    echo ""
    echo "  1) Edit CSF Configuration"
    echo "  2) Configure Connection Limit"
    echo "  3) Configure Login Failure Detection"
    echo "  4) Configure Port Knock"
    echo "  5) View Current Configuration"
    echo "  0) Back"
    echo ""
    read -p "Enter choice: " config_choice
    
    case $config_choice in
        1)
            ${EDITOR:-nano} /etc/csf/csf.conf
            csf -r
            ;;
        2)
            read -p "Enter connection limit per IP: " conn_limit
            sed -i "s/^CT_LIMIT = .*/CT_LIMIT = \"$conn_limit\"/" /etc/csf/csf.conf
            csf -r
            print_success "Connection limit set to $conn_limit"
            ;;
        3)
            read -p "Enter SSH login failure limit: " ssh_limit
            read -p "Enter FTP login failure limit: " ftp_limit
            sed -i "s/^LF_SSHD = .*/LF_SSHD = \"$ssh_limit\"/" /etc/csf/csf.conf
            sed -i "s/^LF_FTPD = .*/LF_FTPD = \"$ftp_limit\"/" /etc/csf/csf.conf
            csf -r
            print_success "Login failure detection configured"
            ;;
        4)
            print_info "Port Knock configuration..."
            ${EDITOR:-nano} /etc/csf/csf.conf
            csf -r
            ;;
        5)
            less /etc/csf/csf.conf
            ;;
        0) return ;;
    esac
    
    press_any_key
}

# Check CSF status
check_csf_status() {
    if [ ! -d "/etc/csf" ]; then
        print_error "CSF is not installed"
        press_any_key
        return
    fi
    
    show_header
    echo -e "${CYAN}CSF Firewall Status:${NC}"
    echo ""
    
    csf -l | head -50
    
    echo ""
    echo -e "${CYAN}CSF Version:${NC}"
    csf -v
    
    echo ""
    press_any_key
}

# Uninstall CSF
uninstall_csf() {
    if [ ! -d "/etc/csf" ]; then
        print_error "CSF is not installed"
        press_any_key
        return
    fi
    
    print_warning "This will completely remove CSF Firewall"
    read -p "Are you sure? (yes/no): " confirm
    
    if [ "$confirm" != "yes" ]; then
        print_info "Uninstall cancelled"
        press_any_key
        return
    fi
    
    cd /etc/csf || exit
    sh uninstall.sh
    
    print_success "CSF uninstalled"
    press_any_key
}
