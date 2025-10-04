#!/bin/bash

################################################################################
# RocketVPS - n8n Automation Platform Module (Docker-based)
# Workflow automation and integration platform
################################################################################

N8N_DIR="/opt/n8n"
N8N_CONFIG="${CONFIG_DIR}/n8n.conf"

# n8n menu
n8n_menu() {
    while true; do
        show_header
        echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║                  N8N AUTOMATION PLATFORM                      ║${NC}"
        echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo "  ${CYAN}Setup:${NC}"
        echo "  1) Install n8n"
        echo "  2) Uninstall n8n"
        echo ""
        echo "  ${CYAN}Configuration:${NC}"
        echo "  3) Configure Domain & SSL"
        echo "  4) Configure Webhooks"
        echo "  5) Set Timezone"
        echo "  6) Configure Execution Settings"
        echo ""
        echo "  ${CYAN}Management:${NC}"
        echo "  7) Start n8n"
        echo "  8) Stop n8n"
        echo "  9) Restart n8n"
        echo "  10) View n8n Status"
        echo "  11) View n8n Logs"
        echo ""
        echo "  ${CYAN}Data Management:${NC}"
        echo "  12) Backup Workflows"
        echo "  13) Restore Workflows"
        echo "  14) Export All Workflows"
        echo "  15) Import Workflows"
        echo ""
        echo "  ${CYAN}Credentials:${NC}"
        echo "  16) Change Admin Password"
        echo "  17) View Access Info"
        echo ""
        echo "  0) Back to Main Menu"
        echo ""
        echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
        
        read -p "Enter your choice [0-17]: " n8n_choice
        
        case $n8n_choice in
            1) install_n8n ;;
            2) uninstall_n8n ;;
            3) configure_n8n_domain ;;
            4) configure_n8n_webhooks ;;
            5) set_n8n_timezone ;;
            6) configure_n8n_execution ;;
            7) start_n8n ;;
            8) stop_n8n ;;
            9) restart_n8n ;;
            10) view_n8n_status ;;
            11) view_n8n_logs ;;
            12) backup_n8n ;;
            13) restore_n8n ;;
            14) export_n8n_workflows ;;
            15) import_n8n_workflows ;;
            16) change_n8n_password ;;
            17) view_n8n_info ;;
            0) return ;;
            *)
                print_error "Invalid choice"
                sleep 2
                ;;
        esac
    done
}

# Install n8n
install_n8n() {
    show_header
    print_info "Installing n8n Automation Platform..."
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        print_error "Docker is required. Please install Docker first."
        press_any_key
        return
    fi
    
    # Get configuration
    echo ""
    read -p "Enter domain for n8n (e.g., n8n.example.com): " n8n_domain
    read -p "Enter admin email: " n8n_email
    read -p "Enter admin password: " -s n8n_password
    echo ""
    read -p "Enter timezone (e.g., Asia/Ho_Chi_Minh): " n8n_timezone
    n8n_timezone=${n8n_timezone:-UTC}
    
    if [ -z "$n8n_domain" ] || [ -z "$n8n_password" ]; then
        print_error "Domain and password are required"
        press_any_key
        return
    fi
    
    # Create directory
    mkdir -p "$N8N_DIR"/{data,backup}
    cd "$N8N_DIR"
    
    # Generate encryption key
    local encryption_key=$(openssl rand -hex 32)
    
    # Create docker-compose.yml
    cat > docker-compose.yml <<EOF
version: '3.8'

services:
  n8n:
    image: n8nio/n8n:latest
    restart: always
    container_name: n8n
    ports:
      - "5678:5678"
    environment:
      # Basic configuration
      - N8N_BASIC_AUTH_ACTIVE=true
      - N8N_BASIC_AUTH_USER=admin
      - N8N_BASIC_AUTH_PASSWORD=${n8n_password}
      
      # Domain & SSL
      - N8N_HOST=${n8n_domain}
      - N8N_PORT=5678
      - N8N_PROTOCOL=https
      - WEBHOOK_URL=https://${n8n_domain}/
      
      # Database (SQLite by default)
      - DB_TYPE=sqlite
      
      # Timezone
      - GENERIC_TIMEZONE=${n8n_timezone}
      - TZ=${n8n_timezone}
      
      # Security
      - N8N_ENCRYPTION_KEY=${encryption_key}
      
      # Execution
      - EXECUTIONS_PROCESS=main
      - EXECUTIONS_TIMEOUT=300
      - EXECUTIONS_TIMEOUT_MAX=3600
      
      # Performance
      - N8N_METRICS=true
      
    volumes:
      - ./data:/home/node/.n8n
      - ./backup:/backup
    
    networks:
      - n8n_network

networks:
  n8n_network:
    driver: bridge
EOF

    # Create .env file
    cat > .env <<EOF
N8N_DOMAIN=${n8n_domain}
N8N_EMAIL=${n8n_email}
N8N_PASSWORD=${n8n_password}
N8N_TIMEZONE=${n8n_timezone}
ENCRYPTION_KEY=${encryption_key}
EOF

    chmod 600 .env
    
    # Start container
    print_info "Starting n8n..."
    docker compose up -d
    
    # Wait for service
    print_info "Waiting for n8n to start..."
    sleep 15
    
    # Configure Nginx
    configure_n8n_nginx "$n8n_domain"
    
    # Save config
    cat > "$N8N_CONFIG" <<EOF
N8N_DOMAIN=${n8n_domain}
N8N_EMAIL=${n8n_email}
INSTALLED_DATE=$(date +%Y-%m-%d)
EOF

    print_success "n8n installed successfully!"
    echo ""
    print_info "Access URL: https://${n8n_domain}"
    print_info "Username: admin"
    print_info "Password: ${n8n_password}"
    echo ""
    print_warning "Next steps:"
    echo "  1. Configure DNS A record: ${n8n_domain} -> ${server_ip}"
    echo "  2. Setup SSL certificate (option 3)"
    echo "  3. Access the web interface"
    echo ""
    
    log_action "n8n automation platform installed"
    press_any_key
}

# Configure n8n Nginx
configure_n8n_nginx() {
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
    
    # SSL configuration (update with your certificates)
    ssl_certificate /etc/ssl/certs/ssl-cert-snakeoil.pem;
    ssl_certificate_key /etc/ssl/private/ssl-cert-snakeoil.key;
    
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;
    
    # Logs
    access_log /var/log/nginx/${domain}_access.log;
    error_log /var/log/nginx/${domain}_error.log;
    
    # Proxy settings
    location / {
        proxy_pass http://localhost:5678;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # Increase timeouts for long-running workflows
        proxy_connect_timeout 300;
        proxy_send_timeout 300;
        proxy_read_timeout 300;
    }
}
EOF

    nginx -t && systemctl reload nginx
    print_success "Nginx configured for $domain"
}

# Uninstall n8n
uninstall_n8n() {
    show_header
    print_warning "This will remove n8n and all workflows!"
    read -p "Create backup before uninstalling? (y/n): " do_backup
    
    if [[ "$do_backup" =~ ^[Yy]$ ]]; then
        backup_n8n
    fi
    
    read -p "Proceed with uninstallation? (yes/no): " confirm
    
    if [ "$confirm" != "yes" ]; then
        return
    fi
    
    if [ -d "$N8N_DIR" ]; then
        cd "$N8N_DIR"
        docker compose down -v
    fi
    
    # Remove Nginx config
    if [ -f "$N8N_CONFIG" ]; then
        source "$N8N_CONFIG"
        rm -f "${NGINX_VHOST_DIR}/${N8N_DOMAIN}"
        nginx -t && systemctl reload nginx
    fi
    
    read -p "Delete all data? (y/n): " delete_data
    if [[ "$delete_data" =~ ^[Yy]$ ]]; then
        rm -rf "$N8N_DIR"
    fi
    
    rm -f "$N8N_CONFIG"
    
    print_success "n8n uninstalled"
    press_any_key
}

# Configure domain
configure_n8n_domain() {
    show_header
    print_info "Configure n8n Domain & SSL"
    
    if [ ! -f "$N8N_CONFIG" ]; then
        print_error "n8n not installed"
        press_any_key
        return
    fi
    
    source "$N8N_CONFIG"
    
    echo ""
    echo "Current domain: $N8N_DOMAIN"
    read -p "Enter new domain (or press Enter to keep current): " new_domain
    
    if [ -n "$new_domain" ]; then
        # Update docker-compose
        cd "$N8N_DIR"
        sed -i "s|N8N_HOST=.*|N8N_HOST=${new_domain}|" docker-compose.yml
        sed -i "s|WEBHOOK_URL=.*|WEBHOOK_URL=https://${new_domain}/|" docker-compose.yml
        
        # Update config
        sed -i "s|N8N_DOMAIN=.*|N8N_DOMAIN=${new_domain}|" "$N8N_CONFIG"
        
        # Restart
        docker compose restart
        
        print_success "Domain updated to $new_domain"
    fi
    
    # SSL setup
    print_info "Setting up SSL certificate..."
    apt-get install -y certbot python3-certbot-nginx
    
    source "$N8N_CONFIG"
    certbot --nginx -d "$N8N_DOMAIN" --non-interactive --agree-tos -m "$N8N_EMAIL"
    
    print_success "SSL configured"
    press_any_key
}

# Configure webhooks
configure_n8n_webhooks() {
    show_header
    print_info "n8n Webhook Configuration"
    
    source "$N8N_CONFIG"
    
    echo ""
    echo "Current webhook URL: https://${N8N_DOMAIN}/"
    echo ""
    print_info "Webhook endpoints:"
    echo "  - Webhook: https://${N8N_DOMAIN}/webhook/{webhook-path}"
    echo "  - Test Webhook: https://${N8N_DOMAIN}/webhook-test/{webhook-path}"
    echo ""
    
    press_any_key
}

# Set timezone
set_n8n_timezone() {
    show_header
    echo "Current timezone: $(grep GENERIC_TIMEZONE "$N8N_DIR/docker-compose.yml" | cut -d= -f2)"
    echo ""
    echo "Common timezones:"
    echo "  UTC, America/New_York, Europe/London"
    echo "  Asia/Ho_Chi_Minh, Asia/Singapore, Asia/Tokyo"
    echo ""
    read -p "Enter new timezone: " new_tz
    
    if [ -n "$new_tz" ]; then
        cd "$N8N_DIR"
        sed -i "s|GENERIC_TIMEZONE=.*|GENERIC_TIMEZONE=${new_tz}|" docker-compose.yml
        sed -i "s|TZ=.*|TZ=${new_tz}|" docker-compose.yml
        
        docker compose restart
        print_success "Timezone updated to $new_tz"
    fi
    
    press_any_key
}

# Configure execution
configure_n8n_execution() {
    show_header
    print_info "Execution Settings"
    echo ""
    echo "1) Set execution timeout"
    echo "2) Set max timeout"
    echo "3) Configure execution process"
    echo "0) Back"
    echo ""
    read -p "Choice: " exec_choice
    
    cd "$N8N_DIR"
    
    case $exec_choice in
        1)
            read -p "Enter timeout in seconds (default 300): " timeout
            sed -i "s|EXECUTIONS_TIMEOUT=.*|EXECUTIONS_TIMEOUT=${timeout}|" docker-compose.yml
            docker compose restart
            print_success "Timeout updated"
            ;;
        2)
            read -p "Enter max timeout in seconds (default 3600): " max_timeout
            sed -i "s|EXECUTIONS_TIMEOUT_MAX=.*|EXECUTIONS_TIMEOUT_MAX=${max_timeout}|" docker-compose.yml
            docker compose restart
            print_success "Max timeout updated"
            ;;
        3)
            echo "Process modes:"
            echo "  main - Run in main process (default)"
            echo "  own - Run in separate process"
            read -p "Enter mode: " mode
            sed -i "s|EXECUTIONS_PROCESS=.*|EXECUTIONS_PROCESS=${mode}|" docker-compose.yml
            docker compose restart
            print_success "Process mode updated"
            ;;
    esac
    
    press_any_key
}

# Start n8n
start_n8n() {
    print_info "Starting n8n..."
    cd "$N8N_DIR"
    docker compose start
    print_success "n8n started"
    press_any_key
}

# Stop n8n
stop_n8n() {
    print_info "Stopping n8n..."
    cd "$N8N_DIR"
    docker compose stop
    print_success "n8n stopped"
    press_any_key
}

# Restart n8n
restart_n8n() {
    print_info "Restarting n8n..."
    cd "$N8N_DIR"
    docker compose restart
    print_success "n8n restarted"
    press_any_key
}

# View status
view_n8n_status() {
    show_header
    echo -e "${CYAN}n8n Status:${NC}"
    echo ""
    cd "$N8N_DIR"
    docker compose ps
    press_any_key
}

# View logs
view_n8n_logs() {
    cd "$N8N_DIR"
    docker compose logs -f --tail=100
}

# Backup
backup_n8n() {
    show_header
    print_info "Backing up n8n..."
    
    backup_file="${BACKUP_DIR}/n8n_$(date +%Y%m%d_%H%M%S).tar.gz"
    tar -czf "$backup_file" -C "$N8N_DIR" data
    
    print_success "Backup created: $backup_file"
    press_any_key
}

# Restore
restore_n8n() {
    show_header
    echo "Available backups:"
    ls -lh "${BACKUP_DIR}"/n8n_*.tar.gz
    echo ""
    read -p "Enter backup file path: " backup_file
    
    if [ ! -f "$backup_file" ]; then
        print_error "Backup file not found"
        press_any_key
        return
    fi
    
    print_warning "This will replace current workflows!"
    read -p "Continue? (y/n): " confirm
    
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        cd "$N8N_DIR"
        docker compose stop
        rm -rf data/*
        tar -xzf "$backup_file" -C .
        docker compose start
        print_success "Restore completed"
    fi
    
    press_any_key
}

# Export workflows
export_n8n_workflows() {
    show_header
    print_info "Exporting all workflows..."
    
    export_file="${BACKUP_DIR}/n8n_workflows_$(date +%Y%m%d_%H%M%S).json"
    
    cp "${N8N_DIR}/data/.n8n/database.sqlite" "$export_file"
    
    print_success "Workflows exported: $export_file"
    press_any_key
}

# Import workflows
import_n8n_workflows() {
    show_header
    read -p "Enter workflow JSON file path: " import_file
    
    if [ ! -f "$import_file" ]; then
        print_error "File not found"
        press_any_key
        return
    fi
    
    print_info "Import workflows via n8n web interface:"
    print_info "  1. Open n8n web interface"
    print_info "  2. Go to Workflows"
    print_info "  3. Click 'Import from File'"
    print_info "  4. Select: $import_file"
    
    press_any_key
}

# Change password
change_n8n_password() {
    show_header
    read -p "Enter new admin password: " -s new_password
    echo ""
    
    cd "$N8N_DIR"
    sed -i "s|N8N_BASIC_AUTH_PASSWORD=.*|N8N_BASIC_AUTH_PASSWORD=${new_password}|" docker-compose.yml
    
    docker compose restart
    
    print_success "Password updated"
    press_any_key
}

# View info
view_n8n_info() {
    show_header
    
    if [ ! -f "$N8N_CONFIG" ]; then
        print_error "n8n not installed"
        press_any_key
        return
    fi
    
    source "$N8N_CONFIG"
    
    echo -e "${CYAN}n8n Access Information:${NC}"
    echo ""
    echo "URL: https://${N8N_DOMAIN}"
    echo "Username: admin"
    echo "Email: ${N8N_EMAIL}"
    echo ""
    echo "Webhooks: https://${N8N_DOMAIN}/webhook/{path}"
    echo "API: https://${N8N_DOMAIN}/api/v1"
    echo ""
    
    press_any_key
}
