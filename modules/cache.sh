#!/bin/bash

################################################################################
# RocketVPS - Cache Management Module (Redis)
################################################################################

# Cache menu
cache_menu() {
    while true; do
        show_header
        echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║                   CACHE MANAGEMENT (Redis)                    ║${NC}"
        echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo "  1) Install Redis"
        echo "  2) Upgrade Redis"
        echo "  3) Configure Redis"
        echo "  4) Start Redis"
        echo "  5) Stop Redis"
        echo "  6) Restart Redis"
        echo "  7) Check Redis Status"
        echo "  8) Redis CLI"
        echo "  9) View Redis Info"
        echo "  10) Flush Redis Cache"
        echo "  11) Optimize Redis Configuration"
        echo "  12) Uninstall Redis"
        echo ""
        echo "  0) Back to Main Menu"
        echo ""
        echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
        
        read -p "Enter your choice [0-12]: " cache_choice
        
        case $cache_choice in
            1) install_redis ;;
            2) upgrade_redis ;;
            3) configure_redis ;;
            4) start_redis ;;
            5) stop_redis ;;
            6) restart_redis ;;
            7) check_redis_status ;;
            8) redis_cli_interactive ;;
            9) view_redis_info ;;
            10) flush_redis_cache ;;
            11) optimize_redis ;;
            12) uninstall_redis ;;
            0) return ;;
            *)
                print_error "Invalid choice"
                sleep 2
                ;;
        esac
    done
}

# Install Redis
install_redis() {
    print_info "Installing Redis..."
    
    if command -v redis-server &> /dev/null; then
        print_warning "Redis is already installed"
        redis-server --version
        press_any_key
        return
    fi
    
    if [[ "$OS" == "ubuntu" || "$OS" == "debian" ]]; then
        apt-get update
        apt-get install -y redis-server redis-tools
    elif [[ "$OS" == "centos" || "$OS" == "rhel" ]]; then
        yum install -y redis
    fi
    
    # Configure Redis
    configure_redis_defaults
    
    # Enable and start Redis
    systemctl enable redis-server 2>/dev/null || systemctl enable redis 2>/dev/null
    systemctl start redis-server 2>/dev/null || systemctl start redis 2>/dev/null
    
    if systemctl is-active --quiet redis-server || systemctl is-active --quiet redis; then
        print_success "Redis installed successfully"
        redis-server --version
    else
        print_error "Redis installation failed"
    fi
    
    press_any_key
}

# Configure Redis defaults
configure_redis_defaults() {
    local redis_conf="/etc/redis/redis.conf"
    
    if [ ! -f "$redis_conf" ]; then
        redis_conf="/etc/redis.conf"
    fi
    
    if [ ! -f "$redis_conf" ]; then
        print_warning "Redis configuration file not found"
        return
    fi
    
    # Backup original configuration
    cp "$redis_conf" "${redis_conf}.bak.$(date +%Y%m%d_%H%M%S)"
    
    # Basic optimizations
    sed -i 's/^# maxmemory <bytes>/maxmemory 256mb/' "$redis_conf"
    sed -i 's/^# maxmemory-policy noeviction/maxmemory-policy allkeys-lru/' "$redis_conf"
    
    # Enable persistence
    if ! grep -q "^save 900 1" "$redis_conf"; then
        echo "save 900 1" >> "$redis_conf"
        echo "save 300 10" >> "$redis_conf"
        echo "save 60 10000" >> "$redis_conf"
    fi
    
    # Security: require password
    local redis_password=$(openssl rand -base64 32)
    sed -i "s/^# requirepass foobared/requirepass $redis_password/" "$redis_conf"
    
    # Save password to config file
    echo "REDIS_PASSWORD=$redis_password" > "${CONFIG_DIR}/redis.conf"
    chmod 600 "${CONFIG_DIR}/redis.conf"
    
    print_info "Redis password saved to ${CONFIG_DIR}/redis.conf"
}

# Upgrade Redis
upgrade_redis() {
    print_info "Upgrading Redis..."
    
    if ! command -v redis-server &> /dev/null; then
        print_error "Redis is not installed"
        press_any_key
        return
    fi
    
    # Backup Redis data
    print_info "Backing up Redis data..."
    if [ -f /var/lib/redis/dump.rdb ]; then
        cp /var/lib/redis/dump.rdb "${BACKUP_DIR}/redis_dump_$(date +%Y%m%d_%H%M%S).rdb"
    fi
    
    current_version=$(redis-server --version | grep -oP 'v=\K[0-9.]+')
    print_info "Current Redis version: $current_version"
    
    if [[ "$OS" == "ubuntu" || "$OS" == "debian" ]]; then
        apt-get update
        apt-get upgrade -y redis-server redis-tools
    elif [[ "$OS" == "centos" || "$OS" == "rhel" ]]; then
        yum update -y redis
    fi
    
    systemctl restart redis-server 2>/dev/null || systemctl restart redis 2>/dev/null
    
    new_version=$(redis-server --version | grep -oP 'v=\K[0-9.]+')
    print_success "Redis upgraded from $current_version to $new_version"
    
    press_any_key
}

# Configure Redis
configure_redis() {
    local redis_conf="/etc/redis/redis.conf"
    
    if [ ! -f "$redis_conf" ]; then
        redis_conf="/etc/redis.conf"
    fi
    
    if [ ! -f "$redis_conf" ]; then
        print_error "Redis configuration file not found"
        press_any_key
        return
    fi
    
    show_header
    echo -e "${CYAN}Redis Configuration${NC}"
    echo ""
    echo "1) Set Max Memory"
    echo "2) Change Max Memory Policy"
    echo "3) Set Password"
    echo "4) Enable/Disable Persistence"
    echo "5) Edit Configuration File"
    echo "0) Back"
    echo ""
    read -p "Enter choice: " config_choice
    
    case $config_choice in
        1)
            read -p "Enter max memory (e.g., 256mb, 1gb): " max_mem
            sed -i "s/^maxmemory .*/maxmemory $max_mem/" "$redis_conf"
            print_success "Max memory set to $max_mem"
            systemctl restart redis-server 2>/dev/null || systemctl restart redis 2>/dev/null
            ;;
        2)
            echo "Select policy:"
            echo "1) allkeys-lru (Recommended)"
            echo "2) volatile-lru"
            echo "3) allkeys-lfu"
            echo "4) volatile-lfu"
            echo "5) noeviction"
            read -p "Choice: " policy_choice
            
            case $policy_choice in
                1) policy="allkeys-lru" ;;
                2) policy="volatile-lru" ;;
                3) policy="allkeys-lfu" ;;
                4) policy="volatile-lfu" ;;
                5) policy="noeviction" ;;
                *) print_error "Invalid choice"; press_any_key; return ;;
            esac
            
            sed -i "s/^maxmemory-policy .*/maxmemory-policy $policy/" "$redis_conf"
            print_success "Max memory policy set to $policy"
            systemctl restart redis-server 2>/dev/null || systemctl restart redis 2>/dev/null
            ;;
        3)
            read -s -p "Enter new Redis password: " new_pass
            echo ""
            sed -i "s/^requirepass .*/requirepass $new_pass/" "$redis_conf"
            echo "REDIS_PASSWORD=$new_pass" > "${CONFIG_DIR}/redis.conf"
            chmod 600 "${CONFIG_DIR}/redis.conf"
            print_success "Password updated"
            systemctl restart redis-server 2>/dev/null || systemctl restart redis 2>/dev/null
            ;;
        4)
            read -p "Enable persistence? (yes/no): " enable_persist
            if [ "$enable_persist" = "yes" ]; then
                sed -i '/^save /d' "$redis_conf"
                echo "save 900 1" >> "$redis_conf"
                echo "save 300 10" >> "$redis_conf"
                echo "save 60 10000" >> "$redis_conf"
                print_success "Persistence enabled"
            else
                sed -i '/^save /d' "$redis_conf"
                print_success "Persistence disabled"
            fi
            systemctl restart redis-server 2>/dev/null || systemctl restart redis 2>/dev/null
            ;;
        5)
            ${EDITOR:-nano} "$redis_conf"
            systemctl restart redis-server 2>/dev/null || systemctl restart redis 2>/dev/null
            ;;
        0) return ;;
    esac
    
    press_any_key
}

# Start Redis
start_redis() {
    print_info "Starting Redis..."
    systemctl start redis-server 2>/dev/null || systemctl start redis 2>/dev/null
    
    if systemctl is-active --quiet redis-server || systemctl is-active --quiet redis; then
        print_success "Redis started successfully"
    else
        print_error "Failed to start Redis"
    fi
    
    press_any_key
}

# Stop Redis
stop_redis() {
    print_info "Stopping Redis..."
    systemctl stop redis-server 2>/dev/null || systemctl stop redis 2>/dev/null
    
    if ! systemctl is-active --quiet redis-server && ! systemctl is-active --quiet redis; then
        print_success "Redis stopped successfully"
    else
        print_error "Failed to stop Redis"
    fi
    
    press_any_key
}

# Restart Redis
restart_redis() {
    print_info "Restarting Redis..."
    systemctl restart redis-server 2>/dev/null || systemctl restart redis 2>/dev/null
    
    if systemctl is-active --quiet redis-server || systemctl is-active --quiet redis; then
        print_success "Redis restarted successfully"
    else
        print_error "Failed to restart Redis"
    fi
    
    press_any_key
}

# Check Redis status
check_redis_status() {
    show_header
    echo -e "${CYAN}Redis Service Status:${NC}"
    echo ""
    systemctl status redis-server 2>/dev/null || systemctl status redis 2>/dev/null
    echo ""
    press_any_key
}

# Redis CLI interactive
redis_cli_interactive() {
    if ! command -v redis-cli &> /dev/null; then
        print_error "Redis CLI is not installed"
        press_any_key
        return
    fi
    
    print_info "Entering Redis CLI. Type 'exit' to return."
    
    # Check if password is required
    if [ -f "${CONFIG_DIR}/redis.conf" ]; then
        source "${CONFIG_DIR}/redis.conf"
        redis-cli -a "$REDIS_PASSWORD"
    else
        redis-cli
    fi
    
    press_any_key
}

# View Redis info
view_redis_info() {
    if ! command -v redis-cli &> /dev/null; then
        print_error "Redis CLI is not installed"
        press_any_key
        return
    fi
    
    show_header
    echo -e "${CYAN}Redis Information:${NC}"
    echo ""
    
    if [ -f "${CONFIG_DIR}/redis.conf" ]; then
        source "${CONFIG_DIR}/redis.conf"
        redis-cli -a "$REDIS_PASSWORD" INFO
    else
        redis-cli INFO
    fi
    
    echo ""
    press_any_key
}

# Flush Redis cache
flush_redis_cache() {
    if ! command -v redis-cli &> /dev/null; then
        print_error "Redis CLI is not installed"
        press_any_key
        return
    fi
    
    print_warning "This will clear ALL data in Redis!"
    read -p "Are you sure? (yes/no): " confirm
    
    if [ "$confirm" != "yes" ]; then
        print_info "Operation cancelled"
        press_any_key
        return
    fi
    
    if [ -f "${CONFIG_DIR}/redis.conf" ]; then
        source "${CONFIG_DIR}/redis.conf"
        redis-cli -a "$REDIS_PASSWORD" FLUSHALL
    else
        redis-cli FLUSHALL
    fi
    
    print_success "Redis cache flushed"
    press_any_key
}

# Optimize Redis
optimize_redis() {
    print_info "Optimizing Redis configuration..."
    
    local redis_conf="/etc/redis/redis.conf"
    
    if [ ! -f "$redis_conf" ]; then
        redis_conf="/etc/redis.conf"
    fi
    
    if [ ! -f "$redis_conf" ]; then
        print_error "Redis configuration file not found"
        press_any_key
        return
    fi
    
    # Backup
    cp "$redis_conf" "${redis_conf}.bak.$(date +%Y%m%d_%H%M%S)"
    
    # Calculate optimal memory based on system RAM
    total_mem=$(free -m | awk '/^Mem:/{print $2}')
    redis_mem=$((total_mem / 4))  # 25% of RAM
    
    print_info "Total RAM: ${total_mem}MB"
    print_info "Setting Redis max memory to: ${redis_mem}MB"
    
    # Apply optimizations
    sed -i "s/^maxmemory .*/maxmemory ${redis_mem}mb/" "$redis_conf"
    sed -i "s/^# maxmemory-policy .*/maxmemory-policy allkeys-lru/" "$redis_conf"
    sed -i "s/^maxmemory-policy .*/maxmemory-policy allkeys-lru/" "$redis_conf"
    
    # TCP backlog
    sed -i "s/^tcp-backlog .*/tcp-backlog 511/" "$redis_conf"
    
    # Timeout
    sed -i "s/^timeout .*/timeout 300/" "$redis_conf"
    
    # TCP keepalive
    sed -i "s/^tcp-keepalive .*/tcp-keepalive 60/" "$redis_conf"
    
    systemctl restart redis-server 2>/dev/null || systemctl restart redis 2>/dev/null
    
    print_success "Redis optimized successfully"
    print_info "Max memory: ${redis_mem}MB"
    print_info "Policy: allkeys-lru"
    
    press_any_key
}

# Uninstall Redis
uninstall_redis() {
    print_warning "This will remove Redis and all its data!"
    read -p "Are you sure? (yes/no): " confirm
    
    if [ "$confirm" != "yes" ]; then
        print_info "Uninstall cancelled"
        press_any_key
        return
    fi
    
    # Backup Redis data
    print_info "Backing up Redis data..."
    if [ -f /var/lib/redis/dump.rdb ]; then
        cp /var/lib/redis/dump.rdb "${BACKUP_DIR}/redis_final_dump_$(date +%Y%m%d_%H%M%S).rdb"
    fi
    
    systemctl stop redis-server 2>/dev/null || systemctl stop redis 2>/dev/null
    systemctl disable redis-server 2>/dev/null || systemctl disable redis 2>/dev/null
    
    if [[ "$OS" == "ubuntu" || "$OS" == "debian" ]]; then
        apt-get remove --purge -y redis-server redis-tools
        apt-get autoremove -y
    elif [[ "$OS" == "centos" || "$OS" == "rhel" ]]; then
        yum remove -y redis
    fi
    
    print_success "Redis uninstalled. Backup saved to ${BACKUP_DIR}/"
    press_any_key
}
