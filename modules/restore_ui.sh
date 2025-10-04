#!/bin/bash

################################################################################
# RocketVPS v2.2.0 - Smart Restore UI Module
# 
# Interactive interface for restore operations
################################################################################

# Source restore core module
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/restore.sh"
source "$SCRIPT_DIR/utils.sh"

################################################################################
# MAIN RESTORE MENU
################################################################################

restore_main_menu() {
    restore_init_dirs
    
    while true; do
        clear
        echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║              SMART RESTORE SYSTEM                              ║${NC}"
        echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        
        echo "  ${GREEN}1)${NC} Restore Domain"
        echo "     └─ Restore from backup with safety snapshot"
        echo ""
        echo "  ${GREEN}2)${NC} List Available Backups"
        echo "     └─ View all backups for a domain"
        echo ""
        echo "  ${GREEN}3)${NC} Preview Backup"
        echo "     └─ View backup contents before restore"
        echo ""
        echo "  ${GREEN}4)${NC} Manage Snapshots"
        echo "     └─ View and manage safety snapshots"
        echo ""
        echo "  ${GREEN}5)${NC} View Restore Logs"
        echo "     └─ Review restore operation history"
        echo ""
        echo "  ${RED}0)${NC} Back to Main Menu"
        echo ""
        echo -e "${CYAN}────────────────────────────────────────────────────────────────${NC}"
        read -p "$(echo -e ${CYAN}Choose an option: ${NC})" choice
        
        case "$choice" in
            1)
                restore_ui_restore_domain
                ;;
            2)
                restore_ui_list_backups
                ;;
            3)
                restore_ui_preview_backup
                ;;
            4)
                restore_ui_manage_snapshots
                ;;
            5)
                restore_ui_view_logs
                ;;
            0)
                return 0
                ;;
            *)
                echo -e "${RED}Invalid option${NC}"
                sleep 1
                ;;
        esac
    done
}

################################################################################
# RESTORE DOMAIN
################################################################################

restore_ui_restore_domain() {
    clear
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║              RESTORE DOMAIN                                    ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # List available domains
    echo -e "${CYAN}Available domains with backups:${NC}"
    local domains=($(ls -1 "$BACKUP_BASE_DIR" 2>/dev/null))
    
    if [[ ${#domains[@]} -eq 0 ]]; then
        echo -e "${YELLOW}No domains with backups found${NC}"
        read -p "Press Enter to continue..."
        return
    fi
    
    local index=1
    for domain in "${domains[@]}"; do
        local backup_count=$(ls -1 "$BACKUP_BASE_DIR/$domain"/backup_*.tar.gz 2>/dev/null | wc -l)
        echo "  $index) $domain ($backup_count backups)"
        ((index++))
    done
    
    echo ""
    read -p "$(echo -e ${CYAN}Enter domain name or number: ${NC})" domain_choice
    
    # Convert number to domain name
    if [[ "$domain_choice" =~ ^[0-9]+$ ]] && [[ $domain_choice -gt 0 ]] && [[ $domain_choice -le ${#domains[@]} ]]; then
        domain_choice="${domains[$((domain_choice-1))]}"
    fi
    
    if [[ -z "$domain_choice" ]]; then
        return
    fi
    
    # List backups for selected domain
    echo ""
    echo -e "${CYAN}Available backups for $domain_choice:${NC}"
    
    local backups=($(restore_list_backups "$domain_choice"))
    
    if [[ ${#backups[@]} -eq 0 ]]; then
        read -p "Press Enter to continue..."
        return
    fi
    
    index=1
    for backup in "${backups[@]}"; do
        local info=($(restore_get_backup_info "$backup"))
        IFS='|' read -r file date size size_bytes integrity file_count db_tables <<< "${info[0]}"
        echo "  $index) $date ($size)"
        ((index++))
    done
    
    echo ""
    read -p "$(echo -e ${CYAN}Select backup number: ${NC})" backup_choice
    
    if [[ ! "$backup_choice" =~ ^[0-9]+$ ]] || [[ $backup_choice -lt 1 ]] || [[ $backup_choice -gt ${#backups[@]} ]]; then
        echo -e "${RED}Invalid backup selection${NC}"
        read -p "Press Enter to continue..."
        return
    fi
    
    local selected_backup="${backups[$((backup_choice-1))]}"
    
    # Show backup preview
    restore_ui_show_backup_preview "$domain_choice" "$selected_backup"
    
    echo ""
    echo -e "${CYAN}Restore Options:${NC}"
    echo "  1) Full Restore (files + database + config)"
    echo "  2) Incremental Restore (select components)"
    echo "  0) Cancel"
    echo ""
    
    read -p "$(echo -e ${CYAN}Choose restore type: ${NC})" restore_type
    
    case "$restore_type" in
        1)
            restore_ui_execute_full_restore "$domain_choice" "$selected_backup"
            ;;
        2)
            restore_ui_execute_incremental_restore "$domain_choice" "$selected_backup"
            ;;
        0)
            return
            ;;
        *)
            echo -e "${RED}Invalid option${NC}"
            read -p "Press Enter to continue..."
            ;;
    esac
}

# Show backup preview
restore_ui_show_backup_preview() {
    local domain="$1"
    local backup_file="$2"
    
    clear
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║              BACKUP PREVIEW                                    ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    local info=($(restore_get_backup_info "$backup_file"))
    IFS='|' read -r file date size size_bytes integrity file_count db_tables <<< "${info[0]}"
    
    echo -e "${CYAN}📊 BACKUP INFORMATION${NC}"
    echo "   Domain:             $domain"
    echo "   Backup Date:        $date"
    echo "   Backup Size:        $size"
    echo "   Integrity:          ${integrity:-unknown}"
    echo ""
    
    # Get preview data
    local preview=($(restore_preview_backup "$backup_file"))
    IFS='|' read -r files has_db has_config php js css images dirs <<< "${preview[0]}"
    
    echo -e "${CYAN}📁 FILES ($files files)${NC}"
    echo "   PHP files:          $php"
    echo "   JavaScript files:   $js"
    echo "   CSS files:          $css"
    echo "   Image files:        $images"
    echo "   Directories:        $dirs"
    echo ""
    
    if [[ "$has_db" -eq 1 ]]; then
        local db_info=($(restore_get_database_info "$backup_file"))
        IFS='|' read -r db_size table_count row_estimate <<< "${db_info[0]}"
        
        echo -e "${CYAN}🗄️  DATABASE${NC}"
        echo "   Size:               $db_size"
        echo "   Tables:             $table_count"
        echo "   Estimated rows:     ~$row_estimate"
        echo ""
    fi
    
    if [[ "$has_config" -eq 1 ]]; then
        echo -e "${CYAN}⚙️  CONFIGURATION${NC}"
        echo "   Configuration files included"
        echo ""
    fi
    
    # Estimate restore time
    local size_mb=$((size_bytes / 1024 / 1024))
    local est_minutes=$((size_mb / 30))  # Rough estimate: 30MB/min
    [[ $est_minutes -lt 1 ]] && est_minutes=1
    
    echo -e "${CYAN}⏱️  RESTORE ESTIMATE${NC}"
    echo "   Estimated time:     ~$est_minutes minutes"
    echo ""
    
    # Check disk space
    local available_space=$(df /var/www | tail -1 | awk '{print $4}')
    local required_space=$((size_bytes * 3 / 1024))
    
    echo -e "${CYAN}💾 DISK SPACE${NC}"
    echo "   Required:           $(numfmt --to=iec-i --suffix=B $((required_space * 1024)))"
    echo "   Available:          $(numfmt --to=iec-i --suffix=B $((available_space * 1024)))"
    
    if [[ $available_space -gt $required_space ]]; then
        echo -e "   Status:             ${GREEN}✓ Sufficient${NC}"
    else
        echo -e "   Status:             ${RED}✗ Insufficient${NC}"
    fi
    echo ""
}

# Execute full restore
restore_ui_execute_full_restore() {
    local domain="$1"
    local backup_file="$2"
    
    clear
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║              FULL RESTORE CONFIRMATION                         ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    echo -e "${YELLOW}⚠ WARNING: This will replace all current data!${NC}"
    echo ""
    echo "  • Current files will be deleted"
    echo "  • Current database will be dropped"
    echo "  • Current configuration will be replaced"
    echo ""
    echo "  ${GREEN}✓${NC} Safety snapshot will be created"
    echo "  ${GREEN}✓${NC} Automatic rollback on failure"
    echo ""
    
    read -p "$(echo -e ${YELLOW}Type 'YES' to confirm restore: ${NC})" confirm
    
    if [[ "$confirm" != "YES" ]]; then
        echo -e "${YELLOW}Restore cancelled${NC}"
        read -p "Press Enter to continue..."
        return
    fi
    
    echo ""
    
    # Validate prerequisites
    if ! restore_validate_prerequisites "$domain" "$backup_file"; then
        echo ""
        read -p "$(echo -e ${YELLOW}Continue anyway? \(y/n\): ${NC})" force
        if [[ "$force" != "y" ]]; then
            echo -e "${YELLOW}Restore cancelled${NC}"
            read -p "Press Enter to continue..."
            return
        fi
    fi
    
    echo ""
    
    # Create safety snapshot
    local snapshot_path=$(restore_create_snapshot "$domain")
    
    if [[ -z "$snapshot_path" ]]; then
        echo -e "${RED}✗ Failed to create safety snapshot${NC}"
        read -p "Press Enter to continue..."
        return
    fi
    
    read -p "Press Enter to start restore..."
    echo ""
    
    # Execute restore
    if restore_execute_full "$domain" "$backup_file" "$snapshot_path"; then
        echo ""
        
        # Verify restore
        if restore_verify "$domain"; then
            echo ""
            
            # Clean up
            restore_cleanup "$domain" "$snapshot_path" "yes"
            
            echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
            echo -e "${GREEN}║              RESTORE COMPLETED SUCCESSFULLY                    ║${NC}"
            echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
        else
            echo ""
            echo -e "${YELLOW}⚠ Restore completed but verification found issues${NC}"
            echo -e "${YELLOW}  Please review the verification results above${NC}"
        fi
    else
        echo ""
        echo -e "${RED}✗ Restore failed${NC}"
    fi
    
    echo ""
    read -p "Press Enter to continue..."
}

# Execute incremental restore
restore_ui_execute_incremental_restore() {
    local domain="$1"
    local backup_file="$2"
    
    clear
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║              SELECT RESTORE COMPONENTS                         ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    local restore_files="no"
    local restore_database="no"
    local restore_config="no"
    
    echo "Choose components to restore:"
    echo ""
    
    read -p "  Restore files? (y/n): " files_choice
    [[ "$files_choice" =~ ^[Yy] ]] && restore_files="yes"
    
    read -p "  Restore database? (y/n): " db_choice
    [[ "$db_choice" =~ ^[Yy] ]] && restore_database="yes"
    
    read -p "  Restore configuration? (y/n): " config_choice
    [[ "$config_choice" =~ ^[Yy] ]] && restore_config="yes"
    
    if [[ "$restore_files" == "no" && "$restore_database" == "no" && "$restore_config" == "no" ]]; then
        echo ""
        echo -e "${YELLOW}No components selected for restore${NC}"
        read -p "Press Enter to continue..."
        return
    fi
    
    echo ""
    echo -e "${CYAN}Selected components:${NC}"
    [[ "$restore_files" == "yes" ]] && echo -e "  ${GREEN}✓${NC} Files"
    [[ "$restore_database" == "yes" ]] && echo -e "  ${GREEN}✓${NC} Database"
    [[ "$restore_config" == "yes" ]] && echo -e "  ${GREEN}✓${NC} Configuration"
    echo ""
    
    read -p "$(echo -e ${YELLOW}Type 'YES' to confirm: ${NC})" confirm
    
    if [[ "$confirm" != "YES" ]]; then
        echo -e "${YELLOW}Restore cancelled${NC}"
        read -p "Press Enter to continue..."
        return
    fi
    
    echo ""
    
    # Create safety snapshot
    local snapshot_path=$(restore_create_snapshot "$domain")
    
    read -p "Press Enter to start restore..."
    echo ""
    
    # Execute incremental restore
    if restore_execute_incremental "$domain" "$backup_file" "$snapshot_path" "$restore_files" "$restore_database" "$restore_config"; then
        echo ""
        
        # Verify restore
        restore_verify "$domain"
        
        echo ""
        restore_cleanup "$domain" "$snapshot_path" "yes"
    fi
    
    echo ""
    read -p "Press Enter to continue..."
}

################################################################################
# LIST BACKUPS
################################################################################

restore_ui_list_backups() {
    clear
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║              LIST AVAILABLE BACKUPS                            ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    read -p "$(echo -e ${CYAN}Enter domain name: ${NC})" domain
    
    if [[ -z "$domain" ]]; then
        return
    fi
    
    echo ""
    echo -e "${CYAN}Backups for $domain:${NC}"
    echo ""
    
    local backups=($(restore_list_backups "$domain"))
    
    if [[ ${#backups[@]} -eq 0 ]]; then
        read -p "Press Enter to continue..."
        return
    fi
    
    printf "%-5s %-25s %-15s %-15s\n" "#" "DATE" "SIZE" "INTEGRITY"
    echo -e "${CYAN}────────────────────────────────────────────────────────────────${NC}"
    
    local index=1
    for backup in "${backups[@]}"; do
        local info=($(restore_get_backup_info "$backup"))
        IFS='|' read -r file date size size_bytes integrity file_count db_tables <<< "${info[0]}"
        
        printf "%-5s %-25s %-15s %-15s\n" "$index" "$date" "$size" "${integrity:-unknown}"
        ((index++))
    done
    
    echo ""
    read -p "$(echo -e ${CYAN}Enter backup number to preview \(or 'q' to quit\): ${NC})" choice
    
    if [[ "$choice" =~ ^[0-9]+$ ]] && [[ $choice -gt 0 ]] && [[ $choice -le ${#backups[@]} ]]; then
        local selected_backup="${backups[$((choice-1))]}"
        restore_ui_show_backup_preview "$domain" "$selected_backup"
        read -p "Press Enter to continue..."
    fi
}

################################################################################
# PREVIEW BACKUP
################################################################################

restore_ui_preview_backup() {
    clear
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║              PREVIEW BACKUP                                    ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    read -p "$(echo -e ${CYAN}Enter domain name: ${NC})" domain
    
    if [[ -z "$domain" ]]; then
        return
    fi
    
    local backups=($(restore_list_backups "$domain"))
    
    if [[ ${#backups[@]} -eq 0 ]]; then
        read -p "Press Enter to continue..."
        return
    fi
    
    echo ""
    echo -e "${CYAN}Available backups:${NC}"
    
    local index=1
    for backup in "${backups[@]}"; do
        local info=($(restore_get_backup_info "$backup"))
        IFS='|' read -r file date size size_bytes integrity file_count db_tables <<< "${info[0]}"
        echo "  $index) $date ($size)"
        ((index++))
    done
    
    echo ""
    read -p "$(echo -e ${CYAN}Select backup number: ${NC})" choice
    
    if [[ ! "$choice" =~ ^[0-9]+$ ]] || [[ $choice -lt 1 ]] || [[ $choice -gt ${#backups[@]} ]]; then
        return
    fi
    
    local selected_backup="${backups[$((choice-1))]}"
    
    restore_ui_show_backup_preview "$domain" "$selected_backup"
    
    read -p "Press Enter to continue..."
}

################################################################################
# MANAGE SNAPSHOTS
################################################################################

restore_ui_manage_snapshots() {
    clear
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║              MANAGE SNAPSHOTS                                  ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    if [[ ! -d "$SNAPSHOT_DIR" ]] || [[ -z "$(ls -A "$SNAPSHOT_DIR" 2>/dev/null)" ]]; then
        echo -e "${YELLOW}No snapshots found${NC}"
        read -p "Press Enter to continue..."
        return
    fi
    
    echo -e "${CYAN}Available snapshots:${NC}"
    echo ""
    
    printf "%-30s %-30s %-15s\n" "DOMAIN" "SNAPSHOT DATE" "SIZE"
    echo -e "${CYAN}────────────────────────────────────────────────────────────────${NC}"
    
    local snapshots=()
    for domain_dir in "$SNAPSHOT_DIR"/*; do
        [[ -d "$domain_dir" ]] || continue
        local domain=$(basename "$domain_dir")
        
        for snapshot_dir in "$domain_dir"/pre_restore_*; do
            [[ -d "$snapshot_dir" ]] || continue
            
            local snapshot_name=$(basename "$snapshot_dir")
            local snapshot_date=$(echo "$snapshot_name" | sed 's/pre_restore_//' | sed 's/_/ /')
            local snapshot_date="${snapshot_date:0:4}-${snapshot_date:4:2}-${snapshot_date:6:2} ${snapshot_date:9:2}:${snapshot_date:11:2}:${snapshot_date:13:2}"
            local snapshot_size=$(du -sh "$snapshot_dir" 2>/dev/null | cut -f1)
            
            printf "%-30s %-30s %-15s\n" "$domain" "$snapshot_date" "$snapshot_size"
            snapshots+=("$snapshot_dir")
        done
    done
    
    if [[ ${#snapshots[@]} -eq 0 ]]; then
        echo -e "${YELLOW}No snapshots found${NC}"
        read -p "Press Enter to continue..."
        return
    fi
    
    echo ""
    echo "  1) Clean old snapshots (older than $SNAPSHOT_RETENTION hours)"
    echo "  2) Delete specific snapshot"
    echo "  0) Back"
    echo ""
    
    read -p "$(echo -e ${CYAN}Choose option: ${NC})" choice
    
    case "$choice" in
        1)
            echo ""
            echo -e "${CYAN}⏳ Cleaning old snapshots...${NC}"
            
            local cleaned=0
            for snapshot in "${snapshots[@]}"; do
                if [[ -d "$snapshot" ]]; then
                    local age=$(find "$snapshot" -maxdepth 0 -mmin +$((SNAPSHOT_RETENTION * 60)) 2>/dev/null)
                    if [[ -n "$age" ]]; then
                        rm -rf "$snapshot"
                        ((cleaned++))
                    fi
                fi
            done
            
            echo -e "${GREEN}✓ Cleaned $cleaned old snapshots${NC}"
            read -p "Press Enter to continue..."
            ;;
        2)
            echo ""
            read -p "$(echo -e ${CYAN}Enter snapshot number to delete: ${NC})" snap_num
            
            if [[ "$snap_num" =~ ^[0-9]+$ ]] && [[ $snap_num -gt 0 ]] && [[ $snap_num -le ${#snapshots[@]} ]]; then
                local snapshot_to_delete="${snapshots[$((snap_num-1))]}"
                
                read -p "$(echo -e ${YELLOW}Are you sure? \(y/n\): ${NC})" confirm
                if [[ "$confirm" =~ ^[Yy] ]]; then
                    rm -rf "$snapshot_to_delete"
                    echo -e "${GREEN}✓ Snapshot deleted${NC}"
                fi
            fi
            read -p "Press Enter to continue..."
            ;;
    esac
}

################################################################################
# VIEW LOGS
################################################################################

restore_ui_view_logs() {
    clear
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║              RESTORE LOGS                                      ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    if [[ ! -d "$RESTORE_LOG_DIR" ]] || [[ -z "$(ls -A "$RESTORE_LOG_DIR" 2>/dev/null)" ]]; then
        echo -e "${YELLOW}No restore logs found${NC}"
        read -p "Press Enter to continue..."
        return
    fi
    
    echo -e "${CYAN}Available logs:${NC}"
    echo ""
    
    local logs=($(find "$RESTORE_LOG_DIR" -name "*.log" -type f | sort -r))
    
    if [[ ${#logs[@]} -eq 0 ]]; then
        echo -e "${YELLOW}No restore logs found${NC}"
        read -p "Press Enter to continue..."
        return
    fi
    
    local index=1
    for log in "${logs[@]}"; do
        local log_name=$(basename "$log")
        local log_size=$(du -h "$log" | cut -f1)
        local log_date=$(stat -c %y "$log" 2>/dev/null | cut -d' ' -f1,2)
        
        echo "  $index) $log_name ($log_size) - $log_date"
        ((index++))
        
        [[ $index -gt 10 ]] && break  # Show max 10 logs
    done
    
    echo ""
    read -p "$(echo -e ${CYAN}Enter log number to view \(or 'q' to quit\): ${NC})" choice
    
    if [[ "$choice" =~ ^[0-9]+$ ]] && [[ $choice -gt 0 ]] && [[ $choice -le ${#logs[@]} ]]; then
        local selected_log="${logs[$((choice-1))]}"
        
        clear
        echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
        echo -e "${CYAN}LOG: $(basename "$selected_log")${NC}"
        echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
        echo ""
        
        cat "$selected_log"
        
        echo ""
        echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
        read -p "Press Enter to continue..."
    fi
}

# Export menu function
export -f restore_main_menu
