#!/bin/bash

################################################################################
# RocketVPS v2.2.0 - Phase 1B Integration Test Suite
# 
# Tests Credentials Vault + Smart Restore + Integration
################################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Source modules
source "$PROJECT_ROOT/modules/utils.sh"
source "$PROJECT_ROOT/modules/vault.sh"
source "$PROJECT_ROOT/modules/restore.sh"
source "$PROJECT_ROOT/modules/integration.sh"

# Test configuration
TEST_DOMAIN="test-phase1b.local"
TEST_MASTER_PASS="TestMaster@Pass2024"
TEST_RESULTS_DIR="/tmp/rocketvps_test_results"
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Create results directory
mkdir -p "$TEST_RESULTS_DIR"
TEST_LOG="$TEST_RESULTS_DIR/phase1b_test_$(date +%Y%m%d_%H%M%S).log"

################################################################################
# TEST UTILITIES
################################################################################

test_start() {
    local test_name="$1"
    ((TOTAL_TESTS++))
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}TEST $TOTAL_TESTS: $test_name${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Starting test: $test_name" >> "$TEST_LOG"
}

test_pass() {
    ((PASSED_TESTS++))
    echo -e "${GREEN}✓ PASSED${NC}"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Test PASSED" >> "$TEST_LOG"
}

test_fail() {
    local reason="$1"
    ((FAILED_TESTS++))
    echo -e "${RED}✗ FAILED: $reason${NC}"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Test FAILED: $reason" >> "$TEST_LOG"
}

test_cleanup() {
    # Cleanup vault
    if [[ -d "/opt/rocketvps/vault" ]]; then
        rm -rf /opt/rocketvps/vault
    fi
    
    # Cleanup test snapshots
    if [[ -d "/opt/rocketvps/snapshots/$TEST_DOMAIN" ]]; then
        rm -rf "/opt/rocketvps/snapshots/$TEST_DOMAIN"
    fi
    
    # Cleanup restore logs
    if [[ -d "/opt/rocketvps/restore_logs/$TEST_DOMAIN" ]]; then
        rm -rf "/opt/rocketvps/restore_logs/$TEST_DOMAIN"
    fi
}

################################################################################
# CREDENTIALS VAULT TESTS
################################################################################

test_vault_initialization() {
    test_start "Vault Initialization"
    
    # Initialize vault with test master password
    echo "$TEST_MASTER_PASS" | vault_init >/dev/null 2>&1
    
    if vault_is_initialized; then
        test_pass
    else
        test_fail "Vault initialization failed"
    fi
}

test_vault_unlock() {
    test_start "Vault Unlock/Lock"
    
    # Test unlock
    echo "$TEST_MASTER_PASS" | vault_unlock >/dev/null 2>&1
    
    if ! vault_is_locked; then
        # Test lock
        vault_lock >/dev/null 2>&1
        
        if vault_is_locked; then
            test_pass
        else
            test_fail "Vault lock failed"
        fi
    else
        test_fail "Vault unlock failed"
    fi
}

test_vault_add_credentials() {
    test_start "Add Credentials to Vault"
    
    # Unlock vault
    echo "$TEST_MASTER_PASS" | vault_unlock >/dev/null 2>&1
    
    # Prepare test credentials
    local credentials=$(cat <<EOF
{
  "domain_info": {
    "domain": "$TEST_DOMAIN",
    "document_root": "/var/www/$TEST_DOMAIN"
  },
  "admin": {
    "username": "testadmin",
    "password": "Test@Pass123",
    "email": "admin@$TEST_DOMAIN"
  },
  "database": {
    "type": "mysql",
    "database": "testdb",
    "username": "testuser",
    "password": "DbPass@123"
  }
}
EOF
)
    
    # Add credentials
    if vault_add_credentials "$TEST_DOMAIN" "test_profile" "$credentials" >/dev/null 2>&1; then
        test_pass
    else
        test_fail "Failed to add credentials"
    fi
}

test_vault_get_credentials() {
    test_start "Get Credentials from Vault"
    
    # Get credentials
    local retrieved=$(vault_get_credentials "$TEST_DOMAIN" 2>/dev/null)
    
    if [[ -n "$retrieved" ]]; then
        # Verify it's valid JSON
        if echo "$retrieved" | jq . >/dev/null 2>&1; then
            test_pass
        else
            test_fail "Retrieved data is not valid JSON"
        fi
    else
        test_fail "Failed to retrieve credentials"
    fi
}

test_vault_search() {
    test_start "Search Vault"
    
    # Search by domain
    local results=$(vault_search "$TEST_DOMAIN" 2>/dev/null)
    
    if [[ "$results" == *"$TEST_DOMAIN"* ]]; then
        test_pass
    else
        test_fail "Search did not find test domain"
    fi
}

test_vault_update_credentials() {
    test_start "Update Credentials"
    
    # Update admin password
    if vault_update_credentials "$TEST_DOMAIN" "admin.password" "NewPass@456" >/dev/null 2>&1; then
        # Verify update
        local updated=$(vault_get_credentials "$TEST_DOMAIN" 2>/dev/null)
        if echo "$updated" | jq -r '.admin.password' 2>/dev/null | grep -q "NewPass@456"; then
            test_pass
        else
            test_fail "Password not updated in vault"
        fi
    else
        test_fail "Failed to update credentials"
    fi
}

test_vault_export() {
    test_start "Export Credentials"
    
    local export_file="$TEST_RESULTS_DIR/test_export.json"
    
    # Export to JSON
    if vault_export "$TEST_DOMAIN" "json" "$export_file" >/dev/null 2>&1; then
        if [[ -f "$export_file" ]] && jq . "$export_file" >/dev/null 2>&1; then
            test_pass
        else
            test_fail "Export file invalid or missing"
        fi
    else
        test_fail "Failed to export credentials"
    fi
}

test_vault_password_rotation() {
    test_start "Password Rotation"
    
    # Get current password
    local old_pass=$(vault_get_credentials "$TEST_DOMAIN" 2>/dev/null | jq -r '.admin.password' 2>/dev/null)
    
    # Rotate password
    if vault_rotate_passwords "$TEST_DOMAIN" >/dev/null 2>&1; then
        # Get new password
        local new_pass=$(vault_get_credentials "$TEST_DOMAIN" 2>/dev/null | jq -r '.admin.password' 2>/dev/null)
        
        if [[ "$new_pass" != "$old_pass" ]] && [[ ${#new_pass} -ge 20 ]]; then
            test_pass
        else
            test_fail "Password not rotated properly"
        fi
    else
        test_fail "Failed to rotate password"
    fi
}

test_vault_access_log() {
    test_start "Access Logging"
    
    local log_file="/opt/rocketvps/vault/access.log"
    
    if [[ -f "$log_file" ]]; then
        # Check if log contains test domain
        if grep -q "$TEST_DOMAIN" "$log_file"; then
            test_pass
        else
            test_fail "Access log missing entries"
        fi
    else
        test_fail "Access log file not found"
    fi
}

test_vault_session_timeout() {
    test_start "Session Timeout"
    
    # Unlock vault
    echo "$TEST_MASTER_PASS" | vault_unlock >/dev/null 2>&1
    
    # Check if session file exists
    local session_file="/opt/rocketvps/config/vault/session.lock"
    
    if [[ -f "$session_file" ]]; then
        # Modify session timestamp to simulate timeout
        local timeout_time=$(($(date +%s) - 1000)) # 16+ minutes ago
        echo "$timeout_time" > "$session_file"
        
        # Check if vault is locked due to timeout
        if vault_is_locked; then
            test_pass
        else
            test_fail "Session timeout not working"
        fi
    else
        test_fail "Session file not created"
    fi
}

################################################################################
# SMART RESTORE TESTS
################################################################################

test_restore_create_snapshot() {
    test_start "Create Safety Snapshot"
    
    # Create test domain directory
    mkdir -p "/var/www/$TEST_DOMAIN"
    echo "test file" > "/var/www/$TEST_DOMAIN/test.html"
    
    # Create snapshot
    local snapshot_path=$(restore_create_snapshot "$TEST_DOMAIN" 2>/dev/null)
    
    if [[ -n "$snapshot_path" ]] && [[ -d "$snapshot_path" ]]; then
        if [[ -f "$snapshot_path/files.tar.gz" ]]; then
            test_pass
        else
            test_fail "Snapshot files missing"
        fi
    else
        test_fail "Failed to create snapshot"
    fi
    
    # Cleanup
    rm -rf "/var/www/$TEST_DOMAIN"
}

test_restore_list_backups() {
    test_start "List Backups"
    
    # Create test backup
    local backup_dir="/opt/rocketvps/backups/$TEST_DOMAIN"
    mkdir -p "$backup_dir"
    
    # Create fake backup file
    touch "$backup_dir/backup_20240101_120000.tar.gz"
    
    # List backups
    local backups=$(restore_list_backups "$TEST_DOMAIN" 2>/dev/null)
    
    if [[ "$backups" == *"backup_20240101_120000.tar.gz"* ]]; then
        test_pass
    else
        test_fail "Failed to list backups"
    fi
    
    # Cleanup
    rm -rf "$backup_dir"
}

test_restore_get_backup_info() {
    test_start "Get Backup Information"
    
    # Create test backup with metadata
    local backup_dir="/opt/rocketvps/backups/$TEST_DOMAIN"
    mkdir -p "$backup_dir"
    local backup_file="$backup_dir/backup_20240101_120000.tar.gz"
    
    # Create metadata
    cat > "$backup_dir/backup_20240101_120000.meta" <<EOF
{
  "domain": "$TEST_DOMAIN",
  "timestamp": "2024-01-01 12:00:00",
  "size": 1048576,
  "files_count": 100
}
EOF
    
    # Create dummy backup
    tar czf "$backup_file" -C /tmp . 2>/dev/null
    
    # Get backup info
    local info=$(restore_get_backup_info "$backup_file" 2>/dev/null)
    
    if [[ -n "$info" ]]; then
        test_pass
    else
        test_fail "Failed to get backup info"
    fi
    
    # Cleanup
    rm -rf "$backup_dir"
}

test_restore_validate_prerequisites() {
    test_start "Validate Prerequisites"
    
    # Create test backup
    local backup_dir="/opt/rocketvps/backups/$TEST_DOMAIN"
    mkdir -p "$backup_dir"
    local backup_file="$backup_dir/backup_20240101_120000.tar.gz"
    
    # Create minimal backup
    tar czf "$backup_file" -C /tmp . 2>/dev/null
    
    # Validate prerequisites
    if restore_validate_prerequisites "$TEST_DOMAIN" "$backup_file" >/dev/null 2>&1; then
        test_pass
    else
        test_fail "Prerequisites validation failed"
    fi
    
    # Cleanup
    rm -rf "$backup_dir"
}

################################################################################
# INTEGRATION TESTS
################################################################################

test_integration_wordpress() {
    test_start "WordPress Integration"
    
    # Unlock vault
    echo "$TEST_MASTER_PASS" | vault_unlock >/dev/null 2>&1
    
    # Simulate WordPress setup
    integration_hook_wordpress_complete \
        "wordpress-test.local" \
        "admin" \
        "WpPass@123" \
        "admin@wordpress-test.local" \
        "wpdb" \
        "wpuser" \
        "DbPass@123"
    
    # Check if credentials saved
    local saved=$(vault_get_credentials "wordpress-test.local" 2>/dev/null)
    
    if [[ -n "$saved" ]]; then
        test_pass
    else
        test_fail "WordPress credentials not saved"
    fi
    
    # Cleanup
    vault_delete_credentials "wordpress-test.local" >/dev/null 2>&1
}

test_integration_laravel() {
    test_start "Laravel Integration"
    
    # Unlock vault
    echo "$TEST_MASTER_PASS" | vault_unlock >/dev/null 2>&1
    
    # Simulate Laravel setup
    integration_hook_laravel_complete \
        "laravel-test.local" \
        "laraveldb" \
        "laraveluser" \
        "LaravelPass@123"
    
    # Check if credentials saved
    local saved=$(vault_get_credentials "laravel-test.local" 2>/dev/null)
    
    if [[ -n "$saved" ]]; then
        test_pass
    else
        test_fail "Laravel credentials not saved"
    fi
    
    # Cleanup
    vault_delete_credentials "laravel-test.local" >/dev/null 2>&1
}

test_integration_nodejs() {
    test_start "Node.js Integration"
    
    # Unlock vault
    echo "$TEST_MASTER_PASS" | vault_unlock >/dev/null 2>&1
    
    # Simulate Node.js setup
    integration_hook_nodejs_complete \
        "nodejs-test.local" \
        "3000"
    
    # Check if configuration saved
    local saved=$(vault_get_credentials "nodejs-test.local" 2>/dev/null)
    
    if [[ -n "$saved" ]]; then
        test_pass
    else
        test_fail "Node.js configuration not saved"
    fi
    
    # Cleanup
    vault_delete_credentials "nodejs-test.local" >/dev/null 2>&1
}

################################################################################
# PERFORMANCE TESTS
################################################################################

test_vault_performance() {
    test_start "Vault Performance"
    
    # Measure unlock time
    local start=$(date +%s%3N)
    echo "$TEST_MASTER_PASS" | vault_unlock >/dev/null 2>&1
    local end=$(date +%s%3N)
    local unlock_time=$((end - start))
    
    # Measure get credentials time
    start=$(date +%s%3N)
    vault_get_credentials "$TEST_DOMAIN" >/dev/null 2>&1
    end=$(date +%s%3N)
    local get_time=$((end - start))
    
    echo "  Unlock time: ${unlock_time}ms"
    echo "  Get credentials time: ${get_time}ms"
    
    # Check if within performance targets
    if [[ $unlock_time -lt 1000 ]] && [[ $get_time -lt 500 ]]; then
        test_pass
    else
        test_fail "Performance below targets (unlock: ${unlock_time}ms, get: ${get_time}ms)"
    fi
}

################################################################################
# SECURITY TESTS
################################################################################

test_vault_brute_force_protection() {
    test_start "Brute Force Protection"
    
    # Lock vault
    vault_lock >/dev/null 2>&1
    
    # Attempt multiple wrong passwords
    for i in {1..6}; do
        echo "WrongPassword$i" | vault_unlock >/dev/null 2>&1
    done
    
    # Check if locked out
    if vault_is_locked_out; then
        test_pass
    else
        test_fail "Brute force protection not triggered"
    fi
    
    # Reset lockout for other tests
    local lockout_file="/opt/rocketvps/config/vault/lockout"
    [[ -f "$lockout_file" ]] && rm "$lockout_file"
}

test_vault_encryption() {
    test_start "Encryption Strength"
    
    # Check if vault database is encrypted
    local vault_db="/opt/rocketvps/vault/credentials.db.enc"
    
    if [[ -f "$vault_db" ]]; then
        # Check if file is not plain text
        if ! strings "$vault_db" | grep -q "$TEST_DOMAIN"; then
            test_pass
        else
            test_fail "Vault database not properly encrypted"
        fi
    else
        test_fail "Vault database not found"
    fi
}

################################################################################
# RUN ALL TESTS
################################################################################

run_all_tests() {
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║          ROCKETVPS v2.2.0 - PHASE 1B TEST SUITE               ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "Test started: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "Test log: $TEST_LOG"
    echo ""
    
    # Cleanup before tests
    test_cleanup
    
    # Vault Tests
    echo -e "${YELLOW}━━━ CREDENTIALS VAULT TESTS ━━━${NC}"
    test_vault_initialization
    test_vault_unlock
    test_vault_add_credentials
    test_vault_get_credentials
    test_vault_search
    test_vault_update_credentials
    test_vault_export
    test_vault_password_rotation
    test_vault_access_log
    test_vault_session_timeout
    
    # Restore Tests
    echo ""
    echo -e "${YELLOW}━━━ SMART RESTORE TESTS ━━━${NC}"
    test_restore_create_snapshot
    test_restore_list_backups
    test_restore_get_backup_info
    test_restore_validate_prerequisites
    
    # Integration Tests
    echo ""
    echo -e "${YELLOW}━━━ INTEGRATION TESTS ━━━${NC}"
    test_integration_wordpress
    test_integration_laravel
    test_integration_nodejs
    
    # Performance Tests
    echo ""
    echo -e "${YELLOW}━━━ PERFORMANCE TESTS ━━━${NC}"
    test_vault_performance
    
    # Security Tests
    echo ""
    echo -e "${YELLOW}━━━ SECURITY TESTS ━━━${NC}"
    test_vault_brute_force_protection
    test_vault_encryption
    
    # Cleanup after tests
    test_cleanup
    
    # Show results
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}                      TEST RESULTS                             ${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo "Total Tests:  $TOTAL_TESTS"
    echo -e "${GREEN}Passed:       $PASSED_TESTS${NC}"
    echo -e "${RED}Failed:       $FAILED_TESTS${NC}"
    echo ""
    
    local success_rate=0
    if [[ $TOTAL_TESTS -gt 0 ]]; then
        success_rate=$((PASSED_TESTS * 100 / TOTAL_TESTS))
    fi
    
    echo "Success Rate: ${success_rate}%"
    echo ""
    
    if [[ $FAILED_TESTS -eq 0 ]]; then
        echo -e "${GREEN}✓ ALL TESTS PASSED${NC}"
        echo ""
        return 0
    else
        echo -e "${RED}✗ SOME TESTS FAILED${NC}"
        echo ""
        echo "Check test log for details: $TEST_LOG"
        echo ""
        return 1
    fi
}

# Run tests
run_all_tests
