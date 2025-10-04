#!/bin/bash

################################################################################
# RocketVPS v2.2.0 - Credentials Vault Module
# 
# Secure credential management system with AES-256 encryption
# 
# Features:
# - Master password protection
# - AES-256-CBC encryption
# - Auto-save from profiles
# - Search and filter
# - Export credentials
# - Password rotation
# - Access audit logging
# - Session management
# - Brute-force protection
################################################################################

# Vault configuration
VAULT_DIR="/opt/rocketvps/vault"
VAULT_CONFIG="$VAULT_DIR/config.conf"
VAULT_DB="$VAULT_DIR/credentials.db.enc"
VAULT_KEY="$VAULT_DIR/master.key.enc"
VAULT_LOG="$VAULT_DIR/access.log"
SESSION_LOCK="/opt/rocketvps/config/vault/session.lock"
SESSION_TIMEOUT=900  # 15 minutes

# Security settings
MAX_ATTEMPTS=5
LOCKOUT_DURATION=900  # 15 minutes
LOCKOUT_FILE="$VAULT_DIR/lockout.lock"
PBKDF2_ITERATIONS=100000

################################################################################
# INITIALIZATION FUNCTIONS
################################################################################

# Initialize vault directory structure
vault_init_dirs() {
    mkdir -p "$VAULT_DIR" 2>/dev/null
    mkdir -p "$(dirname "$SESSION_LOCK")" 2>/dev/null
    
    # Set strict permissions
    chmod 700 "$VAULT_DIR" 2>/dev/null
    chmod 700 "$(dirname "$SESSION_LOCK")" 2>/dev/null
}

# Check if vault is initialized
vault_is_initialized() {
    [[ -f "$VAULT_KEY" && -f "$VAULT_DB" ]]
}

# Initialize vault for first time
vault_init() {
    vault_init_dirs
    
    if vault_is_initialized; then
        echo -e "${YELLOW}⚠ Vault is already initialized${NC}"
        return 1
    fi
    
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║              INITIALIZE CREDENTIALS VAULT                      ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    echo -e "${YELLOW}Master Password Requirements:${NC}"
    echo "  • Minimum 12 characters"
    echo "  • Must contain uppercase letters (A-Z)"
    echo "  • Must contain lowercase letters (a-z)"
    echo "  • Must contain numbers (0-9)"
    echo "  • Must contain special characters (!@#\$%^&*)"
    echo ""
    
    local password
    local password_confirm
    
    while true; do
        read -sp "🔐 Enter master password: " password
        echo ""
        
        # Validate password
        if ! vault_validate_password "$password"; then
            echo -e "${RED}✗ Password does not meet requirements${NC}"
            continue
        fi
        
        read -sp "🔐 Confirm master password: " password_confirm
        echo ""
        
        if [[ "$password" != "$password_confirm" ]]; then
            echo -e "${RED}✗ Passwords do not match${NC}"
            continue
        fi
        
        break
    done
    
    echo ""
    echo -e "${CYAN}⏳ Initializing vault...${NC}"
    
    # Generate salt
    local salt=$(openssl rand -hex 32)
    
    # Create encryption key from password
    local key=$(echo -n "$password" | openssl enc -base64 -A)
    
    # Store encrypted master key
    echo -n "$key|$salt" | openssl enc -aes-256-cbc -pbkdf2 -iter $PBKDF2_ITERATIONS \
        -pass pass:"$password" -out "$VAULT_KEY" 2>/dev/null
    
    # Create initial empty database
    local init_db='{
  "version": "1.0",
  "created": "'$(date -u +"%Y-%m-%dT%H:%M:%SZ")'",
  "last_modified": "'$(date -u +"%Y-%m-%dT%H:%M:%SZ")'",
  "domains": {}
}'
    
    echo -n "$init_db" | openssl enc -aes-256-cbc -pbkdf2 -iter $PBKDF2_ITERATIONS \
        -pass pass:"$key" -out "$VAULT_DB" 2>/dev/null
    
    # Set permissions
    chmod 600 "$VAULT_KEY" "$VAULT_DB"
    
    # Create config
    cat > "$VAULT_CONFIG" <<EOF
# Vault Configuration
VAULT_VERSION=1.0
SESSION_TIMEOUT=$SESSION_TIMEOUT
MAX_ATTEMPTS=$MAX_ATTEMPTS
LOCKOUT_DURATION=$LOCKOUT_DURATION
CREATED=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
EOF
    chmod 600 "$VAULT_CONFIG"
    
    # Initialize access log
    touch "$VAULT_LOG"
    chmod 640 "$VAULT_LOG"
    
    vault_log "init" "success" "Vault initialized"
    
    echo -e "${GREEN}✅ Vault initialized successfully!${NC}"
    echo ""
    echo -e "${CYAN}📊 Vault Information:${NC}"
    echo "   Location: $VAULT_DIR"
    echo "   Encryption: AES-256-CBC"
    echo "   Session timeout: 15 minutes"
    echo "   Max attempts: $MAX_ATTEMPTS"
    echo ""
    
    return 0
}

# Validate master password strength
vault_validate_password() {
    local password="$1"
    
    # Check length
    if [[ ${#password} -lt 12 ]]; then
        return 1
    fi
    
    # Check for uppercase
    if ! [[ "$password" =~ [A-Z] ]]; then
        return 1
    fi
    
    # Check for lowercase
    if ! [[ "$password" =~ [a-z] ]]; then
        return 1
    fi
    
    # Check for numbers
    if ! [[ "$password" =~ [0-9] ]]; then
        return 1
    fi
    
    # Check for special characters
    if ! [[ "$password" =~ [[:punct:]] ]]; then
        return 1
    fi
    
    return 0
}

################################################################################
# SESSION MANAGEMENT
################################################################################

# Check if vault is locked
vault_is_locked() {
    if [[ ! -f "$SESSION_LOCK" ]]; then
        return 0  # Locked
    fi
    
    # Check session timeout
    local lock_time=$(stat -c %Y "$SESSION_LOCK" 2>/dev/null || echo 0)
    local current_time=$(date +%s)
    local elapsed=$((current_time - lock_time))
    
    if [[ $elapsed -gt $SESSION_TIMEOUT ]]; then
        vault_lock
        return 0  # Locked (timeout)
    fi
    
    return 1  # Unlocked
}

# Check if vault is in lockout
vault_is_locked_out() {
    if [[ ! -f "$LOCKOUT_FILE" ]]; then
        return 1  # Not locked out
    fi
    
    local lockout_time=$(cat "$LOCKOUT_FILE" 2>/dev/null || echo 0)
    local current_time=$(date +%s)
    local elapsed=$((current_time - lockout_time))
    
    if [[ $elapsed -lt $LOCKOUT_DURATION ]]; then
        local remaining=$((LOCKOUT_DURATION - elapsed))
        echo -e "${RED}🔒 Vault is locked due to too many failed attempts${NC}"
        echo -e "${YELLOW}   Please wait $(($remaining / 60)) minutes and $(($remaining % 60)) seconds${NC}"
        return 0  # Locked out
    else
        rm -f "$LOCKOUT_FILE"
        return 1  # Not locked out
    fi
}

# Record failed attempt
vault_record_failed_attempt() {
    local attempts_file="$VAULT_DIR/failed_attempts"
    local current_attempts=0
    
    if [[ -f "$attempts_file" ]]; then
        current_attempts=$(cat "$attempts_file")
    fi
    
    current_attempts=$((current_attempts + 1))
    echo "$current_attempts" > "$attempts_file"
    
    if [[ $current_attempts -ge $MAX_ATTEMPTS ]]; then
        echo "$(date +%s)" > "$LOCKOUT_FILE"
        rm -f "$attempts_file"
        vault_log "lockout" "triggered" "Too many failed attempts"
        return 1
    fi
    
    return 0
}

# Clear failed attempts
vault_clear_failed_attempts() {
    rm -f "$VAULT_DIR/failed_attempts"
}

# Unlock vault
vault_unlock() {
    vault_init_dirs
    
    if ! vault_is_initialized; then
        echo -e "${RED}✗ Vault is not initialized. Run vault initialization first.${NC}"
        return 1
    fi
    
    if ! vault_is_locked; then
        echo -e "${GREEN}✓ Vault is already unlocked${NC}"
        return 0
    fi
    
    if vault_is_locked_out; then
        return 1
    fi
    
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║              UNLOCK CREDENTIALS VAULT                          ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    local password
    read -sp "🔐 Enter master password: " password
    echo ""
    
    echo -e "${CYAN}⏳ Verifying password...${NC}"
    
    # Try to decrypt master key
    local key=$(openssl enc -d -aes-256-cbc -pbkdf2 -iter $PBKDF2_ITERATIONS \
        -pass pass:"$password" -in "$VAULT_KEY" 2>/dev/null)
    
    if [[ -z "$key" ]]; then
        echo -e "${RED}✗ Invalid master password${NC}"
        vault_log "unlock" "failed" "Invalid password"
        vault_record_failed_attempt
        return 1
    fi
    
    # Extract encryption key
    VAULT_MASTER_KEY="${key%%|*}"
    
    echo -e "${CYAN}⏳ Decrypting credentials database...${NC}"
    
    # Try to decrypt database
    VAULT_DATA=$(openssl enc -d -aes-256-cbc -pbkdf2 -iter $PBKDF2_ITERATIONS \
        -pass pass:"$VAULT_MASTER_KEY" -in "$VAULT_DB" 2>/dev/null)
    
    if [[ -z "$VAULT_DATA" ]]; then
        echo -e "${RED}✗ Failed to decrypt database${NC}"
        vault_log "unlock" "failed" "Decryption failed"
        return 1
    fi
    
    echo -e "${CYAN}⏳ Loading credentials...${NC}"
    
    # Create session lock
    echo "$$|$(date +%s)|$(whoami)" > "$SESSION_LOCK"
    chmod 600 "$SESSION_LOCK"
    
    # Clear failed attempts
    vault_clear_failed_attempts
    
    vault_log "unlock" "success" "Vault unlocked"
    
    # Count domains
    local total_domains=$(echo "$VAULT_DATA" | jq -r '.domains | length' 2>/dev/null || echo 0)
    local active_domains=$(echo "$VAULT_DATA" | jq -r '[.domains[] | select(.status == "active")] | length' 2>/dev/null || echo 0)
    local disabled_domains=$((total_domains - active_domains))
    
    echo ""
    echo -e "${GREEN}✅ Vault unlocked successfully!${NC}"
    echo ""
    echo -e "${CYAN}📊 Summary:${NC}"
    echo "   - Total Domains: $total_domains"
    echo "   - Active Domains: $active_domains"
    echo "   - Disabled Domains: $disabled_domains"
    echo "   - Last Modified: $(echo "$VAULT_DATA" | jq -r '.last_modified' 2>/dev/null)"
    echo ""
    echo -e "${YELLOW}⏰ Session will auto-lock in 15 minutes of inactivity${NC}"
    echo ""
    
    return 0
}

# Lock vault
vault_lock() {
    if [[ -f "$SESSION_LOCK" ]]; then
        rm -f "$SESSION_LOCK"
        unset VAULT_MASTER_KEY
        unset VAULT_DATA
        vault_log "lock" "success" "Vault locked"
        echo -e "${GREEN}✓ Vault locked${NC}"
    fi
}

# Verify vault is unlocked
vault_require_unlock() {
    if vault_is_locked; then
        echo -e "${RED}✗ Vault is locked. Please unlock it first.${NC}"
        return 1
    fi
    
    # Touch session lock to update timestamp
    touch "$SESSION_LOCK"
    
    return 0
}

################################################################################
# CREDENTIAL OPERATIONS
################################################################################

# Add credentials to vault
vault_add_credentials() {
    local domain="$1"
    local profile="$2"
    local credentials_json="$3"
    
    if ! vault_require_unlock; then
        return 1
    fi
    
    # Parse current database
    local updated_data=$(echo "$VAULT_DATA" | jq \
        --arg domain "$domain" \
        --arg profile "$profile" \
        --argjson creds "$credentials_json" \
        --arg created "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
        --arg modified "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
        '.domains[$domain] = ($creds + {
            "profile": $profile,
            "created_date": $created,
            "status": "active"
        }) | .last_modified = $modified' 2>/dev/null)
    
    if [[ -z "$updated_data" ]]; then
        echo -e "${RED}✗ Failed to add credentials${NC}"
        return 1
    fi
    
    # Encrypt and save
    echo -n "$updated_data" | openssl enc -aes-256-cbc -pbkdf2 -iter $PBKDF2_ITERATIONS \
        -pass pass:"$VAULT_MASTER_KEY" -out "$VAULT_DB" 2>/dev/null
    
    # Update in-memory data
    VAULT_DATA="$updated_data"
    
    vault_log "add" "success" "domain=$domain,profile=$profile"
    
    return 0
}

# Get credentials for a domain
vault_get_credentials() {
    local domain="$1"
    
    if ! vault_require_unlock; then
        return 1
    fi
    
    echo "$VAULT_DATA" | jq -r --arg domain "$domain" '.domains[$domain]' 2>/dev/null
    
    vault_log "view" "success" "domain=$domain"
}

# List all domains
vault_list_domains() {
    if ! vault_require_unlock; then
        return 1
    fi
    
    echo "$VAULT_DATA" | jq -r '.domains | keys[]' 2>/dev/null | sort
}

# Search credentials
vault_search() {
    local query="$1"
    
    if ! vault_require_unlock; then
        return 1
    fi
    
    # Search in domain names, profiles, and status
    echo "$VAULT_DATA" | jq -r --arg query "$query" '
        .domains | to_entries[] | 
        select(
            .key | contains($query) or
            .value.profile | contains($query) or
            .value.status | contains($query)
        ) | .key
    ' 2>/dev/null | sort
    
    vault_log "search" "success" "query=$query"
}

# Update credentials
vault_update_credentials() {
    local domain="$1"
    local field_path="$2"
    local new_value="$3"
    
    if ! vault_require_unlock; then
        return 1
    fi
    
    # Update field using jq
    local updated_data=$(echo "$VAULT_DATA" | jq \
        --arg domain "$domain" \
        --arg path "$field_path" \
        --arg value "$new_value" \
        --arg modified "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
        'setpath(["domains", $domain] + ($path | split(".")); $value) | 
         .last_modified = $modified' 2>/dev/null)
    
    if [[ -z "$updated_data" ]]; then
        echo -e "${RED}✗ Failed to update credentials${NC}"
        return 1
    fi
    
    # Encrypt and save
    echo -n "$updated_data" | openssl enc -aes-256-cbc -pbkdf2 -iter $PBKDF2_ITERATIONS \
        -pass pass:"$VAULT_MASTER_KEY" -out "$VAULT_DB" 2>/dev/null
    
    # Update in-memory data
    VAULT_DATA="$updated_data"
    
    vault_log "update" "success" "domain=$domain,field=$field_path"
    
    return 0
}

# Delete credentials
vault_delete_credentials() {
    local domain="$1"
    
    if ! vault_require_unlock; then
        return 1
    fi
    
    # Remove domain from database
    local updated_data=$(echo "$VAULT_DATA" | jq \
        --arg domain "$domain" \
        --arg modified "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
        'del(.domains[$domain]) | .last_modified = $modified' 2>/dev/null)
    
    if [[ -z "$updated_data" ]]; then
        echo -e "${RED}✗ Failed to delete credentials${NC}"
        return 1
    fi
    
    # Encrypt and save
    echo -n "$updated_data" | openssl enc -aes-256-cbc -pbkdf2 -iter $PBKDF2_ITERATIONS \
        -pass pass:"$VAULT_MASTER_KEY" -out "$VAULT_DB" 2>/dev/null
    
    # Update in-memory data
    VAULT_DATA="$updated_data"
    
    vault_log "delete" "success" "domain=$domain"
    
    return 0
}

################################################################################
# EXPORT FUNCTIONS
################################################################################

# Export credentials
vault_export() {
    local domain="${1:-all}"
    local format="${2:-json}"
    local output_file="${3:-}"
    
    if ! vault_require_unlock; then
        return 1
    fi
    
    local export_data
    
    if [[ "$domain" == "all" ]]; then
        export_data="$VAULT_DATA"
    else
        export_data=$(echo "$VAULT_DATA" | jq \
            --arg domain "$domain" \
            '{domains: {($domain): .domains[$domain]}}' 2>/dev/null)
    fi
    
    if [[ -z "$export_data" ]]; then
        echo -e "${RED}✗ No data to export${NC}"
        return 1
    fi
    
    # Generate output filename if not provided
    if [[ -z "$output_file" ]]; then
        output_file="/root/vault_export_$(date +%Y%m%d_%H%M%S).$format.enc"
    fi
    
    case "$format" in
        json)
            echo -n "$export_data" | openssl enc -aes-256-cbc -pbkdf2 -iter $PBKDF2_ITERATIONS \
                -pass pass:"$VAULT_MASTER_KEY" -out "$output_file" 2>/dev/null
            ;;
        csv)
            # Convert to CSV
            local csv_data=$(echo "$export_data" | jq -r '
                ["Domain", "Profile", "Status", "Admin User", "DB Type", "DB Name"],
                (.domains | to_entries[] | [
                    .key,
                    .value.profile,
                    .value.status,
                    .value.admin.username // "",
                    .value.database.type // "",
                    .value.database.database // ""
                ]) | @csv
            ' 2>/dev/null)
            
            echo -n "$csv_data" | openssl enc -aes-256-cbc -pbkdf2 -iter $PBKDF2_ITERATIONS \
                -pass pass:"$VAULT_MASTER_KEY" -out "$output_file" 2>/dev/null
            ;;
        txt)
            # Plain text (warning: less secure)
            echo -n "$export_data" | jq -r '
                .domains | to_entries[] | 
                "========================================\n" +
                "Domain: " + .key + "\n" +
                "Profile: " + .value.profile + "\n" +
                "Status: " + .value.status + "\n" +
                (if .value.admin then
                    "Admin URL: " + .value.admin.url + "\n" +
                    "Admin User: " + .value.admin.username + "\n" +
                    "Admin Password: " + .value.admin.password + "\n"
                else "" end) +
                (if .value.database then
                    "DB Host: " + .value.database.host + "\n" +
                    "DB Name: " + .value.database.database + "\n" +
                    "DB User: " + .value.database.username + "\n" +
                    "DB Password: " + .value.database.password + "\n"
                else "" end) +
                "========================================\n"
            ' > "$output_file" 2>/dev/null
            ;;
    esac
    
    chmod 600 "$output_file"
    
    vault_log "export" "success" "domain=$domain,format=$format,file=$output_file"
    
    echo -e "${GREEN}✅ Export successful: $output_file${NC}"
    
    return 0
}

################################################################################
# PASSWORD ROTATION
################################################################################

# Generate secure password
vault_generate_password() {
    local length="${1:-20}"
    openssl rand -base64 48 | tr -d "=+/" | cut -c1-$length
}

# Rotate passwords for a domain
vault_rotate_passwords() {
    local domain="$1"
    
    if ! vault_require_unlock; then
        return 1
    fi
    
    echo -e "${CYAN}🔄 Rotating passwords for $domain...${NC}"
    
    # Get current credentials
    local creds=$(vault_get_credentials "$domain")
    
    if [[ -z "$creds" || "$creds" == "null" ]]; then
        echo -e "${RED}✗ Domain not found${NC}"
        return 1
    fi
    
    local profile=$(echo "$creds" | jq -r '.profile')
    
    # Generate new passwords
    local new_admin_pass=$(vault_generate_password 20)
    local new_db_pass=$(vault_generate_password 24)
    local new_ftp_pass=$(vault_generate_password 20)
    
    echo "  • Admin password: ✓"
    echo "  • Database password: ✓"
    echo "  • FTP password: ✓"
    
    # Update in vault
    vault_update_credentials "$domain" "admin.password" "$new_admin_pass"
    vault_update_credentials "$domain" "database.password" "$new_db_pass"
    vault_update_credentials "$domain" "ftp.password" "$new_ftp_pass"
    
    vault_log "rotate" "success" "domain=$domain"
    
    echo -e "${GREEN}✅ Password rotation complete${NC}"
    echo ""
    echo -e "${YELLOW}⚠ Note: You must manually update passwords in the actual services${NC}"
    
    return 0
}

################################################################################
# LOGGING
################################################################################

# Log vault access
vault_log() {
    local action="$1"
    local status="$2"
    local details="${3:-}"
    
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    local user=$(whoami)
    local ip=$(who am i | awk '{print $NF}' | tr -d '()')
    
    echo "$timestamp | USER:$user | ACTION:$action | STATUS:$status | DETAILS:$details | IP:${ip:-localhost}" >> "$VAULT_LOG"
}

# View access log
vault_view_log() {
    local lines="${1:-20}"
    
    if [[ ! -f "$VAULT_LOG" ]]; then
        echo -e "${YELLOW}No access log found${NC}"
        return
    fi
    
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║              VAULT ACCESS LOG (Last $lines entries)              ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    tail -n "$lines" "$VAULT_LOG"
}

# Export log
vault_export_log() {
    local filter="${1:-}"
    local output_file="/root/vault_log_$(date +%Y%m%d_%H%M%S).txt"
    
    if [[ ! -f "$VAULT_LOG" ]]; then
        echo -e "${YELLOW}No access log found${NC}"
        return 1
    fi
    
    if [[ -n "$filter" ]]; then
        grep -i "$filter" "$VAULT_LOG" > "$output_file"
    else
        cp "$VAULT_LOG" "$output_file"
    fi
    
    chmod 600 "$output_file"
    
    echo -e "${GREEN}✅ Log exported: $output_file${NC}"
    
    return 0
}

################################################################################
# CHANGE MASTER PASSWORD
################################################################################

vault_change_master_password() {
    if ! vault_require_unlock; then
        return 1
    fi
    
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║              CHANGE MASTER PASSWORD                            ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    local old_password
    read -sp "🔐 Enter current master password: " old_password
    echo ""
    
    # Verify old password
    local key=$(openssl enc -d -aes-256-cbc -pbkdf2 -iter $PBKDF2_ITERATIONS \
        -pass pass:"$old_password" -in "$VAULT_KEY" 2>/dev/null)
    
    if [[ -z "$key" ]]; then
        echo -e "${RED}✗ Invalid current password${NC}"
        vault_log "change_password" "failed" "Invalid old password"
        return 1
    fi
    
    echo ""
    echo -e "${YELLOW}New Master Password Requirements:${NC}"
    echo "  • Minimum 12 characters"
    echo "  • Must contain uppercase, lowercase, numbers, and special characters"
    echo ""
    
    local new_password
    local new_password_confirm
    
    while true; do
        read -sp "🔐 Enter new master password: " new_password
        echo ""
        
        if ! vault_validate_password "$new_password"; then
            echo -e "${RED}✗ Password does not meet requirements${NC}"
            continue
        fi
        
        read -sp "🔐 Confirm new master password: " new_password_confirm
        echo ""
        
        if [[ "$new_password" != "$new_password_confirm" ]]; then
            echo -e "${RED}✗ Passwords do not match${NC}"
            continue
        fi
        
        break
    done
    
    echo ""
    echo -e "${CYAN}⏳ Re-encrypting vault with new password...${NC}"
    
    # Generate new salt
    local new_salt=$(openssl rand -hex 32)
    
    # Create new encryption key
    local new_key=$(echo -n "$new_password" | openssl enc -base64 -A)
    
    # Re-encrypt master key
    echo -n "$new_key|$new_salt" | openssl enc -aes-256-cbc -pbkdf2 -iter $PBKDF2_ITERATIONS \
        -pass pass:"$new_password" -out "$VAULT_KEY.new" 2>/dev/null
    
    # Re-encrypt database
    echo -n "$VAULT_DATA" | openssl enc -aes-256-cbc -pbkdf2 -iter $PBKDF2_ITERATIONS \
        -pass pass:"$new_key" -out "$VAULT_DB.new" 2>/dev/null
    
    # Replace old files
    mv "$VAULT_KEY.new" "$VAULT_KEY"
    mv "$VAULT_DB.new" "$VAULT_DB"
    
    # Update in-memory key
    VAULT_MASTER_KEY="$new_key"
    
    vault_log "change_password" "success" "Master password changed"
    
    echo -e "${GREEN}✅ Master password changed successfully!${NC}"
    echo ""
    
    return 0
}

################################################################################
# IMPORT FROM EXISTING CONFIGS
################################################################################

# Import credentials from existing domain configs
vault_import_existing() {
    if ! vault_require_unlock; then
        return 1
    fi
    
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║              IMPORT EXISTING CREDENTIALS                       ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    local imported=0
    local failed=0
    
    # Import from WordPress configs
    if [[ -d "/opt/rocketvps/config/wordpress" ]]; then
        for wp_file in /opt/rocketvps/config/wordpress/*.txt; do
            [[ -f "$wp_file" ]] || continue
            
            local domain=$(basename "$wp_file" .txt | sed 's/_/./g')
            
            echo -e "${CYAN}⏳ Importing $domain...${NC}"
            
            # Parse WordPress config
            local wp_url=$(grep "WordPress URL:" "$wp_file" | cut -d' ' -f3)
            local wp_user=$(grep "Username:" "$wp_file" | cut -d' ' -f2)
            local wp_pass=$(grep "Password:" "$wp_file" | cut -d' ' -f2)
            local wp_email=$(grep "Email:" "$wp_file" | cut -d' ' -f2)
            
            # Create credentials JSON
            local creds="{
                \"domain_info\": {
                    \"domain\": \"$domain\"
                },
                \"admin\": {
                    \"url\": \"$wp_url\",
                    \"username\": \"$wp_user\",
                    \"password\": \"$wp_pass\",
                    \"email\": \"$wp_email\"
                }
            }"
            
            if vault_add_credentials "$domain" "wordpress" "$creds"; then
                echo -e "${GREEN}  ✓ Imported successfully${NC}"
                ((imported++))
            else
                echo -e "${RED}  ✗ Import failed${NC}"
                ((failed++))
            fi
        done
    fi
    
    echo ""
    echo -e "${GREEN}✅ Import complete${NC}"
    echo "   - Imported: $imported domains"
    echo "   - Failed: $failed domains"
    
    vault_log "import" "success" "imported=$imported,failed=$failed"
    
    return 0
}

# Export function for sourcing
export -f vault_init vault_unlock vault_lock vault_is_locked
export -f vault_add_credentials vault_get_credentials vault_list_domains
export -f vault_search vault_update_credentials vault_delete_credentials
export -f vault_export vault_rotate_passwords
export -f vault_view_log vault_export_log
export -f vault_change_master_password vault_import_existing
