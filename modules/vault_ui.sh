#!/bin/bash

################################################################################
# RocketVPS v2.2.0 - Credentials Vault UI Module
# 
# Interactive interface for vault management
################################################################################

# Source vault core module
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/vault.sh"
source "$SCRIPT_DIR/utils.sh"

################################################################################
# MAIN VAULT MENU
################################################################################

vault_main_menu() {
    while true; do
        clear
        
        # Check vault status
        local vault_status
        local status_color
        if vault_is_locked; then
            vault_status="🔒 Locked"
            status_color="$RED"
        else
            vault_status="🔓 Unlocked"
            status_color="$GREEN"
        fi
        
        echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║              CREDENTIALS VAULT                                 ║${NC}"
        echo -e "${CYAN}║              Status: ${status_color}${vault_status}${CYAN}                                 ║${NC}"
        echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        
        if ! vault_is_initialized; then
            echo -e "${YELLOW}⚠ Vault is not initialized${NC}"
            echo ""
            echo "  ${GREEN}1)${NC} Initialize Vault"
            echo "     └─ Set up vault for first time use"
            echo ""
            echo "  ${RED}0)${NC} Back to Main Menu"
        else
            echo "  ${GREEN}1)${NC} Unlock Vault"
            echo "     └─ Enter master password to access credentials"
            echo ""
            echo "  ${GREEN}2)${NC} View All Credentials"
            echo "     └─ Display all domains with credentials"
            echo ""
            echo "  ${GREEN}3)${NC} Search Credentials"
            echo "     └─ Search by domain name or profile type"
            echo ""
            echo "  ${GREEN}4)${NC} View Domain Details"
            echo "     └─ Show complete credentials for a domain"
            echo ""
            echo "  ${GREEN}5)${NC} Export Credentials"
            echo "     └─ Export encrypted credentials (requires unlock)"
            echo ""
            echo "  ${GREEN}6)${NC} Rotate Domain Passwords"
            echo "     └─ Auto-generate and update passwords"
            echo ""
            echo "  ${GREEN}7)${NC} Change Master Password"
            echo "     └─ Update vault master password"
            echo ""
            echo "  ${GREEN}8)${NC} Import Existing Credentials"
            echo "     └─ Import from existing domain configs"
            echo ""
            echo "  ${GREEN}9)${NC} View Access Log"
            echo "     └─ Show recent vault access history"
            echo ""
            echo "  ${GREEN}10)${NC} Vault Settings"
            echo "     └─ Configure timeout, auto-lock, etc."
            echo ""
            if ! vault_is_locked; then
                echo "  ${YELLOW}L)${NC} Lock Vault"
                echo "     └─ Lock vault and clear session"
                echo ""
            fi
            echo "  ${RED}0)${NC} Back to Main Menu"
        fi
        
        echo ""
        echo -e "${CYAN}────────────────────────────────────────────────────────────────${NC}"
        read -p "$(echo -e ${CYAN}Choose an option: ${NC})" choice
        
        case "$choice" in
            1)
                if ! vault_is_initialized; then
                    vault_init
                else
                    vault_unlock
                fi
                read -p "Press Enter to continue..."
                ;;
            2)
                vault_ui_view_all
                ;;
            3)
                vault_ui_search
                ;;
            4)
                vault_ui_view_domain
                ;;
            5)
                vault_ui_export
                ;;
            6)
                vault_ui_rotate_passwords
                ;;
            7)
                vault_change_master_password
                read -p "Press Enter to continue..."
                ;;
            8)
                vault_import_existing
                read -p "Press Enter to continue..."
                ;;
            9)
                vault_ui_view_log
                ;;
            10)
                vault_ui_settings
                ;;
            [Ll])
                if ! vault_is_locked; then
                    vault_lock
                    read -p "Press Enter to continue..."
                fi
                ;;
            0)
                if ! vault_is_locked; then
                    echo ""
                    read -p "$(echo -e ${YELLOW}Lock vault before exit? (y/n): ${NC})" lock_confirm
                    if [[ "$lock_confirm" =~ ^[Yy] ]]; then
                        vault_lock
                    fi
                fi
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
# VIEW ALL CREDENTIALS
################################################################################

vault_ui_view_all() {
    if ! vault_require_unlock; then
        read -p "Press Enter to continue..."
        return 1
    fi
    
    clear
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║              ALL CREDENTIALS                                   ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    local domains=($(vault_list_domains))
    
    if [[ ${#domains[@]} -eq 0 ]]; then
        echo -e "${YELLOW}No credentials found${NC}"
        read -p "Press Enter to continue..."
        return
    fi
    
    # Display header
    printf "%-30s %-15s %-10s %-20s\n" "DOMAIN" "PROFILE" "STATUS" "CREATED"
    echo -e "${CYAN}────────────────────────────────────────────────────────────────${NC}"
    
    local total=0
    local active=0
    local disabled=0
    
    for domain in "${domains[@]}"; do
        local creds=$(vault_get_credentials "$domain")
        local profile=$(echo "$creds" | jq -r '.profile // "unknown"')
        local status=$(echo "$creds" | jq -r '.status // "unknown"')
        local created=$(echo "$creds" | jq -r '.created_date // "unknown"' | cut -d'T' -f1)
        
        local status_symbol
        if [[ "$status" == "active" ]]; then
            status_symbol="${GREEN}✓ active${NC}"
            ((active++))
        else
            status_symbol="${RED}✗ disabled${NC}"
            ((disabled++))
        fi
        
        printf "%-30s %-15s %-20s %-20s\n" "$domain" "$profile" "$(echo -e $status_symbol)" "$created"
        ((total++))
    done
    
    echo ""
    echo -e "${CYAN}Total: $total domains | Active: $active | Disabled: $disabled${NC}"
    echo ""
    
    read -p "$(echo -e ${CYAN}Enter domain name to view details \(or 'q' to quit\): ${NC})" domain_choice
    
    if [[ -n "$domain_choice" && "$domain_choice" != "q" ]]; then
        vault_ui_show_domain_details "$domain_choice"
    fi
}

################################################################################
# SEARCH CREDENTIALS
################################################################################

vault_ui_search() {
    if ! vault_require_unlock; then
        read -p "Press Enter to continue..."
        return 1
    fi
    
    clear
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║              SEARCH CREDENTIALS                                ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    read -p "$(echo -e ${CYAN}Enter search query \(domain, profile, or status\): ${NC})" query
    
    if [[ -z "$query" ]]; then
        return
    fi
    
    echo ""
    echo -e "${CYAN}⏳ Searching...${NC}"
    echo ""
    
    local results=($(vault_search "$query"))
    
    if [[ ${#results[@]} -eq 0 ]]; then
        echo -e "${YELLOW}No results found for: $query${NC}"
        read -p "Press Enter to continue..."
        return
    fi
    
    echo -e "${GREEN}Found ${#results[@]} result(s):${NC}"
    echo ""
    
    # Display results
    printf "%-5s %-30s %-15s %-10s\n" "#" "DOMAIN" "PROFILE" "STATUS"
    echo -e "${CYAN}────────────────────────────────────────────────────────────────${NC}"
    
    local index=1
    for domain in "${results[@]}"; do
        local creds=$(vault_get_credentials "$domain")
        local profile=$(echo "$creds" | jq -r '.profile // "unknown"')
        local status=$(echo "$creds" | jq -r '.status // "unknown"')
        
        local status_symbol
        if [[ "$status" == "active" ]]; then
            status_symbol="${GREEN}✓${NC}"
        else
            status_symbol="${RED}✗${NC}"
        fi
        
        printf "%-5s %-30s %-15s %-10s\n" "$index" "$domain" "$profile" "$(echo -e $status_symbol)"
        ((index++))
    done
    
    echo ""
    read -p "$(echo -e ${CYAN}Enter number to view details \(or 'q' to quit\): ${NC})" choice
    
    if [[ "$choice" =~ ^[0-9]+$ ]] && [[ $choice -gt 0 ]] && [[ $choice -le ${#results[@]} ]]; then
        local selected_domain="${results[$((choice-1))]}"
        vault_ui_show_domain_details "$selected_domain"
    fi
}

################################################################################
# VIEW DOMAIN DETAILS
################################################################################

vault_ui_view_domain() {
    if ! vault_require_unlock; then
        read -p "Press Enter to continue..."
        return 1
    fi
    
    clear
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║              VIEW DOMAIN DETAILS                               ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # List domains
    local domains=($(vault_list_domains))
    
    if [[ ${#domains[@]} -eq 0 ]]; then
        echo -e "${YELLOW}No credentials found${NC}"
        read -p "Press Enter to continue..."
        return
    fi
    
    echo -e "${CYAN}Available domains:${NC}"
    local index=1
    for domain in "${domains[@]}"; do
        echo "  $index) $domain"
        ((index++))
    done
    
    echo ""
    read -p "$(echo -e ${CYAN}Enter domain name or number: ${NC})" domain_choice
    
    if [[ "$domain_choice" =~ ^[0-9]+$ ]] && [[ $domain_choice -gt 0 ]] && [[ $domain_choice -le ${#domains[@]} ]]; then
        domain_choice="${domains[$((domain_choice-1))]}"
    fi
    
    if [[ -z "$domain_choice" ]]; then
        return
    fi
    
    vault_ui_show_domain_details "$domain_choice"
}

# Show detailed credentials for a domain
vault_ui_show_domain_details() {
    local domain="$1"
    
    local creds=$(vault_get_credentials "$domain")
    
    if [[ -z "$creds" || "$creds" == "null" ]]; then
        echo -e "${RED}✗ Domain not found: $domain${NC}"
        read -p "Press Enter to continue..."
        return 1
    fi
    
    clear
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║              CREDENTIALS DETAILS - $domain${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Domain Information
    echo -e "${CYAN}🌐 DOMAIN INFORMATION${NC}"
    local profile=$(echo "$creds" | jq -r '.profile // "N/A"')
    local status=$(echo "$creds" | jq -r '.status // "N/A"')
    local created=$(echo "$creds" | jq -r '.created_date // "N/A"')
    local doc_root=$(echo "$creds" | jq -r '.domain_info.document_root // "N/A"')
    
    echo "   Domain:         $domain"
    echo "   Profile:        $profile"
    echo "   Status:         $status"
    echo "   Created:        $created"
    if [[ "$doc_root" != "N/A" ]]; then
        echo "   Document Root:  $doc_root"
    fi
    echo ""
    
    # Admin Access
    local admin_url=$(echo "$creds" | jq -r '.admin.url // empty')
    if [[ -n "$admin_url" ]]; then
        echo -e "${CYAN}🔐 ADMIN ACCESS${NC}"
        echo "   URL:            $admin_url"
        echo "   Username:       $(echo "$creds" | jq -r '.admin.username')"
        echo "   Password:       $(echo "$creds" | jq -r '.admin.password')"
        local admin_email=$(echo "$creds" | jq -r '.admin.email // empty')
        if [[ -n "$admin_email" ]]; then
            echo "   Email:          $admin_email"
        fi
        echo ""
    fi
    
    # Database Access
    local db_type=$(echo "$creds" | jq -r '.database.type // empty')
    if [[ -n "$db_type" ]]; then
        echo -e "${CYAN}🗄️  DATABASE ACCESS${NC}"
        echo "   Type:           $db_type"
        echo "   Host:           $(echo "$creds" | jq -r '.database.host'):$(echo "$creds" | jq -r '.database.port // "3306"')"
        echo "   Database:       $(echo "$creds" | jq -r '.database.database')"
        echo "   Username:       $(echo "$creds" | jq -r '.database.username')"
        echo "   Password:       $(echo "$creds" | jq -r '.database.password')"
        echo ""
    fi
    
    # FTP Access
    local ftp_user=$(echo "$creds" | jq -r '.ftp.username // empty')
    if [[ -n "$ftp_user" ]]; then
        echo -e "${CYAN}📁 FTP ACCESS${NC}"
        echo "   Host:           $(echo "$creds" | jq -r '.ftp.host // "'$domain'"):$(echo "$creds" | jq -r '.ftp.port // "21"')"
        echo "   Username:       $ftp_user"
        echo "   Password:       $(echo "$creds" | jq -r '.ftp.password')"
        local ftp_path=$(echo "$creds" | jq -r '.ftp.path // empty')
        if [[ -n "$ftp_path" ]]; then
            echo "   Path:           $ftp_path"
        fi
        echo ""
    fi
    
    # Services
    local redis_enabled=$(echo "$creds" | jq -r '.services.redis.enabled // false')
    local ssl_enabled=$(echo "$creds" | jq -r '.domain_info.ssl_enabled // false')
    local backup_enabled=$(echo "$creds" | jq -r '.services.backup.enabled // false')
    
    if [[ "$redis_enabled" == "true" || "$ssl_enabled" == "true" || "$backup_enabled" == "true" ]]; then
        echo -e "${CYAN}⚙️  SERVICES${NC}"
        
        if [[ "$redis_enabled" == "true" ]]; then
            echo "   Redis:          ✓ Enabled ($(echo "$creds" | jq -r '.services.redis.host'):$(echo "$creds" | jq -r '.services.redis.port'))"
        fi
        
        if [[ "$ssl_enabled" == "true" ]]; then
            local ssl_expiry=$(echo "$creds" | jq -r '.domain_info.ssl_expiry // "N/A"')
            echo "   SSL:            ✓ Enabled (expires: $ssl_expiry)"
        fi
        
        if [[ "$backup_enabled" == "true" ]]; then
            local backup_schedule=$(echo "$creds" | jq -r '.services.backup.schedule // "N/A"')
            local last_backup=$(echo "$creds" | jq -r '.services.backup.last_backup // "N/A"')
            echo "   Backup:         ✓ $backup_schedule (last: $last_backup)"
        fi
        echo ""
    fi
    
    echo -e "${CYAN}────────────────────────────────────────────────────────────────${NC}"
    echo -e "${CYAN}Actions:${NC}"
    echo "  [C] Copy all credentials  [E] Export  [U] Update  [R] Rotate passwords  [Q] Back"
    echo ""
    
    read -p "$(echo -e ${CYAN}Your choice: ${NC})" action
    
    case "$action" in
        [Cc])
            # Copy to clipboard (if xclip/xsel available)
            local all_creds=$(echo "$creds" | jq -r '.')
            echo "$all_creds" | xclip -selection clipboard 2>/dev/null || \
            echo "$all_creds" | xsel --clipboard 2>/dev/null || \
            echo -e "${YELLOW}⚠ Clipboard not available. Credentials displayed above.${NC}"
            read -p "Press Enter to continue..."
            ;;
        [Ee])
            vault_ui_export_single "$domain"
            ;;
        [Uu])
            vault_ui_update_credentials "$domain"
            ;;
        [Rr])
            vault_rotate_passwords "$domain"
            read -p "Press Enter to continue..."
            ;;
        [Qq])
            return
            ;;
    esac
}

################################################################################
# EXPORT CREDENTIALS
################################################################################

vault_ui_export() {
    if ! vault_require_unlock; then
        read -p "Press Enter to continue..."
        return 1
    fi
    
    clear
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║              EXPORT CREDENTIALS                                ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    echo "  1) Export all domains (encrypted)"
    echo "  2) Export specific domain"
    echo "  3) Export as CSV"
    echo "  4) Export as plain text (requires confirmation)"
    echo "  0) Back"
    echo ""
    
    read -p "$(echo -e ${CYAN}Choose option: ${NC})" choice
    
    case "$choice" in
        1)
            vault_export "all" "json"
            read -p "Press Enter to continue..."
            ;;
        2)
            read -p "$(echo -e ${CYAN}Enter domain name: ${NC})" domain
            if [[ -n "$domain" ]]; then
                vault_export "$domain" "json"
            fi
            read -p "Press Enter to continue..."
            ;;
        3)
            vault_export "all" "csv"
            read -p "Press Enter to continue..."
            ;;
        4)
            echo ""
            echo -e "${YELLOW}⚠ WARNING: Plain text export is less secure!${NC}"
            read -p "Are you sure? (yes/no): " confirm
            if [[ "$confirm" == "yes" ]]; then
                vault_export "all" "txt"
            fi
            read -p "Press Enter to continue..."
            ;;
    esac
}

vault_ui_export_single() {
    local domain="$1"
    
    echo ""
    echo -e "${CYAN}Export Options:${NC}"
    echo "  1) JSON (encrypted)"
    echo "  2) CSV (encrypted)"
    echo "  3) Plain text (requires confirmation)"
    echo ""
    
    read -p "$(echo -e ${CYAN}Choose format: ${NC})" format_choice
    
    case "$format_choice" in
        1) vault_export "$domain" "json" ;;
        2) vault_export "$domain" "csv" ;;
        3)
            echo ""
            echo -e "${YELLOW}⚠ WARNING: Plain text export is less secure!${NC}"
            read -p "Are you sure? (yes/no): " confirm
            if [[ "$confirm" == "yes" ]]; then
                vault_export "$domain" "txt"
            fi
            ;;
    esac
    
    read -p "Press Enter to continue..."
}

################################################################################
# ROTATE PASSWORDS
################################################################################

vault_ui_rotate_passwords() {
    if ! vault_require_unlock; then
        read -p "Press Enter to continue..."
        return 1
    fi
    
    clear
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║              ROTATE DOMAIN PASSWORDS                           ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    echo "  1) Rotate passwords for specific domain"
    echo "  2) Rotate passwords for all domains"
    echo "  0) Back"
    echo ""
    
    read -p "$(echo -e ${CYAN}Choose option: ${NC})" choice
    
    case "$choice" in
        1)
            read -p "$(echo -e ${CYAN}Enter domain name: ${NC})" domain
            if [[ -n "$domain" ]]; then
                echo ""
                read -p "$(echo -e ${YELLOW}⚠ This will generate new passwords. Continue? \(y/n\): ${NC})" confirm
                if [[ "$confirm" =~ ^[Yy] ]]; then
                    vault_rotate_passwords "$domain"
                fi
            fi
            read -p "Press Enter to continue..."
            ;;
        2)
            echo ""
            echo -e "${YELLOW}⚠ WARNING: This will rotate passwords for ALL domains!${NC}"
            read -p "Are you sure? (yes/no): " confirm
            if [[ "$confirm" == "yes" ]]; then
                local domains=($(vault_list_domains))
                local total=${#domains[@]}
                local count=0
                
                for domain in "${domains[@]}"; do
                    ((count++))
                    echo ""
                    echo -e "${CYAN}[$count/$total] Processing $domain...${NC}"
                    vault_rotate_passwords "$domain"
                done
                
                echo ""
                echo -e "${GREEN}✅ Password rotation complete for $total domains${NC}"
            fi
            read -p "Press Enter to continue..."
            ;;
    esac
}

################################################################################
# UPDATE CREDENTIALS
################################################################################

vault_ui_update_credentials() {
    local domain="$1"
    
    clear
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║              UPDATE CREDENTIALS - $domain${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    echo "What would you like to update?"
    echo "  1) Admin username"
    echo "  2) Admin password"
    echo "  3) Admin email"
    echo "  4) Database password"
    echo "  5) FTP password"
    echo "  6) Domain status (active/disabled)"
    echo "  0) Back"
    echo ""
    
    read -p "$(echo -e ${CYAN}Choose field: ${NC})" field_choice
    
    local field_path
    case "$field_choice" in
        1) field_path="admin.username" ;;
        2) field_path="admin.password" ;;
        3) field_path="admin.email" ;;
        4) field_path="database.password" ;;
        5) field_path="ftp.password" ;;
        6) field_path="status" ;;
        0) return ;;
        *) echo -e "${RED}Invalid option${NC}"; read -p "Press Enter to continue..."; return ;;
    esac
    
    echo ""
    read -p "$(echo -e ${CYAN}Enter new value: ${NC})" new_value
    
    if [[ -n "$new_value" ]]; then
        if vault_update_credentials "$domain" "$field_path" "$new_value"; then
            echo -e "${GREEN}✅ Updated successfully${NC}"
        else
            echo -e "${RED}✗ Update failed${NC}"
        fi
    fi
    
    read -p "Press Enter to continue..."
}

################################################################################
# VIEW ACCESS LOG
################################################################################

vault_ui_view_log() {
    clear
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║              VAULT ACCESS LOG                                  ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    echo "  1) View last 20 entries"
    echo "  2) View last 50 entries"
    echo "  3) View all entries"
    echo "  4) Search log"
    echo "  5) Export log"
    echo "  0) Back"
    echo ""
    
    read -p "$(echo -e ${CYAN}Choose option: ${NC})" choice
    
    case "$choice" in
        1)
            vault_view_log 20
            read -p "Press Enter to continue..."
            ;;
        2)
            vault_view_log 50
            read -p "Press Enter to continue..."
            ;;
        3)
            vault_view_log 1000
            read -p "Press Enter to continue..."
            ;;
        4)
            read -p "$(echo -e ${CYAN}Enter search term: ${NC})" search_term
            if [[ -n "$search_term" ]]; then
                echo ""
                grep -i "$search_term" "$VAULT_LOG" | tail -20
            fi
            read -p "Press Enter to continue..."
            ;;
        5)
            vault_export_log
            read -p "Press Enter to continue..."
            ;;
    esac
}

################################################################################
# VAULT SETTINGS
################################################################################

vault_ui_settings() {
    clear
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║              VAULT SETTINGS                                    ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    echo -e "${CYAN}Current Settings:${NC}"
    if [[ -f "$VAULT_CONFIG" ]]; then
        cat "$VAULT_CONFIG" | grep -v "^#" | while read line; do
            echo "  $line"
        done
    fi
    echo ""
    
    echo "  1) Change session timeout"
    echo "  2) Change max login attempts"
    echo "  3) Change lockout duration"
    echo "  4) View vault statistics"
    echo "  0) Back"
    echo ""
    
    read -p "$(echo -e ${CYAN}Choose option: ${NC})" choice
    
    case "$choice" in
        1|2|3)
            echo -e "${YELLOW}⚠ Settings modification requires vault rebuild${NC}"
            echo -e "${YELLOW}  This feature will be available in future version${NC}"
            read -p "Press Enter to continue..."
            ;;
        4)
            vault_ui_show_statistics
            ;;
    esac
}

vault_ui_show_statistics() {
    if ! vault_require_unlock; then
        read -p "Press Enter to continue..."
        return 1
    fi
    
    clear
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║              VAULT STATISTICS                                  ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    local total_domains=$(echo "$VAULT_DATA" | jq -r '.domains | length')
    local active_domains=$(echo "$VAULT_DATA" | jq -r '[.domains[] | select(.status == "active")] | length')
    local disabled_domains=$((total_domains - active_domains))
    
    # Count by profile
    local wp_count=$(echo "$VAULT_DATA" | jq -r '[.domains[] | select(.profile == "wordpress")] | length')
    local laravel_count=$(echo "$VAULT_DATA" | jq -r '[.domains[] | select(.profile == "laravel")] | length')
    local nodejs_count=$(echo "$VAULT_DATA" | jq -r '[.domains[] | select(.profile == "nodejs")] | length')
    local static_count=$(echo "$VAULT_DATA" | jq -r '[.domains[] | select(.profile == "static")] | length')
    local ecommerce_count=$(echo "$VAULT_DATA" | jq -r '[.domains[] | select(.profile == "ecommerce")] | length')
    local saas_count=$(echo "$VAULT_DATA" | jq -r '[.domains[] | select(.profile == "saas")] | length')
    
    echo -e "${CYAN}📊 Domain Statistics:${NC}"
    echo "   Total Domains:        $total_domains"
    echo "   Active Domains:       $active_domains"
    echo "   Disabled Domains:     $disabled_domains"
    echo ""
    
    echo -e "${CYAN}📁 Domains by Profile:${NC}"
    echo "   WordPress:            $wp_count"
    echo "   Laravel:              $laravel_count"
    echo "   Node.js:              $nodejs_count"
    echo "   Static HTML:          $static_count"
    echo "   E-commerce:           $ecommerce_count"
    echo "   SaaS:                 $saas_count"
    echo ""
    
    # Vault info
    local vault_size=$(du -sh "$VAULT_DIR" 2>/dev/null | cut -f1)
    local db_size=$(du -sh "$VAULT_DB" 2>/dev/null | cut -f1)
    local log_lines=$(wc -l < "$VAULT_LOG" 2>/dev/null || echo 0)
    
    echo -e "${CYAN}💾 Vault Information:${NC}"
    echo "   Vault Directory:      $vault_size"
    echo "   Database Size:        $db_size"
    echo "   Log Entries:          $log_lines"
    echo "   Created:              $(grep CREATED "$VAULT_CONFIG" | cut -d= -f2)"
    echo "   Last Modified:        $(echo "$VAULT_DATA" | jq -r '.last_modified')"
    echo ""
    
    read -p "Press Enter to continue..."
}

# Export menu function
export -f vault_main_menu
