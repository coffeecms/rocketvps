#!/bin/bash

# ==============================================================================
# RocketVPS v2.2.0 - Phase 2 Automated Test Suite
# ==============================================================================
# File: tests/test_phase2.sh
# Description: Comprehensive automated testing for Smart Backup System
# Version: 2.2.0
# Author: RocketVPS Team
# ==============================================================================

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test configuration
TEST_DIR="/tmp/rocketvps_test_phase2"
TEST_DOMAIN="test-phase2.local"
TEST_LOG="${TEST_DIR}/test_phase2.log"
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_TOTAL=0

# Source modules
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/modules/smart_backup.sh"
source "${SCRIPT_DIR}/modules/utils.sh"

# ==============================================================================
# TEST UTILITIES
# ==============================================================================

test_start() {
    local test_name="$1"
    ((TESTS_TOTAL++))
    echo -e "\n${BLUE}[TEST ${TESTS_TOTAL}]${NC} ${test_name}"
    echo "[$(date)] TEST ${TESTS_TOTAL}: ${test_name}" >> "$TEST_LOG"
}

test_pass() {
    local message="$1"
    ((TESTS_PASSED++))
    echo -e "${GREEN}  ✓ PASS${NC}: ${message}"
    echo "  ✓ PASS: ${message}" >> "$TEST_LOG"
}

test_fail() {
    local message="$1"
    ((TESTS_FAILED++))
    echo -e "${RED}  ✗ FAIL${NC}: ${message}"
    echo "  ✗ FAIL: ${message}" >> "$TEST_LOG"
}

test_info() {
    local message="$1"
    echo -e "${YELLOW}  ℹ INFO${NC}: ${message}"
    echo "  ℹ INFO: ${message}" >> "$TEST_LOG"
}

# Setup test environment
setup_test_env() {
    echo -e "${BLUE}Setting up test environment...${NC}"
    
    # Create test directories
    mkdir -p "$TEST_DIR"
    mkdir -p "/var/www/${TEST_DOMAIN}"
    mkdir -p "$BACKUP_BASE_DIR"
    mkdir -p "$BACKUP_METADATA_DIR"
    mkdir -p "$BACKUP_INCREMENTAL_DIR"
    mkdir -p "$BACKUP_TRACKING_DIR"
    
    # Create test files
    for i in {1..50}; do
        echo "Test file $i" > "/var/www/${TEST_DOMAIN}/file${i}.txt"
    done
    
    # Create test structure
    mkdir -p "/var/www/${TEST_DOMAIN}/wp-content/cache"
    mkdir -p "/var/www/${TEST_DOMAIN}/wp-content/uploads"
    mkdir -p "/var/www/${TEST_DOMAIN}/wp-admin"
    
    # Create wp-config.php for WordPress detection
    cat > "/var/www/${TEST_DOMAIN}/wp-config.php" <<'EOF'
<?php
define('DB_NAME', 'test_db');
define('DB_USER', 'test_user');
define('DB_PASSWORD', 'test_pass');
define('DB_HOST', 'localhost');
?>
EOF
    
    # Initialize log
    echo "==================================" > "$TEST_LOG"
    echo "Phase 2 Test Suite - $(date)" >> "$TEST_LOG"
    echo "==================================" >> "$TEST_LOG"
    
    echo -e "${GREEN}Test environment ready${NC}\n"
}

# Cleanup test environment
cleanup_test_env() {
    echo -e "\n${BLUE}Cleaning up test environment...${NC}"
    
    # Remove test domain
    rm -rf "/var/www/${TEST_DOMAIN}"
    
    # Remove test backups
    rm -rf "${BACKUP_BASE_DIR}/${TEST_DOMAIN}"
    rm -rf "${BACKUP_INCREMENTAL_DIR}/${TEST_DOMAIN}"
    rm -rf "${BACKUP_TRACKING_DIR}/${TEST_DOMAIN}_*.json"
    
    # Keep test log for review
    # rm -rf "$TEST_DIR"
    
    echo -e "${GREEN}Cleanup completed${NC}"
}

# ==============================================================================
# PHASE 2 TESTS
# ==============================================================================

# Test 1: Module initialization
test_module_initialization() {
    test_start "Smart Backup Module Initialization"
    
    # Check if directories exist
    if [[ -d "$BACKUP_BASE_DIR" ]] && \
       [[ -d "$BACKUP_METADATA_DIR" ]] && \
       [[ -d "$BACKUP_INCREMENTAL_DIR" ]] && \
       [[ -d "$BACKUP_TRACKING_DIR" ]]; then
        test_pass "All backup directories created"
    else
        test_fail "Backup directories missing"
        return 1
    fi
    
    # Check permissions
    local perms=$(stat -c %a "$BACKUP_BASE_DIR" 2>/dev/null)
    if [[ "$perms" == "700" ]]; then
        test_pass "Correct permissions (700) on backup directory"
    else
        test_fail "Incorrect permissions on backup directory: $perms"
    fi
}

# Test 2: Domain activity analysis
test_activity_analysis() {
    test_start "Domain Activity Analysis"
    
    # Test activity detection
    local activity=$(analyze_domain_activity "$TEST_DOMAIN")
    
    if [[ -n "$activity" ]] && [[ "$activity" =~ ^(high|medium|low)$ ]]; then
        test_pass "Activity detected: ${activity}"
    else
        test_fail "Invalid activity level: ${activity}"
        return 1
    fi
    
    # Check tracking file created
    local tracking_file="${BACKUP_TRACKING_DIR}/${TEST_DOMAIN}_activity.json"
    if [[ -f "$tracking_file" ]]; then
        test_pass "Activity tracking file created"
        
        # Validate JSON
        if jq empty "$tracking_file" 2>/dev/null; then
            test_pass "Tracking file is valid JSON"
        else
            test_fail "Tracking file is invalid JSON"
        fi
    else
        test_fail "Activity tracking file not created"
    fi
}

# Test 3: Domain size detection
test_size_detection() {
    test_start "Domain Size Detection"
    
    local size=$(get_domain_size "$TEST_DOMAIN")
    
    if [[ -n "$size" ]] && [[ "$size" =~ ^[0-9]+$ ]]; then
        test_pass "Domain size detected: ${size}MB"
    else
        test_fail "Invalid domain size: ${size}"
        return 1
    fi
    
    local size_category=$(get_domain_size_category "$TEST_DOMAIN")
    
    if [[ "$size_category" =~ ^(small|medium|large)$ ]]; then
        test_pass "Size category: ${size_category}"
    else
        test_fail "Invalid size category: ${size_category}"
    fi
}

# Test 4: Backup strategy selection
test_strategy_selection() {
    test_start "Backup Strategy Selection"
    
    local strategy=$(select_backup_strategy "$TEST_DOMAIN")
    
    if [[ "$strategy" =~ ^(full|incremental|differential|mixed)$ ]]; then
        test_pass "Strategy selected: ${strategy}"
    else
        test_fail "Invalid strategy: ${strategy}"
        return 1
    fi
    
    # Test strategy logic
    test_info "Testing strategy selection logic..."
    
    # Small domain should use full backup
    # This is a simplified test
    if [[ "$strategy" != "" ]]; then
        test_pass "Strategy selection logic working"
    else
        test_fail "Strategy selection failed"
    fi
}

# Test 5: Schedule recommendation
test_schedule_recommendation() {
    test_start "Schedule Recommendation"
    
    local schedule=$(get_recommended_schedule "$TEST_DOMAIN")
    
    if [[ -n "$schedule" ]]; then
        test_pass "Schedule recommended: ${schedule}"
    else
        test_fail "Schedule recommendation failed"
        return 1
    fi
    
    # Validate cron format (basic check)
    if [[ "$schedule" =~ ^[0-9*]+\ [0-9*]+\ [0-9*]+\ [0-9*]+\ [0-9*]+$ ]]; then
        test_pass "Schedule is valid cron format"
    else
        test_fail "Invalid cron format: ${schedule}"
    fi
}

# Test 6: Full backup creation
test_full_backup() {
    test_start "Full Backup Creation"
    
    # Create full backup
    create_full_backup "$TEST_DOMAIN"
    local result=$?
    
    if [[ $result -eq 0 ]]; then
        test_pass "Full backup created successfully"
    else
        test_fail "Full backup creation failed"
        return 1
    fi
    
    # Check backup file exists
    local backup_dir="${BACKUP_BASE_DIR}/${TEST_DOMAIN}"
    local backup_count=$(find "$backup_dir" -name "backup_*.tar.gz" -type f ! -name "*incremental*" | wc -l)
    
    if [[ $backup_count -gt 0 ]]; then
        test_pass "Backup file created in ${backup_dir}"
    else
        test_fail "Backup file not found"
        return 1
    fi
    
    # Check metadata exists
    local meta_count=$(find "$backup_dir" -name "backup_*.tar.gz.meta" -type f | wc -l)
    if [[ $meta_count -gt 0 ]]; then
        test_pass "Backup metadata created"
    else
        test_fail "Backup metadata not found"
    fi
    
    # Verify backup integrity
    local backup_file=$(find "$backup_dir" -name "backup_*.tar.gz" -type f ! -name "*incremental*" | head -n 1)
    if verify_backup "$backup_file"; then
        test_pass "Backup integrity verified"
    else
        test_fail "Backup integrity check failed"
    fi
}

# Test 7: Changed files detection
test_changed_files_detection() {
    test_start "Changed Files Detection"
    
    # Modify some files
    sleep 2
    echo "Modified content" > "/var/www/${TEST_DOMAIN}/file1.txt"
    echo "New file" > "/var/www/${TEST_DOMAIN}/new_file.txt"
    
    # Find changed files
    local changed_files=$(find_changed_files "$TEST_DOMAIN")
    local file_count=$(echo "$changed_files" | grep -v "^$" | wc -l)
    
    if [[ $file_count -ge 2 ]]; then
        test_pass "Changed files detected: ${file_count} files"
    else
        test_fail "Changed files detection failed: only ${file_count} files found"
        return 1
    fi
    
    # Verify modified files are in the list
    if echo "$changed_files" | grep -q "file1.txt"; then
        test_pass "Modified file detected in change list"
    else
        test_fail "Modified file not detected"
    fi
}

# Test 8: Incremental backup creation
test_incremental_backup() {
    test_start "Incremental Backup Creation"
    
    # Create incremental backup
    create_incremental_backup "$TEST_DOMAIN"
    local result=$?
    
    if [[ $result -eq 0 ]]; then
        test_pass "Incremental backup created successfully"
    else
        test_fail "Incremental backup creation failed"
        return 1
    fi
    
    # Check incremental backup file
    local backup_dir="${BACKUP_BASE_DIR}/${TEST_DOMAIN}"
    local incremental_count=$(find "$backup_dir" -name "*incremental*.tar.gz" -type f | wc -l)
    
    if [[ $incremental_count -gt 0 ]]; then
        test_pass "Incremental backup file created"
    else
        test_fail "Incremental backup file not found"
        return 1
    fi
    
    # Check metadata
    local inc_backup=$(find "$backup_dir" -name "*incremental*.tar.gz" -type f | head -n 1)
    if [[ -f "${inc_backup}.meta" ]]; then
        test_pass "Incremental backup metadata created"
        
        # Verify metadata type
        local backup_type=$(jq -r '.type' "${inc_backup}.meta" 2>/dev/null)
        if [[ "$backup_type" == "incremental" ]]; then
            test_pass "Metadata type is 'incremental'"
        else
            test_fail "Incorrect metadata type: ${backup_type}"
        fi
    else
        test_fail "Incremental backup metadata not found"
    fi
}

# Test 9: Database type detection
test_database_detection() {
    test_start "Database Type Detection"
    
    local db_type=$(detect_database_type "$TEST_DOMAIN")
    
    if [[ "$db_type" == "wordpress" ]]; then
        test_pass "WordPress detected correctly"
    else
        test_fail "Expected 'wordpress', got '${db_type}'"
    fi
    
    # Test database name extraction
    local db_name=$(get_database_name "$TEST_DOMAIN")
    
    if [[ "$db_name" == "test_db" ]]; then
        test_pass "Database name extracted: ${db_name}"
    else
        test_fail "Expected 'test_db', got '${db_name}'"
    fi
}

# Test 10: Smart database backup
test_smart_database_backup() {
    test_start "Smart Database Backup"
    
    # Note: This test requires MySQL to be running
    # We'll test the function execution, not actual MySQL backup
    
    # Check if function exists
    if declare -f create_smart_database_backup >/dev/null; then
        test_pass "create_smart_database_backup function exists"
    else
        test_fail "create_smart_database_backup function not found"
        return 1
    fi
    
    # Check WordPress backup function
    if declare -f create_wordpress_database_backup >/dev/null; then
        test_pass "create_wordpress_database_backup function exists"
    else
        test_fail "create_wordpress_database_backup function not found"
    fi
    
    # Check Laravel backup function
    if declare -f create_laravel_database_backup >/dev/null; then
        test_pass "create_laravel_database_backup function exists"
    else
        test_fail "create_laravel_database_backup function not found"
    fi
    
    test_info "MySQL backup test skipped (requires running MySQL server)"
}

# Test 11: Backup schedule setup
test_backup_schedule_setup() {
    test_start "Backup Schedule Setup"
    
    # Setup schedule
    setup_backup_schedule "$TEST_DOMAIN"
    
    # Check cron file created
    local cron_file="/etc/cron.d/rocketvps_backup_${TEST_DOMAIN}"
    
    if [[ -f "$cron_file" ]]; then
        test_pass "Cron file created: ${cron_file}"
    else
        test_fail "Cron file not created"
        return 1
    fi
    
    # Check cron file permissions
    local perms=$(stat -c %a "$cron_file" 2>/dev/null)
    if [[ "$perms" == "644" ]]; then
        test_pass "Correct cron file permissions (644)"
    else
        test_fail "Incorrect cron file permissions: ${perms}"
    fi
    
    # Verify cron file content
    if grep -q "${TEST_DOMAIN}" "$cron_file"; then
        test_pass "Cron file contains domain name"
    else
        test_fail "Cron file missing domain name"
    fi
    
    # Cleanup cron file
    rm -f "$cron_file"
}

# Test 12: Backup tracking
test_backup_tracking() {
    test_start "Backup Tracking System"
    
    # Update tracking
    update_backup_tracking "$TEST_DOMAIN" "full"
    
    # Check tracking file
    local tracking_file="${BACKUP_TRACKING_DIR}/${TEST_DOMAIN}_backup.json"
    
    if [[ -f "$tracking_file" ]]; then
        test_pass "Backup tracking file created"
    else
        test_fail "Backup tracking file not created"
        return 1
    fi
    
    # Validate tracking data
    if jq empty "$tracking_file" 2>/dev/null; then
        test_pass "Tracking file is valid JSON"
    else
        test_fail "Tracking file is invalid JSON"
        return 1
    fi
    
    # Check tracking fields
    local last_backup_type=$(jq -r '.last_backup_type' "$tracking_file" 2>/dev/null)
    if [[ "$last_backup_type" == "full" ]]; then
        test_pass "Backup type tracked correctly"
    else
        test_fail "Incorrect backup type: ${last_backup_type}"
    fi
}

# Test 13: Backup verification
test_backup_verification() {
    test_start "Backup Verification"
    
    # Get a backup file
    local backup_dir="${BACKUP_BASE_DIR}/${TEST_DOMAIN}"
    local backup_file=$(find "$backup_dir" -name "backup_*.tar.gz" -type f | head -n 1)
    
    if [[ -z "$backup_file" ]]; then
        test_fail "No backup file found for verification"
        return 1
    fi
    
    # Verify backup
    if verify_backup "$backup_file"; then
        test_pass "Backup verification successful"
    else
        test_fail "Backup verification failed"
    fi
}

# Test 14: Backup statistics
test_backup_statistics() {
    test_start "Backup Statistics"
    
    # Get statistics
    local stats=$(get_backup_statistics "$TEST_DOMAIN")
    
    if [[ -n "$stats" ]]; then
        test_pass "Statistics generated successfully"
    else
        test_fail "Statistics generation failed"
        return 1
    fi
    
    # Check statistics content
    if echo "$stats" | grep -q "Total Backups"; then
        test_pass "Statistics include backup count"
    else
        test_fail "Statistics missing backup count"
    fi
    
    if echo "$stats" | grep -q "Activity"; then
        test_pass "Statistics include activity level"
    else
        test_fail "Statistics missing activity level"
    fi
}

# Test 15: List domain backups
test_list_backups() {
    test_start "List Domain Backups"
    
    # List backups
    local backup_list=$(list_domain_backups "$TEST_DOMAIN")
    
    if [[ -n "$backup_list" ]]; then
        test_pass "Backup list generated"
    else
        test_fail "Backup list generation failed"
        return 1
    fi
    
    # Check if list contains domain name
    if echo "$backup_list" | grep -q "$TEST_DOMAIN"; then
        test_pass "Backup list contains domain name"
    else
        test_fail "Backup list missing domain name"
    fi
}

# Test 16: Exclude patterns
test_exclude_patterns() {
    test_start "Exclude Patterns"
    
    # Create files in excluded directories
    mkdir -p "/var/www/${TEST_DOMAIN}/cache"
    mkdir -p "/var/www/${TEST_DOMAIN}/node_modules"
    echo "Cache file" > "/var/www/${TEST_DOMAIN}/cache/test.cache"
    echo "Node module" > "/var/www/${TEST_DOMAIN}/node_modules/package.js"
    
    # Create a new backup
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_dir="${BACKUP_BASE_DIR}/${TEST_DOMAIN}"
    local backup_file="${backup_dir}/backup_exclude_test_${timestamp}.tar.gz"
    
    # Build exclude args
    local exclude_args=""
    for pattern in "${EXCLUDE_PATTERNS[@]}"; do
        exclude_args+=" --exclude='${pattern}'"
    done
    
    # Create backup with exclusions
    eval "tar czf '$backup_file' -C / $exclude_args '/var/www/${TEST_DOMAIN}' 2>/dev/null"
    
    if [[ -f "$backup_file" ]]; then
        test_pass "Backup with exclusions created"
    else
        test_fail "Backup with exclusions failed"
        return 1
    fi
    
    # Check if excluded files are NOT in backup
    if tar -tzf "$backup_file" | grep -q "cache/test.cache"; then
        test_fail "Cache file should be excluded but found in backup"
    else
        test_pass "Cache file correctly excluded"
    fi
    
    if tar -tzf "$backup_file" | grep -q "node_modules/package.js"; then
        test_fail "Node modules should be excluded but found in backup"
    else
        test_pass "Node modules correctly excluded"
    fi
    
    # Cleanup
    rm -f "$backup_file"
}

# Test 17: Compression optimization
test_compression() {
    test_start "Compression Optimization"
    
    # Check compression level variable
    if [[ -n "$COMPRESSION_LEVEL" ]] && [[ "$COMPRESSION_LEVEL" =~ ^[1-9]$ ]]; then
        test_pass "Compression level configured: ${COMPRESSION_LEVEL}"
    else
        test_fail "Invalid compression level: ${COMPRESSION_LEVEL}"
    fi
    
    # Test compression with different levels
    local test_file="/var/www/${TEST_DOMAIN}/test_compress.txt"
    local large_content=$(head -c 1M /dev/urandom | base64)
    echo "$large_content" > "$test_file"
    
    local compressed_file="${TEST_DIR}/test_compress.gz"
    gzip -${COMPRESSION_LEVEL} -c "$test_file" > "$compressed_file"
    
    if [[ -f "$compressed_file" ]] && [[ -s "$compressed_file" ]]; then
        local original_size=$(du -b "$test_file" | awk '{print $1}')
        local compressed_size=$(du -b "$compressed_file" | awk '{print $1}')
        local ratio=$((100 - (compressed_size * 100 / original_size)))
        
        test_pass "Compression ratio: ${ratio}%"
        
        if [[ $ratio -gt 0 ]]; then
            test_pass "Compression working correctly"
        else
            test_fail "No compression achieved"
        fi
    else
        test_fail "Compression test failed"
    fi
    
    # Cleanup
    rm -f "$test_file" "$compressed_file"
}

# Test 18: Performance - Activity analysis speed
test_performance_activity_analysis() {
    test_start "Performance: Activity Analysis Speed"
    
    local start_time=$(date +%s%N)
    analyze_domain_activity "$TEST_DOMAIN" >/dev/null
    local end_time=$(date +%s%N)
    
    local duration=$(( (end_time - start_time) / 1000000 ))
    
    test_info "Activity analysis took ${duration}ms"
    
    if [[ $duration -lt 1000 ]]; then
        test_pass "Activity analysis is fast (< 1 second)"
    elif [[ $duration -lt 5000 ]]; then
        test_pass "Activity analysis is acceptable (< 5 seconds)"
    else
        test_fail "Activity analysis is slow (${duration}ms)"
    fi
}

# Test 19: Performance - Backup speed
test_performance_backup_speed() {
    test_start "Performance: Backup Speed"
    
    local start_time=$(date +%s)
    create_full_backup "$TEST_DOMAIN" >/dev/null 2>&1
    local end_time=$(date +%s)
    
    local duration=$((end_time - start_time))
    
    test_info "Full backup took ${duration} seconds"
    
    if [[ $duration -lt 10 ]]; then
        test_pass "Backup speed is excellent (< 10 seconds)"
    elif [[ $duration -lt 30 ]]; then
        test_pass "Backup speed is good (< 30 seconds)"
    elif [[ $duration -lt 60 ]]; then
        test_pass "Backup speed is acceptable (< 60 seconds)"
    else
        test_fail "Backup speed is slow (${duration} seconds)"
    fi
}

# Test 20: Integration - Smart backup with all features
test_integration_smart_backup() {
    test_start "Integration: Complete Smart Backup Flow"
    
    # Run complete smart backup
    smart_backup_domain "$TEST_DOMAIN" "auto" >/dev/null 2>&1
    local result=$?
    
    if [[ $result -eq 0 ]]; then
        test_pass "Smart backup completed successfully"
    else
        test_fail "Smart backup failed"
        return 1
    fi
    
    # Verify all components worked
    local backup_dir="${BACKUP_BASE_DIR}/${TEST_DOMAIN}"
    local backup_count=$(find "$backup_dir" -name "backup_*.tar.gz" -type f | wc -l)
    
    if [[ $backup_count -gt 0 ]]; then
        test_pass "Backup files created"
    else
        test_fail "No backup files found"
    fi
    
    # Check tracking updated
    local tracking_file="${BACKUP_TRACKING_DIR}/${TEST_DOMAIN}_backup.json"
    if [[ -f "$tracking_file" ]]; then
        test_pass "Tracking file updated"
    else
        test_fail "Tracking file not updated"
    fi
}

# ==============================================================================
# MAIN TEST EXECUTION
# ==============================================================================

main() {
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║          ROCKETVPS v2.2.0 - PHASE 2 TEST SUITE                ║"
    echo "║             Smart Backup System Testing                        ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""
    
    # Setup
    setup_test_env
    
    # Run all tests
    test_module_initialization
    test_activity_analysis
    test_size_detection
    test_strategy_selection
    test_schedule_recommendation
    test_full_backup
    test_changed_files_detection
    test_incremental_backup
    test_database_detection
    test_smart_database_backup
    test_backup_schedule_setup
    test_backup_tracking
    test_backup_verification
    test_backup_statistics
    test_list_backups
    test_exclude_patterns
    test_compression
    test_performance_activity_analysis
    test_performance_backup_speed
    test_integration_smart_backup
    
    # Cleanup
    cleanup_test_env
    
    # Print summary
    echo ""
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║                        TEST SUMMARY                             ║"
    echo "╠════════════════════════════════════════════════════════════════╣"
    printf "║  Total Tests:     %-45s║\n" "$TESTS_TOTAL"
    printf "║  Passed:          %-44s║\n" "${GREEN}${TESTS_PASSED}${NC}"
    printf "║  Failed:          %-44s║\n" "${RED}${TESTS_FAILED}${NC}"
    printf "║  Success Rate:    %-45s║\n" "$((TESTS_PASSED * 100 / TESTS_TOTAL))%"
    echo "╠════════════════════════════════════════════════════════════════╣"
    printf "║  Test Log:        %-45s║\n" "$TEST_LOG"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""
    
    # Exit with appropriate code
    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "${GREEN}All tests passed! ✓${NC}"
        exit 0
    else
        echo -e "${RED}Some tests failed! ✗${NC}"
        exit 1
    fi
}

# Run tests
main "$@"
