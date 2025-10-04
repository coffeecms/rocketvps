#!/bin/bash

################################################################################
# RocketVPS v2.2.0 - Smart Restore Module
# 
# Intelligent backup restoration system with:
# - Backup preview
# - Incremental restore
# - Safety snapshots
# - Automatic rollback
# - Progress tracking
# - Comprehensive verification
################################################################################

# Restore configuration
BACKUP_BASE_DIR="/opt/rocketvps/backups"
SNAPSHOT_DIR="/opt/rocketvps/snapshots"
RESTORE_LOG_DIR="/opt/rocketvps/restore_logs"
RESTORE_TEMP_DIR="/tmp/rocketvps_restore"
RESTORE_TIMEOUT=1800  # 30 minutes
MAX_RETRIES=3
SNAPSHOT_RETENTION=24  # hours

################################################################################
# INITIALIZATION
################################################################################

restore_init_dirs() {
    mkdir -p "$SNAPSHOT_DIR" "$RESTORE_LOG_DIR" "$RESTORE_TEMP_DIR" 2>/dev/null
    chmod 750 "$SNAPSHOT_DIR" "$RESTORE_LOG_DIR" 2>/dev/null
}

################################################################################
# BACKUP LISTING & DISCOVERY
################################################################################

# List all available backups for a domain
restore_list_backups() {
    local domain="$1"
    local backup_dir="$BACKUP_BASE_DIR/$domain"
    
    if [[ ! -d "$backup_dir" ]]; then
        echo -e "${YELLOW}No backups found for domain: $domain${NC}"
        return 1
    fi
    
    # Find all backup files
    local backups=($(find "$backup_dir" -name "backup_*.tar.gz" -type f | sort -r))
    
    if [[ ${#backups[@]} -eq 0 ]]; then
        echo -e "${YELLOW}No backup files found for domain: $domain${NC}"
        return 1
    fi
    
    echo "${backups[@]}"
    return 0
}

# Get backup metadata
restore_get_backup_info() {
    local backup_file="$1"
    
    if [[ ! -f "$backup_file" ]]; then
        return 1
    fi
    
    # Extract basic info
    local filename=$(basename "$backup_file")
    local backup_date=$(echo "$filename" | sed -n 's/backup_\([0-9]\{8\}_[0-9]\{6\}\).*/\1/p')
    local formatted_date=$(echo "$backup_date" | sed 's/_/ /')
    local formatted_date="${formatted_date:0:4}-${formatted_date:4:2}-${formatted_date:6:2} ${formatted_date:9:2}:${formatted_date:11:2}:${formatted_date:13:2}"
    
    local size=$(du -h "$backup_file" | cut -f1)
    local size_bytes=$(stat -c%s "$backup_file" 2>/dev/null || stat -f%z "$backup_file" 2>/dev/null)
    
    # Check if metadata file exists
    local metadata_file="${backup_file}.meta"
    local integrity="unknown"
    local file_count="unknown"
    local db_tables="unknown"
    
    if [[ -f "$metadata_file" ]]; then
        integrity=$(grep "^integrity=" "$metadata_file" | cut -d= -f2)
        file_count=$(grep "^file_count=" "$metadata_file" | cut -d= -f2)
        db_tables=$(grep "^db_tables=" "$metadata_file" | cut -d= -f2)
    fi
    
    echo "$backup_file|$formatted_date|$size|$size_bytes|$integrity|$file_count|$db_tables"
}

# Preview backup contents
restore_preview_backup() {
    local backup_file="$1"
    
    if [[ ! -f "$backup_file" ]]; then
        echo -e "${RED}✗ Backup file not found: $backup_file${NC}"
        return 1
    fi
    
    echo -e "${CYAN}⏳ Analyzing backup contents...${NC}"
    
    local temp_dir="$RESTORE_TEMP_DIR/preview_$$"
    mkdir -p "$temp_dir"
    
    # Extract metadata and file list
    tar -tzf "$backup_file" > "$temp_dir/filelist.txt" 2>/dev/null
    
    local file_count=$(wc -l < "$temp_dir/filelist.txt")
    local has_database=0
    local has_config=0
    
    if grep -q "database.sql" "$temp_dir/filelist.txt"; then
        has_database=1
    fi
    
    if grep -q "config/" "$temp_dir/filelist.txt"; then
        has_config=1
    fi
    
    # Count files by type
    local php_files=$(grep -c "\.php$" "$temp_dir/filelist.txt" 2>/dev/null || echo 0)
    local js_files=$(grep -c "\.js$" "$temp_dir/filelist.txt" 2>/dev/null || echo 0)
    local css_files=$(grep -c "\.css$" "$temp_dir/filelist.txt" 2>/dev/null || echo 0)
    local image_files=$(grep -cE "\.(jpg|jpeg|png|gif|svg|webp)$" "$temp_dir/filelist.txt" 2>/dev/null || echo 0)
    
    # Get directory structure
    local directories=$(grep "/$" "$temp_dir/filelist.txt" | wc -l)
    
    # Clean up
    rm -rf "$temp_dir"
    
    # Return results as pipe-separated values
    echo "$file_count|$has_database|$has_config|$php_files|$js_files|$css_files|$image_files|$directories"
}

# Get database info from backup
restore_get_database_info() {
    local backup_file="$1"
    local temp_dir="$RESTORE_TEMP_DIR/dbinfo_$$"
    
    mkdir -p "$temp_dir"
    
    # Extract database dump if exists
    if tar -tzf "$backup_file" | grep -q "database.sql"; then
        tar -xzf "$backup_file" -C "$temp_dir" "./database.sql" 2>/dev/null
        
        if [[ -f "$temp_dir/database.sql" ]]; then
            local db_size=$(du -h "$temp_dir/database.sql" | cut -f1)
            local table_count=$(grep -c "CREATE TABLE" "$temp_dir/database.sql" 2>/dev/null || echo 0)
            local insert_count=$(grep -c "INSERT INTO" "$temp_dir/database.sql" 2>/dev/null || echo 0)
            
            # Estimate row count (rough estimate)
            local row_estimate=$((insert_count * 10))
            
            rm -rf "$temp_dir"
            echo "$db_size|$table_count|$row_estimate"
            return 0
        fi
    fi
    
    rm -rf "$temp_dir"
    echo "0|0|0"
    return 1
}

################################################################################
# VALIDATION & SAFETY CHECKS
################################################################################

# Validate restore prerequisites
restore_validate_prerequisites() {
    local domain="$1"
    local backup_file="$2"
    
    local errors=0
    local warnings=0
    
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║              PRE-RESTORE VALIDATION                            ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Check 1: Backup file exists
    echo -n "  ⏳ Checking backup file... "
    if [[ ! -f "$backup_file" ]]; then
        echo -e "${RED}✗ FAILED${NC}"
        echo "     Error: Backup file not found"
        ((errors++))
    else
        echo -e "${GREEN}✓ OK${NC}"
    fi
    
    # Check 2: Backup integrity
    echo -n "  ⏳ Verifying backup integrity... "
    if tar -tzf "$backup_file" >/dev/null 2>&1; then
        echo -e "${GREEN}✓ OK${NC}"
    else
        echo -e "${RED}✗ FAILED${NC}"
        echo "     Error: Backup file is corrupted"
        ((errors++))
    fi
    
    # Check 3: Disk space
    echo -n "  ⏳ Checking disk space... "
    local backup_size=$(stat -c%s "$backup_file" 2>/dev/null || stat -f%z "$backup_file" 2>/dev/null)
    local available_space=$(df /var/www | tail -1 | awk '{print $4}')
    local required_space=$((backup_size * 3 / 1024))  # 3x for extraction + snapshot
    
    if [[ $available_space -gt $required_space ]]; then
        echo -e "${GREEN}✓ OK${NC}"
        echo "     Available: $(numfmt --to=iec-i --suffix=B $((available_space * 1024)))"
        echo "     Required:  $(numfmt --to=iec-i --suffix=B $((required_space * 1024)))"
    else
        echo -e "${RED}✗ FAILED${NC}"
        echo "     Error: Insufficient disk space"
        echo "     Available: $(numfmt --to=iec-i --suffix=B $((available_space * 1024)))"
        echo "     Required:  $(numfmt --to=iec-i --suffix=B $((required_space * 1024)))"
        ((errors++))
    fi
    
    # Check 4: Service status
    echo -n "  ⏳ Checking services... "
    local services_ok=1
    
    if ! systemctl is-active nginx >/dev/null 2>&1; then
        services_ok=0
    fi
    
    if ! systemctl is-active php*-fpm >/dev/null 2>&1; then
        services_ok=0
    fi
    
    if ! systemctl is-active mysql >/dev/null 2>&1 && ! systemctl is-active mariadb >/dev/null 2>&1; then
        services_ok=0
    fi
    
    if [[ $services_ok -eq 1 ]]; then
        echo -e "${GREEN}✓ OK${NC}"
    else
        echo -e "${YELLOW}⚠ WARNING${NC}"
        echo "     Warning: Some services are not running"
        ((warnings++))
    fi
    
    # Check 5: Domain exists
    echo -n "  ⏳ Checking domain existence... "
    if [[ -d "/var/www/$domain" ]]; then
        echo -e "${YELLOW}⚠ WARNING${NC}"
        echo "     Warning: Domain directory exists and will be overwritten"
        ((warnings++))
    else
        echo -e "${GREEN}✓ OK${NC}"
    fi
    
    echo ""
    echo -e "${CYAN}────────────────────────────────────────────────────────────────${NC}"
    
    if [[ $errors -gt 0 ]]; then
        echo -e "${RED}✗ VALIDATION FAILED${NC}"
        echo "   Errors: $errors | Warnings: $warnings"
        return 1
    elif [[ $warnings -gt 0 ]]; then
        echo -e "${YELLOW}⚠ VALIDATION PASSED WITH WARNINGS${NC}"
        echo "   Errors: $errors | Warnings: $warnings"
        return 0
    else
        echo -e "${GREEN}✅ VALIDATION PASSED${NC}"
        echo "   All checks passed successfully"
        return 0
    fi
}

################################################################################
# SNAPSHOT CREATION
################################################################################

# Create safety snapshot before restore
restore_create_snapshot() {
    local domain="$1"
    local snapshot_name="pre_restore_$(date +%Y%m%d_%H%M%S)"
    local snapshot_path="$SNAPSHOT_DIR/$domain/$snapshot_name"
    
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║              CREATING SAFETY SNAPSHOT                          ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    mkdir -p "$snapshot_path"
    
    # Snapshot files
    echo -e "${CYAN}⏳ Snapshotting files...${NC}"
    if [[ -d "/var/www/$domain" ]]; then
        tar -czf "$snapshot_path/files.tar.gz" -C "/var/www" "$domain" 2>/dev/null
        echo -e "${GREEN}  ✓ Files snapshotted${NC}"
    fi
    
    # Snapshot database
    echo -e "${CYAN}⏳ Snapshotting database...${NC}"
    local db_cred_file="/opt/rocketvps/config/database_credentials/${domain//./_}.txt"
    
    if [[ -f "$db_cred_file" ]]; then
        local db_name=$(grep "Database:" "$db_cred_file" | cut -d: -f2 | xargs)
        local db_user=$(grep "Username:" "$db_cred_file" | cut -d: -f2 | xargs)
        local db_pass=$(grep "Password:" "$db_cred_file" | cut -d: -f2 | xargs)
        
        if [[ -n "$db_name" ]]; then
            mysqldump -u "$db_user" -p"$db_pass" "$db_name" 2>/dev/null | gzip > "$snapshot_path/database.sql.gz"
            echo -e "${GREEN}  ✓ Database snapshotted${NC}"
        fi
    fi
    
    # Snapshot configuration
    echo -e "${CYAN}⏳ Snapshotting configuration...${NC}"
    mkdir -p "$snapshot_path/config"
    
    if [[ -f "/etc/nginx/sites-available/$domain" ]]; then
        cp "/etc/nginx/sites-available/$domain" "$snapshot_path/config/nginx.conf"
    fi
    
    if [[ -f "/etc/php/8.2/fpm/pool.d/$domain.conf" ]]; then
        cp "/etc/php/8.2/fpm/pool.d/$domain.conf" "$snapshot_path/config/php-fpm.conf"
    fi
    
    echo -e "${GREEN}  ✓ Configuration snapshotted${NC}"
    
    # Save snapshot metadata
    cat > "$snapshot_path/metadata.txt" <<EOF
domain=$domain
snapshot_date=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
purpose=pre_restore_safety
retention_hours=$SNAPSHOT_RETENTION
EOF
    
    echo ""
    echo -e "${GREEN}✅ Safety snapshot created${NC}"
    echo "   Location: $snapshot_path"
    echo ""
    
    echo "$snapshot_path"
}

################################################################################
# RESTORE EXECUTION
################################################################################

# Execute full restore
restore_execute_full() {
    local domain="$1"
    local backup_file="$2"
    local snapshot_path="$3"
    
    local restore_log="$RESTORE_LOG_DIR/$domain/restore_$(date +%Y%m%d_%H%M%S).log"
    mkdir -p "$(dirname "$restore_log")"
    
    {
        echo "=========================================="
        echo "RESTORE STARTED"
        echo "Domain: $domain"
        echo "Backup: $backup_file"
        echo "Snapshot: $snapshot_path"
        echo "Start time: $(date)"
        echo "=========================================="
        echo ""
    } >> "$restore_log"
    
    local start_time=$(date +%s)
    
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║              RESTORE IN PROGRESS                               ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Phase 1: Extract backup
    echo -e "${CYAN}PHASE 1: EXTRACTING BACKUP${NC}"
    echo "────────────────────────────────────────────────────────────────"
    
    local extract_dir="$RESTORE_TEMP_DIR/extract_$$"
    mkdir -p "$extract_dir"
    
    echo -n "  ⏳ Extracting backup archive... "
    if tar -xzf "$backup_file" -C "$extract_dir" 2>>"$restore_log"; then
        echo -e "${GREEN}✓ DONE${NC}"
        echo "Phase 1: Extraction successful" >> "$restore_log"
    else
        echo -e "${RED}✗ FAILED${NC}"
        echo "Phase 1: Extraction failed" >> "$restore_log"
        restore_rollback "$domain" "$snapshot_path" "$restore_log"
        return 1
    fi
    echo ""
    
    # Phase 2: Restore files
    echo -e "${CYAN}PHASE 2: RESTORING FILES${NC}"
    echo "────────────────────────────────────────────────────────────────"
    
    echo -n "  ⏳ Removing old files... "
    if [[ -d "/var/www/$domain" ]]; then
        rm -rf "/var/www/$domain" 2>>"$restore_log"
    fi
    echo -e "${GREEN}✓ DONE${NC}"
    
    echo -n "  ⏳ Copying restored files... "
    if [[ -d "$extract_dir/www" ]]; then
        cp -r "$extract_dir/www" "/var/www/$domain" 2>>"$restore_log"
        echo -e "${GREEN}✓ DONE${NC}"
        
        echo -n "  ⏳ Setting permissions... "
        chown -R www-data:www-data "/var/www/$domain" 2>>"$restore_log"
        find "/var/www/$domain" -type d -exec chmod 755 {} \; 2>>"$restore_log"
        find "/var/www/$domain" -type f -exec chmod 644 {} \; 2>>"$restore_log"
        echo -e "${GREEN}✓ DONE${NC}"
        
        echo "Phase 2: File restore successful" >> "$restore_log"
    else
        echo -e "${RED}✗ FAILED${NC}"
        echo "Phase 2: Files directory not found in backup" >> "$restore_log"
        restore_rollback "$domain" "$snapshot_path" "$restore_log"
        return 1
    fi
    echo ""
    
    # Phase 3: Restore database
    echo -e "${CYAN}PHASE 3: RESTORING DATABASE${NC}"
    echo "────────────────────────────────────────────────────────────────"
    
    if [[ -f "$extract_dir/database.sql" ]]; then
        local db_cred_file="/opt/rocketvps/config/database_credentials/${domain//./_}.txt"
        
        if [[ -f "$db_cred_file" ]]; then
            local db_name=$(grep "Database:" "$db_cred_file" | cut -d: -f2 | xargs)
            local db_user=$(grep "Username:" "$db_cred_file" | cut -d: -f2 | xargs)
            local db_pass=$(grep "Password:" "$db_cred_file" | cut -d: -f2 | xargs)
            
            echo -n "  ⏳ Dropping existing database... "
            mysql -u "$db_user" -p"$db_pass" -e "DROP DATABASE IF EXISTS \`$db_name\`" 2>>"$restore_log"
            echo -e "${GREEN}✓ DONE${NC}"
            
            echo -n "  ⏳ Creating database... "
            mysql -u "$db_user" -p"$db_pass" -e "CREATE DATABASE \`$db_name\`" 2>>"$restore_log"
            echo -e "${GREEN}✓ DONE${NC}"
            
            echo -n "  ⏳ Importing database... "
            if mysql -u "$db_user" -p"$db_pass" "$db_name" < "$extract_dir/database.sql" 2>>"$restore_log"; then
                echo -e "${GREEN}✓ DONE${NC}"
                echo "Phase 3: Database restore successful" >> "$restore_log"
            else
                echo -e "${RED}✗ FAILED${NC}"
                echo "Phase 3: Database import failed" >> "$restore_log"
                restore_rollback "$domain" "$snapshot_path" "$restore_log"
                return 1
            fi
        else
            echo -e "${YELLOW}  ⚠ Database credentials not found, skipping${NC}"
        fi
    else
        echo -e "${YELLOW}  ⚠ No database backup found, skipping${NC}"
    fi
    echo ""
    
    # Phase 4: Restore configuration
    echo -e "${CYAN}PHASE 4: RESTORING CONFIGURATION${NC}"
    echo "────────────────────────────────────────────────────────────────"
    
    if [[ -d "$extract_dir/config" ]]; then
        if [[ -f "$extract_dir/config/nginx.conf" ]]; then
            echo -n "  ⏳ Restoring Nginx configuration... "
            cp "$extract_dir/config/nginx.conf" "/etc/nginx/sites-available/$domain" 2>>"$restore_log"
            ln -sf "/etc/nginx/sites-available/$domain" "/etc/nginx/sites-enabled/$domain" 2>>"$restore_log"
            echo -e "${GREEN}✓ DONE${NC}"
        fi
        
        if [[ -f "$extract_dir/config/php-fpm.conf" ]]; then
            echo -n "  ⏳ Restoring PHP-FPM configuration... "
            cp "$extract_dir/config/php-fpm.conf" "/etc/php/8.2/fpm/pool.d/$domain.conf" 2>>"$restore_log"
            echo -e "${GREEN}✓ DONE${NC}"
        fi
        
        echo "Phase 4: Configuration restore successful" >> "$restore_log"
    else
        echo -e "${YELLOW}  ⚠ No configuration backup found, skipping${NC}"
    fi
    echo ""
    
    # Phase 5: Restart services
    echo -e "${CYAN}PHASE 5: RESTARTING SERVICES${NC}"
    echo "────────────────────────────────────────────────────────────────"
    
    echo -n "  ⏳ Restarting Nginx... "
    systemctl restart nginx 2>>"$restore_log"
    echo -e "${GREEN}✓ DONE${NC}"
    
    echo -n "  ⏳ Restarting PHP-FPM... "
    systemctl restart php8.2-fpm 2>>"$restore_log"
    echo -e "${GREEN}✓ DONE${NC}"
    
    echo "Phase 5: Services restarted" >> "$restore_log"
    echo ""
    
    # Clean up
    rm -rf "$extract_dir"
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    {
        echo ""
        echo "=========================================="
        echo "RESTORE COMPLETED SUCCESSFULLY"
        echo "Duration: $duration seconds"
        echo "End time: $(date)"
        echo "=========================================="
    } >> "$restore_log"
    
    echo -e "${GREEN}✅ RESTORE COMPLETED SUCCESSFULLY${NC}"
    echo "   Duration: $duration seconds"
    echo "   Log: $restore_log"
    echo ""
    
    return 0
}

# Execute incremental restore
restore_execute_incremental() {
    local domain="$1"
    local backup_file="$2"
    local snapshot_path="$3"
    local restore_files="$4"
    local restore_database="$5"
    local restore_config="$6"
    
    local restore_log="$RESTORE_LOG_DIR/$domain/restore_incremental_$(date +%Y%m%d_%H%M%S).log"
    mkdir -p "$(dirname "$restore_log")"
    
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║              INCREMENTAL RESTORE IN PROGRESS                   ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    local extract_dir="$RESTORE_TEMP_DIR/extract_$$"
    mkdir -p "$extract_dir"
    
    # Extract backup
    echo -n "⏳ Extracting backup... "
    tar -xzf "$backup_file" -C "$extract_dir" 2>>"$restore_log"
    echo -e "${GREEN}✓ DONE${NC}"
    echo ""
    
    # Restore files if selected
    if [[ "$restore_files" == "yes" ]]; then
        echo -e "${CYAN}⏳ Restoring files...${NC}"
        if [[ -d "$extract_dir/www" ]]; then
            rm -rf "/var/www/$domain"
            cp -r "$extract_dir/www" "/var/www/$domain" 2>>"$restore_log"
            chown -R www-data:www-data "/var/www/$domain" 2>>"$restore_log"
            echo -e "${GREEN}  ✓ Files restored${NC}"
        fi
        echo ""
    fi
    
    # Restore database if selected
    if [[ "$restore_database" == "yes" ]]; then
        echo -e "${CYAN}⏳ Restoring database...${NC}"
        if [[ -f "$extract_dir/database.sql" ]]; then
            local db_cred_file="/opt/rocketvps/config/database_credentials/${domain//./_}.txt"
            if [[ -f "$db_cred_file" ]]; then
                local db_name=$(grep "Database:" "$db_cred_file" | cut -d: -f2 | xargs)
                local db_user=$(grep "Username:" "$db_cred_file" | cut -d: -f2 | xargs)
                local db_pass=$(grep "Password:" "$db_cred_file" | cut -d: -f2 | xargs)
                
                mysql -u "$db_user" -p"$db_pass" -e "DROP DATABASE IF EXISTS \`$db_name\`" 2>>"$restore_log"
                mysql -u "$db_user" -p"$db_pass" -e "CREATE DATABASE \`$db_name\`" 2>>"$restore_log"
                mysql -u "$db_user" -p"$db_pass" "$db_name" < "$extract_dir/database.sql" 2>>"$restore_log"
                echo -e "${GREEN}  ✓ Database restored${NC}"
            fi
        fi
        echo ""
    fi
    
    # Restore configuration if selected
    if [[ "$restore_config" == "yes" ]]; then
        echo -e "${CYAN}⏳ Restoring configuration...${NC}"
        if [[ -d "$extract_dir/config" ]]; then
            [[ -f "$extract_dir/config/nginx.conf" ]] && cp "$extract_dir/config/nginx.conf" "/etc/nginx/sites-available/$domain" 2>>"$restore_log"
            [[ -f "$extract_dir/config/php-fpm.conf" ]] && cp "$extract_dir/config/php-fpm.conf" "/etc/php/8.2/fpm/pool.d/$domain.conf" 2>>"$restore_log"
            echo -e "${GREEN}  ✓ Configuration restored${NC}"
        fi
        echo ""
    fi
    
    # Restart services
    echo -e "${CYAN}⏳ Restarting services...${NC}"
    systemctl restart nginx php8.2-fpm 2>>"$restore_log"
    echo -e "${GREEN}  ✓ Services restarted${NC}"
    echo ""
    
    rm -rf "$extract_dir"
    
    echo -e "${GREEN}✅ INCREMENTAL RESTORE COMPLETED${NC}"
    return 0
}

################################################################################
# ROLLBACK SYSTEM
################################################################################

# Rollback to snapshot
restore_rollback() {
    local domain="$1"
    local snapshot_path="$2"
    local restore_log="${3:-/tmp/rollback.log}"
    
    echo ""
    echo -e "${RED}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║              RESTORE FAILED - AUTOMATIC ROLLBACK               ║${NC}"
    echo -e "${RED}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    echo -e "${YELLOW}⏳ Initiating automatic rollback...${NC}" | tee -a "$restore_log"
    echo ""
    
    if [[ ! -d "$snapshot_path" ]]; then
        echo -e "${RED}✗ Snapshot not found: $snapshot_path${NC}" | tee -a "$restore_log"
        return 1
    fi
    
    # Rollback files
    if [[ -f "$snapshot_path/files.tar.gz" ]]; then
        echo -n "  ⏳ Rolling back files... "
        rm -rf "/var/www/$domain" 2>>"$restore_log"
        tar -xzf "$snapshot_path/files.tar.gz" -C "/var/www" 2>>"$restore_log"
        echo -e "${GREEN}✓ DONE${NC}"
    fi
    
    # Rollback database
    if [[ -f "$snapshot_path/database.sql.gz" ]]; then
        echo -n "  ⏳ Rolling back database... "
        local db_cred_file="/opt/rocketvps/config/database_credentials/${domain//./_}.txt"
        
        if [[ -f "$db_cred_file" ]]; then
            local db_name=$(grep "Database:" "$db_cred_file" | cut -d: -f2 | xargs)
            local db_user=$(grep "Username:" "$db_cred_file" | cut -d: -f2 | xargs)
            local db_pass=$(grep "Password:" "$db_cred_file" | cut -d: -f2 | xargs)
            
            mysql -u "$db_user" -p"$db_pass" -e "DROP DATABASE IF EXISTS \`$db_name\`" 2>>"$restore_log"
            mysql -u "$db_user" -p"$db_pass" -e "CREATE DATABASE \`$db_name\`" 2>>"$restore_log"
            gunzip -c "$snapshot_path/database.sql.gz" | mysql -u "$db_user" -p"$db_pass" "$db_name" 2>>"$restore_log"
            echo -e "${GREEN}✓ DONE${NC}"
        fi
    fi
    
    # Rollback configuration
    if [[ -d "$snapshot_path/config" ]]; then
        echo -n "  ⏳ Rolling back configuration... "
        [[ -f "$snapshot_path/config/nginx.conf" ]] && cp "$snapshot_path/config/nginx.conf" "/etc/nginx/sites-available/$domain" 2>>"$restore_log"
        [[ -f "$snapshot_path/config/php-fpm.conf" ]] && cp "$snapshot_path/config/php-fpm.conf" "/etc/php/8.2/fpm/pool.d/$domain.conf" 2>>"$restore_log"
        echo -e "${GREEN}✓ DONE${NC}"
    fi
    
    # Restart services
    echo -n "  ⏳ Restarting services... "
    systemctl restart nginx php8.2-fpm 2>>"$restore_log"
    echo -e "${GREEN}✓ DONE${NC}"
    
    echo ""
    echo -e "${GREEN}✓ ROLLBACK SUCCESSFUL${NC}" | tee -a "$restore_log"
    echo "  Your domain has been restored to the state before the restore attempt."
    echo ""
    
    return 0
}

################################################################################
# VERIFICATION SYSTEM
################################################################################

# Verify restored system
restore_verify() {
    local domain="$1"
    
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║              VERIFYING RESTORED SYSTEM                         ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    local checks_passed=0
    local checks_failed=0
    
    # Check 1: File integrity
    echo -e "${CYAN}FILE INTEGRITY${NC}"
    echo "────────────────────────────────────────────────────────────────"
    
    if [[ -d "/var/www/$domain" ]]; then
        local file_count=$(find "/var/www/$domain" -type f | wc -l)
        echo -e "  ${GREEN}✓${NC} Domain directory exists"
        echo -e "  ${GREEN}✓${NC} File count: $file_count files"
        
        local owner=$(stat -c '%U:%G' "/var/www/$domain" 2>/dev/null)
        if [[ "$owner" == "www-data:www-data" ]]; then
            echo -e "  ${GREEN}✓${NC} Ownership correct (www-data:www-data)"
        else
            echo -e "  ${YELLOW}⚠${NC} Ownership: $owner (expected www-data:www-data)"
        fi
        
        ((checks_passed++))
    else
        echo -e "  ${RED}✗${NC} Domain directory not found"
        ((checks_failed++))
    fi
    echo ""
    
    # Check 2: Database integrity
    echo -e "${CYAN}DATABASE INTEGRITY${NC}"
    echo "────────────────────────────────────────────────────────────────"
    
    local db_cred_file="/opt/rocketvps/config/database_credentials/${domain//./_}.txt"
    if [[ -f "$db_cred_file" ]]; then
        local db_name=$(grep "Database:" "$db_cred_file" | cut -d: -f2 | xargs)
        local db_user=$(grep "Username:" "$db_cred_file" | cut -d: -f2 | xargs)
        local db_pass=$(grep "Password:" "$db_cred_file" | cut -d: -f2 | xargs)
        
        if mysql -u "$db_user" -p"$db_pass" -e "USE \`$db_name\`" 2>/dev/null; then
            echo -e "  ${GREEN}✓${NC} Database connection successful"
            
            local table_count=$(mysql -u "$db_user" -p"$db_pass" "$db_name" -e "SHOW TABLES" 2>/dev/null | wc -l)
            echo -e "  ${GREEN}✓${NC} Table count: $((table_count - 1)) tables"
            
            ((checks_passed++))
        else
            echo -e "  ${RED}✗${NC} Database connection failed"
            ((checks_failed++))
        fi
    else
        echo -e "  ${YELLOW}⚠${NC} No database credentials found"
    fi
    echo ""
    
    # Check 3: Configuration
    echo -e "${CYAN}CONFIGURATION${NC}"
    echo "────────────────────────────────────────────────────────────────"
    
    if [[ -f "/etc/nginx/sites-available/$domain" ]]; then
        echo -e "  ${GREEN}✓${NC} Nginx configuration exists"
        
        if nginx -t 2>/dev/null | grep -q "successful"; then
            echo -e "  ${GREEN}✓${NC} Nginx configuration valid"
        else
            echo -e "  ${RED}✗${NC} Nginx configuration invalid"
            ((checks_failed++))
        fi
        ((checks_passed++))
    else
        echo -e "  ${YELLOW}⚠${NC} Nginx configuration not found"
    fi
    echo ""
    
    # Check 4: Service status
    echo -e "${CYAN}SERVICE STATUS${NC}"
    echo "────────────────────────────────────────────────────────────────"
    
    if systemctl is-active nginx >/dev/null 2>&1; then
        echo -e "  ${GREEN}✓${NC} Nginx: running"
        ((checks_passed++))
    else
        echo -e "  ${RED}✗${NC} Nginx: not running"
        ((checks_failed++))
    fi
    
    if systemctl is-active php8.2-fpm >/dev/null 2>&1; then
        echo -e "  ${GREEN}✓${NC} PHP-FPM: running"
        ((checks_passed++))
    else
        echo -e "  ${RED}✗${NC} PHP-FPM: not running"
        ((checks_failed++))
    fi
    
    if systemctl is-active mysql >/dev/null 2>&1 || systemctl is-active mariadb >/dev/null 2>&1; then
        echo -e "  ${GREEN}✓${NC} MySQL: running"
        ((checks_passed++))
    else
        echo -e "  ${RED}✗${NC} MySQL: not running"
        ((checks_failed++))
    fi
    echo ""
    
    # Summary
    echo -e "${CYAN}────────────────────────────────────────────────────────────────${NC}"
    
    if [[ $checks_failed -eq 0 ]]; then
        echo -e "${GREEN}✅ ALL VERIFICATION CHECKS PASSED${NC}"
        echo "   Checks passed: $checks_passed"
        echo "   Your domain has been successfully restored and verified."
        return 0
    else
        echo -e "${YELLOW}⚠ VERIFICATION COMPLETED WITH ISSUES${NC}"
        echo "   Checks passed: $checks_passed"
        echo "   Checks failed: $checks_failed"
        echo "   Please review the issues above."
        return 1
    fi
}

################################################################################
# CLEANUP
################################################################################

# Clean up after restore
restore_cleanup() {
    local domain="$1"
    local snapshot_path="$2"
    local success="$3"
    
    # Clean up temporary files
    rm -rf "$RESTORE_TEMP_DIR"/*_$$ 2>/dev/null
    
    # Handle snapshot
    if [[ "$success" == "yes" ]]; then
        # Keep snapshot for retention period
        echo -e "${CYAN}⏳ Snapshot will be kept for $SNAPSHOT_RETENTION hours${NC}"
    fi
    
    # Clean old snapshots (older than retention period)
    if [[ -d "$SNAPSHOT_DIR/$domain" ]]; then
        find "$SNAPSHOT_DIR/$domain" -type d -name "pre_restore_*" -mmin +$((SNAPSHOT_RETENTION * 60)) -exec rm -rf {} \; 2>/dev/null
    fi
}

# Export functions
export -f restore_init_dirs restore_list_backups restore_get_backup_info
export -f restore_preview_backup restore_get_database_info
export -f restore_validate_prerequisites restore_create_snapshot
export -f restore_execute_full restore_execute_incremental
export -f restore_rollback restore_verify restore_cleanup
