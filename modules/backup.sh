#!/bin/bash

################################################################################
# RocketVPS - Backup & Restore Module
################################################################################

# Backup menu
backup_menu() {
    while true; do
        show_header
        echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║                  BACKUP & RESTORE                             ║${NC}"
        echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo "  1) Backup Domain (Local)"
        echo "  2) Backup All Domains (Local)"
        echo "  3) Backup to Google Drive"
        echo "  4) Backup to Amazon S3"
        echo "  5) Restore from Local Backup"
        echo "  6) Restore from Google Drive"
        echo "  7) Restore from Amazon S3"
        echo "  8) List All Backups"
        echo "  9) Delete Old Backups"
        echo "  10) Schedule Automatic Backups"
        echo ""
        echo "  0) Back to Main Menu"
        echo ""
        echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
        
        read -p "Enter your choice [0-10]: " backup_choice
        
        case $backup_choice in
            1) backup_domain_local ;;
            2) backup_all_domains_local ;;
            3) backup_to_gdrive ;;
            4) backup_to_s3 ;;
            5) restore_from_local ;;
            6) restore_from_gdrive ;;
            7) restore_from_s3 ;;
            8) list_all_backups ;;
            9) delete_old_backups ;;
            10) schedule_backups ;;
            0) return ;;
            *)
                print_error "Invalid choice"
                sleep 2
                ;;
        esac
    done
}

# Backup domain locally
backup_domain_local() {
    show_header
    echo -e "${CYAN}Backup Domain (Local)${NC}"
    echo ""
    
    if [ ! -s "${DOMAIN_LIST_FILE}" ]; then
        print_warning "No domains found"
        press_any_key
        return
    fi
    
    # List domains
    local domain_index=1
    declare -A domain_array
    
    while IFS='|' read -r domain root date_added; do
        echo "  $domain_index) $domain (Root: $root)"
        domain_array[$domain_index]="$domain|$root"
        ((domain_index++))
    done < "${DOMAIN_LIST_FILE}"
    
    echo ""
    read -p "Select domain number: " domain_input
    
    if [ -z "${domain_array[$domain_input]}" ]; then
        print_error "Invalid domain selection"
        press_any_key
        return
    fi
    
    local domain_name=$(echo "${domain_array[$domain_input]}" | cut -d'|' -f1)
    local domain_root=$(echo "${domain_array[$domain_input]}" | cut -d'|' -f2)
    
    print_info "Backing up $domain_name..."
    
    local backup_file="${BACKUP_DIR}/domain_${domain_name}_$(date +%Y%m%d_%H%M%S).tar.gz"
    
    # Create backup
    tar -czf "$backup_file" -C "$(dirname "$domain_root")" "$(basename "$domain_root")" 2>/dev/null
    
    if [ -f "$backup_file" ]; then
        local size=$(du -h "$backup_file" | cut -f1)
        print_success "Backup completed: $backup_file"
        print_info "Size: $size"
        
        # Upload to cloud if configured
        if [ -f "${CONFIG_DIR}/cloud_backup.conf" ]; then
            upload_to_cloud "$backup_file"
        fi
    else
        print_error "Backup failed"
    fi
    
    press_any_key
}

# Backup all domains locally
backup_all_domains_local() {
    show_header
    echo -e "${CYAN}Backup All Domains (Local)${NC}"
    echo ""
    
    if [ ! -s "${DOMAIN_LIST_FILE}" ]; then
        print_warning "No domains found"
        press_any_key
        return
    fi
    
    print_info "Backing up all domains..."
    
    local backup_file="${BACKUP_DIR}/all_domains_$(date +%Y%m%d_%H%M%S).tar.gz"
    local temp_dir="/tmp/rocketvps_backup_$$"
    
    mkdir -p "$temp_dir"
    
    # Copy all domain directories
    while IFS='|' read -r domain root date_added; do
        if [ -d "$root" ]; then
            print_info "Adding $domain to backup..."
            local domain_backup_dir="$temp_dir/$domain"
            mkdir -p "$domain_backup_dir"
            cp -r "$root" "$domain_backup_dir/"
        fi
    done < "${DOMAIN_LIST_FILE}"
    
    # Create archive
    tar -czf "$backup_file" -C "$temp_dir" . 2>/dev/null
    
    # Cleanup
    rm -rf "$temp_dir"
    
    if [ -f "$backup_file" ]; then
        local size=$(du -h "$backup_file" | cut -f1)
        print_success "All domains backed up: $backup_file"
        print_info "Size: $size"
        
        # Upload to cloud if configured
        if [ -f "${CONFIG_DIR}/cloud_backup.conf" ]; then
            upload_to_cloud "$backup_file"
        fi
    else
        print_error "Backup failed"
    fi
    
    press_any_key
}

# Backup to Google Drive
backup_to_gdrive() {
    if ! command -v rclone &> /dev/null; then
        print_error "rclone is not installed. Please configure cloud backup first."
        press_any_key
        return
    fi
    
    if [ ! -f "${CONFIG_DIR}/cloud_backup.conf" ]; then
        print_error "Cloud backup not configured"
        press_any_key
        return
    fi
    
    source "${CONFIG_DIR}/cloud_backup.conf"
    
    if [ "$CLOUD_PROVIDER" != "gdrive" ]; then
        print_error "Google Drive is not configured"
        press_any_key
        return
    fi
    
    # Create local backup first
    backup_all_domains_local
    
    print_info "Uploading to Google Drive..."
    
    # Upload all backups
    for backup_file in ${BACKUP_DIR}/*.tar.gz; do
        if [ -f "$backup_file" ]; then
            rclone copy "$backup_file" "${RCLONE_REMOTE}:${REMOTE_PATH}"
            print_success "Uploaded: $(basename "$backup_file")"
        fi
    done
    
    press_any_key
}

# Backup to Amazon S3
backup_to_s3() {
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed. Please configure cloud backup first."
        press_any_key
        return
    fi
    
    if [ ! -f "${CONFIG_DIR}/cloud_backup.conf" ]; then
        print_error "Cloud backup not configured"
        press_any_key
        return
    fi
    
    source "${CONFIG_DIR}/cloud_backup.conf"
    
    if [ "$CLOUD_PROVIDER" != "s3" ]; then
        print_error "Amazon S3 is not configured"
        press_any_key
        return
    fi
    
    # Create local backup first
    backup_all_domains_local
    
    print_info "Uploading to Amazon S3..."
    
    # Set AWS credentials
    export AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY_ID"
    export AWS_SECRET_ACCESS_KEY="$AWS_SECRET_ACCESS_KEY"
    
    # Upload all backups
    for backup_file in ${BACKUP_DIR}/*.tar.gz; do
        if [ -f "$backup_file" ]; then
            aws s3 cp "$backup_file" "s3://${S3_BUCKET}/" --region "$AWS_REGION"
            print_success "Uploaded: $(basename "$backup_file")"
        fi
    done
    
    press_any_key
}

# Restore from local backup
restore_from_local() {
    show_header
    echo -e "${CYAN}Restore from Local Backup${NC}"
    echo ""
    
    echo "Available local backups:"
    ls -lh "${BACKUP_DIR}"/*.tar.gz 2>/dev/null | nl
    
    echo ""
    read -p "Enter backup file path: " backup_file
    
    if [ ! -f "$backup_file" ]; then
        print_error "Backup file not found"
        press_any_key
        return
    fi
    
    read -p "Enter restore destination directory: " restore_dir
    
    print_warning "This will restore data to $restore_dir"
    read -p "Continue? (yes/no): " confirm
    
    if [ "$confirm" != "yes" ]; then
        print_info "Restore cancelled"
        press_any_key
        return
    fi
    
    mkdir -p "$restore_dir"
    
    print_info "Restoring from backup..."
    tar -xzf "$backup_file" -C "$restore_dir"
    
    if [ $? -eq 0 ]; then
        print_success "Restore completed successfully"
        print_info "Files restored to: $restore_dir"
    else
        print_error "Restore failed"
    fi
    
    press_any_key
}

# Restore from Google Drive
restore_from_gdrive() {
    if ! command -v rclone &> /dev/null; then
        print_error "rclone is not installed"
        press_any_key
        return
    fi
    
    if [ ! -f "${CONFIG_DIR}/cloud_backup.conf" ]; then
        print_error "Cloud backup not configured"
        press_any_key
        return
    fi
    
    source "${CONFIG_DIR}/cloud_backup.conf"
    
    print_info "Listing backups from Google Drive..."
    rclone ls "${RCLONE_REMOTE}:${REMOTE_PATH}"
    
    echo ""
    read -p "Enter backup filename to restore: " backup_filename
    
    if [ -z "$backup_filename" ]; then
        print_error "Filename cannot be empty"
        press_any_key
        return
    fi
    
    print_info "Downloading from Google Drive..."
    rclone copy "${RCLONE_REMOTE}:${REMOTE_PATH}/${backup_filename}" "${BACKUP_DIR}/"
    
    if [ -f "${BACKUP_DIR}/${backup_filename}" ]; then
        print_success "Downloaded successfully"
        
        read -p "Enter restore destination: " restore_dir
        mkdir -p "$restore_dir"
        
        tar -xzf "${BACKUP_DIR}/${backup_filename}" -C "$restore_dir"
        print_success "Restore completed to: $restore_dir"
    else
        print_error "Download failed"
    fi
    
    press_any_key
}

# Restore from Amazon S3
restore_from_s3() {
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed"
        press_any_key
        return
    fi
    
    if [ ! -f "${CONFIG_DIR}/cloud_backup.conf" ]; then
        print_error "Cloud backup not configured"
        press_any_key
        return
    fi
    
    source "${CONFIG_DIR}/cloud_backup.conf"
    
    print_info "Listing backups from Amazon S3..."
    aws s3 ls "s3://${S3_BUCKET}/" --region "$AWS_REGION"
    
    echo ""
    read -p "Enter backup filename to restore: " backup_filename
    
    if [ -z "$backup_filename" ]; then
        print_error "Filename cannot be empty"
        press_any_key
        return
    fi
    
    print_info "Downloading from Amazon S3..."
    aws s3 cp "s3://${S3_BUCKET}/${backup_filename}" "${BACKUP_DIR}/" --region "$AWS_REGION"
    
    if [ -f "${BACKUP_DIR}/${backup_filename}" ]; then
        print_success "Downloaded successfully"
        
        read -p "Enter restore destination: " restore_dir
        mkdir -p "$restore_dir"
        
        tar -xzf "${BACKUP_DIR}/${backup_filename}" -C "$restore_dir"
        print_success "Restore completed to: $restore_dir"
    else
        print_error "Download failed"
    fi
    
    press_any_key
}

# List all backups
list_all_backups() {
    show_header
    echo -e "${CYAN}All Backups${NC}"
    echo ""
    
    echo -e "${GREEN}Local Backups:${NC}"
    if ls "${BACKUP_DIR}"/*.tar.gz 1> /dev/null 2>&1; then
        ls -lh "${BACKUP_DIR}"/*.tar.gz | awk '{print $9, "(" $5 ")"}'
    else
        print_info "No local backups found"
    fi
    
    echo ""
    
    # Check cloud backups
    if [ -f "${CONFIG_DIR}/cloud_backup.conf" ]; then
        source "${CONFIG_DIR}/cloud_backup.conf"
        
        echo -e "${GREEN}Cloud Backups:${NC}"
        
        if [ "$CLOUD_PROVIDER" = "gdrive" ] && command -v rclone &> /dev/null; then
            rclone ls "${RCLONE_REMOTE}:${REMOTE_PATH}" 2>/dev/null | grep ".tar.gz"
        elif [ "$CLOUD_PROVIDER" = "s3" ] && command -v aws &> /dev/null; then
            aws s3 ls "s3://${S3_BUCKET}/" --region "$AWS_REGION" 2>/dev/null | grep ".tar.gz"
        fi
    fi
    
    echo ""
    press_any_key
}

# Delete old backups
delete_old_backups() {
    show_header
    echo -e "${CYAN}Delete Old Backups${NC}"
    echo ""
    
    read -p "Delete backups older than how many days? " days
    
    if [ -z "$days" ] || ! [[ "$days" =~ ^[0-9]+$ ]]; then
        print_error "Invalid number of days"
        press_any_key
        return
    fi
    
    print_warning "This will delete backups older than $days days"
    read -p "Continue? (yes/no): " confirm
    
    if [ "$confirm" != "yes" ]; then
        print_info "Operation cancelled"
        press_any_key
        return
    fi
    
    print_info "Deleting old backups..."
    
    local deleted_count=0
    while IFS= read -r file; do
        rm -f "$file"
        print_info "Deleted: $(basename "$file")"
        ((deleted_count++))
    done < <(find "${BACKUP_DIR}" -name "*.tar.gz" -mtime +${days})
    
    print_success "Deleted $deleted_count old backup(s)"
    press_any_key
}

# Schedule automatic backups
schedule_backups() {
    show_header
    echo -e "${CYAN}Schedule Automatic Backups${NC}"
    echo ""
    
    echo "Select backup frequency:"
    echo "  1) Daily at 2 AM"
    echo "  2) Every 12 hours"
    echo "  3) Every 6 hours"
    echo "  4) Weekly (Sunday 2 AM)"
    echo "  5) Custom cron expression"
    echo ""
    read -p "Enter choice [1-5]: " freq_choice
    
    case $freq_choice in
        1) cron_schedule="0 2 * * *" ;;
        2) cron_schedule="0 */12 * * *" ;;
        3) cron_schedule="0 */6 * * *" ;;
        4) cron_schedule="0 2 * * 0" ;;
        5) 
            read -p "Enter cron expression: " cron_schedule
            ;;
        *)
            print_error "Invalid choice"
            press_any_key
            return
            ;;
    esac
    
    # Create backup script
    cat > "${ROCKETVPS_DIR}/auto_backup.sh" <<'EOF'
#!/bin/bash

# RocketVPS Auto Backup Script
BACKUP_DIR="/opt/rocketvps/backups"
DOMAIN_LIST="/opt/rocketvps/config/domains.list"
LOG_FILE="/opt/rocketvps/logs/auto_backup.log"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting automatic backup..." >> "$LOG_FILE"

# Backup all domains
backup_file="${BACKUP_DIR}/auto_backup_$(date +%Y%m%d_%H%M%S).tar.gz"
tar -czf "$backup_file" /var/www/ 2>> "$LOG_FILE"

if [ -f "$backup_file" ]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Backup completed: $backup_file" >> "$LOG_FILE"
    
    # Upload to cloud if configured
    if [ -f "/opt/rocketvps/config/cloud_backup.conf" ]; then
        source "/opt/rocketvps/config/cloud_backup.conf"
        
        if [ "$CLOUD_PROVIDER" = "gdrive" ] && command -v rclone &> /dev/null; then
            rclone copy "$backup_file" "${RCLONE_REMOTE}:${REMOTE_PATH}" >> "$LOG_FILE" 2>&1
        elif [ "$CLOUD_PROVIDER" = "s3" ] && command -v aws &> /dev/null; then
            aws s3 cp "$backup_file" "s3://${S3_BUCKET}/" --region "$AWS_REGION" >> "$LOG_FILE" 2>&1
        fi
    fi
    
    # Delete backups older than 7 days
    find "$BACKUP_DIR" -name "auto_backup_*.tar.gz" -mtime +7 -delete
else
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Backup failed" >> "$LOG_FILE"
fi

echo "" >> "$LOG_FILE"
EOF
    
    chmod +x "${ROCKETVPS_DIR}/auto_backup.sh"
    
    # Add to crontab
    local cron_job="${cron_schedule} ${ROCKETVPS_DIR}/auto_backup.sh"
    
    # Remove existing backup job
    crontab -l 2>/dev/null | grep -v "auto_backup.sh" | crontab -
    
    # Add new job
    (crontab -l 2>/dev/null; echo "$cron_job") | crontab -
    
    print_success "Automatic backup scheduled"
    print_info "Schedule: $cron_schedule"
    print_info "Backups will be kept for 7 days"
    
    press_any_key
}
