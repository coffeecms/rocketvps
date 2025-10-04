#!/bin/bash

# ==============================================================================
# RocketVPS v2.2.0 - Smart Backup System (Phase 2)
# ==============================================================================
# File: modules/smart_backup.sh
# Description: Intelligent backup system with incremental backups, activity
#              analysis, smart scheduling, and database optimization
# Version: 2.2.0
# Author: RocketVPS Team
# ==============================================================================

# Source required modules
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/utils.sh" 2>/dev/null || true

# ==============================================================================
# CONFIGURATION
# ==============================================================================

# Backup directories
BACKUP_BASE_DIR="/opt/rocketvps/backups"
BACKUP_METADATA_DIR="${BACKUP_BASE_DIR}/.metadata"
BACKUP_INCREMENTAL_DIR="${BACKUP_BASE_DIR}/.incremental"
BACKUP_TRACKING_DIR="${BACKUP_BASE_DIR}/.tracking"

# Activity thresholds
ACTIVITY_HIGH_THRESHOLD=100      # File changes per day
ACTIVITY_MEDIUM_THRESHOLD=20     # File changes per day
ACTIVITY_LOW_THRESHOLD=5         # File changes per day

# Size thresholds (in MB)
SIZE_SMALL_THRESHOLD=100         # < 100MB = small
SIZE_MEDIUM_THRESHOLD=1000       # < 1GB = medium
SIZE_LARGE_THRESHOLD=10000       # >= 10GB = large

# Backup strategies
STRATEGY_FULL="full"
STRATEGY_INCREMENTAL="incremental"
STRATEGY_DIFFERENTIAL="differential"
STRATEGY_MIXED="mixed"

# Schedule presets
SCHEDULE_HIGH_ACTIVITY="0 */6 * * *"       # Every 6 hours
SCHEDULE_MEDIUM_ACTIVITY="0 3 * * *"       # Daily at 3 AM
SCHEDULE_LOW_ACTIVITY="0 3 * * 0"          # Weekly on Sunday 3 AM
SCHEDULE_SMALL_SITE="0 3 * * *"            # Daily full backup
SCHEDULE_MEDIUM_SITE="0 3 * * *"           # Daily incremental
SCHEDULE_LARGE_SITE="0 3 * * 0"            # Weekly full + daily incremental

# Compression settings
COMPRESSION_LEVEL=6                         # gzip compression level (1-9)
COMPRESSION_THREADS=4                       # Parallel compression threads

# Exclude patterns
EXCLUDE_PATTERNS=(
    "*/cache/*"
    "*/tmp/*"
    "*/temp/*"
    "*/.cache/*"
    "*/logs/*"
    "*.log"
    "*/node_modules/*"
    "*/vendor/*"
    "*/.git/*"
    "*/wp-content/cache/*"
    "*/wp-content/uploads/cache/*"
    "*/storage/framework/cache/*"
    "*/storage/framework/sessions/*"
    "*/storage/framework/views/*"
    "*/storage/logs/*"
)

# WordPress tables to skip
WP_SKIP_TABLES=(
    "wp_commentmeta"
    "wp_comments"
    "wp_links"
    "wp_termmeta"
    "wp_terms"
    "wp_term_relationships"
    "wp_term_taxonomy"
)

WP_TRANSIENT_TABLES=(
    "wp_options WHERE option_name LIKE '_transient_%'"
    "wp_options WHERE option_name LIKE '_site_transient_%'"
)

# Laravel tables to skip
LARAVEL_SKIP_TABLES=(
    "sessions"
    "cache"
    "cache_locks"
    "jobs"
    "failed_jobs"
)

# ==============================================================================
# INITIALIZATION
# ==============================================================================

smart_backup_init() {
    log_info "Initializing Smart Backup System..."
    
    # Create necessary directories
    mkdir -p "${BACKUP_BASE_DIR}"
    mkdir -p "${BACKUP_METADATA_DIR}"
    mkdir -p "${BACKUP_INCREMENTAL_DIR}"
    mkdir -p "${BACKUP_TRACKING_DIR}"
    
    # Set permissions
    chmod 700 "${BACKUP_BASE_DIR}"
    chmod 700 "${BACKUP_METADATA_DIR}"
    chmod 700 "${BACKUP_INCREMENTAL_DIR}"
    chmod 700 "${BACKUP_TRACKING_DIR}"
    
    log_success "Smart Backup System initialized"
}

# ==============================================================================
# ACTIVITY ANALYSIS
# ==============================================================================

# Analyze domain activity level
# Returns: high, medium, low
analyze_domain_activity() {
    local domain="$1"
    local web_root="/var/www/${domain}"
    local tracking_file="${BACKUP_TRACKING_DIR}/${domain}_activity.json"
    
    if [[ ! -d "$web_root" ]]; then
        echo "low"
        return
    fi
    
    # Check if tracking file exists
    if [[ ! -f "$tracking_file" ]]; then
        # First time - analyze last 24 hours
        local changes=$(find "$web_root" -type f -mtime -1 2>/dev/null | wc -l)
    else
        # Get last check time
        local last_check=$(jq -r '.last_check // empty' "$tracking_file" 2>/dev/null)
        if [[ -z "$last_check" ]]; then
            last_check=$(date -d '1 day ago' +%s)
        fi
        
        # Count files modified since last check
        local changes=$(find "$web_root" -type f -newermt "@${last_check}" 2>/dev/null | wc -l)
    fi
    
    # Determine activity level
    if [[ $changes -ge $ACTIVITY_HIGH_THRESHOLD ]]; then
        echo "high"
    elif [[ $changes -ge $ACTIVITY_MEDIUM_THRESHOLD ]]; then
        echo "medium"
    else
        echo "low"
    fi
    
    # Update tracking file
    cat > "$tracking_file" <<EOF
{
    "domain": "${domain}",
    "last_check": $(date +%s),
    "file_changes": ${changes},
    "activity_level": "$(if [[ $changes -ge $ACTIVITY_HIGH_THRESHOLD ]]; then echo "high"; elif [[ $changes -ge $ACTIVITY_MEDIUM_THRESHOLD ]]; then echo "medium"; else echo "low"; fi)"
}
EOF
}

# Analyze traffic from access logs
analyze_domain_traffic() {
    local domain="$1"
    local access_log="/var/log/nginx/${domain}.access.log"
    
    if [[ ! -f "$access_log" ]]; then
        echo "0"
        return
    fi
    
    # Count requests in last 24 hours
    local yesterday=$(date -d '1 day ago' +%d/%b/%Y)
    local today=$(date +%d/%b/%Y)
    
    local requests=$(grep -E "${yesterday}|${today}" "$access_log" 2>/dev/null | wc -l)
    echo "$requests"
}

# Get domain size in MB
get_domain_size() {
    local domain="$1"
    local web_root="/var/www/${domain}"
    
    if [[ ! -d "$web_root" ]]; then
        echo "0"
        return
    fi
    
    # Get size in MB
    local size_mb=$(du -sm "$web_root" 2>/dev/null | awk '{print $1}')
    echo "${size_mb:-0}"
}

# Determine domain size category
get_domain_size_category() {
    local domain="$1"
    local size=$(get_domain_size "$domain")
    
    if [[ $size -lt $SIZE_SMALL_THRESHOLD ]]; then
        echo "small"
    elif [[ $size -lt $SIZE_MEDIUM_THRESHOLD ]]; then
        echo "medium"
    else
        echo "large"
    fi
}

# ==============================================================================
# BACKUP STRATEGY SELECTION
# ==============================================================================

# Select optimal backup strategy
select_backup_strategy() {
    local domain="$1"
    local activity=$(analyze_domain_activity "$domain")
    local size_category=$(get_domain_size_category "$domain")
    local size=$(get_domain_size "$domain")
    
    log_info "Domain: ${domain}"
    log_info "  Activity: ${activity}"
    log_info "  Size: ${size}MB (${size_category})"
    
    # Strategy selection logic
    local strategy=""
    
    if [[ "$size_category" == "small" ]]; then
        # Small sites: Always full backup (fast enough)
        strategy="$STRATEGY_FULL"
        
    elif [[ "$size_category" == "medium" ]]; then
        if [[ "$activity" == "high" ]]; then
            # Medium + High activity: Incremental
            strategy="$STRATEGY_INCREMENTAL"
        else
            # Medium + Low/Medium activity: Full
            strategy="$STRATEGY_FULL"
        fi
        
    else
        # Large sites
        if [[ "$activity" == "high" ]]; then
            # Large + High activity: Mixed (weekly full + daily incremental)
            strategy="$STRATEGY_MIXED"
        elif [[ "$activity" == "medium" ]]; then
            # Large + Medium activity: Incremental
            strategy="$STRATEGY_INCREMENTAL"
        else
            # Large + Low activity: Weekly full only
            strategy="$STRATEGY_FULL"
        fi
    fi
    
    echo "$strategy"
}

# Get recommended schedule for domain
get_recommended_schedule() {
    local domain="$1"
    local activity=$(analyze_domain_activity "$domain")
    local size_category=$(get_domain_size_category "$domain")
    
    local schedule=""
    
    if [[ "$size_category" == "small" ]]; then
        schedule="$SCHEDULE_SMALL_SITE"
        
    elif [[ "$size_category" == "medium" ]]; then
        if [[ "$activity" == "high" ]]; then
            schedule="$SCHEDULE_HIGH_ACTIVITY"
        else
            schedule="$SCHEDULE_MEDIUM_ACTIVITY"
        fi
        
    else
        # Large sites
        if [[ "$activity" == "high" ]]; then
            schedule="$SCHEDULE_HIGH_ACTIVITY"
        elif [[ "$activity" == "medium" ]]; then
            schedule="$SCHEDULE_MEDIUM_ACTIVITY"
        else
            schedule="$SCHEDULE_LOW_ACTIVITY"
        fi
    fi
    
    echo "$schedule"
}

# ==============================================================================
# INCREMENTAL BACKUP SYSTEM
# ==============================================================================

# Get last full backup path
get_last_full_backup() {
    local domain="$1"
    local domain_backup_dir="${BACKUP_BASE_DIR}/${domain}"
    
    if [[ ! -d "$domain_backup_dir" ]]; then
        echo ""
        return
    fi
    
    # Find latest full backup
    local last_full=$(find "$domain_backup_dir" -name "backup_*.tar.gz" -type f \
        | grep -v "incremental" \
        | sort -r \
        | head -n 1)
    
    echo "$last_full"
}

# Get last backup timestamp
get_last_backup_timestamp() {
    local domain="$1"
    local tracking_file="${BACKUP_TRACKING_DIR}/${domain}_backup.json"
    
    if [[ ! -f "$tracking_file" ]]; then
        echo "0"
        return
    fi
    
    jq -r '.last_backup_timestamp // 0' "$tracking_file" 2>/dev/null || echo "0"
}

# Find files changed since last backup
find_changed_files() {
    local domain="$1"
    local web_root="/var/www/${domain}"
    local last_backup=$(get_last_backup_timestamp "$domain")
    
    if [[ ! -d "$web_root" ]]; then
        return
    fi
    
    if [[ "$last_backup" == "0" ]]; then
        # No previous backup - all files are "changed"
        find "$web_root" -type f 2>/dev/null
    else
        # Find files modified since last backup
        find "$web_root" -type f -newermt "@${last_backup}" 2>/dev/null
    fi
}

# Create incremental backup
create_incremental_backup() {
    local domain="$1"
    local web_root="/var/www/${domain}"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_dir="${BACKUP_BASE_DIR}/${domain}"
    local incremental_dir="${BACKUP_INCREMENTAL_DIR}/${domain}"
    local backup_file="${backup_dir}/backup_${timestamp}_incremental.tar.gz"
    local changed_files_list="${incremental_dir}/changed_files_${timestamp}.txt"
    
    log_info "Creating incremental backup for ${domain}..."
    
    # Create directories
    mkdir -p "$backup_dir"
    mkdir -p "$incremental_dir"
    
    # Find changed files
    local changed_files=$(find_changed_files "$domain")
    local file_count=$(echo "$changed_files" | wc -l)
    
    if [[ $file_count -eq 0 ]]; then
        log_info "No changes detected since last backup"
        return 0
    fi
    
    log_info "Found ${file_count} changed files"
    
    # Save changed files list
    echo "$changed_files" > "$changed_files_list"
    
    # Build exclude patterns
    local exclude_args=""
    for pattern in "${EXCLUDE_PATTERNS[@]}"; do
        exclude_args+=" --exclude='${pattern}'"
    done
    
    # Create incremental backup with changed files only
    eval "tar czf '$backup_file' -C / \
        $exclude_args \
        --files-from='$changed_files_list' \
        2>/dev/null"
    
    if [[ $? -eq 0 ]]; then
        # Save metadata
        local backup_size=$(du -h "$backup_file" | awk '{print $1}')
        cat > "${backup_file}.meta" <<EOF
{
    "type": "incremental",
    "domain": "${domain}",
    "timestamp": "${timestamp}",
    "unix_timestamp": $(date +%s),
    "file_count": ${file_count},
    "backup_size": "${backup_size}",
    "changed_files_list": "${changed_files_list}",
    "base_backup": "$(get_last_full_backup "$domain")"
}
EOF
        
        # Update tracking
        update_backup_tracking "$domain" "incremental"
        
        log_success "Incremental backup created: ${backup_file} (${backup_size})"
        return 0
    else
        log_error "Failed to create incremental backup"
        return 1
    fi
}

# Create full backup
create_full_backup() {
    local domain="$1"
    local web_root="/var/www/${domain}"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_dir="${BACKUP_BASE_DIR}/${domain}"
    local backup_file="${backup_dir}/backup_${timestamp}.tar.gz"
    
    log_info "Creating full backup for ${domain}..."
    
    mkdir -p "$backup_dir"
    
    # Build exclude patterns
    local exclude_args=""
    for pattern in "${EXCLUDE_PATTERNS[@]}"; do
        exclude_args+=" --exclude='${pattern}'"
    done
    
    # Create full backup
    eval "tar czf '$backup_file' -C / \
        $exclude_args \
        '$web_root' \
        2>/dev/null"
    
    if [[ $? -eq 0 ]]; then
        local backup_size=$(du -h "$backup_file" | awk '{print $1}')
        local file_count=$(tar -tzf "$backup_file" 2>/dev/null | wc -l)
        
        # Save metadata
        cat > "${backup_file}.meta" <<EOF
{
    "type": "full",
    "domain": "${domain}",
    "timestamp": "${timestamp}",
    "unix_timestamp": $(date +%s),
    "file_count": ${file_count},
    "backup_size": "${backup_size}"
}
EOF
        
        # Update tracking
        update_backup_tracking "$domain" "full"
        
        log_success "Full backup created: ${backup_file} (${backup_size})"
        return 0
    else
        log_error "Failed to create full backup"
        return 1
    fi
}

# Update backup tracking information
update_backup_tracking() {
    local domain="$1"
    local backup_type="$2"
    local tracking_file="${BACKUP_TRACKING_DIR}/${domain}_backup.json"
    
    local current_timestamp=$(date +%s)
    local backup_count=0
    
    if [[ -f "$tracking_file" ]]; then
        backup_count=$(jq -r '.total_backups // 0' "$tracking_file" 2>/dev/null)
    fi
    
    ((backup_count++))
    
    cat > "$tracking_file" <<EOF
{
    "domain": "${domain}",
    "last_backup_type": "${backup_type}",
    "last_backup_timestamp": ${current_timestamp},
    "last_backup_date": "$(date)",
    "total_backups": ${backup_count}
}
EOF
}

# ==============================================================================
# DATABASE BACKUP INTELLIGENCE
# ==============================================================================

# Detect database type for domain
detect_database_type() {
    local domain="$1"
    local web_root="/var/www/${domain}"
    
    if [[ -f "${web_root}/wp-config.php" ]]; then
        echo "wordpress"
    elif [[ -f "${web_root}/.env" ]] && grep -q "DB_CONNECTION=mysql" "${web_root}/.env" 2>/dev/null; then
        echo "laravel"
    elif [[ -f "${web_root}/config/database.php" ]]; then
        echo "php"
    else
        echo "generic"
    fi
}

# Get database name for domain
get_database_name() {
    local domain="$1"
    local web_root="/var/www/${domain}"
    local db_type=$(detect_database_type "$domain")
    
    case "$db_type" in
        wordpress)
            grep "DB_NAME" "${web_root}/wp-config.php" 2>/dev/null \
                | cut -d "'" -f 4 \
                | head -n 1
            ;;
        laravel)
            grep "DB_DATABASE=" "${web_root}/.env" 2>/dev/null \
                | cut -d "=" -f 2 \
                | tr -d '"' \
                | head -n 1
            ;;
        *)
            echo "${domain//./_}"
            ;;
    esac
}

# Create smart database backup
create_smart_database_backup() {
    local domain="$1"
    local db_name=$(get_database_name "$domain")
    local db_type=$(detect_database_type "$domain")
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_dir="${BACKUP_BASE_DIR}/${domain}"
    local db_backup_file="${backup_dir}/database_${timestamp}.sql.gz"
    
    if [[ -z "$db_name" ]]; then
        log_error "Could not determine database name for ${domain}"
        return 1
    fi
    
    log_info "Creating smart database backup for ${domain} (${db_type})..."
    
    mkdir -p "$backup_dir"
    
    case "$db_type" in
        wordpress)
            create_wordpress_database_backup "$db_name" "$db_backup_file"
            ;;
        laravel)
            create_laravel_database_backup "$db_name" "$db_backup_file"
            ;;
        *)
            create_generic_database_backup "$db_name" "$db_backup_file"
            ;;
    esac
    
    if [[ $? -eq 0 ]]; then
        local backup_size=$(du -h "$db_backup_file" | awk '{print $1}')
        log_success "Database backup created: ${db_backup_file} (${backup_size})"
        return 0
    else
        log_error "Failed to create database backup"
        return 1
    fi
}

# WordPress-optimized database backup
create_wordpress_database_backup() {
    local db_name="$1"
    local output_file="$2"
    
    # Skip transient and cache data
    local ignore_tables=""
    for table in "${WP_SKIP_TABLES[@]}"; do
        ignore_tables+=" --ignore-table=${db_name}.${table}"
    done
    
    # Export with optimizations
    mysqldump \
        --single-transaction \
        --quick \
        --lock-tables=false \
        --skip-comments \
        --skip-extended-insert \
        ${ignore_tables} \
        "$db_name" \
        | gzip -${COMPRESSION_LEVEL} > "$output_file"
    
    return $?
}

# Laravel-optimized database backup
create_laravel_database_backup() {
    local db_name="$1"
    local output_file="$2"
    
    # Skip session, cache, and job tables
    local ignore_tables=""
    for table in "${LARAVEL_SKIP_TABLES[@]}"; do
        ignore_tables+=" --ignore-table=${db_name}.${table}"
    done
    
    mysqldump \
        --single-transaction \
        --quick \
        --lock-tables=false \
        --skip-comments \
        ${ignore_tables} \
        "$db_name" \
        | gzip -${COMPRESSION_LEVEL} > "$output_file"
    
    return $?
}

# Generic database backup
create_generic_database_backup() {
    local db_name="$1"
    local output_file="$2"
    
    mysqldump \
        --single-transaction \
        --quick \
        --lock-tables=false \
        "$db_name" \
        | gzip -${COMPRESSION_LEVEL} > "$output_file"
    
    return $?
}

# ==============================================================================
# SMART SCHEDULING
# ==============================================================================

# Setup automatic backup schedule for domain
setup_backup_schedule() {
    local domain="$1"
    local strategy=$(select_backup_strategy "$domain")
    local schedule=$(get_recommended_schedule "$domain")
    local activity=$(analyze_domain_activity "$domain")
    local size_category=$(get_domain_size_category "$domain")
    
    log_info "Setting up backup schedule for ${domain}..."
    log_info "  Strategy: ${strategy}"
    log_info "  Activity: ${activity}"
    log_info "  Size: ${size_category}"
    log_info "  Schedule: ${schedule}"
    
    # Create cron job entry
    local cron_file="/etc/cron.d/rocketvps_backup_${domain}"
    
    case "$strategy" in
        "$STRATEGY_FULL")
            cat > "$cron_file" <<EOF
# RocketVPS Smart Backup - ${domain}
# Strategy: Full Backup
# Activity: ${activity}
# Size: ${size_category}

${schedule} root /opt/rocketvps/rocketvps.sh backup-domain ${domain} >/dev/null 2>&1
EOF
            ;;
            
        "$STRATEGY_INCREMENTAL")
            cat > "$cron_file" <<EOF
# RocketVPS Smart Backup - ${domain}
# Strategy: Incremental Backup
# Activity: ${activity}
# Size: ${size_category}

# Incremental backup
${schedule} root /opt/rocketvps/rocketvps.sh backup-domain ${domain} incremental >/dev/null 2>&1

# Full backup weekly (Sunday 3 AM)
0 3 * * 0 root /opt/rocketvps/rocketvps.sh backup-domain ${domain} full >/dev/null 2>&1
EOF
            ;;
            
        "$STRATEGY_MIXED")
            cat > "$cron_file" <<EOF
# RocketVPS Smart Backup - ${domain}
# Strategy: Mixed (Weekly Full + Daily Incremental)
# Activity: ${activity}
# Size: ${size_category}

# Daily incremental backup
0 3 * * * root /opt/rocketvps/rocketvps.sh backup-domain ${domain} incremental >/dev/null 2>&1

# Weekly full backup (Sunday 3 AM)
0 3 * * 0 root /opt/rocketvps/rocketvps.sh backup-domain ${domain} full >/dev/null 2>&1
EOF
            ;;
    esac
    
    chmod 644 "$cron_file"
    
    log_success "Backup schedule configured for ${domain}"
}

# Update schedule based on activity changes
update_backup_schedule() {
    local domain="$1"
    
    log_info "Updating backup schedule for ${domain}..."
    
    # Re-analyze and setup schedule
    setup_backup_schedule "$domain"
}

# ==============================================================================
# BACKUP VERIFICATION
# ==============================================================================

# Verify backup integrity
verify_backup() {
    local backup_file="$1"
    
    if [[ ! -f "$backup_file" ]]; then
        return 1
    fi
    
    # Test tar archive integrity
    tar -tzf "$backup_file" >/dev/null 2>&1
    return $?
}

# ==============================================================================
# PARALLEL BACKUP FOR MULTIPLE DOMAINS
# ==============================================================================

# Backup multiple domains in parallel
backup_all_domains_parallel() {
    local max_parallel=4
    local domains=()
    
    # Get all domains
    if [[ -d "/var/www" ]]; then
        for domain_dir in /var/www/*/; do
            if [[ -d "$domain_dir" ]]; then
                local domain=$(basename "$domain_dir")
                domains+=("$domain")
            fi
        done
    fi
    
    if [[ ${#domains[@]} -eq 0 ]]; then
        log_info "No domains found to backup"
        return
    fi
    
    log_info "Starting parallel backup for ${#domains[@]} domains..."
    
    # Backup domains in parallel
    local count=0
    for domain in "${domains[@]}"; do
        smart_backup_domain "$domain" &
        
        ((count++))
        if [[ $((count % max_parallel)) -eq 0 ]]; then
            wait # Wait for batch to complete
        fi
    done
    
    wait # Wait for remaining
    
    log_success "Parallel backup completed for all domains"
}

# ==============================================================================
# MAIN BACKUP FUNCTION
# ==============================================================================

# Smart backup for single domain
smart_backup_domain() {
    local domain="$1"
    local force_type="${2:-auto}" # auto, full, incremental
    
    log_section "Smart Backup: ${domain}"
    
    # Analyze domain
    local strategy=$(select_backup_strategy "$domain")
    local activity=$(analyze_domain_activity "$domain")
    local size=$(get_domain_size "$domain")
    
    log_info "Backup Strategy: ${strategy}"
    log_info "Activity Level: ${activity}"
    log_info "Domain Size: ${size}MB"
    
    # Determine backup type
    local backup_type=""
    if [[ "$force_type" != "auto" ]]; then
        backup_type="$force_type"
    else
        case "$strategy" in
            "$STRATEGY_FULL")
                backup_type="full"
                ;;
            "$STRATEGY_INCREMENTAL"|"$STRATEGY_MIXED")
                # Check if we have a recent full backup
                local last_full=$(get_last_full_backup "$domain")
                if [[ -z "$last_full" ]]; then
                    backup_type="full"
                else
                    backup_type="incremental"
                fi
                ;;
        esac
    fi
    
    log_info "Backup Type: ${backup_type}"
    
    # Create backup
    case "$backup_type" in
        "full")
            create_full_backup "$domain"
            ;;
        "incremental")
            create_incremental_backup "$domain"
            ;;
    esac
    
    local backup_result=$?
    
    # Backup database
    create_smart_database_backup "$domain"
    
    if [[ $backup_result -eq 0 ]]; then
        log_success "Smart backup completed for ${domain}"
        return 0
    else
        log_error "Smart backup failed for ${domain}"
        return 1
    fi
}

# ==============================================================================
# UTILITY FUNCTIONS
# ==============================================================================

# Get backup statistics
get_backup_statistics() {
    local domain="$1"
    local backup_dir="${BACKUP_BASE_DIR}/${domain}"
    local tracking_file="${BACKUP_TRACKING_DIR}/${domain}_backup.json"
    
    if [[ ! -d "$backup_dir" ]]; then
        echo "No backups found for ${domain}"
        return
    fi
    
    local total_backups=$(find "$backup_dir" -name "backup_*.tar.gz" -type f | wc -l)
    local total_size=$(du -sh "$backup_dir" 2>/dev/null | awk '{print $1}')
    local last_backup=""
    local strategy=$(select_backup_strategy "$domain")
    local activity=$(analyze_domain_activity "$domain")
    
    if [[ -f "$tracking_file" ]]; then
        last_backup=$(jq -r '.last_backup_date // "Never"' "$tracking_file" 2>/dev/null)
    fi
    
    cat <<EOF

Backup Statistics: ${domain}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Total Backups:    ${total_backups}
Total Size:       ${total_size}
Last Backup:      ${last_backup}
Activity:         ${activity}
Strategy:         ${strategy}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
}

# List all backups for domain
list_domain_backups() {
    local domain="$1"
    local backup_dir="${BACKUP_BASE_DIR}/${domain}"
    
    if [[ ! -d "$backup_dir" ]]; then
        echo "No backups found for ${domain}"
        return
    fi
    
    echo ""
    echo "Backups for ${domain}:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    printf "%-30s %-12s %-10s %s\n" "BACKUP FILE" "TYPE" "SIZE" "DATE"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    for backup in $(find "$backup_dir" -name "backup_*.tar.gz" -type f | sort -r); do
        local filename=$(basename "$backup")
        local size=$(du -h "$backup" | awk '{print $1}')
        local date=$(stat -c %y "$backup" | cut -d ' ' -f 1)
        local type="full"
        
        if [[ "$filename" == *"incremental"* ]]; then
            type="incremental"
        fi
        
        printf "%-30s %-12s %-10s %s\n" "$filename" "$type" "$size" "$date"
    done
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
}

# ==============================================================================
# EXPORTS
# ==============================================================================

# Initialize on module load
smart_backup_init

# Export functions
export -f smart_backup_domain
export -f create_full_backup
export -f create_incremental_backup
export -f create_smart_database_backup
export -f setup_backup_schedule
export -f backup_all_domains_parallel
export -f get_backup_statistics
export -f list_domain_backups
export -f analyze_domain_activity
export -f select_backup_strategy

log_success "Smart Backup module loaded successfully"
