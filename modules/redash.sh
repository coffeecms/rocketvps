#!/bin/bash

################################################################################
# RocketVPS - Redash Business Intelligence Module (Docker-based)
# Data visualization and dashboards
################################################################################

REDASH_DIR="/opt/redash"
REDASH_CONFIG="${CONFIG_DIR}/redash.conf"

# Redash menu
redash_menu() {
    while true; do
        show_header
        echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║                 REDASH BUSINESS INTELLIGENCE                  ║${NC}"
        echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo "  ${CYAN}Setup:${NC}"
        echo "  1) Install Redash"
        echo "  2) Uninstall Redash"
        echo ""
        echo "  ${CYAN}Configuration:${NC}"
        echo "  3) Configure Domain & SSL"
        echo "  4) Add Data Source"
        echo "  5) Configure SMTP (Email)"
        echo "  6) Configure Authentication"
        echo ""
        echo "  ${CYAN}User Management:${NC}"
        echo "  7) Create User"
        echo "  8) List Users"
        echo "  9) Reset User Password"
        echo ""
        echo "  ${CYAN}Management:${NC}"
        echo "  10) Start Redash"
        echo "  11) Stop Redash"
        echo "  12) Restart Redash"
        echo "  13) View Status"
        echo "  14) View Logs"
        echo ""
        echo "  ${CYAN}Data:${NC}"
        echo "  15) Backup Database"
        echo "  16) Restore Database"
        echo "  17) View System Info"
        echo ""
        echo "  0) Back to Main Menu"
        echo ""
        echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
        
        read -p "Enter your choice [0-17]: " redash_choice
        
        case $redash_choice in
            1) install_redash ;;
            2) uninstall_redash ;;
            3) configure_redash_domain ;;
            4) add_redash_datasource ;;
            5) configure_redash_smtp ;;
            6) configure_redash_auth ;;
            7) create_redash_user ;;
            8) list_redash_users ;;
            9) reset_redash_password ;;
            10) start_redash ;;
            11) stop_redash ;;
            12) restart_redash ;;
            13) view_redash_status ;;
            14) view_redash_logs ;;
            15) backup_redash ;;
            16) restore_redash ;;
            17) view_redash_info ;;
            0) return ;;
            *)
                print_error "Invalid choice"
                sleep 2
                ;;
        esac
    done
}

# Install Redash
install_redash() {
    show_header
    print_info "Installing Redash Business Intelligence Platform..."
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        print_error "Docker is required. Please install Docker first."
        press_any_key
        return
    fi
    
    # Get configuration
    echo ""
    read -p "Enter domain for Redash (e.g., redash.example.com): " redash_domain
    read -p "Enter admin email: " admin_email
    read -p "Enter admin name: " admin_name
    read -p "Enter admin password: " -s admin_password
    echo ""
    
    if [ -z "$redash_domain" ] || [ -z "$admin_email" ] || [ -z "$admin_password" ]; then
        print_error "All fields are required"
        press_any_key
        return
    fi
    
    # Create directory
    mkdir -p "$REDASH_DIR"
    cd "$REDASH_DIR"
    
    # Generate secrets
    local cookie_secret=$(openssl rand -hex 32)
    local secret_key=$(openssl rand -hex 32)
    local postgres_password=$(openssl rand -hex 16)
    
    # Create docker-compose.yml
    cat > docker-compose.yml <<EOF
version: '3.8'

services:
  server:
    image: redash/redash:latest
    container_name: redash_server
    command: server
    depends_on:
      - postgres
      - redis
    ports:
      - "5000:5000"
    environment:
      PYTHONUNBUFFERED: 0
      REDASH_LOG_LEVEL: "INFO"
      REDASH_REDIS_URL: "redis://redis:6379/0"
      REDASH_DATABASE_URL: "postgresql://redash:${postgres_password}@postgres/redash"
      REDASH_COOKIE_SECRET: "${cookie_secret}"
      REDASH_SECRET_KEY: "${secret_key}"
      REDASH_HOST: "https://${redash_domain}"
    restart: always
    volumes:
      - ./data:/app/data
    networks:
      - redash_network

  worker:
    image: redash/redash:latest
    container_name: redash_worker
    command: scheduler
    depends_on:
      - server
    environment:
      PYTHONUNBUFFERED: 0
      REDASH_LOG_LEVEL: "INFO"
      REDASH_REDIS_URL: "redis://redis:6379/0"
      REDASH_DATABASE_URL: "postgresql://redash:${postgres_password}@postgres/redash"
      QUEUES: "queries,scheduled_queries,celery,schemas"
      WORKERS_COUNT: 2
    restart: always
    networks:
      - redash_network

  postgres:
    image: postgres:13-alpine
    container_name: redash_postgres
    environment:
      POSTGRES_USER: redash
      POSTGRES_PASSWORD: ${postgres_password}
      POSTGRES_DB: redash
    volumes:
      - postgres_data:/var/lib/postgresql/data
    restart: always
    networks:
      - redash_network

  redis:
    image: redis:7-alpine
    container_name: redash_redis
    restart: always
    volumes:
      - redis_data:/data
    networks:
      - redash_network

volumes:
  postgres_data:
  redis_data:

networks:
  redash_network:
    driver: bridge
EOF

    # Create .env
    cat > .env <<EOF
REDASH_DOMAIN=${redash_domain}
ADMIN_EMAIL=${admin_email}
ADMIN_NAME=${admin_name}
ADMIN_PASSWORD=${admin_password}
POSTGRES_PASSWORD=${postgres_password}
COOKIE_SECRET=${cookie_secret}
SECRET_KEY=${secret_key}
EOF

    chmod 600 .env
    
    # Start services
    print_info "Starting Redash services..."
    docker compose up -d
    
    # Wait for PostgreSQL
    print_info "Waiting for database..."
    sleep 20
    
    # Create database schema
    print_info "Creating database schema..."
    docker compose exec -T server ./manage.py database create_tables
    
    # Create admin user
    print_info "Creating admin user..."
    docker compose exec -T server ./manage.py users create \
        --admin \
        --password "$admin_password" \
        "$admin_email" \
        "$admin_name"
    
    # Configure Nginx
    configure_redash_nginx "$redash_domain"
    
    # Save config
    cat > "$REDASH_CONFIG" <<EOF
REDASH_DOMAIN=${redash_domain}
ADMIN_EMAIL=${admin_email}
ADMIN_NAME=${admin_name}
POSTGRES_PASSWORD=${postgres_password}
INSTALLED_DATE=$(date +%Y-%m-%d)
EOF

    print_success "Redash installed successfully!"
    echo ""
    print_info "Access URL: https://${redash_domain}"
    print_info "Admin Email: ${admin_email}"
    print_info "Admin Password: ${admin_password}"
    echo ""
    print_warning "Next steps:"
    echo "  1. Configure DNS A record: ${redash_domain} -> ${server_ip}"
    echo "  2. Setup SSL certificate (option 3)"
    echo "  3. Add data sources (option 4)"
    echo ""
    
    log_action "Redash BI platform installed"
    press_any_key
}

# Configure Redash Nginx
configure_redash_nginx() {
    local domain=$1
    
    cat > "${NGINX_VHOST_DIR}/${domain}" <<EOF
server {
    listen 80;
    listen [::]:80;
    server_name ${domain};
    
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name ${domain};
    
    # SSL configuration
    ssl_certificate /etc/ssl/certs/ssl-cert-snakeoil.pem;
    ssl_certificate_key /etc/ssl/private/ssl-cert-snakeoil.key;
    
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    
    # Logs
    access_log /var/log/nginx/${domain}_access.log;
    error_log /var/log/nginx/${domain}_error.log;
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    
    location / {
        proxy_pass http://localhost:5000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # Increase timeouts for long queries
        proxy_connect_timeout 300;
        proxy_send_timeout 300;
        proxy_read_timeout 300;
    }
}
EOF

    nginx -t && systemctl reload nginx
    print_success "Nginx configured for $domain"
}

# Uninstall Redash
uninstall_redash() {
    show_header
    print_warning "This will remove Redash and all data!"
    read -p "Create backup before uninstalling? (y/n): " do_backup
    
    if [[ "$do_backup" =~ ^[Yy]$ ]]; then
        backup_redash
    fi
    
    read -p "Proceed with uninstallation? (yes/no): " confirm
    
    if [ "$confirm" != "yes" ]; then
        return
    fi
    
    if [ -d "$REDASH_DIR" ]; then
        cd "$REDASH_DIR"
        docker compose down -v
    fi
    
    # Remove Nginx config
    if [ -f "$REDASH_CONFIG" ]; then
        source "$REDASH_CONFIG"
        rm -f "${NGINX_VHOST_DIR}/${REDASH_DOMAIN}"
        nginx -t && systemctl reload nginx
    fi
    
    read -p "Delete all data? (y/n): " delete_data
    if [[ "$delete_data" =~ ^[Yy]$ ]]; then
        rm -rf "$REDASH_DIR"
    fi
    
    rm -f "$REDASH_CONFIG"
    
    print_success "Redash uninstalled"
    press_any_key
}

# Configure domain
configure_redash_domain() {
    show_header
    print_info "Configure Redash Domain & SSL"
    
    if [ ! -f "$REDASH_CONFIG" ]; then
        print_error "Redash not installed"
        press_any_key
        return
    fi
    
    source "$REDASH_CONFIG"
    
    # SSL setup
    print_info "Setting up SSL certificate..."
    apt-get install -y certbot python3-certbot-nginx
    
    certbot --nginx -d "$REDASH_DOMAIN" --non-interactive --agree-tos -m "$ADMIN_EMAIL"
    
    print_success "SSL configured"
    press_any_key
}

# Add data source
add_redash_datasource() {
    show_header
    print_info "Add Data Source"
    echo ""
    echo "Data source types:"
    echo "  1) PostgreSQL"
    echo "  2) MySQL"
    echo "  3) MongoDB"
    echo "  4) Redis"
    echo "  5) Other (add via web interface)"
    echo ""
    read -p "Select type [1-5]: " ds_type
    
    case $ds_type in
        1|2|3|4)
            print_info "Please add the data source via web interface:"
            source "$REDASH_CONFIG"
            echo ""
            echo "1. Go to: https://${REDASH_DOMAIN}/data_sources/new"
            echo "2. Select data source type"
            echo "3. Enter connection details"
            echo "4. Test connection and save"
            ;;
        5)
            print_info "Add via web interface: Settings > Data Sources > New Data Source"
            ;;
    esac
    
    press_any_key
}

# Configure SMTP
configure_redash_smtp() {
    show_header
    print_info "Configure SMTP Settings"
    echo ""
    read -p "SMTP Host: " smtp_host
    read -p "SMTP Port (default 587): " smtp_port
    smtp_port=${smtp_port:-587}
    read -p "SMTP Username: " smtp_user
    read -p "SMTP Password: " -s smtp_pass
    echo ""
    
    cd "$REDASH_DIR"
    
    # Add to docker-compose
    cat >> docker-compose.yml <<EOF
      REDASH_MAIL_SERVER: "${smtp_host}"
      REDASH_MAIL_PORT: ${smtp_port}
      REDASH_MAIL_USE_TLS: "true"
      REDASH_MAIL_USERNAME: "${smtp_user}"
      REDASH_MAIL_PASSWORD: "${smtp_pass}"
      REDASH_MAIL_DEFAULT_SENDER: "${smtp_user}"
EOF

    docker compose restart
    
    print_success "SMTP configured"
    press_any_key
}

# Configure authentication
configure_redash_auth() {
    show_header
    echo "Authentication options:"
    echo "  1) Enable Google OAuth"
    echo "  2) Enable SAML"
    echo "  3) Disable password login"
    echo "0) Back"
    echo ""
    read -p "Choice: " auth_choice
    
    print_info "Please configure via web interface:"
    source "$REDASH_CONFIG"
    echo "Settings > Settings > Authentication"
    echo "URL: https://${REDASH_DOMAIN}/settings/organization"
    
    press_any_key
}

# Create user
create_redash_user() {
    show_header
    read -p "Email: " user_email
    read -p "Name: " user_name
    read -p "Password: " -s user_password
    echo ""
    read -p "Make admin? (y/n): " is_admin
    
    cd "$REDASH_DIR"
    
    if [[ "$is_admin" =~ ^[Yy]$ ]]; then
        docker compose exec -T server ./manage.py users create \
            --admin --password "$user_password" "$user_email" "$user_name"
    else
        docker compose exec -T server ./manage.py users create \
            --password "$user_password" "$user_email" "$user_name"
    fi
    
    print_success "User created"
    press_any_key
}

# List users
list_redash_users() {
    show_header
    echo -e "${CYAN}Redash Users:${NC}"
    echo ""
    
    cd "$REDASH_DIR"
    docker compose exec -T postgres psql -U redash -d redash \
        -c "SELECT id, email, name, created_at FROM users;"
    
    press_any_key
}

# Reset password
reset_redash_password() {
    list_redash_users
    echo ""
    read -p "Enter user email: " user_email
    read -p "Enter new password: " -s new_password
    echo ""
    
    cd "$REDASH_DIR"
    docker compose exec -T server ./manage.py users password "$user_email" "$new_password"
    
    print_success "Password reset"
    press_any_key
}

# Start/Stop/Restart
start_redash() {
    print_info "Starting Redash..."
    cd "$REDASH_DIR"
    docker compose start
    print_success "Redash started"
    press_any_key
}

stop_redash() {
    print_info "Stopping Redash..."
    cd "$REDASH_DIR"
    docker compose stop
    print_success "Redash stopped"
    press_any_key
}

restart_redash() {
    print_info "Restarting Redash..."
    cd "$REDASH_DIR"
    docker compose restart
    print_success "Redash restarted"
    press_any_key
}

# View status
view_redash_status() {
    show_header
    echo -e "${CYAN}Redash Status:${NC}"
    echo ""
    cd "$REDASH_DIR"
    docker compose ps
    press_any_key
}

# View logs
view_redash_logs() {
    echo "Select log:"
    echo "1) Server logs"
    echo "2) Worker logs"
    echo "3) All logs"
    read -p "Choice: " log_choice
    
    cd "$REDASH_DIR"
    case $log_choice in
        1) docker compose logs -f server ;;
        2) docker compose logs -f worker ;;
        3) docker compose logs -f ;;
    esac
}

# Backup
backup_redash() {
    show_header
    print_info "Backing up Redash..."
    
    backup_file="${BACKUP_DIR}/redash_$(date +%Y%m%d_%H%M%S).sql"
    
    cd "$REDASH_DIR"
    source .env
    
    docker compose exec -T postgres pg_dump -U redash redash > "$backup_file"
    
    print_success "Backup created: $backup_file"
    press_any_key
}

# Restore
restore_redash() {
    show_header
    echo "Available backups:"
    ls -lh "${BACKUP_DIR}"/redash_*.sql
    echo ""
    read -p "Enter backup file path: " backup_file
    
    if [ ! -f "$backup_file" ]; then
        print_error "Backup file not found"
        press_any_key
        return
    fi
    
    print_warning "This will replace current database!"
    read -p "Continue? (y/n): " confirm
    
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        cd "$REDASH_DIR"
        docker compose exec -T postgres psql -U redash redash < "$backup_file"
        print_success "Restore completed"
    fi
    
    press_any_key
}

# View info
view_redash_info() {
    show_header
    
    if [ ! -f "$REDASH_CONFIG" ]; then
        print_error "Redash not installed"
        press_any_key
        return
    fi
    
    source "$REDASH_CONFIG"
    
    echo -e "${CYAN}Redash Information:${NC}"
    echo ""
    echo "URL: https://${REDASH_DOMAIN}"
    echo "Admin Email: ${ADMIN_EMAIL}"
    echo "Installed: ${INSTALLED_DATE}"
    echo ""
    
    press_any_key
}
