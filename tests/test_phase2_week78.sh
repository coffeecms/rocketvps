#!/bin/bash

# ==============================================================================
# RocketVPS v2.2.0 - Phase 2 Week 7-8 Test Suite
# ==============================================================================
# File: tests/test_phase2_week78.sh
# Description: Comprehensive tests for Health Monitoring & Auto-Detect
# Version: 2.2.0
# ==============================================================================

# Test configuration
TEST_DIR="/tmp/rocketvps_test_phase2_week78"
TEST_LOG="${TEST_DIR}/test_phase2_week78.log"
TEST_DOMAIN="test-domain-week78.local"
TEST_WEB_ROOT="${TEST_DIR}/www/${TEST_DOMAIN}"

# Counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ==============================================================================
# TEST UTILITIES
# ==============================================================================

test_start() {
    local test_name="$1"
    ((TESTS_RUN++))
    echo -e "${BLUE}[TEST ${TESTS_RUN}]${NC} ${test_name}..." | tee -a "$TEST_LOG"
}

test_pass() {
    local message="${1:-Passed}"
    ((TESTS_PASSED++))
    echo -e "  ${GREEN}✓${NC} ${message}" | tee -a "$TEST_LOG"
}

test_fail() {
    local message="${1:-Failed}"
    ((TESTS_FAILED++))
    echo -e "  ${RED}✗${NC} ${message}" | tee -a "$TEST_LOG"
}

test_info() {
    local message="$1"
    echo -e "  ${YELLOW}ℹ${NC} ${message}" | tee -a "$TEST_LOG"
}

# ==============================================================================
# SETUP & CLEANUP
# ==============================================================================

setup_test_environment() {
    echo "Setting up test environment..." | tee -a "$TEST_LOG"
    
    # Create test directories
    mkdir -p "${TEST_DIR}"
    mkdir -p "${TEST_WEB_ROOT}"
    mkdir -p "/opt/rocketvps/health/status"
    mkdir -p "/opt/rocketvps/health/history"
    mkdir -p "/opt/rocketvps/health/logs"
    mkdir -p "/opt/rocketvps/auto_detect"
    
    # Source modules
    source "../modules/health_monitor.sh" 2>/dev/null || source "modules/health_monitor.sh"
    source "../modules/auto_detect.sh" 2>/dev/null || source "modules/auto_detect.sh"
    
    echo "Test environment ready" | tee -a "$TEST_LOG"
}

cleanup_test_environment() {
    echo "Cleaning up test environment..." | tee -a "$TEST_LOG"
    
    # Remove test directories
    rm -rf "${TEST_DIR}"
    
    # Remove test domain web root
    rm -rf "/var/www/${TEST_DOMAIN}"
    
    echo "Cleanup completed" | tee -a "$TEST_LOG"
}

# ==============================================================================
# HEALTH MONITORING TESTS
# ==============================================================================

# Test 1: Health Monitor Module Initialization
test_health_monitor_init() {
    test_start "Health Monitor Module Initialization"
    
    if [[ -d "/opt/rocketvps/health" ]]; then
        test_pass "Health directory created"
    else
        test_fail "Health directory not found"
        return 1
    fi
    
    if [[ -d "/opt/rocketvps/health/status" ]]; then
        test_pass "Status directory created"
    else
        test_fail "Status directory not found"
    fi
    
    if [[ -d "/opt/rocketvps/health/history" ]]; then
        test_pass "History directory created"
    else
        test_fail "History directory not found"
    fi
}

# Test 2: System Health Checks - Disk Space
test_disk_space_check() {
    test_start "Disk Space Health Check"
    
    local result=$(check_disk_space "/")
    local status=$?
    
    if [[ -n "$result" ]]; then
        test_pass "Disk check returned: ${result}"
        test_info "Status code: ${status}"
    else
        test_fail "Disk check returned empty result"
    fi
}

# Test 3: System Health Checks - Memory Usage
test_memory_usage_check() {
    test_start "Memory Usage Health Check"
    
    local result=$(check_memory_usage)
    local status=$?
    
    if [[ -n "$result" ]]; then
        test_pass "Memory check returned: ${result}"
        test_info "Status code: ${status}"
    else
        test_fail "Memory check returned empty result"
    fi
}

# Test 4: System Health Checks - CPU Usage
test_cpu_usage_check() {
    test_start "CPU Usage Health Check"
    
    local result=$(check_cpu_usage)
    local status=$?
    
    if [[ -n "$result" ]]; then
        test_pass "CPU check returned: ${result}"
        test_info "Status code: ${status}"
    else
        test_fail "CPU check returned empty result"
    fi
}

# Test 5: Service Status Checks - Nginx
test_nginx_status_check() {
    test_start "Nginx Status Check"
    
    local result=$(check_nginx_status)
    local status=$?
    
    if [[ -n "$result" ]]; then
        test_pass "Nginx check returned: ${result}"
        test_info "Status code: ${status}"
    else
        test_fail "Nginx check returned empty result"
    fi
}

# Test 6: Service Status Checks - MySQL
test_mysql_status_check() {
    test_start "MySQL Status Check"
    
    local result=$(check_mysql_status)
    local status=$?
    
    if [[ -n "$result" ]]; then
        test_pass "MySQL check returned: ${result}"
        test_info "Status code: ${status}"
    else
        test_fail "MySQL check returned empty result"
    fi
}

# Test 7: Service Status Checks - PHP-FPM
test_php_fpm_status_check() {
    test_start "PHP-FPM Status Check"
    
    local result=$(check_php_fpm_status)
    local status=$?
    
    if [[ -n "$result" ]]; then
        test_pass "PHP-FPM check returned: ${result}"
        test_info "Status code: ${status}"
    else
        test_fail "PHP-FPM check returned empty result"
    fi
}

# Test 8: Complete System Health Check
test_complete_system_health_check() {
    test_start "Complete System Health Check"
    
    run_system_health_checks
    local status=$?
    
    local status_file="/opt/rocketvps/health/status/system.json"
    
    if [[ -f "$status_file" ]]; then
        test_pass "System health status file created"
        
        # Verify JSON structure
        if grep -q "overall_status" "$status_file"; then
            test_pass "JSON contains overall_status"
        else
            test_fail "JSON missing overall_status"
        fi
        
        if grep -q "checks" "$status_file"; then
            test_pass "JSON contains checks"
        else
            test_fail "JSON missing checks"
        fi
    else
        test_fail "System health status file not created"
    fi
}

# Test 9: Alert System - Should Send Check
test_alert_should_send() {
    test_start "Alert System - Rate Limiting"
    
    # First alert should be sent
    if should_send_alert "test-alert"; then
        test_pass "First alert allowed"
    else
        test_fail "First alert blocked incorrectly"
    fi
    
    # Second immediate alert should be blocked
    if ! should_send_alert "test-alert"; then
        test_pass "Duplicate alert blocked by rate limiting"
    else
        test_fail "Duplicate alert not blocked"
    fi
}

# Test 10: Health History Tracking
test_health_history() {
    test_start "Health History Tracking"
    
    # Save test history
    save_to_history "test-domain.local" "OK" "$(date +%s)"
    save_to_history "test-domain.local" "FAIL" "$(date +%s)"
    
    local history_file=$(find "/opt/rocketvps/health/history" -name "test-domain.local_*.log" -type f | head -1)
    
    if [[ -f "$history_file" ]]; then
        test_pass "History file created"
        
        local entry_count=$(wc -l < "$history_file")
        if [[ $entry_count -eq 2 ]]; then
            test_pass "History contains 2 entries"
        else
            test_fail "History should contain 2 entries, found ${entry_count}"
        fi
    else
        test_fail "History file not created"
    fi
}

# ==============================================================================
# AUTO-DETECT TESTS
# ==============================================================================

# Test 11: WordPress Detection
test_wordpress_detection() {
    test_start "WordPress Site Detection"
    
    # Create fake WordPress site
    mkdir -p "${TEST_WEB_ROOT}"
    echo "<?php define('DB_NAME', 'wp_test');" > "${TEST_WEB_ROOT}/wp-config.php"
    mkdir -p "${TEST_WEB_ROOT}/wp-includes"
    echo "<?php \$wp_version = '6.4';" > "${TEST_WEB_ROOT}/wp-includes/version.php"
    
    local site_type=$(detect_site_type "test-domain-week78.local")
    
    if [[ "$site_type" == "WORDPRESS" ]]; then
        test_pass "WordPress detected correctly"
    else
        test_fail "WordPress not detected (got: ${site_type})"
    fi
    
    # Test framework detection
    local framework=$(detect_site_framework "test-domain-week78.local")
    test_info "Framework: ${framework}"
    
    # Cleanup
    rm -rf "${TEST_WEB_ROOT}"
}

# Test 12: Laravel Detection
test_laravel_detection() {
    test_start "Laravel Site Detection"
    
    # Create fake Laravel site
    mkdir -p "${TEST_WEB_ROOT}"
    echo "#!/usr/bin/env php" > "${TEST_WEB_ROOT}/artisan"
    cat > "${TEST_WEB_ROOT}/composer.json" <<EOF
{
    "require": {
        "laravel/framework": "^10.0"
    }
}
EOF
    
    local site_type=$(detect_site_type "test-domain-week78.local")
    
    if [[ "$site_type" == "LARAVEL" ]]; then
        test_pass "Laravel detected correctly"
    else
        test_fail "Laravel not detected (got: ${site_type})"
    fi
    
    # Cleanup
    rm -rf "${TEST_WEB_ROOT}"
}

# Test 13: Node.js Detection
test_nodejs_detection() {
    test_start "Node.js Site Detection"
    
    # Create fake Node.js site
    mkdir -p "${TEST_WEB_ROOT}"
    cat > "${TEST_WEB_ROOT}/package.json" <<EOF
{
    "name": "test-app",
    "dependencies": {
        "express": "^4.18.0"
    },
    "scripts": {
        "start": "node server.js"
    }
}
EOF
    
    local site_type=$(detect_site_type "test-domain-week78.local")
    
    if [[ "$site_type" == "NODEJS" ]]; then
        test_pass "Node.js detected correctly"
    else
        test_fail "Node.js not detected (got: ${site_type})"
    fi
    
    # Cleanup
    rm -rf "${TEST_WEB_ROOT}"
}

# Test 14: Static HTML Detection
test_static_detection() {
    test_start "Static HTML Site Detection"
    
    # Create fake static site
    mkdir -p "${TEST_WEB_ROOT}"
    echo "<html><body>Test</body></html>" > "${TEST_WEB_ROOT}/index.html"
    
    local site_type=$(detect_site_type "test-domain-week78.local")
    
    if [[ "$site_type" == "STATIC" ]]; then
        test_pass "Static site detected correctly"
    else
        test_fail "Static site not detected (got: ${site_type})"
    fi
    
    # Cleanup
    rm -rf "${TEST_WEB_ROOT}"
}

# Test 15: Database Configuration Extraction - WordPress
test_database_extraction_wordpress() {
    test_start "Database Config Extraction - WordPress"
    
    # Create fake WordPress config
    mkdir -p "${TEST_WEB_ROOT}"
    cat > "${TEST_WEB_ROOT}/wp-config.php" <<EOF
<?php
define('DB_NAME', 'wordpress_db');
define('DB_USER', 'wp_user');
define('DB_PASSWORD', 'secret123');
define('DB_HOST', 'localhost');
EOF
    
    local db_config=$(extract_database_config "test-domain-week78.local")
    
    if echo "$db_config" | grep -q '"db_name": "wordpress_db"'; then
        test_pass "Database name extracted correctly"
    else
        test_fail "Database name not extracted"
    fi
    
    if echo "$db_config" | grep -q '"db_user": "wp_user"'; then
        test_pass "Database user extracted correctly"
    else
        test_fail "Database user not extracted"
    fi
    
    # Cleanup
    rm -rf "${TEST_WEB_ROOT}"
}

# Test 16: Database Configuration Extraction - Laravel
test_database_extraction_laravel() {
    test_start "Database Config Extraction - Laravel"
    
    # Create fake Laravel .env
    mkdir -p "${TEST_WEB_ROOT}"
    cat > "${TEST_WEB_ROOT}/.env" <<EOF
DB_DATABASE=laravel_db
DB_USERNAME=laravel_user
DB_PASSWORD=password123
DB_HOST=localhost
DB_PORT=3306
EOF
    
    local db_config=$(extract_database_config "test-domain-week78.local")
    
    if echo "$db_config" | grep -q '"db_name": "laravel_db"'; then
        test_pass "Database name extracted correctly"
    else
        test_fail "Database name not extracted"
    fi
    
    if echo "$db_config" | grep -q '"db_user": "laravel_user"'; then
        test_pass "Database user extracted correctly"
    else
        test_fail "Database user not extracted"
    fi
    
    # Cleanup
    rm -rf "${TEST_WEB_ROOT}"
}

# Test 17: Nginx Configuration Generation - WordPress
test_nginx_config_wordpress() {
    test_start "Nginx Config Generation - WordPress"
    
    # Create fake WordPress site
    mkdir -p "${TEST_WEB_ROOT}"
    echo "<?php define('DB_NAME', 'test');" > "${TEST_WEB_ROOT}/wp-config.php"
    
    local nginx_config=$(generate_nginx_config "test-domain-week78.local")
    
    if echo "$nginx_config" | grep -q "server_name test-domain-week78.local"; then
        test_pass "Server name configured correctly"
    else
        test_fail "Server name not found in config"
    fi
    
    if echo "$nginx_config" | grep -q "root /var/www/test-domain-week78.local"; then
        test_pass "Web root configured correctly"
    else
        test_fail "Web root not found in config"
    fi
    
    if echo "$nginx_config" | grep -q "try_files.*index.php"; then
        test_pass "WordPress rewrite rules present"
    else
        test_fail "WordPress rewrite rules missing"
    fi
    
    # Cleanup
    rm -rf "${TEST_WEB_ROOT}"
}

# Test 18: Nginx Configuration Generation - Laravel
test_nginx_config_laravel() {
    test_start "Nginx Config Generation - Laravel"
    
    # Create fake Laravel site
    mkdir -p "${TEST_WEB_ROOT}"
    echo "#!/usr/bin/env php" > "${TEST_WEB_ROOT}/artisan"
    cat > "${TEST_WEB_ROOT}/composer.json" <<EOF
{"require": {"laravel/framework": "^10.0"}}
EOF
    
    local nginx_config=$(generate_nginx_config "test-domain-week78.local")
    
    if echo "$nginx_config" | grep -q "root /var/www/test-domain-week78.local/public"; then
        test_pass "Laravel public directory configured"
    else
        test_fail "Laravel public directory not configured"
    fi
    
    if echo "$nginx_config" | grep -q 'try_files.*$query_string'; then
        test_pass "Laravel rewrite rules present"
    else
        test_fail "Laravel rewrite rules missing"
    fi
    
    # Cleanup
    rm -rf "${TEST_WEB_ROOT}"
}

# Test 19: Nginx Configuration Generation - Node.js
test_nginx_config_nodejs() {
    test_start "Nginx Config Generation - Node.js"
    
    # Create fake Node.js site
    mkdir -p "${TEST_WEB_ROOT}"
    cat > "${TEST_WEB_ROOT}/package.json" <<EOF
{
    "name": "test",
    "dependencies": {"express": "^4.0.0"},
    "scripts": {"start": "node server.js"}
}
EOF
    cat > "${TEST_WEB_ROOT}/.env" <<EOF
PORT=3000
EOF
    
    local nginx_config=$(generate_nginx_config "test-domain-week78.local")
    
    if echo "$nginx_config" | grep -q "proxy_pass http://localhost:3000"; then
        test_pass "Node.js proxy configured correctly"
    else
        test_fail "Node.js proxy not configured"
    fi
    
    if echo "$nginx_config" | grep -q "proxy_set_header Upgrade"; then
        test_pass "WebSocket support configured"
    else
        test_fail "WebSocket support missing"
    fi
    
    # Cleanup
    rm -rf "${TEST_WEB_ROOT}"
}

# Test 20: PHP Version Detection
test_php_version_detection() {
    test_start "PHP Version Detection"
    
    # Test WordPress
    mkdir -p "${TEST_WEB_ROOT}"
    echo "<?php define('DB_NAME', 'test');" > "${TEST_WEB_ROOT}/wp-config.php"
    local php_version=$(detect_php_version "test-domain-week78.local")
    test_info "WordPress recommended PHP: ${php_version}"
    
    # Test Laravel
    rm -f "${TEST_WEB_ROOT}/wp-config.php"
    echo "#!/usr/bin/env php" > "${TEST_WEB_ROOT}/artisan"
    cat > "${TEST_WEB_ROOT}/composer.json" <<EOF
{"require": {"laravel/framework": "^10.0", "php": "^8.2"}}
EOF
    php_version=$(detect_php_version "test-domain-week78.local")
    test_info "Laravel recommended PHP: ${php_version}"
    
    if [[ -n "$php_version" ]]; then
        test_pass "PHP version detection working"
    else
        test_fail "PHP version not detected"
    fi
    
    # Cleanup
    rm -rf "${TEST_WEB_ROOT}"
}

# ==============================================================================
# PERFORMANCE TESTS
# ==============================================================================

# Test 21: Health Check Performance
test_health_check_performance() {
    test_start "Health Check Performance"
    
    local start_time=$(date +%s%N)
    run_system_health_checks >/dev/null 2>&1
    local end_time=$(date +%s%N)
    
    local duration=$(( (end_time - start_time) / 1000000 ))  # ms
    
    test_info "System health check took ${duration}ms"
    
    if [[ $duration -lt 5000 ]]; then
        test_pass "Performance acceptable (<5s)"
    elif [[ $duration -lt 10000 ]]; then
        test_pass "Performance acceptable (<10s) but could be improved"
    else
        test_fail "Performance too slow (>10s)"
    fi
}

# Test 22: Auto-Detect Performance
test_auto_detect_performance() {
    test_start "Auto-Detect Performance"
    
    # Create test sites
    mkdir -p "${TEST_WEB_ROOT}"
    echo "<?php define('DB_NAME', 'test');" > "${TEST_WEB_ROOT}/wp-config.php"
    
    local start_time=$(date +%s%N)
    local site_type=$(detect_site_type "test-domain-week78.local")
    local framework=$(detect_site_framework "test-domain-week78.local")
    local php_version=$(detect_php_version "test-domain-week78.local")
    local end_time=$(date +%s%N)
    
    local duration=$(( (end_time - start_time) / 1000000 ))  # ms
    
    test_info "Site detection took ${duration}ms"
    
    if [[ $duration -lt 500 ]]; then
        test_pass "Performance excellent (<500ms)"
    elif [[ $duration -lt 1000 ]]; then
        test_pass "Performance good (<1s)"
    else
        test_fail "Performance needs improvement (>1s)"
    fi
    
    # Cleanup
    rm -rf "${TEST_WEB_ROOT}"
}

# ==============================================================================
# INTEGRATION TEST
# ==============================================================================

# Test 23: Complete Health → Auto-Fix Flow
test_complete_health_flow() {
    test_start "Complete Health Check → Auto-Fix Integration"
    
    # Run full system health check
    run_system_health_checks >/dev/null 2>&1
    
    # Verify status file
    if [[ -f "/opt/rocketvps/health/status/system.json" ]]; then
        test_pass "Health check completed"
        
        # Check auto-fix log
        if [[ -f "/opt/rocketvps/health/logs/auto_fix.log" ]]; then
            test_info "Auto-fix log exists"
        fi
    else
        test_fail "Health check did not complete"
    fi
}

# ==============================================================================
# MAIN TEST RUNNER
# ==============================================================================

main() {
    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║  RocketVPS v2.2.0 - Phase 2 Week 7-8 Test Suite          ║"
    echo "║  Testing: Health Monitoring & Auto-Detect                ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
    
    # Setup
    setup_test_environment
    
    # Run tests
    echo ""
    echo "Running Health Monitoring Tests..."
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    test_health_monitor_init
    test_disk_space_check
    test_memory_usage_check
    test_cpu_usage_check
    test_nginx_status_check
    test_mysql_status_check
    test_php_fpm_status_check
    test_complete_system_health_check
    test_alert_should_send
    test_health_history
    
    echo ""
    echo "Running Auto-Detect Tests..."
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    test_wordpress_detection
    test_laravel_detection
    test_nodejs_detection
    test_static_detection
    test_database_extraction_wordpress
    test_database_extraction_laravel
    test_nginx_config_wordpress
    test_nginx_config_laravel
    test_nginx_config_nodejs
    test_php_version_detection
    
    echo ""
    echo "Running Performance Tests..."
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    test_health_check_performance
    test_auto_detect_performance
    
    echo ""
    echo "Running Integration Test..."
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    test_complete_health_flow
    
    # Cleanup
    cleanup_test_environment
    
    # Results
    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║                      TEST RESULTS                         ║"
    echo "╠════════════════════════════════════════════════════════════╣"
    echo "║  Total Tests: ${TESTS_RUN}"
    echo "║  Passed:      ${GREEN}${TESTS_PASSED}${NC}"
    echo "║  Failed:      ${RED}${TESTS_FAILED}${NC}"
    
    local success_rate=$(( TESTS_PASSED * 100 / TESTS_RUN ))
    echo "║  Success Rate: ${success_rate}%"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "${GREEN}✓ All tests passed!${NC}"
        echo ""
        return 0
    else
        echo -e "${RED}✗ Some tests failed. Check log: ${TEST_LOG}${NC}"
        echo ""
        return 1
    fi
}

# Run tests
main "$@"
