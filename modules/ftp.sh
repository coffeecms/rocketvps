#!/bin/bash

################################################################################
# RocketVPS - FTP Management Module
################################################################################

# FTP menu
ftp_menu() {
    while true; do
        show_header
        echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║                     FTP MANAGEMENT                            ║${NC}"
        echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo "  1) Install vsftpd"
        echo "  2) Add FTP User for Domain"
        echo "  3) Edit FTP User"
        echo "  4) Delete FTP User"
        echo "  5) List All FTP Users"
        echo "  6) Change FTP User Password"
        echo "  7) Enable/Disable FTP User"
        echo "  8) Configure vsftpd"
        echo "  9) Restart vsftpd"
        echo "  10) View vsftpd Status"
        echo ""
        echo "  0) Back to Main Menu"
        echo ""
        echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
        
        read -p "Enter your choice [0-10]: " ftp_choice
        
        case $ftp_choice in
            1) install_vsftpd ;;
            2) add_ftp_user ;;
            3) edit_ftp_user ;;
            4) delete_ftp_user ;;
            5) list_ftp_users ;;
            6) change_ftp_password ;;
            7) toggle_ftp_user ;;
            8) configure_vsftpd_menu ;;
            9) restart_vsftpd ;;
            10) check_vsftpd_status ;;
            0) return ;;
            *)
                print_error "Invalid choice"
                sleep 2
                ;;
        esac
    done
}

# Install vsftpd
install_vsftpd() {
    print_info "Installing vsftpd..."
    
    if command -v vsftpd &> /dev/null; then
        print_warning "vsftpd is already installed"
        vsftpd -v
        press_any_key
        return
    fi
    
    if [[ "$OS" == "ubuntu" || "$OS" == "debian" ]]; then
        apt-get update
        apt-get install -y vsftpd
    elif [[ "$OS" == "centos" || "$OS" == "rhel" ]]; then
        yum install -y vsftpd
    fi
    
    # Configure vsftpd
    configure_vsftpd_secure
    
    # Enable and start vsftpd
    systemctl enable vsftpd
    systemctl start vsftpd
    
    if systemctl is-active --quiet vsftpd; then
        print_success "vsftpd installed successfully"
        
        # Open FTP port in firewall if CSF is installed
        if [ -f /etc/csf/csf.conf ]; then
            sed -i 's/TCP_IN = "/TCP_IN = "21,/' /etc/csf/csf.conf
            csf -r 2>/dev/null
        fi
    else
        print_error "vsftpd installation failed"
    fi
    
    press_any_key
}

# Configure vsftpd with secure defaults
configure_vsftpd_secure() {
    local vsftpd_conf="/etc/vsftpd.conf"
    
    if [ ! -f "$vsftpd_conf" ]; then
        vsftpd_conf="/etc/vsftpd/vsftpd.conf"
    fi
    
    # Backup original
    cp "$vsftpd_conf" "${vsftpd_conf}.bak.$(date +%Y%m%d_%H%M%S)"
    
    # Create secure configuration
    cat > "$vsftpd_conf" <<'EOF'
# vsftpd configuration - RocketVPS
listen=YES
listen_ipv6=NO
anonymous_enable=NO
local_enable=YES
write_enable=YES
local_umask=022
dirmessage_enable=YES
use_localtime=YES
xferlog_enable=YES
connect_from_port_20=YES
chroot_local_user=YES
secure_chroot_dir=/var/run/vsftpd/empty
pam_service_name=vsftpd
rsa_cert_file=/etc/ssl/certs/ssl-cert-snakeoil.pem
rsa_private_key_file=/etc/ssl/private/ssl-cert-snakeoil.key
ssl_enable=NO
allow_writeable_chroot=YES

# Performance
xferlog_std_format=YES
async_abor_enable=YES

# Security
hide_ids=YES
pasv_min_port=40000
pasv_max_port=50000

# User list
userlist_enable=YES
userlist_file=/etc/vsftpd.user_list
userlist_deny=NO
EOF
    
    # Create user list file
    touch /etc/vsftpd.user_list
    
    # Create empty chroot directory
    mkdir -p /var/run/vsftpd/empty
}

# Add FTP user for domain
add_ftp_user() {
    show_header
    echo -e "${CYAN}Add FTP User${NC}"
    echo ""
    
    # List domains
    if [ -s "${DOMAIN_LIST_FILE}" ]; then
        echo "Available domains:"
        local domain_index=1
        declare -A domain_array
        
        while IFS='|' read -r domain root date_added; do
            echo "  $domain_index) $domain (Root: $root)"
            domain_array[$domain_index]=$domain
            ((domain_index++))
        done < "${DOMAIN_LIST_FILE}"
        
        echo ""
        read -p "Select domain number (or enter domain name): " domain_input
        
        if [[ "$domain_input" =~ ^[0-9]+$ ]] && [ -n "${domain_array[$domain_input]}" ]; then
            domain_name="${domain_array[$domain_input]}"
        else
            domain_name="$domain_input"
        fi
    else
        read -p "Enter domain name: " domain_name
    fi
    
    if [ -z "$domain_name" ]; then
        print_error "Domain name cannot be empty"
        press_any_key
        return
    fi
    
    # Get domain root directory
    local domain_root=$(grep "^${domain_name}|" "${DOMAIN_LIST_FILE}" | cut -d'|' -f2)
    if [ -z "$domain_root" ]; then
        read -p "Enter FTP home directory: " domain_root
    fi
    
    read -p "Enter FTP username: " ftp_user
    read -s -p "Enter FTP password: " ftp_password
    echo ""
    
    if [ -z "$ftp_user" ] || [ -z "$ftp_password" ]; then
        print_error "Username and password cannot be empty"
        press_any_key
        return
    fi
    
    # Create system user
    useradd -d "$domain_root" -s /bin/bash "$ftp_user"
    echo "${ftp_user}:${ftp_password}" | chpasswd
    
    # Add to vsftpd user list
    echo "$ftp_user" >> /etc/vsftpd.user_list
    
    # Set permissions
    chown -R "${ftp_user}:${ftp_user}" "$domain_root"
    chmod -R 755 "$domain_root"
    
    print_success "FTP user $ftp_user created for domain $domain_name"
    print_info "Home directory: $domain_root"
    
    press_any_key
}

# Edit FTP user
edit_ftp_user() {
    list_ftp_users
    echo ""
    read -p "Enter FTP username to edit: " ftp_user
    
    if ! id "$ftp_user" &>/dev/null; then
        print_error "User $ftp_user does not exist"
        press_any_key
        return
    fi
    
    echo ""
    echo "What would you like to edit?"
    echo "  1) Change home directory"
    echo "  2) Change password"
    echo "  3) Change shell"
    echo ""
    read -p "Enter choice [1-3]: " edit_choice
    
    case $edit_choice in
        1)
            read -p "Enter new home directory: " new_home
            usermod -d "$new_home" "$ftp_user"
            chown -R "${ftp_user}:${ftp_user}" "$new_home"
            print_success "Home directory updated"
            ;;
        2)
            read -s -p "Enter new password: " new_password
            echo ""
            echo "${ftp_user}:${new_password}" | chpasswd
            print_success "Password updated"
            ;;
        3)
            echo "  1) /bin/bash"
            echo "  2) /usr/sbin/nologin (FTP only)"
            read -p "Select shell: " shell_choice
            if [ "$shell_choice" = "1" ]; then
                usermod -s /bin/bash "$ftp_user"
            else
                usermod -s /usr/sbin/nologin "$ftp_user"
            fi
            print_success "Shell updated"
            ;;
    esac
    
    press_any_key
}

# Delete FTP user
delete_ftp_user() {
    list_ftp_users
    echo ""
    read -p "Enter FTP username to delete: " ftp_user
    
    if ! id "$ftp_user" &>/dev/null; then
        print_error "User $ftp_user does not exist"
        press_any_key
        return
    fi
    
    print_warning "This will delete user $ftp_user"
    read -p "Delete home directory as well? (yes/no): " delete_home
    
    # Remove from vsftpd user list
    sed -i "/^${ftp_user}$/d" /etc/vsftpd.user_list
    
    # Delete user
    if [ "$delete_home" = "yes" ]; then
        userdel -r "$ftp_user"
        print_success "User $ftp_user and home directory deleted"
    else
        userdel "$ftp_user"
        print_success "User $ftp_user deleted (home directory preserved)"
    fi
    
    press_any_key
}

# List all FTP users
list_ftp_users() {
    show_header
    echo -e "${CYAN}FTP Users:${NC}"
    echo ""
    
    if [ -f /etc/vsftpd.user_list ]; then
        echo -e "${GREEN}Username            | Home Directory                    | Status${NC}"
        echo "───────────────────────────────────────────────────────────────────────"
        
        while read -r user; do
            if id "$user" &>/dev/null; then
                local home_dir=$(eval echo ~$user)
                local status="Active"
                
                if ! passwd -S "$user" 2>/dev/null | grep -q "P"; then
                    status="Locked"
                fi
                
                printf "%-19s | %-33s | %s\n" "$user" "$home_dir" "$status"
            fi
        done < /etc/vsftpd.user_list
    else
        print_warning "No FTP users found"
    fi
    
    echo ""
}

# Change FTP password
change_ftp_password() {
    list_ftp_users
    echo ""
    read -p "Enter FTP username: " ftp_user
    
    if ! id "$ftp_user" &>/dev/null; then
        print_error "User $ftp_user does not exist"
        press_any_key
        return
    fi
    
    read -s -p "Enter new password: " new_password
    echo ""
    read -s -p "Confirm new password: " confirm_password
    echo ""
    
    if [ "$new_password" != "$confirm_password" ]; then
        print_error "Passwords do not match"
        press_any_key
        return
    fi
    
    echo "${ftp_user}:${new_password}" | chpasswd
    print_success "Password updated for $ftp_user"
    
    press_any_key
}

# Enable/Disable FTP user
toggle_ftp_user() {
    list_ftp_users
    echo ""
    read -p "Enter FTP username: " ftp_user
    
    if ! id "$ftp_user" &>/dev/null; then
        print_error "User $ftp_user does not exist"
        press_any_key
        return
    fi
    
    echo ""
    echo "  1) Enable user"
    echo "  2) Disable user"
    echo ""
    read -p "Enter choice: " action
    
    case $action in
        1)
            passwd -u "$ftp_user"
            print_success "User $ftp_user enabled"
            ;;
        2)
            passwd -l "$ftp_user"
            print_success "User $ftp_user disabled"
            ;;
    esac
    
    press_any_key
}

# Configure vsftpd menu
configure_vsftpd_menu() {
    show_header
    echo -e "${CYAN}Configure vsftpd${NC}"
    echo ""
    echo "  1) Enable/Disable SSL/TLS"
    echo "  2) Change passive port range"
    echo "  3) Edit configuration file"
    echo "  4) View current configuration"
    echo "  0) Back"
    echo ""
    read -p "Enter choice: " config_choice
    
    local vsftpd_conf="/etc/vsftpd.conf"
    if [ ! -f "$vsftpd_conf" ]; then
        vsftpd_conf="/etc/vsftpd/vsftpd.conf"
    fi
    
    case $config_choice in
        1)
            read -p "Enable SSL/TLS? (yes/no): " enable_ssl
            if [ "$enable_ssl" = "yes" ]; then
                sed -i 's/^ssl_enable=.*/ssl_enable=YES/' "$vsftpd_conf"
                print_success "SSL/TLS enabled"
            else
                sed -i 's/^ssl_enable=.*/ssl_enable=NO/' "$vsftpd_conf"
                print_success "SSL/TLS disabled"
            fi
            systemctl restart vsftpd
            ;;
        2)
            read -p "Enter minimum passive port: " min_port
            read -p "Enter maximum passive port: " max_port
            sed -i "s/^pasv_min_port=.*/pasv_min_port=$min_port/" "$vsftpd_conf"
            sed -i "s/^pasv_max_port=.*/pasv_max_port=$max_port/" "$vsftpd_conf"
            print_success "Passive port range updated"
            systemctl restart vsftpd
            ;;
        3)
            ${EDITOR:-nano} "$vsftpd_conf"
            systemctl restart vsftpd
            ;;
        4)
            cat "$vsftpd_conf"
            ;;
        0) return ;;
    esac
    
    press_any_key
}

# Restart vsftpd
restart_vsftpd() {
    print_info "Restarting vsftpd..."
    systemctl restart vsftpd
    
    if systemctl is-active --quiet vsftpd; then
        print_success "vsftpd restarted successfully"
    else
        print_error "Failed to restart vsftpd"
    fi
    
    press_any_key
}

# Check vsftpd status
check_vsftpd_status() {
    show_header
    echo -e "${CYAN}vsftpd Service Status:${NC}"
    echo ""
    systemctl status vsftpd
    echo ""
    press_any_key
}
