#!/bin/bash

################################################################################
# RocketVPS - Utility Functions Module
################################################################################

# System information
system_info() {
    show_header
    echo -e "${CYAN}System Information${NC}"
    echo ""
    
    echo -e "${YELLOW}=== Operating System ===${NC}"
    cat /etc/os-release | head -5
    echo ""
    
    echo -e "${YELLOW}=== CPU Information ===${NC}"
    echo "CPU Cores: $(nproc)"
    echo "CPU Model: $(grep "model name" /proc/cpuinfo | head -1 | cut -d':' -f2 | xargs)"
    echo "CPU Load: $(uptime | awk -F'load average:' '{print $2}')"
    echo ""
    
    echo -e "${YELLOW}=== Memory Information ===${NC}"
    free -h
    echo ""
    
    echo -e "${YELLOW}=== Disk Usage ===${NC}"
    df -h | grep -E '^/dev/'
    echo ""
    
    echo -e "${YELLOW}=== Network Information ===${NC}"
    ip addr show | grep -E 'inet |inet6 ' | awk '{print $2, $NF}'
    echo ""
    
    echo -e "${YELLOW}=== Uptime ===${NC}"
    uptime
    echo ""
    
    echo -e "${YELLOW}=== Installed Software ===${NC}"
    echo -n "Nginx: "
    if command -v nginx &> /dev/null; then
        nginx -v 2>&1 | cut -d'/' -f2
    else
        echo "Not installed"
    fi
    
    echo -n "PHP: "
    if command -v php &> /dev/null; then
        php -v | head -1 | awk '{print $2}'
    else
        echo "Not installed"
    fi
    
    echo -n "MySQL/MariaDB: "
    if command -v mysql &> /dev/null; then
        mysql --version | awk '{print $5}' | sed 's/,//'
    else
        echo "Not installed"
    fi
    
    echo -n "PostgreSQL: "
    if command -v psql &> /dev/null; then
        psql --version | awk '{print $3}'
    else
        echo "Not installed"
    fi
    
    echo -n "Redis: "
    if command -v redis-server &> /dev/null; then
        redis-server --version | awk '{print $3}' | cut -d'=' -f2
    else
        echo "Not installed"
    fi
    
    echo ""
    
    echo -e "${YELLOW}=== Running Services ===${NC}"
    systemctl list-units --type=service --state=running | grep -E 'nginx|php|mysql|mariadb|postgresql|redis' | awk '{print $1}'
    
    echo ""
    
    echo -e "${YELLOW}=== Active Connections ===${NC}"
    echo "Established connections: $(netstat -an | grep ESTABLISHED | wc -l)"
    echo "Listening ports: $(netstat -tuln | grep LISTEN | wc -l)"
    
    echo ""
    press_any_key
}

# View logs
view_logs() {
    show_header
    echo -e "${CYAN}View Logs${NC}"
    echo ""
    
    echo "Select log to view:"
    echo "  1) RocketVPS Log"
    echo "  2) Nginx Error Log"
    echo "  3) Nginx Access Log"
    echo "  4) PHP-FPM Error Log"
    echo "  5) MySQL/MariaDB Error Log"
    echo "  6) System Log"
    echo "  7) Authentication Log"
    echo "  8) Fail2Ban Log"
    echo ""
    read -p "Enter choice [1-8]: " log_choice
    
    show_header
    
    case $log_choice in
        1)
            echo -e "${CYAN}RocketVPS Log:${NC}"
            echo ""
            tail -n 50 "${LOG_DIR}/rocketvps.log" 2>/dev/null || echo "No logs found"
            ;;
        2)
            echo -e "${CYAN}Nginx Error Log:${NC}"
            echo ""
            tail -n 50 /var/log/nginx/error.log 2>/dev/null || echo "Log file not found"
            ;;
        3)
            echo -e "${CYAN}Nginx Access Log:${NC}"
            echo ""
            tail -n 50 /var/log/nginx/access.log 2>/dev/null || echo "Log file not found"
            ;;
        4)
            echo -e "${CYAN}PHP-FPM Error Log:${NC}"
            echo ""
            local php_log=$(find /var/log -name "*php*fpm*.log" | head -1)
            if [ -n "$php_log" ]; then
                tail -n 50 "$php_log"
            else
                echo "Log file not found"
            fi
            ;;
        5)
            echo -e "${CYAN}MySQL/MariaDB Error Log:${NC}"
            echo ""
            if [ -f /var/log/mysql/error.log ]; then
                tail -n 50 /var/log/mysql/error.log
            elif [ -f /var/log/mariadb/mariadb.log ]; then
                tail -n 50 /var/log/mariadb/mariadb.log
            else
                echo "Log file not found"
            fi
            ;;
        6)
            echo -e "${CYAN}System Log:${NC}"
            echo ""
            tail -n 50 /var/log/syslog 2>/dev/null || tail -n 50 /var/log/messages 2>/dev/null || echo "Log file not found"
            ;;
        7)
            echo -e "${CYAN}Authentication Log:${NC}"
            echo ""
            tail -n 50 /var/log/auth.log 2>/dev/null || tail -n 50 /var/log/secure 2>/dev/null || echo "Log file not found"
            ;;
        8)
            echo -e "${CYAN}Fail2Ban Log:${NC}"
            echo ""
            tail -n 50 /var/log/fail2ban.log 2>/dev/null || echo "Fail2Ban not installed or log not found"
            ;;
        *)
            print_error "Invalid choice"
            ;;
    esac
    
    echo ""
    press_any_key
}

# Quick server health check
server_health_check() {
    show_header
    echo -e "${CYAN}Server Health Check${NC}"
    echo ""
    
    local health_score=100
    local issues=()
    
    # Check CPU load
    local load=$(uptime | awk -F'load average:' '{print $2}' | awk -F',' '{print $1}' | xargs)
    local cpu_cores=$(nproc)
    local load_per_core=$(echo "scale=2; $load / $cpu_cores" | bc 2>/dev/null || echo "0")
    
    if (( $(echo "$load_per_core > 2" | bc -l 2>/dev/null || echo 0) )); then
        issues+=("High CPU load: $load")
        ((health_score-=15))
    fi
    
    # Check memory usage
    local mem_used=$(free | grep Mem | awk '{print ($3/$2) * 100}')
    if (( $(echo "$mem_used > 90" | bc -l 2>/dev/null || echo 0) )); then
        issues+=("High memory usage: ${mem_used}%")
        ((health_score-=15))
    fi
    
    # Check disk usage
    local disk_used=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
    if [ "$disk_used" -gt 90 ]; then
        issues+=("High disk usage: ${disk_used}%")
        ((health_score-=15))
    fi
    
    # Check Nginx
    if ! systemctl is-active --quiet nginx; then
        issues+=("Nginx is not running")
        ((health_score-=20))
    fi
    
    # Check PHP-FPM
    if ! systemctl is-active --quiet php*-fpm; then
        issues+=("PHP-FPM is not running")
        ((health_score-=10))
    fi
    
    # Check database
    if ! systemctl is-active --quiet mysql && ! systemctl is-active --quiet mariadb && ! systemctl is-active --quiet postgresql; then
        issues+=("No database service running")
        ((health_score-=10))
    fi
    
    # Display health score
    echo -e "${YELLOW}=== Health Score: ${health_score}/100 ===${NC}"
    echo ""
    
    if [ ${#issues[@]} -eq 0 ]; then
        echo -e "${GREEN}✓ All checks passed! Server is healthy.${NC}"
    else
        echo -e "${RED}Issues detected:${NC}"
        for issue in "${issues[@]}"; do
            echo "  ✗ $issue"
        done
    fi
    
    echo ""
    
    # Resource usage
    echo -e "${YELLOW}=== Resource Usage ===${NC}"
    echo "CPU Load: $load (Cores: $cpu_cores)"
    echo "Memory: $(free -h | grep Mem | awk '{print $3 "/" $2}')"
    echo "Disk: $(df -h / | tail -1 | awk '{print $3 "/" $2 " (" $5 " used)"}')"
    
    echo ""
    
    # Service status
    echo -e "${YELLOW}=== Service Status ===${NC}"
    systemctl is-active --quiet nginx && echo "✓ Nginx: Running" || echo "✗ Nginx: Stopped"
    systemctl is-active --quiet php*-fpm && echo "✓ PHP-FPM: Running" || echo "✗ PHP-FPM: Stopped"
    systemctl is-active --quiet mysql && echo "✓ MySQL: Running" || \
    systemctl is-active --quiet mariadb && echo "✓ MariaDB: Running" || \
    systemctl is-active --quiet postgresql && echo "✓ PostgreSQL: Running" || \
    echo "✗ Database: Not running"
    
    echo ""
    press_any_key
}

# Clean temporary files
clean_temp_files() {
    show_header
    echo -e "${CYAN}Clean Temporary Files${NC}"
    echo ""
    
    print_warning "This will delete temporary files and cache"
    read -p "Continue? (yes/no): " confirm
    
    if [ "$confirm" != "yes" ]; then
        print_info "Operation cancelled"
        press_any_key
        return
    fi
    
    print_info "Cleaning temporary files..."
    
    # Clean /tmp
    local tmp_before=$(du -sh /tmp 2>/dev/null | cut -f1)
    find /tmp -type f -atime +7 -delete 2>/dev/null
    local tmp_after=$(du -sh /tmp 2>/dev/null | cut -f1)
    
    # Clean /var/tmp
    find /var/tmp -type f -atime +7 -delete 2>/dev/null
    
    # Clean old logs
    find /var/log -type f -name "*.log.*" -mtime +30 -delete 2>/dev/null
    find /var/log -type f -name "*.gz" -mtime +30 -delete 2>/dev/null
    
    # Clean package manager cache
    if [[ "$OS" == "ubuntu" || "$OS" == "debian" ]]; then
        apt-get clean
        apt-get autoclean
    elif [[ "$OS" == "centos" || "$OS" == "rhel" ]]; then
        yum clean all
    fi
    
    print_success "Cleanup completed"
    print_info "/tmp before: $tmp_before, after: $tmp_after"
    
    press_any_key
}

# Update RocketVPS
update_rocketvps() {
    show_header
    echo -e "${CYAN}Update RocketVPS${NC}"
    echo ""
    
    print_info "Current version: 1.0.0"
    print_info "Checking for updates..."
    
    # Check if running from git repository
    if [ -d "${ROCKETVPS_DIR}/.git" ]; then
        cd "${ROCKETVPS_DIR}" || exit
        git fetch origin
        
        local_hash=$(git rev-parse HEAD)
        remote_hash=$(git rev-parse origin/main)
        
        if [ "$local_hash" = "$remote_hash" ]; then
            print_success "RocketVPS is up to date"
        else
            print_info "Update available"
            read -p "Update now? (yes/no): " confirm
            
            if [ "$confirm" = "yes" ]; then
                git pull origin main
                chmod +x rocketvps.sh
                chmod +x modules/*.sh
                print_success "RocketVPS updated successfully"
                print_info "Please restart the script"
                exit 0
            fi
        fi
    else
        print_info "Manual installation detected"
        print_info "To update, download the latest version from GitHub"
    fi
    
    press_any_key
}
