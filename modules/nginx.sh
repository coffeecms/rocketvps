#!/bin/bash

################################################################################
# RocketVPS - Nginx Management Module
################################################################################

# Nginx menu
nginx_menu() {
    while true; do
        show_header
        echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║                    NGINX MANAGEMENT                           ║${NC}"
        echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo "  1) Install Nginx (Latest Version)"
        echo "  2) Upgrade Nginx"
        echo "  3) Restart Nginx"
        echo "  4) Stop Nginx"
        echo "  5) Start Nginx"
        echo "  6) Check Nginx Status"
        echo "  7) Test Nginx Configuration"
        echo "  8) View Nginx Error Log"
        echo "  9) Optimize Nginx Configuration"
        echo "  10) Uninstall Nginx"
        echo ""
        echo "  0) Back to Main Menu"
        echo ""
        echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
        
        read -p "Enter your choice [0-10]: " nginx_choice
        
        case $nginx_choice in
            1) install_nginx ;;
            2) upgrade_nginx ;;
            3) restart_nginx ;;
            4) stop_nginx ;;
            5) start_nginx ;;
            6) check_nginx_status ;;
            7) test_nginx_config ;;
            8) view_nginx_error_log ;;
            9) optimize_nginx ;;
            10) uninstall_nginx ;;
            0) return ;;
            *)
                print_error "Invalid choice"
                sleep 2
                ;;
        esac
    done
}

# Install Nginx
install_nginx() {
    print_info "Installing Nginx..."
    
    if command -v nginx &> /dev/null; then
        print_warning "Nginx is already installed"
        nginx -v
        press_any_key
        return
    fi
    
    # Backup existing configuration if exists
    if [ -d "/etc/nginx" ]; then
        print_info "Backing up existing Nginx configuration..."
        tar -czf "${BACKUP_DIR}/nginx_config_backup_$(date +%Y%m%d_%H%M%S).tar.gz" /etc/nginx/
    fi
    
    if [[ "$OS" == "ubuntu" || "$OS" == "debian" ]]; then
        # Add official Nginx repository for latest version
        apt-get update
        apt-get install -y curl gnupg2 ca-certificates lsb-release ubuntu-keyring
        
        curl https://nginx.org/keys/nginx_signing.key | gpg --dearmor \
            | tee /usr/share/keyrings/nginx-archive-keyring.gpg >/dev/null
        
        echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] \
http://nginx.org/packages/ubuntu $(lsb_release -cs) nginx" \
            | tee /etc/apt/sources.list.d/nginx.list
        
        apt-get update
        apt-get install -y nginx
        
    elif [[ "$OS" == "centos" || "$OS" == "rhel" ]]; then
        # Add official Nginx repository for CentOS/RHEL
        cat > /etc/yum.repos.d/nginx.repo <<EOF
[nginx-stable]
name=nginx stable repo
baseurl=http://nginx.org/packages/centos/\$releasever/\$basearch/
gpgcheck=1
enabled=1
gpgkey=https://nginx.org/keys/nginx_signing.key
module_hotfixes=true
EOF
        
        yum install -y nginx
    fi
    
    # Create default directories
    mkdir -p /var/www/html
    mkdir -p /etc/nginx/sites-available
    mkdir -p /etc/nginx/sites-enabled
    mkdir -p /etc/nginx/snippets
    
    # Create optimal default configuration
    create_nginx_default_config
    
    # Enable and start Nginx
    systemctl enable nginx
    systemctl start nginx
    
    if systemctl is-active --quiet nginx; then
        print_success "Nginx installed successfully!"
        nginx -v
    else
        print_error "Nginx installation failed"
    fi
    
    press_any_key
}

# Create optimized Nginx default configuration
create_nginx_default_config() {
    cat > /etc/nginx/nginx.conf <<'EOF'
user www-data;
worker_processes auto;
worker_rlimit_nofile 65535;
pid /run/nginx.pid;

events {
    worker_connections 4096;
    use epoll;
    multi_accept on;
}

http {
    ##
    # Basic Settings
    ##
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    keepalive_requests 100;
    types_hash_max_size 2048;
    server_tokens off;
    
    client_max_body_size 100M;
    client_body_buffer_size 128k;
    client_header_buffer_size 1k;
    large_client_header_buffers 4 16k;
    
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    ##
    # SSL Settings
    ##
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_ciphers 'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384';
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

    ##
    # Logging Settings
    ##
    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;

    ##
    # Gzip Settings
    ##
    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types text/plain text/css text/xml text/javascript 
               application/json application/javascript application/xml+rss 
               application/rss+xml font/truetype font/opentype 
               application/vnd.ms-fontobject image/svg+xml;
    gzip_disable "msie6";

    ##
    # FastCGI Cache Settings
    ##
    fastcgi_cache_path /var/cache/nginx levels=1:2 keys_zone=fastcgi_cache:100m 
                       max_size=1g inactive=60m use_temp_path=off;
    fastcgi_cache_key "$scheme$request_method$host$request_uri";
    
    ##
    # Rate Limiting
    ##
    limit_req_zone $binary_remote_addr zone=one:10m rate=1r/s;
    limit_conn_zone $binary_remote_addr zone=addr:10m;

    ##
    # Virtual Host Configs
    ##
    include /etc/nginx/conf.d/*.conf;
    include /etc/nginx/sites-enabled/*;
}
EOF

    # Create default server block
    cat > /etc/nginx/sites-available/default <<'EOF'
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    
    root /var/www/html;
    index index.php index.html index.htm;
    
    server_name _;
    
    location / {
        try_files $uri $uri/ =404;
    }
    
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php-fpm.sock;
    }
    
    location ~ /\.ht {
        deny all;
    }
}
EOF

    ln -sf /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default
    
    # Create fastcgi snippet
    cat > /etc/nginx/snippets/fastcgi-php.conf <<'EOF'
fastcgi_split_path_info ^(.+\.php)(/.+)$;
fastcgi_index index.php;
fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
include fastcgi_params;
fastcgi_buffers 16 16k;
fastcgi_buffer_size 32k;
EOF
}

# Upgrade Nginx
upgrade_nginx() {
    print_info "Upgrading Nginx..."
    
    if ! command -v nginx &> /dev/null; then
        print_error "Nginx is not installed"
        press_any_key
        return
    fi
    
    # Backup configuration
    print_info "Backing up Nginx configuration..."
    tar -czf "${BACKUP_DIR}/nginx_config_backup_$(date +%Y%m%d_%H%M%S).tar.gz" /etc/nginx/
    
    # Backup websites data
    if [ -d "/var/www" ]; then
        print_info "Backing up websites data..."
        tar -czf "${BACKUP_DIR}/www_backup_$(date +%Y%m%d_%H%M%S).tar.gz" /var/www/
    fi
    
    # Get current version
    current_version=$(nginx -v 2>&1 | grep -oP '(?<=nginx/)[0-9.]+')
    print_info "Current Nginx version: $current_version"
    
    if [[ "$OS" == "ubuntu" || "$OS" == "debian" ]]; then
        apt-get update
        apt-get upgrade -y nginx
    elif [[ "$OS" == "centos" || "$OS" == "rhel" ]]; then
        yum update -y nginx
    fi
    
    # Test configuration before reload
    if nginx -t; then
        systemctl reload nginx
        new_version=$(nginx -v 2>&1 | grep -oP '(?<=nginx/)[0-9.]+')
        print_success "Nginx upgraded from $current_version to $new_version"
    else
        print_error "Configuration test failed. Rolling back..."
        # Restore backup
        latest_backup=$(ls -t ${BACKUP_DIR}/nginx_config_backup_*.tar.gz | head -1)
        if [ -f "$latest_backup" ]; then
            tar -xzf "$latest_backup" -C /
            systemctl reload nginx
            print_info "Configuration restored from backup"
        fi
    fi
    
    press_any_key
}

# Restart Nginx
restart_nginx() {
    print_info "Restarting Nginx..."
    
    if nginx -t; then
        systemctl restart nginx
        if systemctl is-active --quiet nginx; then
            print_success "Nginx restarted successfully"
        else
            print_error "Failed to restart Nginx"
        fi
    else
        print_error "Nginx configuration test failed. Please fix errors first."
    fi
    
    press_any_key
}

# Stop Nginx
stop_nginx() {
    print_info "Stopping Nginx..."
    systemctl stop nginx
    
    if ! systemctl is-active --quiet nginx; then
        print_success "Nginx stopped successfully"
    else
        print_error "Failed to stop Nginx"
    fi
    
    press_any_key
}

# Start Nginx
start_nginx() {
    print_info "Starting Nginx..."
    
    if nginx -t; then
        systemctl start nginx
        if systemctl is-active --quiet nginx; then
            print_success "Nginx started successfully"
        else
            print_error "Failed to start Nginx"
        fi
    else
        print_error "Nginx configuration test failed"
    fi
    
    press_any_key
}

# Check Nginx status
check_nginx_status() {
    show_header
    echo -e "${CYAN}Nginx Service Status:${NC}"
    echo ""
    systemctl status nginx
    echo ""
    press_any_key
}

# Test Nginx configuration
test_nginx_config() {
    print_info "Testing Nginx configuration..."
    nginx -t
    press_any_key
}

# View Nginx error log
view_nginx_error_log() {
    show_header
    echo -e "${CYAN}Last 50 lines of Nginx error log:${NC}"
    echo ""
    tail -n 50 /var/log/nginx/error.log
    echo ""
    press_any_key
}

# Optimize Nginx
optimize_nginx() {
    print_info "Optimizing Nginx configuration..."
    
    # Calculate optimal worker_processes and worker_connections
    cpu_cores=$(nproc)
    total_mem=$(free -m | awk '/^Mem:/{print $2}')
    
    print_info "Detected $cpu_cores CPU cores and ${total_mem}MB RAM"
    
    # Backup current config
    cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bak
    
    # Update worker_processes
    sed -i "s/worker_processes.*/worker_processes $cpu_cores;/" /etc/nginx/nginx.conf
    
    # Set worker_rlimit_nofile
    worker_rlimit=$((cpu_cores * 4096))
    sed -i "s/worker_rlimit_nofile.*/worker_rlimit_nofile $worker_rlimit;/" /etc/nginx/nginx.conf
    
    # Create cache directory
    mkdir -p /var/cache/nginx
    chown -R www-data:www-data /var/cache/nginx
    
    if nginx -t; then
        systemctl reload nginx
        print_success "Nginx optimized successfully"
        print_info "Worker processes: $cpu_cores"
        print_info "Worker rlimit nofile: $worker_rlimit"
    else
        print_error "Optimization failed. Restoring backup..."
        mv /etc/nginx/nginx.conf.bak /etc/nginx/nginx.conf
    fi
    
    press_any_key
}

# Uninstall Nginx
uninstall_nginx() {
    print_warning "This will remove Nginx and all its configurations!"
    read -p "Are you sure? (yes/no): " confirm
    
    if [ "$confirm" != "yes" ]; then
        print_info "Uninstall cancelled"
        press_any_key
        return
    fi
    
    print_info "Backing up Nginx data before uninstalling..."
    tar -czf "${BACKUP_DIR}/nginx_final_backup_$(date +%Y%m%d_%H%M%S).tar.gz" /etc/nginx/ /var/www/ 2>/dev/null
    
    systemctl stop nginx
    systemctl disable nginx
    
    if [[ "$OS" == "ubuntu" || "$OS" == "debian" ]]; then
        apt-get remove --purge -y nginx nginx-common
        apt-get autoremove -y
    elif [[ "$OS" == "centos" || "$OS" == "rhel" ]]; then
        yum remove -y nginx
    fi
    
    print_success "Nginx uninstalled. Backup saved to ${BACKUP_DIR}/"
    press_any_key
}
