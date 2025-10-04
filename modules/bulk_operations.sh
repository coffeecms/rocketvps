#!/bin/bash

# ==============================================================================
# RocketVPS v2.2.0 - Bulk Operations Module (Phase 2 Week 9-10)
# ==============================================================================
# File: modules/bulk_operations.sh
# Description: Bulk operations for multiple domains with parallel execution
# Version: 2.2.0
# Author: RocketVPS Team
# ==============================================================================

# Source required modules
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/utils.sh" 2>/dev/null || true
source "${SCRIPT_DIR}/smart_backup.sh" 2>/dev/null || true
source "${SCRIPT_DIR}/restore.sh" 2>/dev/null || true
source "${SCRIPT_DIR}/health_monitor.sh" 2>/dev/null || true
source "${SCRIPT_DIR}/auto_detect.sh" 2>/dev/null || true

# ==============================================================================
# CONFIGURATION
# ==============================================================================

BULK_OPERATIONS_DIR="/opt/rocketvps/bulk_operations"
BULK_RESULTS_DIR="${BULK_OPERATIONS_DIR}/results"
BULK_LOG_DIR="${BULK_OPERATIONS_DIR}/logs"
BULK_TEMP_DIR="${BULK_OPERATIONS_DIR}/temp"

# Parallel execution settings
BULK_MAX_PARALLEL=4                 # Maximum parallel processes
BULK_OPERATION_TIMEOUT=3600         # 1 hour timeout per operation

# Progress tracking
BULK_PROGRESS_FILE="${BULK_TEMP_DIR}/progress.json"

# ==============================================================================
# INITIALIZATION
# ==============================================================================

bulk_operations_init() {
    log_info "Initializing Bulk Operations Module..."
    
    # Create directories
    mkdir -p "${BULK_OPERATIONS_DIR}"
    mkdir -p "${BULK_RESULTS_DIR}"
    mkdir -p "${BULK_LOG_DIR}"
    mkdir -p "${BULK_TEMP_DIR}"
    
    # Set permissions
    chmod 700 "${BULK_OPERATIONS_DIR}"
    chmod 700 "${BULK_RESULTS_DIR}"
    chmod 700 "${BULK_LOG_DIR}"
    chmod 700 "${BULK_TEMP_DIR}"
    
    log_success "Bulk Operations Module initialized"
}

# ==============================================================================
# DOMAIN DISCOVERY AND FILTERING
# ==============================================================================

# Get all domains from /var/www
discover_all_domains() {
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
    
    printf '%s\n' "${domains[@]}"
}

# Filter domains by pattern
filter_domains_by_pattern() {
    local pattern="$1"
    shift
    local domains=("$@")
    local filtered=()
    
    for domain in "${domains[@]}"; do
        if [[ "$domain" =~ $pattern ]]; then
            filtered+=("$domain")
        fi
    done
    
    printf '%s\n' "${filtered[@]}"
}

# Filter domains by site type
filter_domains_by_type() {
    local site_type="$1"
    shift
    local domains=("$@")
    local filtered=()
    
    for domain in "${domains[@]}"; do
        local detected_type=$(detect_site_type "$domain" 2>/dev/null)
        if [[ "$detected_type" == "$site_type" ]]; then
            filtered+=("$domain")
        fi
    done
    
    printf '%s\n' "${filtered[@]}"
}

# Filter domains by size
filter_domains_by_size() {
    local min_size="${1:-0}"           # MB
    local max_size="${2:-999999}"      # MB
    shift 2
    local domains=("$@")
    local filtered=()
    
    for domain in "${domains[@]}"; do
        local size=$(get_domain_size "$domain" 2>/dev/null || echo "0")
        if [[ $size -ge $min_size ]] && [[ $size -le $max_size ]]; then
            filtered+=("$domain")
        fi
    done
    
    printf '%s\n' "${filtered[@]}"
}

# ==============================================================================
# PROGRESS TRACKING
# ==============================================================================

# Initialize progress tracking
init_progress_tracking() {
    local operation="$1"
    local total_items="$2"
    
    cat > "$BULK_PROGRESS_FILE" <<EOF
{
    "operation": "${operation}",
    "total": ${total_items},
    "completed": 0,
    "failed": 0,
    "in_progress": 0,
    "start_time": $(date +%s),
    "status": "running"
}
EOF
}

# Update progress
update_progress() {
    local status="$1"  # success, failed, in_progress
    
    if [[ ! -f "$BULK_PROGRESS_FILE" ]]; then
        return 1
    fi
    
    local completed=$(jq -r '.completed' "$BULK_PROGRESS_FILE" 2>/dev/null || echo "0")
    local failed=$(jq -r '.failed' "$BULK_PROGRESS_FILE" 2>/dev/null || echo "0")
    local in_progress=$(jq -r '.in_progress' "$BULK_PROGRESS_FILE" 2>/dev/null || echo "0")
    
    case "$status" in
        start)
            in_progress=$((in_progress + 1))
            ;;
        success)
            completed=$((completed + 1))
            in_progress=$((in_progress - 1))
            ;;
        failed)
            failed=$((failed + 1))
            in_progress=$((in_progress - 1))
            ;;
    esac
    
    jq --arg completed "$completed" \
       --arg failed "$failed" \
       --arg in_progress "$in_progress" \
       '.completed = ($completed | tonumber) | .failed = ($failed | tonumber) | .in_progress = ($in_progress | tonumber)' \
       "$BULK_PROGRESS_FILE" > "${BULK_PROGRESS_FILE}.tmp" 2>/dev/null && \
       mv "${BULK_PROGRESS_FILE}.tmp" "$BULK_PROGRESS_FILE"
}

# Get progress percentage
get_progress_percentage() {
    if [[ ! -f "$BULK_PROGRESS_FILE" ]]; then
        echo "0"
        return
    fi
    
    local total=$(jq -r '.total' "$BULK_PROGRESS_FILE" 2>/dev/null || echo "1")
    local completed=$(jq -r '.completed' "$BULK_PROGRESS_FILE" 2>/dev/null || echo "0")
    local failed=$(jq -r '.failed' "$BULK_PROGRESS_FILE" 2>/dev/null || echo "0")
    
    local done=$((completed + failed))
    local percentage=$(( done * 100 / total ))
    
    echo "$percentage"
}

# Display progress
display_progress() {
    if [[ ! -f "$BULK_PROGRESS_FILE" ]]; then
        return
    fi
    
    local total=$(jq -r '.total' "$BULK_PROGRESS_FILE")
    local completed=$(jq -r '.completed' "$BULK_PROGRESS_FILE")
    local failed=$(jq -r '.failed' "$BULK_PROGRESS_FILE")
    local in_progress=$(jq -r '.in_progress' "$BULK_PROGRESS_FILE")
    local percentage=$(get_progress_percentage)
    
    echo ""
    echo "Progress: ${percentage}% (${completed} success, ${failed} failed, ${in_progress} in progress, $((total - completed - failed - in_progress)) pending)"
    
    # Progress bar
    local bar_width=50
    local filled=$(( percentage * bar_width / 100 ))
    local empty=$(( bar_width - filled ))
    
    printf "["
    printf "%${filled}s" | tr ' ' '='
    printf "%${empty}s" | tr ' ' '-'
    printf "] ${percentage}%%\n"
}

# Finalize progress
finalize_progress() {
    if [[ ! -f "$BULK_PROGRESS_FILE" ]]; then
        return
    fi
    
    local end_time=$(date +%s)
    jq --arg end_time "$end_time" \
       '.end_time = ($end_time | tonumber) | .status = "completed"' \
       "$BULK_PROGRESS_FILE" > "${BULK_PROGRESS_FILE}.tmp" && \
       mv "${BULK_PROGRESS_FILE}.tmp" "$BULK_PROGRESS_FILE"
}

# ==============================================================================
# BULK BACKUP OPERATIONS
# ==============================================================================

# Bulk backup all domains
bulk_backup_all() {
    local backup_type="${1:-auto}"     # auto, full, incremental
    local parallel="${2:-4}"           # parallel processes
    
    log_section "Bulk Backup: All Domains"
    
    # Discover domains
    local domains=($(discover_all_domains))
    local total=${#domains[@]}
    
    if [[ $total -eq 0 ]]; then
        log_info "No domains found"
        return 0
    fi
    
    log_info "Found ${total} domains to backup"
    
    # Initialize progress
    init_progress_tracking "bulk_backup_all" "$total"
    
    # Create result file
    local result_file="${BULK_RESULTS_DIR}/bulk_backup_$(date +%Y%m%d_%H%M%S).json"
    echo '{"operation": "bulk_backup", "domains": []}' > "$result_file"
    
    # Backup domains in parallel
    local pids=()
    local count=0
    
    for domain in "${domains[@]}"; do
        # Wait if max parallel reached
        while [[ ${#pids[@]} -ge $parallel ]]; do
            for i in "${!pids[@]}"; do
                if ! kill -0 "${pids[$i]}" 2>/dev/null; then
                    unset 'pids[i]'
                fi
            done
            pids=("${pids[@]}")  # Re-index array
            sleep 1
            display_progress
        done
        
        # Start backup in background
        (
            update_progress "start"
            log_info "Backing up ${domain}..."
            
            if smart_backup_domain "$domain" "$backup_type" >/dev/null 2>&1; then
                update_progress "success"
                echo "{\"domain\": \"${domain}\", \"status\": \"success\"}" >> "${result_file}.tmp"
            else
                update_progress "failed"
                echo "{\"domain\": \"${domain}\", \"status\": \"failed\"}" >> "${result_file}.tmp"
            fi
        ) &
        
        pids+=($!)
        ((count++))
    done
    
    # Wait for all processes
    for pid in "${pids[@]}"; do
        wait "$pid" 2>/dev/null
    done
    
    # Finalize progress
    finalize_progress
    display_progress
    
    # Generate final result
    generate_bulk_result "$result_file"
    
    log_success "Bulk backup completed: ${count} domains processed"
    echo "Results saved to: ${result_file}"
}

# Bulk backup filtered domains
bulk_backup_filtered() {
    local filter_type="$1"      # pattern, site_type, size
    local filter_value="$2"
    local backup_type="${3:-auto}"
    local parallel="${4:-4}"
    
    log_section "Bulk Backup: Filtered Domains (${filter_type}=${filter_value})"
    
    # Discover all domains
    local all_domains=($(discover_all_domains))
    local domains=()
    
    # Apply filter
    case "$filter_type" in
        pattern)
            domains=($(filter_domains_by_pattern "$filter_value" "${all_domains[@]}"))
            ;;
        site_type)
            domains=($(filter_domains_by_type "$filter_value" "${all_domains[@]}"))
            ;;
        size)
            local min_size=$(echo "$filter_value" | cut -d'-' -f1)
            local max_size=$(echo "$filter_value" | cut -d'-' -f2)
            domains=($(filter_domains_by_size "$min_size" "$max_size" "${all_domains[@]}"))
            ;;
        *)
            log_error "Unknown filter type: ${filter_type}"
            return 1
            ;;
    esac
    
    local total=${#domains[@]}
    
    if [[ $total -eq 0 ]]; then
        log_info "No domains matched filter"
        return 0
    fi
    
    log_info "Found ${total} domains matching filter"
    
    # Initialize progress
    init_progress_tracking "bulk_backup_filtered" "$total"
    
    # Create result file
    local result_file="${BULK_RESULTS_DIR}/bulk_backup_filtered_$(date +%Y%m%d_%H%M%S).json"
    echo "{\"operation\": \"bulk_backup_filtered\", \"filter\": \"${filter_type}=${filter_value}\", \"domains\": []}" > "$result_file"
    
    # Backup domains
    local pids=()
    local count=0
    
    for domain in "${domains[@]}"; do
        while [[ ${#pids[@]} -ge $parallel ]]; do
            for i in "${!pids[@]}"; do
                if ! kill -0 "${pids[$i]}" 2>/dev/null; then
                    unset 'pids[i]'
                fi
            done
            pids=("${pids[@]}")
            sleep 1
            display_progress
        done
        
        (
            update_progress "start"
            if smart_backup_domain "$domain" "$backup_type" >/dev/null 2>&1; then
                update_progress "success"
                echo "{\"domain\": \"${domain}\", \"status\": \"success\"}" >> "${result_file}.tmp"
            else
                update_progress "failed"
                echo "{\"domain\": \"${domain}\", \"status\": \"failed\"}" >> "${result_file}.tmp"
            fi
        ) &
        
        pids+=($!)
        ((count++))
    done
    
    # Wait for completion
    for pid in "${pids[@]}"; do
        wait "$pid" 2>/dev/null
    done
    
    finalize_progress
    display_progress
    
    generate_bulk_result "$result_file"
    
    log_success "Bulk backup completed: ${count} domains processed"
}

# ==============================================================================
# BULK RESTORE OPERATIONS
# ==============================================================================

# Bulk restore all domains from latest backups
bulk_restore_all() {
    local restore_type="${1:-auto}"    # auto, full, incremental
    local parallel="${2:-4}"
    
    log_section "Bulk Restore: All Domains (Latest Backups)"
    
    # Discover domains
    local domains=($(discover_all_domains))
    local total=${#domains[@]}
    
    if [[ $total -eq 0 ]]; then
        log_info "No domains found"
        return 0
    fi
    
    log_info "Found ${total} domains to restore"
    
    # Confirmation prompt
    echo ""
    echo "⚠️  WARNING: This will restore ALL domains from their latest backups."
    echo "   This operation will overwrite existing files!"
    echo ""
    read -p "Type 'YES' to confirm: " confirmation
    
    if [[ "$confirmation" != "YES" ]]; then
        log_info "Bulk restore cancelled"
        return 0
    fi
    
    # Initialize progress
    init_progress_tracking "bulk_restore_all" "$total"
    
    # Create result file
    local result_file="${BULK_RESULTS_DIR}/bulk_restore_$(date +%Y%m%d_%H%M%S).json"
    echo '{"operation": "bulk_restore", "domains": []}' > "$result_file"
    
    # Restore domains in parallel
    local pids=()
    local count=0
    
    for domain in "${domains[@]}"; do
        while [[ ${#pids[@]} -ge $parallel ]]; do
            for i in "${!pids[@]}"; do
                if ! kill -0 "${pids[$i]}" 2>/dev/null; then
                    unset 'pids[i]'
                fi
            done
            pids=("${pids[@]}")
            sleep 1
            display_progress
        done
        
        (
            update_progress "start"
            log_info "Restoring ${domain}..."
            
            # Find latest backup
            local latest_backup=$(find "${BACKUP_BASE_DIR}/${domain}" -name "backup_*.tar.gz" -type f 2>/dev/null | sort -r | head -n 1)
            
            if [[ -z "$latest_backup" ]]; then
                update_progress "failed"
                echo "{\"domain\": \"${domain}\", \"status\": \"failed\", \"error\": \"no_backup\"}" >> "${result_file}.tmp"
            else
                if restore_domain_backup "$domain" "$latest_backup" >/dev/null 2>&1; then
                    update_progress "success"
                    echo "{\"domain\": \"${domain}\", \"status\": \"success\", \"backup\": \"${latest_backup}\"}" >> "${result_file}.tmp"
                else
                    update_progress "failed"
                    echo "{\"domain\": \"${domain}\", \"status\": \"failed\", \"backup\": \"${latest_backup}\"}" >> "${result_file}.tmp"
                fi
            fi
        ) &
        
        pids+=($!)
        ((count++))
    done
    
    # Wait for completion
    for pid in "${pids[@]}"; do
        wait "$pid" 2>/dev/null
    done
    
    finalize_progress
    display_progress
    
    generate_bulk_result "$result_file"
    
    log_success "Bulk restore completed: ${count} domains processed"
}

# Bulk restore specific domains
bulk_restore_specific() {
    local domains_file="$1"    # File containing domain list (one per line)
    local parallel="${2:-4}"
    
    if [[ ! -f "$domains_file" ]]; then
        log_error "Domains file not found: ${domains_file}"
        return 1
    fi
    
    log_section "Bulk Restore: Specific Domains"
    
    # Read domains from file
    local domains=()
    while IFS= read -r domain; do
        [[ -n "$domain" ]] && domains+=("$domain")
    done < "$domains_file"
    
    local total=${#domains[@]}
    
    if [[ $total -eq 0 ]]; then
        log_info "No domains found in file"
        return 0
    fi
    
    log_info "Found ${total} domains to restore"
    
    # Confirmation
    echo "⚠️  WARNING: Restore will overwrite existing files for these domains."
    read -p "Type 'YES' to confirm: " confirmation
    
    if [[ "$confirmation" != "YES" ]]; then
        log_info "Bulk restore cancelled"
        return 0
    fi
    
    # Initialize progress
    init_progress_tracking "bulk_restore_specific" "$total"
    
    # Create result file
    local result_file="${BULK_RESULTS_DIR}/bulk_restore_specific_$(date +%Y%m%d_%H%M%S).json"
    
    # Restore domains
    local pids=()
    
    for domain in "${domains[@]}"; do
        while [[ ${#pids[@]} -ge $parallel ]]; do
            for i in "${!pids[@]}"; do
                if ! kill -0 "${pids[$i]}" 2>/dev/null; then
                    unset 'pids[i]'
                fi
            done
            pids=("${pids[@]}")
            sleep 1
            display_progress
        done
        
        (
            update_progress "start"
            
            local latest_backup=$(find "${BACKUP_BASE_DIR}/${domain}" -name "backup_*.tar.gz" -type f 2>/dev/null | sort -r | head -n 1)
            
            if [[ -z "$latest_backup" ]]; then
                update_progress "failed"
                echo "{\"domain\": \"${domain}\", \"status\": \"failed\", \"error\": \"no_backup\"}" >> "${result_file}.tmp"
            else
                if restore_domain_backup "$domain" "$latest_backup" >/dev/null 2>&1; then
                    update_progress "success"
                    echo "{\"domain\": \"${domain}\", \"status\": \"success\"}" >> "${result_file}.tmp"
                else
                    update_progress "failed"
                    echo "{\"domain\": \"${domain}\", \"status\": \"failed\"}" >> "${result_file}.tmp"
                fi
            fi
        ) &
        
        pids+=($!)
    done
    
    for pid in "${pids[@]}"; do
        wait "$pid" 2>/dev/null
    done
    
    finalize_progress
    display_progress
    
    generate_bulk_result "$result_file"
    
    log_success "Bulk restore completed"
}

# ==============================================================================
# BULK CONFIGURATION OPERATIONS
# ==============================================================================

# Bulk update Nginx configurations
bulk_update_nginx_config() {
    local parallel="${1:-4}"
    
    log_section "Bulk Update: Nginx Configurations"
    
    local domains=($(discover_all_domains))
    local total=${#domains[@]}
    
    if [[ $total -eq 0 ]]; then
        log_info "No domains found"
        return 0
    fi
    
    log_info "Updating Nginx configs for ${total} domains"
    
    init_progress_tracking "bulk_nginx_update" "$total"
    
    local result_file="${BULK_RESULTS_DIR}/bulk_nginx_update_$(date +%Y%m%d_%H%M%S).json"
    
    local pids=()
    
    for domain in "${domains[@]}"; do
        while [[ ${#pids[@]} -ge $parallel ]]; do
            for i in "${!pids[@]}"; do
                if ! kill -0 "${pids[$i]}" 2>/dev/null; then
                    unset 'pids[i]'
                fi
            done
            pids=("${pids[@]}")
            sleep 1
        done
        
        (
            update_progress "start"
            
            # Generate and update Nginx config
            local nginx_config=$(generate_nginx_config "$domain" 2>/dev/null)
            
            if [[ -n "$nginx_config" ]]; then
                echo "$nginx_config" > "/etc/nginx/sites-available/${domain}"
                
                if nginx -t >/dev/null 2>&1; then
                    update_progress "success"
                    echo "{\"domain\": \"${domain}\", \"status\": \"success\"}" >> "${result_file}.tmp"
                else
                    update_progress "failed"
                    echo "{\"domain\": \"${domain}\", \"status\": \"failed\", \"error\": \"nginx_test_failed\"}" >> "${result_file}.tmp"
                fi
            else
                update_progress "failed"
                echo "{\"domain\": \"${domain}\", \"status\": \"failed\", \"error\": \"config_generation_failed\"}" >> "${result_file}.tmp"
            fi
        ) &
        
        pids+=($!)
    done
    
    for pid in "${pids[@]}"; do
        wait "$pid" 2>/dev/null
    done
    
    # Reload Nginx if tests passed
    if nginx -t >/dev/null 2>&1; then
        systemctl reload nginx
        log_success "Nginx reloaded with new configurations"
    fi
    
    finalize_progress
    display_progress
    
    generate_bulk_result "$result_file"
    
    log_success "Bulk Nginx update completed"
}

# Bulk fix permissions
bulk_fix_permissions() {
    local parallel="${1:-4}"
    
    log_section "Bulk Fix: File Permissions"
    
    local domains=($(discover_all_domains))
    local total=${#domains[@]}
    
    log_info "Fixing permissions for ${total} domains"
    
    init_progress_tracking "bulk_fix_permissions" "$total"
    
    local result_file="${BULK_RESULTS_DIR}/bulk_permissions_$(date +%Y%m%d_%H%M%S).json"
    
    local pids=()
    
    for domain in "${domains[@]}"; do
        while [[ ${#pids[@]} -ge $parallel ]]; do
            for i in "${!pids[@]}"; do
                if ! kill -0 "${pids[$i]}" 2>/dev/null; then
                    unset 'pids[i]'
                fi
            done
            pids=("${pids[@]}")
            sleep 1
        done
        
        (
            update_progress "start"
            
            if fix_permissions "$domain" >/dev/null 2>&1; then
                update_progress "success"
                echo "{\"domain\": \"${domain}\", \"status\": \"success\"}" >> "${result_file}.tmp"
            else
                update_progress "failed"
                echo "{\"domain\": \"${domain}\", \"status\": \"failed\"}" >> "${result_file}.tmp"
            fi
        ) &
        
        pids+=($!)
    done
    
    for pid in "${pids[@]}"; do
        wait "$pid" 2>/dev/null
    done
    
    finalize_progress
    display_progress
    
    generate_bulk_result "$result_file"
    
    log_success "Bulk permissions fix completed"
}

# Bulk SSL renewal
bulk_renew_ssl() {
    local parallel="${1:-2}"    # Limit to 2 for SSL (Let's Encrypt rate limits)
    
    log_section "Bulk SSL Renewal"
    
    local domains=($(discover_all_domains))
    local total=${#domains[@]}
    
    log_info "Renewing SSL for ${total} domains"
    
    init_progress_tracking "bulk_ssl_renewal" "$total"
    
    local result_file="${BULK_RESULTS_DIR}/bulk_ssl_renewal_$(date +%Y%m%d_%H%M%S).json"
    
    local pids=()
    
    for domain in "${domains[@]}"; do
        while [[ ${#pids[@]} -ge $parallel ]]; do
            for i in "${!pids[@]}"; do
                if ! kill -0 "${pids[$i]}" 2>/dev/null; then
                    unset 'pids[i]'
                fi
            done
            pids=("${pids[@]}")
            sleep 1
        done
        
        (
            update_progress "start"
            
            # Check if SSL exists
            if [[ -f "/etc/letsencrypt/live/${domain}/cert.pem" ]]; then
                if certbot renew --cert-name "$domain" --quiet 2>/dev/null; then
                    update_progress "success"
                    echo "{\"domain\": \"${domain}\", \"status\": \"success\"}" >> "${result_file}.tmp"
                else
                    update_progress "failed"
                    echo "{\"domain\": \"${domain}\", \"status\": \"failed\", \"error\": \"renewal_failed\"}" >> "${result_file}.tmp"
                fi
            else
                update_progress "failed"
                echo "{\"domain\": \"${domain}\", \"status\": \"skipped\", \"error\": \"no_ssl\"}" >> "${result_file}.tmp"
            fi
        ) &
        
        pids+=($!)
    done
    
    for pid in "${pids[@]}"; do
        wait "$pid" 2>/dev/null
    done
    
    # Reload Nginx
    systemctl reload nginx
    
    finalize_progress
    display_progress
    
    generate_bulk_result "$result_file"
    
    log_success "Bulk SSL renewal completed"
}

# ==============================================================================
# BULK HEALTH CHECK OPERATIONS
# ==============================================================================

# Bulk health check all domains
bulk_health_check() {
    local parallel="${1:-4}"
    
    log_section "Bulk Health Check: All Domains"
    
    local domains=($(discover_all_domains))
    local total=${#domains[@]}
    
    log_info "Checking health for ${total} domains"
    
    init_progress_tracking "bulk_health_check" "$total"
    
    local result_file="${BULK_RESULTS_DIR}/bulk_health_check_$(date +%Y%m%d_%H%M%S).json"
    
    local pids=()
    
    for domain in "${domains[@]}"; do
        while [[ ${#pids[@]} -ge $parallel ]]; do
            for i in "${!pids[@]}"; do
                if ! kill -0 "${pids[$i]}" 2>/dev/null; then
                    unset 'pids[i]'
                fi
            done
            pids=("${pids[@]}")
            sleep 1
            display_progress
        done
        
        (
            update_progress "start"
            
            if run_domain_health_checks "$domain" >/dev/null 2>&1; then
                update_progress "success"
                echo "{\"domain\": \"${domain}\", \"status\": \"healthy\"}" >> "${result_file}.tmp"
            else
                update_progress "failed"
                echo "{\"domain\": \"${domain}\", \"status\": \"unhealthy\"}" >> "${result_file}.tmp"
            fi
        ) &
        
        pids+=($!)
    done
    
    for pid in "${pids[@]}"; do
        wait "$pid" 2>/dev/null
    done
    
    finalize_progress
    display_progress
    
    generate_bulk_result "$result_file"
    
    log_success "Bulk health check completed"
}

# ==============================================================================
# RESULT GENERATION
# ==============================================================================

# Generate final bulk operation result
generate_bulk_result() {
    local result_file="$1"
    
    if [[ ! -f "${result_file}.tmp" ]]; then
        return
    fi
    
    # Aggregate results
    local total=0
    local success=0
    local failed=0
    
    while IFS= read -r line; do
        ((total++))
        if echo "$line" | grep -q '"status": "success"'; then
            ((success++))
        else
            ((failed++))
        fi
    done < "${result_file}.tmp"
    
    # Create final JSON
    cat > "$result_file" <<EOF
{
    "timestamp": $(date +%s),
    "date": "$(date)",
    "total": ${total},
    "success": ${success},
    "failed": ${failed},
    "success_rate": $(( total > 0 ? success * 100 / total : 0 )),
    "results": [
EOF
    
    # Add results
    local first=true
    while IFS= read -r line; do
        if [[ "$first" == "true" ]]; then
            echo "        ${line}" >> "$result_file"
            first=false
        else
            echo "        ,${line}" >> "$result_file"
        fi
    done < "${result_file}.tmp"
    
    cat >> "$result_file" <<EOF
    ]
}
EOF
    
    rm -f "${result_file}.tmp"
}

# Display bulk operation summary
display_bulk_summary() {
    local result_file="$1"
    
    if [[ ! -f "$result_file" ]]; then
        return
    fi
    
    local total=$(jq -r '.total' "$result_file")
    local success=$(jq -r '.success' "$result_file")
    local failed=$(jq -r '.failed' "$result_file")
    local success_rate=$(jq -r '.success_rate' "$result_file")
    
    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║          Bulk Operation Summary"
    echo "╠════════════════════════════════════════════════════════════╣"
    echo "║  Total Domains:    ${total}"
    echo "║  Successful:       ${success}"
    echo "║  Failed:           ${failed}"
    echo "║  Success Rate:     ${success_rate}%"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
}

# ==============================================================================
# EXPORTS
# ==============================================================================

bulk_operations_init

export -f discover_all_domains
export -f filter_domains_by_pattern
export -f filter_domains_by_type
export -f filter_domains_by_size
export -f bulk_backup_all
export -f bulk_backup_filtered
export -f bulk_restore_all
export -f bulk_restore_specific
export -f bulk_update_nginx_config
export -f bulk_fix_permissions
export -f bulk_renew_ssl
export -f bulk_health_check
export -f display_bulk_summary

log_success "Bulk Operations module loaded successfully"
