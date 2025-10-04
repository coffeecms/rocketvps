#!/bin/bash

# ==============================================================================
# RocketVPS v2.2.0 - Health Monitoring & Auto-Healing System (Phase 2 Week 7-8)
# ==============================================================================
# File: modules/health_monitor.sh
# Description: Intelligent health monitoring with automatic healing and alerts
# Version: 2.2.0
# Author: RocketVPS Team
# ==============================================================================

# Source required modules
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/utils.sh" 2>/dev/null || true

# ==============================================================================
# CONFIGURATION
# ==============================================================================

# Health monitoring directories
HEALTH_DIR="/opt/rocketvps/health"
HEALTH_STATUS_DIR="${HEALTH_DIR}/status"
HEALTH_HISTORY_DIR="${HEALTH_DIR}/history"
HEALTH_LOG_DIR="${HEALTH_DIR}/logs"

# Health check intervals (in minutes)
HEALTH_CHECK_INTERVAL=15        # Default: Every 15 minutes
HEALTH_HISTORY_RETENTION=30     # Keep history for 30 days

# Health check thresholds
DISK_WARNING_THRESHOLD=80       # Disk usage warning at 80%
DISK_CRITICAL_THRESHOLD=90      # Disk usage critical at 90%
MEMORY_WARNING_THRESHOLD=85     # Memory warning at 85%
MEMORY_CRITICAL_THRESHOLD=95    # Memory critical at 95%
CPU_WARNING_THRESHOLD=80        # CPU warning at 80%
CPU_CRITICAL_THRESHOLD=95       # CPU critical at 95%
SSL_EXPIRY_WARNING_DAYS=30      # Warn when SSL expires in 30 days
SSL_EXPIRY_CRITICAL_DAYS=7      # Critical when SSL expires in 7 days

# Auto-fix settings
AUTO_FIX_ENABLED=true
AUTO_FIX_MAX_RETRIES=3
AUTO_FIX_RETRY_DELAY=60         # Seconds between retries

# Alert settings
ALERT_ENABLED=true
ALERT_EMAIL=""                   # Set via config
ALERT_WEBHOOK_URL=""             # Set via config
ALERT_SLACK_WEBHOOK=""           # Set via config
ALERT_DISCORD_WEBHOOK=""         # Set via config
ALERT_MIN_INTERVAL=3600          # Min 1 hour between duplicate alerts

# Service names
SERVICE_NGINX="nginx"
SERVICE_MYSQL="mysql"
SERVICE_PHP_FPM="php-fpm"        # Will detect actual PHP-FPM service name

# ==============================================================================
# INITIALIZATION
# ==============================================================================

health_monitor_init() {
    log_info "Initializing Health Monitoring System..."
    
    # Create directories
    mkdir -p "${HEALTH_DIR}"
    mkdir -p "${HEALTH_STATUS_DIR}"
    mkdir -p "${HEALTH_HISTORY_DIR}"
    mkdir -p "${HEALTH_LOG_DIR}"
    
    # Set permissions
    chmod 700 "${HEALTH_DIR}"
    chmod 700 "${HEALTH_STATUS_DIR}"
    chmod 700 "${HEALTH_HISTORY_DIR}"
    chmod 700 "${HEALTH_LOG_DIR}"
    
    # Detect PHP-FPM service name
    detect_php_fpm_service
    
    # Detect MySQL service name
    detect_mysql_service
    
    log_success "Health Monitoring System initialized"
}

# Detect PHP-FPM service name
detect_php_fpm_service() {
    # Try common PHP-FPM service names
    local php_services=(
        "php8.3-fpm"
        "php8.2-fpm"
        "php8.1-fpm"
        "php8.0-fpm"
        "php7.4-fpm"
        "php-fpm"
    )
    
    for service in "${php_services[@]}"; do
        if systemctl list-unit-files | grep -q "^${service}.service"; then
            SERVICE_PHP_FPM="$service"
            return 0
        fi
    done
    
    SERVICE_PHP_FPM="php-fpm"  # Default fallback
}

# Detect MySQL service name
detect_mysql_service() {
    if systemctl list-unit-files | grep -q "^mysql.service"; then
        SERVICE_MYSQL="mysql"
    elif systemctl list-unit-files | grep -q "^mariadb.service"; then
        SERVICE_MYSQL="mariadb"
    else
        SERVICE_MYSQL="mysql"  # Default fallback
    fi
}

# ==============================================================================
# HEALTH CHECKS
# ==============================================================================

# Check 1: Site responding (HTTP status)
check_site_responding() {
    local domain="$1"
    local status_code
    local response_time
    local start_time=$(date +%s%N)
    
    # Try HTTP request
    status_code=$(curl -s -o /dev/null -w "%{http_code}" -m 10 "http://${domain}" 2>/dev/null)
    local end_time=$(date +%s%N)
    response_time=$(( (end_time - start_time) / 1000000 ))  # Convert to ms
    
    if [[ "$status_code" =~ ^(200|301|302|304)$ ]]; then
        echo "OK|${status_code}|${response_time}ms"
        return 0
    else
        echo "FAIL|${status_code}|${response_time}ms"
        return 1
    fi
}

# Check 2: SSL certificate expiry
check_ssl_expiry() {
    local domain="$1"
    local cert_file="/etc/letsencrypt/live/${domain}/cert.pem"
    
    if [[ ! -f "$cert_file" ]]; then
        echo "NO_SSL|0|N/A"
        return 2  # No SSL configured
    fi
    
    # Get certificate expiry date
    local expiry_date=$(openssl x509 -enddate -noout -in "$cert_file" 2>/dev/null | cut -d= -f2)
    
    if [[ -z "$expiry_date" ]]; then
        echo "ERROR|0|Unable to read certificate"
        return 1
    fi
    
    # Calculate days until expiry
    local expiry_epoch=$(date -d "$expiry_date" +%s 2>/dev/null)
    local current_epoch=$(date +%s)
    local days_until_expiry=$(( (expiry_epoch - current_epoch) / 86400 ))
    
    if [[ $days_until_expiry -lt 0 ]]; then
        echo "EXPIRED|${days_until_expiry}|${expiry_date}"
        return 1
    elif [[ $days_until_expiry -lt $SSL_EXPIRY_CRITICAL_DAYS ]]; then
        echo "CRITICAL|${days_until_expiry}|${expiry_date}"
        return 1
    elif [[ $days_until_expiry -lt $SSL_EXPIRY_WARNING_DAYS ]]; then
        echo "WARNING|${days_until_expiry}|${expiry_date}"
        return 0
    else
        echo "OK|${days_until_expiry}|${expiry_date}"
        return 0
    fi
}

# Check 3: Database accessibility
check_database_accessibility() {
    local domain="$1"
    local web_root="/var/www/${domain}"
    
    # Try to detect database credentials
    local db_name=""
    local db_user=""
    local db_pass=""
    
    # WordPress
    if [[ -f "${web_root}/wp-config.php" ]]; then
        db_name=$(grep "DB_NAME" "${web_root}/wp-config.php" 2>/dev/null | cut -d "'" -f 4 | head -n 1)
        db_user=$(grep "DB_USER" "${web_root}/wp-config.php" 2>/dev/null | cut -d "'" -f 4 | head -n 1)
        db_pass=$(grep "DB_PASSWORD" "${web_root}/wp-config.php" 2>/dev/null | cut -d "'" -f 4 | head -n 1)
    # Laravel
    elif [[ -f "${web_root}/.env" ]]; then
        db_name=$(grep "DB_DATABASE=" "${web_root}/.env" 2>/dev/null | cut -d "=" -f 2 | tr -d '"' | head -n 1)
        db_user=$(grep "DB_USERNAME=" "${web_root}/.env" 2>/dev/null | cut -d "=" -f 2 | tr -d '"' | head -n 1)
        db_pass=$(grep "DB_PASSWORD=" "${web_root}/.env" 2>/dev/null | cut -d "=" -f 2 | tr -d '"' | head -n 1)
    fi
    
    if [[ -z "$db_name" ]]; then
        echo "NO_DB|0|No database configured"
        return 2  # No database configured
    fi
    
    # Test database connection
    local test_result=$(mysql -u"${db_user}" -p"${db_pass}" -e "USE ${db_name}; SELECT 1;" 2>&1)
    
    if [[ $? -eq 0 ]]; then
        # Get database size
        local db_size=$(mysql -u"${db_user}" -p"${db_pass}" -e "SELECT ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS 'Size_MB' FROM information_schema.TABLES WHERE table_schema='${db_name}';" -N 2>/dev/null)
        echo "OK|${db_size}MB|Connected"
        return 0
    else
        echo "FAIL|0|${test_result}"
        return 1
    fi
}

# Check 4: Disk space
check_disk_space() {
    local partition="${1:-/}"
    
    # Get disk usage percentage
    local disk_usage=$(df -h "$partition" | awk 'NR==2 {print $5}' | sed 's/%//')
    local disk_avail=$(df -h "$partition" | awk 'NR==2 {print $4}')
    
    if [[ $disk_usage -ge $DISK_CRITICAL_THRESHOLD ]]; then
        echo "CRITICAL|${disk_usage}%|${disk_avail} available"
        return 1
    elif [[ $disk_usage -ge $DISK_WARNING_THRESHOLD ]]; then
        echo "WARNING|${disk_usage}%|${disk_avail} available"
        return 0
    else
        echo "OK|${disk_usage}%|${disk_avail} available"
        return 0
    fi
}

# Check 5: PHP-FPM status
check_php_fpm_status() {
    if systemctl is-active --quiet "$SERVICE_PHP_FPM"; then
        local uptime=$(systemctl show "$SERVICE_PHP_FPM" --property=ActiveEnterTimestamp --value)
        local memory=$(ps aux | grep -E "${SERVICE_PHP_FPM}.*pool" | awk '{sum+=$6} END {print sum/1024}' 2>/dev/null)
        echo "OK|Active|${memory}MB RAM, Up since ${uptime}"
        return 0
    else
        echo "FAIL|Inactive|Service not running"
        return 1
    fi
}

# Check 6: Memory usage
check_memory_usage() {
    local total_mem=$(free -m | awk 'NR==2 {print $2}')
    local used_mem=$(free -m | awk 'NR==2 {print $3}')
    local usage_percent=$(( used_mem * 100 / total_mem ))
    local avail_mem=$(free -m | awk 'NR==2 {print $7}')
    
    if [[ $usage_percent -ge $MEMORY_CRITICAL_THRESHOLD ]]; then
        echo "CRITICAL|${usage_percent}%|${avail_mem}MB available of ${total_mem}MB"
        return 1
    elif [[ $usage_percent -ge $MEMORY_WARNING_THRESHOLD ]]; then
        echo "WARNING|${usage_percent}%|${avail_mem}MB available of ${total_mem}MB"
        return 0
    else
        echo "OK|${usage_percent}%|${avail_mem}MB available of ${total_mem}MB"
        return 0
    fi
}

# Check 7: CPU usage
check_cpu_usage() {
    # Get CPU usage average over 1 second
    local cpu_usage=$(top -bn2 -d 1 | grep "Cpu(s)" | tail -n 1 | awk '{print $2}' | cut -d'%' -f1)
    
    # Remove decimal for comparison
    local cpu_int=${cpu_usage%.*}
    
    if [[ $cpu_int -ge $CPU_CRITICAL_THRESHOLD ]]; then
        echo "CRITICAL|${cpu_usage}%|High CPU load"
        return 1
    elif [[ $cpu_int -ge $CPU_WARNING_THRESHOLD ]]; then
        echo "WARNING|${cpu_usage}%|Elevated CPU load"
        return 0
    else
        echo "OK|${cpu_usage}%|Normal"
        return 0
    fi
}

# Check 8: Nginx status
check_nginx_status() {
    if systemctl is-active --quiet "$SERVICE_NGINX"; then
        local uptime=$(systemctl show "$SERVICE_NGINX" --property=ActiveEnterTimestamp --value)
        local connections=$(ss -s | grep "TCP:" | awk '{print $4}')
        echo "OK|Active|${connections} connections, Up since ${uptime}"
        return 0
    else
        echo "FAIL|Inactive|Service not running"
        return 1
    fi
}

# Check 9: MySQL status
check_mysql_status() {
    if systemctl is-active --quiet "$SERVICE_MYSQL"; then
        local uptime=$(systemctl show "$SERVICE_MYSQL" --property=ActiveEnterTimestamp --value)
        local connections=$(mysql -e "SHOW STATUS LIKE 'Threads_connected';" -N 2>/dev/null | awk '{print $2}')
        echo "OK|Active|${connections} connections, Up since ${uptime}"
        return 0
    else
        echo "FAIL|Inactive|Service not running"
        return 1
    fi
}

# ==============================================================================
# HEALTH CHECK EXECUTION
# ==============================================================================

# Run all health checks for a domain
run_domain_health_checks() {
    local domain="$1"
    local timestamp=$(date +%s)
    local status_file="${HEALTH_STATUS_DIR}/${domain}.json"
    
    log_info "Running health checks for ${domain}..."
    
    # Initialize results
    local results=()
    local overall_status="OK"
    
    # Run each health check
    local site_result=$(check_site_responding "$domain")
    local site_status=$?
    results+=("\"site_responding\": {\"result\": \"${site_result}\", \"status\": ${site_status}}")
    [[ $site_status -ne 0 ]] && overall_status="FAIL"
    
    local ssl_result=$(check_ssl_expiry "$domain")
    local ssl_status=$?
    results+=("\"ssl_expiry\": {\"result\": \"${ssl_result}\", \"status\": ${ssl_status}}")
    [[ $ssl_status -eq 1 ]] && overall_status="FAIL"
    
    local db_result=$(check_database_accessibility "$domain")
    local db_status=$?
    results+=("\"database\": {\"result\": \"${db_result}\", \"status\": ${db_status}}")
    [[ $db_status -eq 1 ]] && overall_status="FAIL"
    
    # Save health status
    cat > "$status_file" <<EOF
{
    "domain": "${domain}",
    "timestamp": ${timestamp},
    "date": "$(date)",
    "overall_status": "${overall_status}",
    "checks": {
        ${results[0]},
        ${results[1]},
        ${results[2]}
    }
}
EOF
    
    # Save to history
    save_to_history "$domain" "$overall_status" "$timestamp"
    
    if [[ "$overall_status" == "FAIL" ]]; then
        log_error "Health check failed for ${domain}"
        
        # Trigger auto-fix if enabled
        if [[ "$AUTO_FIX_ENABLED" == "true" ]]; then
            trigger_auto_fix "$domain" "$status_file"
        fi
        
        # Send alert if enabled
        if [[ "$ALERT_ENABLED" == "true" ]]; then
            send_health_alert "$domain" "FAIL" "$status_file"
        fi
        
        return 1
    else
        log_success "Health check passed for ${domain}"
        return 0
    fi
}

# Run system-wide health checks
run_system_health_checks() {
    log_info "Running system-wide health checks..."
    
    local timestamp=$(date +%s)
    local status_file="${HEALTH_STATUS_DIR}/system.json"
    
    # Run checks
    local disk_result=$(check_disk_space "/")
    local disk_status=$?
    
    local memory_result=$(check_memory_usage)
    local memory_status=$?
    
    local cpu_result=$(check_cpu_usage)
    local cpu_status=$?
    
    local nginx_result=$(check_nginx_status)
    local nginx_status=$?
    
    local mysql_result=$(check_mysql_status)
    local mysql_status=$?
    
    local php_result=$(check_php_fpm_status)
    local php_status=$?
    
    # Determine overall status
    local overall_status="OK"
    if [[ $disk_status -ne 0 ]] || [[ $memory_status -ne 0 ]] || [[ $cpu_status -ne 0 ]] || \
       [[ $nginx_status -ne 0 ]] || [[ $mysql_status -ne 0 ]] || [[ $php_status -ne 0 ]]; then
        overall_status="FAIL"
    fi
    
    # Save status
    cat > "$status_file" <<EOF
{
    "type": "system",
    "timestamp": ${timestamp},
    "date": "$(date)",
    "overall_status": "${overall_status}",
    "checks": {
        "disk_space": {"result": "${disk_result}", "status": ${disk_status}},
        "memory_usage": {"result": "${memory_result}", "status": ${memory_status}},
        "cpu_usage": {"result": "${cpu_result}", "status": ${cpu_status}},
        "nginx_status": {"result": "${nginx_result}", "status": ${nginx_status}},
        "mysql_status": {"result": "${mysql_result}", "status": ${mysql_status}},
        "php_fpm_status": {"result": "${php_result}", "status": ${php_status}}
    }
}
EOF
    
    # Trigger auto-fix if needed
    if [[ "$overall_status" == "FAIL" ]] && [[ "$AUTO_FIX_ENABLED" == "true" ]]; then
        trigger_system_auto_fix "$status_file"
    fi
    
    # Send alert if needed
    if [[ "$overall_status" == "FAIL" ]] && [[ "$ALERT_ENABLED" == "true" ]]; then
        send_health_alert "system" "FAIL" "$status_file"
    fi
    
    log_info "System health check completed: ${overall_status}"
    return $([ "$overall_status" == "OK" ] && echo 0 || echo 1)
}

# Run health checks for all domains
run_all_health_checks() {
    log_section "Running Health Checks for All Domains"
    
    # Run system checks first
    run_system_health_checks
    
    # Get all domains
    local domains=()
    if [[ -d "/var/www" ]]; then
        for domain_dir in /var/www/*/; do
            if [[ -d "$domain_dir" ]]; then
                local domain=$(basename "$domain_dir")
                # Skip system directories
                if [[ "$domain" != "html" ]] && [[ "$domain" != "default" ]]; then
                    domains+=("$domain")
                fi
            fi
        done
    fi
    
    if [[ ${#domains[@]} -eq 0 ]]; then
        log_info "No domains found"
        return 0
    fi
    
    log_info "Checking ${#domains[@]} domains..."
    
    local failed_count=0
    for domain in "${domains[@]}"; do
        run_domain_health_checks "$domain"
        [[ $? -ne 0 ]] && ((failed_count++))
    done
    
    log_info "Health checks completed: $((${#domains[@]} - failed_count))/${#domains[@]} passed"
    
    return 0
}

# ==============================================================================
# AUTO-FIX IMPLEMENTATION
# ==============================================================================

# Auto-fix for domain issues
trigger_auto_fix() {
    local domain="$1"
    local status_file="$2"
    
    log_info "Triggering auto-fix for ${domain}..."
    
    # Parse status file to determine what needs fixing
    if grep -q '"site_responding".*"status": 1' "$status_file"; then
        log_info "Site not responding - checking Nginx..."
        auto_fix_nginx
    fi
    
    if grep -q '"ssl_expiry".*"status": 1' "$status_file"; then
        log_info "SSL issue detected - attempting renewal..."
        auto_fix_ssl "$domain"
    fi
    
    if grep -q '"database".*"status": 1' "$status_file"; then
        log_info "Database issue detected - checking MySQL..."
        auto_fix_mysql
    fi
}

# Auto-fix for system issues
trigger_system_auto_fix() {
    local status_file="$1"
    
    log_info "Triggering system auto-fix..."
    
    if grep -q '"nginx_status".*"status": 1' "$status_file"; then
        auto_fix_nginx
    fi
    
    if grep -q '"mysql_status".*"status": 1' "$status_file"; then
        auto_fix_mysql
    fi
    
    if grep -q '"php_fpm_status".*"status": 1' "$status_file"; then
        auto_fix_php_fpm
    fi
    
    if grep -q '"disk_space".*"CRITICAL"' "$status_file"; then
        auto_fix_disk_space
    fi
    
    if grep -q '"memory_usage".*"CRITICAL"' "$status_file"; then
        auto_fix_memory
    fi
}

# Auto-fix: Restart Nginx
auto_fix_nginx() {
    log_info "Auto-fix: Restarting Nginx..."
    
    if systemctl restart "$SERVICE_NGINX"; then
        log_success "Nginx restarted successfully"
        log_auto_fix_action "nginx" "restart" "success"
        return 0
    else
        log_error "Failed to restart Nginx"
        log_auto_fix_action "nginx" "restart" "failed"
        return 1
    fi
}

# Auto-fix: Restart MySQL
auto_fix_mysql() {
    log_info "Auto-fix: Restarting MySQL..."
    
    if systemctl restart "$SERVICE_MYSQL"; then
        log_success "MySQL restarted successfully"
        log_auto_fix_action "mysql" "restart" "success"
        return 0
    else
        log_error "Failed to restart MySQL"
        log_auto_fix_action "mysql" "restart" "failed"
        return 1
    fi
}

# Auto-fix: Restart PHP-FPM
auto_fix_php_fpm() {
    log_info "Auto-fix: Restarting PHP-FPM..."
    
    if systemctl restart "$SERVICE_PHP_FPM"; then
        log_success "PHP-FPM restarted successfully"
        log_auto_fix_action "php-fpm" "restart" "success"
        return 0
    else
        log_error "Failed to restart PHP-FPM"
        log_auto_fix_action "php-fpm" "restart" "failed"
        return 1
    fi
}

# Auto-fix: Renew SSL certificate
auto_fix_ssl() {
    local domain="$1"
    
    log_info "Auto-fix: Renewing SSL for ${domain}..."
    
    if certbot renew --cert-name "$domain" --quiet; then
        log_success "SSL renewed successfully for ${domain}"
        log_auto_fix_action "ssl" "renew:${domain}" "success"
        
        # Reload Nginx to apply new certificate
        systemctl reload "$SERVICE_NGINX"
        
        return 0
    else
        log_error "Failed to renew SSL for ${domain}"
        log_auto_fix_action "ssl" "renew:${domain}" "failed"
        return 1
    fi
}

# Auto-fix: Clear cache when disk is full
auto_fix_disk_space() {
    log_info "Auto-fix: Clearing cache to free disk space..."
    
    local freed_space=0
    
    # Clear APT cache
    apt-get clean >/dev/null 2>&1
    ((freed_space += 1))
    
    # Clear old logs
    find /var/log -type f -name "*.log" -mtime +30 -delete 2>/dev/null
    ((freed_space += 1))
    
    # Clear old backups (keep last 7 days)
    if [[ -d "/opt/rocketvps/backups" ]]; then
        find /opt/rocketvps/backups -type f -name "backup_*.tar.gz" -mtime +7 -delete 2>/dev/null
        ((freed_space += 1))
    fi
    
    log_success "Disk space cleanup completed"
    log_auto_fix_action "disk" "cleanup" "success:${freed_space}_operations"
    
    return 0
}

# Auto-fix: Optimize memory usage
auto_fix_memory() {
    log_info "Auto-fix: Optimizing memory usage..."
    
    # Clear PageCache, dentries and inodes
    sync
    echo 3 > /proc/sys/vm/drop_caches 2>/dev/null
    
    # Restart PHP-FPM to free memory
    systemctl restart "$SERVICE_PHP_FPM" 2>/dev/null
    
    log_success "Memory optimization completed"
    log_auto_fix_action "memory" "optimize" "success"
    
    return 0
}

# Log auto-fix action
log_auto_fix_action() {
    local component="$1"
    local action="$2"
    local result="$3"
    local timestamp=$(date +%s)
    local log_file="${HEALTH_LOG_DIR}/auto_fix.log"
    
    echo "[$(date)] AUTO-FIX: ${component} | ${action} | ${result}" >> "$log_file"
}

# ==============================================================================
# ALERT SYSTEM
# ==============================================================================

# Send health alert
send_health_alert() {
    local subject="$1"
    local severity="$2"
    local status_file="$3"
    
    # Check if we should send alert (avoid spam)
    if ! should_send_alert "$subject"; then
        return 0
    fi
    
    # Prepare alert message
    local alert_data=$(cat "$status_file")
    local alert_message="Health check failed for ${subject}\n\nDetails:\n${alert_data}"
    
    # Send email alert
    if [[ -n "$ALERT_EMAIL" ]]; then
        send_email_alert "$ALERT_EMAIL" "RocketVPS Health Alert: ${subject}" "$alert_message"
    fi
    
    # Send webhook alert
    if [[ -n "$ALERT_WEBHOOK_URL" ]]; then
        send_webhook_alert "$ALERT_WEBHOOK_URL" "$subject" "$severity" "$alert_message"
    fi
    
    # Send Slack alert
    if [[ -n "$ALERT_SLACK_WEBHOOK" ]]; then
        send_slack_alert "$ALERT_SLACK_WEBHOOK" "$subject" "$severity" "$alert_message"
    fi
    
    # Send Discord alert
    if [[ -n "$ALERT_DISCORD_WEBHOOK" ]]; then
        send_discord_alert "$ALERT_DISCORD_WEBHOOK" "$subject" "$severity" "$alert_message"
    fi
    
    # Update last alert time
    echo "$(date +%s)" > "${HEALTH_DIR}/.last_alert_${subject}"
}

# Check if we should send alert (avoid spam)
should_send_alert() {
    local subject="$1"
    local last_alert_file="${HEALTH_DIR}/.last_alert_${subject}"
    
    if [[ ! -f "$last_alert_file" ]]; then
        return 0  # First alert, send it
    fi
    
    local last_alert=$(cat "$last_alert_file")
    local current_time=$(date +%s)
    local time_diff=$((current_time - last_alert))
    
    if [[ $time_diff -gt $ALERT_MIN_INTERVAL ]]; then
        return 0  # Enough time passed, send alert
    else
        return 1  # Too soon, skip alert
    fi
}

# Send email alert
send_email_alert() {
    local to_email="$1"
    local subject="$2"
    local message="$3"
    
    # Use mail command if available
    if command -v mail >/dev/null 2>&1; then
        echo -e "$message" | mail -s "$subject" "$to_email"
    fi
}

# Send webhook alert
send_webhook_alert() {
    local webhook_url="$1"
    local subject="$2"
    local severity="$3"
    local message="$4"
    
    curl -X POST "$webhook_url" \
        -H "Content-Type: application/json" \
        -d "{\"subject\": \"${subject}\", \"severity\": \"${severity}\", \"message\": \"${message}\"}" \
        2>/dev/null
}

# Send Slack alert
send_slack_alert() {
    local webhook_url="$1"
    local subject="$2"
    local severity="$3"
    local message="$4"
    
    local color="danger"
    [[ "$severity" == "WARNING" ]] && color="warning"
    
    curl -X POST "$webhook_url" \
        -H "Content-Type: application/json" \
        -d "{\"attachments\": [{\"color\": \"${color}\", \"title\": \"${subject}\", \"text\": \"${message}\"}]}" \
        2>/dev/null
}

# Send Discord alert
send_discord_alert() {
    local webhook_url="$1"
    local subject="$2"
    local severity="$3"
    local message="$4"
    
    curl -X POST "$webhook_url" \
        -H "Content-Type: application/json" \
        -d "{\"embeds\": [{\"title\": \"${subject}\", \"description\": \"${message}\", \"color\": 15158332}]}" \
        2>/dev/null
}

# ==============================================================================
# HEALTH HISTORY
# ==============================================================================

# Save health check to history
save_to_history() {
    local domain="$1"
    local status="$2"
    local timestamp="$3"
    local date_str=$(date +%Y-%m-%d)
    local history_file="${HEALTH_HISTORY_DIR}/${domain}_${date_str}.log"
    
    echo "${timestamp}|${status}" >> "$history_file"
}

# Get health history for domain
get_health_history() {
    local domain="$1"
    local days="${2:-7}"  # Last 7 days by default
    
    local history_files=$(find "${HEALTH_HISTORY_DIR}" -name "${domain}_*.log" -mtime -${days} | sort)
    
    if [[ -z "$history_files" ]]; then
        echo "No history found for ${domain}"
        return 1
    fi
    
    echo "Health History for ${domain} (Last ${days} days):"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    while IFS= read -r file; do
        local date=$(basename "$file" | sed "s/${domain}_//" | sed 's/.log//')
        echo ""
        echo "Date: ${date}"
        
        local total=0
        local failed=0
        
        while IFS='|' read -r timestamp status; do
            ((total++))
            [[ "$status" == "FAIL" ]] && ((failed++))
        done < "$file"
        
        local uptime_percent=$(( (total - failed) * 100 / total ))
        echo "  Checks: ${total}"
        echo "  Failed: ${failed}"
        echo "  Uptime: ${uptime_percent}%"
    done <<< "$history_files"
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# ==============================================================================
# HEALTH STATUS DISPLAY
# ==============================================================================

# Display current health status
display_health_status() {
    local domain="${1:-system}"
    local status_file="${HEALTH_STATUS_DIR}/${domain}.json"
    
    if [[ ! -f "$status_file" ]]; then
        echo "No health status found for ${domain}"
        echo "Run: rocketvps health-check ${domain}"
        return 1
    fi
    
    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║          Health Status: ${domain}"
    echo "╠════════════════════════════════════════════════════════════╣"
    
    # Parse and display JSON status
    cat "$status_file" | jq -r '
        "║  Overall Status: " + .overall_status,
        "║  Last Check: " + .date,
        "║",
        "║  Checks:",
        (.checks | to_entries[] | "║    " + .key + ": " + .value.result)
    ' 2>/dev/null || cat "$status_file"
    
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
}

# ==============================================================================
# SCHEDULING
# ==============================================================================

# Setup automatic health monitoring
setup_health_monitoring() {
    log_info "Setting up automatic health monitoring..."
    
    # Create cron job
    local cron_file="/etc/cron.d/rocketvps_health_monitor"
    
    cat > "$cron_file" <<EOF
# RocketVPS Health Monitoring
# Check health every ${HEALTH_CHECK_INTERVAL} minutes

*/${HEALTH_CHECK_INTERVAL} * * * * root /opt/rocketvps/rocketvps.sh health-check-all >/dev/null 2>&1
EOF
    
    chmod 644 "$cron_file"
    
    log_success "Health monitoring scheduled (every ${HEALTH_CHECK_INTERVAL} minutes)"
}

# ==============================================================================
# EXPORTS
# ==============================================================================

# Initialize on module load
health_monitor_init

# Export functions
export -f run_domain_health_checks
export -f run_system_health_checks
export -f run_all_health_checks
export -f display_health_status
export -f get_health_history
export -f setup_health_monitoring

log_success "Health Monitoring module loaded successfully"
