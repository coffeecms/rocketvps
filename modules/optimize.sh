#!/bin/bash

################################################################################
# RocketVPS - VPS Optimization Module
# Tự động tối ưu hóa VPS: SWAP, MySQL/MariaDB, Nginx, PostgreSQL
################################################################################

# Detect system resources
detect_system_resources() {
    # Get total RAM in MB
    TOTAL_RAM=$(free -m | awk '/^Mem:/{print $2}')
    
    # Get CPU cores
    CPU_CORES=$(nproc)
    
    # Get available disk space in GB
    AVAILABLE_DISK=$(df -BG / | awk 'NR==2 {print $4}' | sed 's/G//')
    
    print_info "Detected System Resources:"
    echo "  - RAM: ${TOTAL_RAM} MB"
    echo "  - CPU Cores: ${CPU_CORES}"
    echo "  - Available Disk: ${AVAILABLE_DISK} GB"
}

# Calculate optimal SWAP size
calculate_swap_size() {
    local ram_mb=$1
    local swap_size
    
    if [ "$ram_mb" -le 2048 ]; then
        # RAM <= 2GB: SWAP = RAM * 2
        swap_size=$((ram_mb * 2))
    elif [ "$ram_mb" -le 8192 ]; then
        # 2GB < RAM <= 8GB: SWAP = RAM
        swap_size=$ram_mb
    elif [ "$ram_mb" -le 16384 ]; then
        # 8GB < RAM <= 16GB: SWAP = RAM / 2
        swap_size=$((ram_mb / 2))
    else
        # RAM > 16GB: SWAP = 8GB
        swap_size=8192
    fi
    
    echo $swap_size
}

# Setup or resize SWAP
setup_swap() {
    print_header "SWAP Configuration"
    
    detect_system_resources
    
    # Check current SWAP
    CURRENT_SWAP=$(free -m | awk '/^Swap:/{print $2}')
    
    if [ "$CURRENT_SWAP" -gt 0 ]; then
        print_info "Current SWAP: ${CURRENT_SWAP} MB"
        echo ""
        read -p "Do you want to reconfigure SWAP? (y/n): " reconfigure
        if [[ ! "$reconfigure" =~ ^[Yy]$ ]]; then
            return
        fi
    fi
    
    # Calculate optimal SWAP size
    OPTIMAL_SWAP=$(calculate_swap_size $TOTAL_RAM)
    
    print_info "Recommended SWAP size: ${OPTIMAL_SWAP} MB"
    echo ""
    read -p "Enter SWAP size in MB (press Enter for recommended): " custom_swap
    
    if [ -z "$custom_swap" ]; then
        SWAP_SIZE=$OPTIMAL_SWAP
    else
        SWAP_SIZE=$custom_swap
    fi
    
    print_info "Setting up SWAP: ${SWAP_SIZE} MB"
    
    # Disable existing SWAP
    if [ "$CURRENT_SWAP" -gt 0 ]; then
        swapoff -a
        sed -i '/swap/d' /etc/fstab
        rm -f /swapfile
        print_success "Removed existing SWAP"
    fi
    
    # Create new SWAP file
    dd if=/dev/zero of=/swapfile bs=1M count=$SWAP_SIZE status=progress
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    
    # Make SWAP permanent
    if ! grep -q "/swapfile" /etc/fstab; then
        echo "/swapfile none swap sw 0 0" >> /etc/fstab
    fi
    
    # Optimize SWAP settings
    sysctl vm.swappiness=10
    sysctl vm.vfs_cache_pressure=50
    
    # Make sysctl settings permanent
    if ! grep -q "vm.swappiness" /etc/sysctl.conf; then
        echo "vm.swappiness=10" >> /etc/sysctl.conf
    fi
    if ! grep -q "vm.vfs_cache_pressure" /etc/sysctl.conf; then
        echo "vm.vfs_cache_pressure=50" >> /etc/sysctl.conf
    fi
    
    print_success "SWAP configured successfully: ${SWAP_SIZE} MB"
    free -h
    
    log_action "SWAP configured: ${SWAP_SIZE} MB"
    press_any_key
}

# Optimize MySQL/MariaDB
optimize_mysql() {
    print_header "MySQL/MariaDB Optimization"
    
    # Check if MySQL/MariaDB is installed
    if ! command -v mysql &> /dev/null; then
        print_error "MySQL/MariaDB is not installed"
        press_any_key
        return
    fi
    
    detect_system_resources
    
    # Determine MySQL config file
    if [ -f /etc/mysql/my.cnf ]; then
        MYSQL_CONFIG="/etc/mysql/my.cnf"
    elif [ -f /etc/my.cnf ]; then
        MYSQL_CONFIG="/etc/my.cnf"
    else
        MYSQL_CONFIG="/etc/mysql/mysql.conf.d/mysqld.cnf"
    fi
    
    # Backup current config
    cp "$MYSQL_CONFIG" "${BACKUP_DIR}/mysql_$(date +%Y%m%d_%H%M%S).cnf"
    
    # Calculate optimal settings based on RAM
    local innodb_buffer_pool_size=$((TOTAL_RAM * 70 / 100))  # 70% of RAM
    local max_connections
    local innodb_log_file_size
    
    if [ "$TOTAL_RAM" -le 1024 ]; then
        max_connections=50
        innodb_log_file_size=64
    elif [ "$TOTAL_RAM" -le 2048 ]; then
        max_connections=100
        innodb_log_file_size=128
    elif [ "$TOTAL_RAM" -le 4096 ]; then
        max_connections=150
        innodb_log_file_size=256
    else
        max_connections=200
        innodb_log_file_size=512
    fi
    
    print_info "Applying MySQL/MariaDB optimizations..."
    echo "  - InnoDB Buffer Pool: ${innodb_buffer_pool_size} MB (70% RAM)"
    echo "  - Max Connections: ${max_connections}"
    echo "  - InnoDB Log File Size: ${innodb_log_file_size} MB"
    
    # Create optimized configuration
    cat > /etc/mysql/conf.d/rocketvps_optimization.cnf <<EOF
[mysqld]
# RocketVPS Optimizations - Generated $(date)
# System Resources: ${TOTAL_RAM}MB RAM, ${CPU_CORES} CPU Cores

# Connection Settings
max_connections = ${max_connections}
max_connect_errors = 1000000
wait_timeout = 28800
interactive_timeout = 28800

# InnoDB Settings
innodb_buffer_pool_size = ${innodb_buffer_pool_size}M
innodb_log_file_size = ${innodb_log_file_size}M
innodb_log_buffer_size = 16M
innodb_flush_log_at_trx_commit = 2
innodb_flush_method = O_DIRECT
innodb_file_per_table = 1

# Query Cache (if MySQL < 8.0)
query_cache_type = 1
query_cache_size = 64M
query_cache_limit = 2M

# Thread Settings
thread_cache_size = ${CPU_CORES}
thread_stack = 256K

# Table Settings
table_open_cache = 4096
table_definition_cache = 2048

# Temp Table Settings
tmp_table_size = 64M
max_heap_table_size = 64M

# MyISAM Settings
key_buffer_size = 32M
myisam_sort_buffer_size = 8M

# Logging
slow_query_log = 1
slow_query_log_file = /var/log/mysql/slow-query.log
long_query_time = 2

# Binary Log
expire_logs_days = 7
max_binlog_size = 100M

# Performance Schema
performance_schema = ON
EOF

    # Restart MySQL
    systemctl restart mysql || systemctl restart mariadb
    
    if [ $? -eq 0 ]; then
        print_success "MySQL/MariaDB optimized successfully"
        
        # Show current settings
        echo ""
        print_info "Current MySQL Status:"
        mysql -e "SHOW VARIABLES LIKE 'innodb_buffer_pool_size';"
        mysql -e "SHOW VARIABLES LIKE 'max_connections';"
    else
        print_error "Failed to restart MySQL/MariaDB"
        print_warning "Restoring backup configuration..."
        cp "${BACKUP_DIR}/mysql_$(date +%Y%m%d)*.cnf" "$MYSQL_CONFIG"
        systemctl restart mysql || systemctl restart mariadb
    fi
    
    log_action "MySQL/MariaDB optimized for ${TOTAL_RAM}MB RAM"
    press_any_key
}

# Optimize Nginx
optimize_nginx() {
    print_header "Nginx Optimization"
    
    # Check if Nginx is installed
    if ! command -v nginx &> /dev/null; then
        print_error "Nginx is not installed"
        press_any_key
        return
    fi
    
    detect_system_resources
    
    # Backup current config
    cp /etc/nginx/nginx.conf "${BACKUP_DIR}/nginx_$(date +%Y%m%d_%H%M%S).conf"
    
    # Calculate optimal settings
    local worker_processes=$CPU_CORES
    local worker_connections
    
    if [ "$TOTAL_RAM" -le 1024 ]; then
        worker_connections=1024
    elif [ "$TOTAL_RAM" -le 2048 ]; then
        worker_connections=2048
    elif [ "$TOTAL_RAM" -le 4096 ]; then
        worker_connections=4096
    else
        worker_connections=8192
    fi
    
    print_info "Applying Nginx optimizations..."
    echo "  - Worker Processes: ${worker_processes}"
    echo "  - Worker Connections: ${worker_connections}"
    
    # Create optimized Nginx configuration
    cat > /etc/nginx/nginx.conf <<EOF
# RocketVPS Optimized Nginx Configuration
# Generated: $(date)
# System: ${TOTAL_RAM}MB RAM, ${CPU_CORES} CPU Cores

user www-data;
worker_processes ${worker_processes};
worker_rlimit_nofile 65535;
pid /run/nginx.pid;

events {
    worker_connections ${worker_connections};
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
    
    client_body_buffer_size 128k;
    client_max_body_size 256M;
    client_header_buffer_size 1k;
    large_client_header_buffers 4 16k;
    
    server_names_hash_bucket_size 64;
    server_name_in_redirect off;

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
    fastcgi_cache_key "\$scheme\$request_method\$host\$request_uri";
    fastcgi_cache_use_stale error timeout invalid_header http_500;
    fastcgi_ignore_headers Cache-Control Expires Set-Cookie;

    ##
    # Rate Limiting
    ##
    limit_req_zone \$binary_remote_addr zone=one:10m rate=10r/s;
    limit_conn_zone \$binary_remote_addr zone=addr:10m;

    ##
    # Buffer Settings
    ##
    fastcgi_buffers 16 16k;
    fastcgi_buffer_size 32k;
    proxy_buffer_size 128k;
    proxy_buffers 4 256k;
    proxy_busy_buffers_size 256k;

    ##
    # Timeout Settings
    ##
    fastcgi_connect_timeout 60;
    fastcgi_send_timeout 180;
    fastcgi_read_timeout 180;

    ##
    # File Cache
    ##
    open_file_cache max=10000 inactive=20s;
    open_file_cache_valid 30s;
    open_file_cache_min_uses 2;
    open_file_cache_errors on;

    ##
    # Virtual Host Configs
    ##
    include /etc/nginx/conf.d/*.conf;
    include /etc/nginx/sites-enabled/*;
}
EOF

    # Test configuration
    nginx -t
    
    if [ $? -eq 0 ]; then
        systemctl reload nginx
        print_success "Nginx optimized successfully"
    else
        print_error "Nginx configuration test failed"
        print_warning "Restoring backup configuration..."
        cp "${BACKUP_DIR}/nginx_$(date +%Y%m%d)*.conf" /etc/nginx/nginx.conf
        systemctl reload nginx
    fi
    
    log_action "Nginx optimized for ${TOTAL_RAM}MB RAM, ${CPU_CORES} CPU cores"
    press_any_key
}

# Optimize PostgreSQL
optimize_postgresql() {
    print_header "PostgreSQL Optimization"
    
    # Check if PostgreSQL is installed
    if ! command -v psql &> /dev/null; then
        print_error "PostgreSQL is not installed"
        press_any_key
        return
    fi
    
    detect_system_resources
    
    # Find PostgreSQL version and config file
    PG_VERSION=$(psql --version | awk '{print $3}' | cut -d. -f1)
    PG_CONFIG="/etc/postgresql/${PG_VERSION}/main/postgresql.conf"
    
    if [ ! -f "$PG_CONFIG" ]; then
        print_error "PostgreSQL config file not found"
        press_any_key
        return
    fi
    
    # Backup current config
    cp "$PG_CONFIG" "${BACKUP_DIR}/postgresql_$(date +%Y%m%d_%H%M%S).conf"
    
    # Calculate optimal settings based on RAM
    local shared_buffers=$((TOTAL_RAM * 25 / 100))  # 25% of RAM
    local effective_cache_size=$((TOTAL_RAM * 75 / 100))  # 75% of RAM
    local maintenance_work_mem=$((TOTAL_RAM / 16))  # RAM/16
    local work_mem=$((TOTAL_RAM / 64))  # RAM/64
    local max_connections
    
    if [ "$TOTAL_RAM" -le 1024 ]; then
        max_connections=50
    elif [ "$TOTAL_RAM" -le 2048 ]; then
        max_connections=100
    elif [ "$TOTAL_RAM" -le 4096 ]; then
        max_connections=150
    else
        max_connections=200
    fi
    
    print_info "Applying PostgreSQL optimizations..."
    echo "  - Shared Buffers: ${shared_buffers} MB (25% RAM)"
    echo "  - Effective Cache Size: ${effective_cache_size} MB (75% RAM)"
    echo "  - Max Connections: ${max_connections}"
    
    # Update PostgreSQL configuration
    cat >> "$PG_CONFIG" <<EOF

# RocketVPS Optimizations - Generated $(date)
# System Resources: ${TOTAL_RAM}MB RAM, ${CPU_CORES} CPU Cores

# Memory Settings
shared_buffers = ${shared_buffers}MB
effective_cache_size = ${effective_cache_size}MB
maintenance_work_mem = ${maintenance_work_mem}MB
work_mem = ${work_mem}MB

# Connection Settings
max_connections = ${max_connections}

# WAL Settings
wal_buffers = 16MB
checkpoint_completion_target = 0.9
min_wal_size = 1GB
max_wal_size = 4GB

# Query Planning
random_page_cost = 1.1
effective_io_concurrency = 200

# Worker Processes
max_worker_processes = ${CPU_CORES}
max_parallel_workers_per_gather = $((CPU_CORES / 2))
max_parallel_workers = ${CPU_CORES}

# Logging
log_line_prefix = '%t [%p]: [%l-1] user=%u,db=%d,app=%a,client=%h '
log_checkpoints = on
log_connections = on
log_disconnections = on
log_duration = off
log_lock_waits = on
log_min_duration_statement = 1000

# Autovacuum
autovacuum = on
autovacuum_max_workers = $((CPU_CORES / 2))
EOF

    # Restart PostgreSQL
    systemctl restart postgresql
    
    if [ $? -eq 0 ]; then
        print_success "PostgreSQL optimized successfully"
        
        # Show current settings
        echo ""
        print_info "Current PostgreSQL Settings:"
        su - postgres -c "psql -c 'SHOW shared_buffers;'"
        su - postgres -c "psql -c 'SHOW max_connections;'"
    else
        print_error "Failed to restart PostgreSQL"
        print_warning "Restoring backup configuration..."
        cp "${BACKUP_DIR}/postgresql_$(date +%Y%m%d)*.conf" "$PG_CONFIG"
        systemctl restart postgresql
    fi
    
    log_action "PostgreSQL optimized for ${TOTAL_RAM}MB RAM"
    press_any_key
}

# Optimize all services
optimize_all() {
    print_header "Full VPS Optimization"
    
    print_info "This will optimize all services based on your VPS resources"
    read -p "Continue? (y/n): " confirm
    
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        return
    fi
    
    setup_swap
    
    if command -v nginx &> /dev/null; then
        optimize_nginx
    fi
    
    if command -v mysql &> /dev/null; then
        optimize_mysql
    fi
    
    if command -v psql &> /dev/null; then
        optimize_postgresql
    fi
    
    print_success "Full VPS optimization completed!"
    log_action "Full VPS optimization completed"
    press_any_key
}

# View current optimization status
view_optimization_status() {
    print_header "VPS Optimization Status"
    
    detect_system_resources
    
    echo ""
    print_info "=== SWAP Status ==="
    free -h | grep -i swap
    
    echo ""
    print_info "=== Nginx Status ==="
    if command -v nginx &> /dev/null; then
        nginx -v
        systemctl status nginx --no-pager | grep Active
        echo "Worker Processes: $(grep "worker_processes" /etc/nginx/nginx.conf | head -1)"
    else
        echo "Not installed"
    fi
    
    echo ""
    print_info "=== MySQL/MariaDB Status ==="
    if command -v mysql &> /dev/null; then
        mysql --version
        systemctl status mysql --no-pager 2>/dev/null | grep Active || systemctl status mariadb --no-pager | grep Active
        if [ -f /etc/mysql/conf.d/rocketvps_optimization.cnf ]; then
            echo "Optimization: Enabled"
        else
            echo "Optimization: Not configured"
        fi
    else
        echo "Not installed"
    fi
    
    echo ""
    print_info "=== PostgreSQL Status ==="
    if command -v psql &> /dev/null; then
        psql --version
        systemctl status postgresql --no-pager | grep Active
    else
        echo "Not installed"
    fi
    
    echo ""
    print_info "=== System Load ==="
    uptime
    
    press_any_key
}

# Restore default configurations
restore_defaults() {
    print_header "Restore Default Configurations"
    
    print_warning "This will restore all services to default configurations"
    read -p "Are you sure? (yes/no): " confirm
    
    if [ "$confirm" != "yes" ]; then
        return
    fi
    
    # List available backups
    echo ""
    print_info "Available backups:"
    ls -lh "${BACKUP_DIR}"/*.conf 2>/dev/null || echo "No backups found"
    
    echo ""
    read -p "Enter backup file name to restore (or 'cancel'): " backup_file
    
    if [ "$backup_file" = "cancel" ]; then
        return
    fi
    
    if [ ! -f "${BACKUP_DIR}/${backup_file}" ]; then
        print_error "Backup file not found"
        press_any_key
        return
    fi
    
    # Determine service type and restore
    if [[ "$backup_file" == *"nginx"* ]]; then
        cp "${BACKUP_DIR}/${backup_file}" /etc/nginx/nginx.conf
        nginx -t && systemctl reload nginx
        print_success "Nginx configuration restored"
    elif [[ "$backup_file" == *"mysql"* ]]; then
        cp "${BACKUP_DIR}/${backup_file}" /etc/mysql/my.cnf
        systemctl restart mysql || systemctl restart mariadb
        print_success "MySQL configuration restored"
    elif [[ "$backup_file" == *"postgresql"* ]]; then
        PG_VERSION=$(psql --version | awk '{print $3}' | cut -d. -f1)
        cp "${BACKUP_DIR}/${backup_file}" "/etc/postgresql/${PG_VERSION}/main/postgresql.conf"
        systemctl restart postgresql
        print_success "PostgreSQL configuration restored"
    fi
    
    log_action "Restored configuration from ${backup_file}"
    press_any_key
}

# Optimization menu
optimize_menu() {
    while true; do
        show_header
        echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║                   VPS OPTIMIZATION MENU                       ║${NC}"
        echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo "  1) Setup/Resize SWAP Memory"
        echo "  2) Optimize MySQL/MariaDB"
        echo "  3) Optimize Nginx"
        echo "  4) Optimize PostgreSQL"
        echo "  5) Optimize All Services (Recommended)"
        echo "  6) View Optimization Status"
        echo "  7) Restore Default Configurations"
        echo ""
        echo "  0) Back to Main Menu"
        echo ""
        echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
        
        read -p "Enter your choice [0-7]: " choice
        
        case $choice in
            1) setup_swap ;;
            2) optimize_mysql ;;
            3) optimize_nginx ;;
            4) optimize_postgresql ;;
            5) optimize_all ;;
            6) view_optimization_status ;;
            7) restore_defaults ;;
            0) return ;;
            *)
                print_error "Invalid choice"
                sleep 1
                ;;
        esac
    done
}
