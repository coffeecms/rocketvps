#!/bin/bash

################################################################################
# RocketVPS - Mail Server Management Module (Docker-based)
# Support: Mailu (recommended) and BillionMail
################################################################################

MAILSERVER_DIR="/opt/mailserver"
MAILU_CONFIG="${CONFIG_DIR}/mailu.conf"

# Mail server menu
mailserver_menu() {
    while true; do
        show_header
        echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║                 MAIL SERVER MANAGEMENT                        ║${NC}"
        echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo "  ${CYAN}Setup:${NC}"
        echo "  1) Install Mailu Mail Server (Recommended)"
        echo "  2) Install BillionMail"
        echo "  3) Uninstall Mail Server"
        echo ""
        echo "  ${CYAN}Configuration:${NC}"
        echo "  4) Configure Mail Domain"
        echo "  5) Add Mail User"
        echo "  6) List Mail Users"
        echo "  7) Delete Mail User"
        echo "  8) Add Mail Alias"
        echo "  9) SSL Certificate Setup"
        echo ""
        echo "  ${CYAN}Management:${NC}"
        echo "  10) View Mail Server Status"
        echo "  11) View Mail Logs"
        echo "  12) Restart Mail Server"
        echo "  13) Backup Mail Data"
        echo "  14) Access Webmail"
        echo ""
        echo "  0) Back to Main Menu"
        echo ""
        echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
        
        read -p "Enter your choice [0-14]: " mail_choice
        
        case $mail_choice in
            1) install_mailu ;;
            2) install_billionmail ;;
            3) uninstall_mailserver ;;
            4) configure_mail_domain ;;
            5) add_mail_user ;;
            6) list_mail_users ;;
            7) delete_mail_user ;;
            8) add_mail_alias ;;
            9) setup_mail_ssl ;;
            10) view_mail_status ;;
            11) view_mail_logs ;;
            12) restart_mailserver ;;
            13) backup_mail_data ;;
            14) access_webmail ;;
            0) return ;;
            *)
                print_error "Invalid choice"
                sleep 2
                ;;
        esac
    done
}

# Install Mailu
install_mailu() {
    show_header
    print_info "Installing Mailu Mail Server..."
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        print_error "Docker is required. Please install Docker first."
        press_any_key
        return
    fi
    
    # Get configuration
    echo ""
    read -p "Enter your mail domain (e.g., mail.example.com): " mail_domain
    read -p "Enter admin email: " admin_email
    read -p "Enter admin password: " -s admin_password
    echo ""
    
    if [ -z "$mail_domain" ] || [ -z "$admin_email" ] || [ -z "$admin_password" ]; then
        print_error "All fields are required"
        press_any_key
        return
    fi
    
    # Create directory
    mkdir -p "$MAILSERVER_DIR/mailu"
    cd "$MAILSERVER_DIR/mailu"
    
    # Download setup utility
    print_info "Downloading Mailu setup..."
    wget -O setup.py https://raw.githubusercontent.com/Mailu/Mailu/master/setup.py
    python3 setup.py || pip3 install -r https://raw.githubusercontent.com/Mailu/Mailu/master/setup/requirements.txt && python3 setup.py
    
    # Create docker-compose.yml
    cat > docker-compose.yml <<EOF
version: '3.7'

services:
  front:
    image: mailu/nginx:latest
    restart: always
    env_file: mailu.env
    ports:
      - "80:80"
      - "443:443"
      - "25:25"
      - "465:465"
      - "587:587"
      - "110:110"
      - "995:995"
      - "143:143"
      - "993:993"
    volumes:
      - "./certs:/certs"
      - "./overrides/nginx:/overrides:ro"
    depends_on:
      - admin

  admin:
    image: mailu/admin:latest
    restart: always
    env_file: mailu.env
    volumes:
      - "./data:/data"
      - "./dkim:/dkim"
    depends_on:
      - redis

  imap:
    image: mailu/dovecot:latest
    restart: always
    env_file: mailu.env
    volumes:
      - "./mail:/mail"
      - "./overrides/dovecot:/overrides:ro"
    depends_on:
      - front

  smtp:
    image: mailu/postfix:latest
    restart: always
    env_file: mailu.env
    volumes:
      - "./mailqueue:/queue"
      - "./overrides/postfix:/overrides:ro"
    depends_on:
      - front

  antispam:
    image: mailu/rspamd:latest
    restart: always
    env_file: mailu.env
    volumes:
      - "./filter:/var/lib/rspamd"
      - "./overrides/rspamd:/overrides:ro"
    depends_on:
      - front

  webmail:
    image: mailu/roundcube:latest
    restart: always
    env_file: mailu.env
    volumes:
      - "./webmail:/data"
      - "./overrides/roundcube:/overrides:ro"
    depends_on:
      - imap

  redis:
    image: redis:alpine
    restart: always
    volumes:
      - "./redis:/data"

networks:
  default:
    driver: bridge
    ipam:
      driver: default
      config:
        - subnet: 192.168.203.0/24
EOF

    # Create mailu.env
    cat > mailu.env <<EOF
# Mailu Configuration
SECRET_KEY=$(openssl rand -hex 16)
DOMAIN=${mail_domain}
HOSTNAMES=${mail_domain}
POSTMASTER=admin
TLS_FLAVOR=cert
AUTH_RATELIMIT=10/minute;1000/hour
ADMIN=true
WEBMAIL=roundcube
WEBDAV=none
ANTIVIRUS=none
MESSAGE_SIZE_LIMIT=50000000
SUBNET=192.168.203.0/24
EOF

    # Start containers
    print_info "Starting Mailu containers..."
    docker compose up -d
    
    # Wait for services
    print_info "Waiting for services to start..."
    sleep 30
    
    # Create admin account
    docker compose exec -T admin flask mailu admin "$admin_email" "$DOMAIN" "$admin_password" --mode=create
    
    # Save config
    echo "MAIL_DOMAIN=$mail_domain" > "$MAILU_CONFIG"
    echo "ADMIN_EMAIL=$admin_email" >> "$MAILU_CONFIG"
    echo "INSTALL_TYPE=mailu" >> "$MAILU_CONFIG"
    
    print_success "Mailu installed successfully!"
    echo ""
    print_info "Access webmail: https://${mail_domain}"
    print_info "Access admin panel: https://${mail_domain}/admin"
    print_info "Admin email: ${admin_email}"
    echo ""
    print_warning "Don't forget to configure DNS records:"
    echo "  MX    @    ${mail_domain}    10"
    echo "  A     mail ${server_ip}"
    echo ""
    
    log_action "Mailu mail server installed"
    press_any_key
}

# Install BillionMail
install_billionmail() {
    show_header
    print_info "Installing BillionMail..."
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        print_error "Docker is required. Please install Docker first."
        press_any_key
        return
    fi
    
    mkdir -p "$MAILSERVER_DIR/billionmail"
    cd "$MAILSERVER_DIR/billionmail"
    
    # Clone repository
    if [ ! -d "BillionMail" ]; then
        git clone https://github.com/aaPanel/BillionMail.git
    fi
    
    cd BillionMail
    
    # Run installer
    print_info "Running BillionMail installer..."
    bash install.sh
    
    print_success "BillionMail installed!"
    print_info "Access panel at: http://your-server-ip:8888"
    
    press_any_key
}

# Uninstall mail server
uninstall_mailserver() {
    show_header
    print_warning "This will remove the mail server and all data!"
    read -p "Are you sure? (yes/no): " confirm
    
    if [ "$confirm" != "yes" ]; then
        return
    fi
    
    if [ -f "$MAILU_CONFIG" ]; then
        install_type=$(grep "INSTALL_TYPE" "$MAILU_CONFIG" | cut -d= -f2)
        
        if [ "$install_type" = "mailu" ]; then
            cd "$MAILSERVER_DIR/mailu"
            docker compose down -v
        fi
    fi
    
    rm -rf "$MAILSERVER_DIR"
    rm -f "$MAILU_CONFIG"
    
    print_success "Mail server uninstalled"
    press_any_key
}

# Configure mail domain
configure_mail_domain() {
    show_header
    print_info "Configure Mail Domain"
    
    if [ ! -f "$MAILU_CONFIG" ]; then
        print_error "Mail server not installed"
        press_any_key
        return
    fi
    
    read -p "Enter domain to add: " new_domain
    
    cd "$MAILSERVER_DIR/mailu"
    docker compose exec -T admin flask mailu domain "$new_domain"
    
    print_success "Domain $new_domain configured"
    press_any_key
}

# Add mail user
add_mail_user() {
    show_header
    print_info "Add Mail User"
    
    if [ ! -f "$MAILU_CONFIG" ]; then
        print_error "Mail server not installed"
        press_any_key
        return
    fi
    
    source "$MAILU_CONFIG"
    
    read -p "Enter email address: " email
    read -p "Enter password: " -s password
    echo ""
    
    cd "$MAILSERVER_DIR/mailu"
    docker compose exec -T admin flask mailu user "$email" "$password"
    
    print_success "User $email created"
    press_any_key
}

# List mail users
list_mail_users() {
    show_header
    echo -e "${CYAN}Mail Users:${NC}"
    echo ""
    
    if [ ! -f "$MAILU_CONFIG" ]; then
        print_error "Mail server not installed"
        press_any_key
        return
    fi
    
    cd "$MAILSERVER_DIR/mailu"
    docker compose exec -T admin flask mailu user-list
    
    press_any_key
}

# Delete mail user
delete_mail_user() {
    list_mail_users
    echo ""
    read -p "Enter email to delete: " email
    
    cd "$MAILSERVER_DIR/mailu"
    docker compose exec -T admin flask mailu user-delete "$email"
    
    print_success "User $email deleted"
    press_any_key
}

# Add mail alias
add_mail_alias() {
    show_header
    print_info "Add Mail Alias"
    
    read -p "Enter alias email: " alias_email
    read -p "Enter destination email: " dest_email
    
    cd "$MAILSERVER_DIR/mailu"
    docker compose exec -T admin flask mailu alias "$alias_email" "$dest_email"
    
    print_success "Alias created: $alias_email -> $dest_email"
    press_any_key
}

# Setup mail SSL
setup_mail_ssl() {
    show_header
    print_info "SSL Certificate Setup"
    
    source "$MAILU_CONFIG"
    
    print_info "Installing certbot..."
    apt-get install -y certbot
    
    print_info "Obtaining SSL certificate..."
    certbot certonly --standalone -d "$MAIL_DOMAIN"
    
    # Copy certificates
    mkdir -p "$MAILSERVER_DIR/mailu/certs"
    cp /etc/letsencrypt/live/"$MAIL_DOMAIN"/fullchain.pem "$MAILSERVER_DIR/mailu/certs/cert.pem"
    cp /etc/letsencrypt/live/"$MAIL_DOMAIN"/privkey.pem "$MAILSERVER_DIR/mailu/certs/key.pem"
    
    # Restart
    cd "$MAILSERVER_DIR/mailu"
    docker compose restart front
    
    print_success "SSL configured"
    press_any_key
}

# View mail status
view_mail_status() {
    show_header
    echo -e "${CYAN}Mail Server Status:${NC}"
    echo ""
    
    cd "$MAILSERVER_DIR/mailu"
    docker compose ps
    
    press_any_key
}

# View mail logs
view_mail_logs() {
    show_header
    
    echo "Select log to view:"
    echo "1) SMTP logs"
    echo "2) IMAP logs"
    echo "3) Admin logs"
    echo "4) All logs"
    read -p "Choice: " log_choice
    
    cd "$MAILSERVER_DIR/mailu"
    
    case $log_choice in
        1) docker compose logs -f smtp ;;
        2) docker compose logs -f imap ;;
        3) docker compose logs -f admin ;;
        4) docker compose logs -f ;;
    esac
}

# Restart mail server
restart_mailserver() {
    show_header
    print_info "Restarting mail server..."
    
    cd "$MAILSERVER_DIR/mailu"
    docker compose restart
    
    print_success "Mail server restarted"
    press_any_key
}

# Backup mail data
backup_mail_data() {
    show_header
    print_info "Backing up mail data..."
    
    backup_file="${BACKUP_DIR}/mailserver_$(date +%Y%m%d_%H%M%S).tar.gz"
    
    tar -czf "$backup_file" -C "$MAILSERVER_DIR" .
    
    print_success "Backup created: $backup_file"
    press_any_key
}

# Access webmail
access_webmail() {
    show_header
    
    if [ ! -f "$MAILU_CONFIG" ]; then
        print_error "Mail server not installed"
        press_any_key
        return
    fi
    
    source "$MAILU_CONFIG"
    
    echo -e "${CYAN}Webmail Access:${NC}"
    echo ""
    echo "Webmail URL: https://${MAIL_DOMAIN}"
    echo "Admin Panel: https://${MAIL_DOMAIN}/admin"
    echo "Admin Email: ${ADMIN_EMAIL}"
    echo ""
    
    press_any_key
}
