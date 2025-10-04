#!/bin/bash

################################################################################
# RocketVPS - Permission Management Module
################################################################################

# Permission menu
permission_menu() {
    while true; do
        show_header
        echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║                 PERMISSION MANAGEMENT                         ║${NC}"
        echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo "  1) Set Permissions for Domain"
        echo "  2) Fix Permissions (Auto)"
        echo "  3) Set Custom CHMOD"
        echo "  4) Change Owner"
        echo "  5) View Current Permissions"
        echo "  6) Apply WordPress Permissions"
        echo "  7) Apply Laravel Permissions"
        echo "  8) Apply General Web Permissions"
        echo ""
        echo "  0) Back to Main Menu"
        echo ""
        echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
        
        read -p "Enter your choice [0-8]: " perm_choice
        
        case $perm_choice in
            1) set_domain_permissions ;;
            2) fix_permissions_auto ;;
            3) set_custom_chmod ;;
            4) change_owner ;;
            5) view_permissions ;;
            6) apply_wordpress_permissions ;;
            7) apply_laravel_permissions ;;
            8) apply_web_permissions ;;
            0) return ;;
            *)
                print_error "Invalid choice"
                sleep 2
                ;;
        esac
    done
}

# Set permissions for domain
set_domain_permissions() {
    show_header
    echo -e "${CYAN}Set Permissions for Domain${NC}"
    echo ""
    
    # List domains
    if [ ! -s "${DOMAIN_LIST_FILE}" ]; then
        print_warning "No domains found"
        press_any_key
        return
    fi
    
    local domain_index=1
    declare -A domain_array
    
    while IFS='|' read -r domain root date_added; do
        echo "  $domain_index) $domain (Root: $root)"
        domain_array[$domain_index]=$domain
        ((domain_index++))
    done < "${DOMAIN_LIST_FILE}"
    
    echo ""
    read -p "Select domain number: " domain_input
    
    if [ -z "${domain_array[$domain_input]}" ]; then
        print_error "Invalid domain selection"
        press_any_key
        return
    fi
    
    local domain_name="${domain_array[$domain_input]}"
    local domain_root=$(grep "^${domain_name}|" "${DOMAIN_LIST_FILE}" | cut -d'|' -f2)
    
    echo ""
    echo "Select permission template:"
    echo "  1) Secure (755/644) - Recommended"
    echo "  2) WordPress (755/644 with wp-content/uploads 775)"
    echo "  3) Laravel (755/644 with storage/bootstrap 775)"
    echo "  4) Permissive (777/666) - Not recommended"
    echo "  5) Custom"
    echo ""
    read -p "Enter choice [1-5]: " perm_template
    
    case $perm_template in
        1) apply_secure_permissions "$domain_root" ;;
        2) apply_wordpress_permissions_dir "$domain_root" ;;
        3) apply_laravel_permissions_dir "$domain_root" ;;
        4) apply_permissive_permissions "$domain_root" ;;
        5) 
            read -p "Enter directory permission (e.g., 755): " dir_perm
            read -p "Enter file permission (e.g., 644): " file_perm
            apply_custom_permissions "$domain_root" "$dir_perm" "$file_perm"
            ;;
        *)
            print_error "Invalid choice"
            press_any_key
            return
            ;;
    esac
    
    print_success "Permissions applied to $domain_name"
    press_any_key
}

# Apply secure permissions
apply_secure_permissions() {
    local target_dir=$1
    
    print_info "Applying secure permissions (755/644)..."
    
    # Set directory permissions
    find "$target_dir" -type d -exec chmod 755 {} \;
    
    # Set file permissions
    find "$target_dir" -type f -exec chmod 644 {} \;
    
    # Make scripts executable
    find "$target_dir" -type f -name "*.sh" -exec chmod 755 {} \;
    
    print_success "Secure permissions applied"
}

# Apply WordPress permissions
apply_wordpress_permissions_dir() {
    local target_dir=$1
    
    print_info "Applying WordPress permissions..."
    
    # Base permissions
    find "$target_dir" -type d -exec chmod 755 {} \;
    find "$target_dir" -type f -exec chmod 644 {} \;
    
    # wp-content uploads
    if [ -d "$target_dir/wp-content/uploads" ]; then
        chmod 775 "$target_dir/wp-content/uploads"
        find "$target_dir/wp-content/uploads" -type d -exec chmod 775 {} \;
    fi
    
    # wp-config.php
    if [ -f "$target_dir/wp-config.php" ]; then
        chmod 640 "$target_dir/wp-config.php"
    fi
    
    print_success "WordPress permissions applied"
}

# Apply Laravel permissions
apply_laravel_permissions_dir() {
    local target_dir=$1
    
    print_info "Applying Laravel permissions..."
    
    # Base permissions
    find "$target_dir" -type d -exec chmod 755 {} \;
    find "$target_dir" -type f -exec chmod 644 {} \;
    
    # Storage directory
    if [ -d "$target_dir/storage" ]; then
        chmod -R 775 "$target_dir/storage"
    fi
    
    # Bootstrap cache
    if [ -d "$target_dir/bootstrap/cache" ]; then
        chmod -R 775 "$target_dir/bootstrap/cache"
    fi
    
    # .env file
    if [ -f "$target_dir/.env" ]; then
        chmod 640 "$target_dir/.env"
    fi
    
    print_success "Laravel permissions applied"
}

# Apply permissive permissions
apply_permissive_permissions() {
    local target_dir=$1
    
    print_warning "Applying permissive permissions (777/666) - NOT SECURE!"
    
    find "$target_dir" -type d -exec chmod 777 {} \;
    find "$target_dir" -type f -exec chmod 666 {} \;
    
    print_warning "Permissive permissions applied - This is a security risk!"
}

# Apply custom permissions
apply_custom_permissions() {
    local target_dir=$1
    local dir_perm=$2
    local file_perm=$3
    
    print_info "Applying custom permissions ($dir_perm/$file_perm)..."
    
    find "$target_dir" -type d -exec chmod "$dir_perm" {} \;
    find "$target_dir" -type f -exec chmod "$file_perm" {} \;
    
    print_success "Custom permissions applied"
}

# Fix permissions automatically
fix_permissions_auto() {
    show_header
    echo -e "${CYAN}Fix Permissions Automatically${NC}"
    echo ""
    
    read -p "Enter directory path: " target_dir
    
    if [ ! -d "$target_dir" ]; then
        print_error "Directory not found"
        press_any_key
        return
    fi
    
    print_info "Detecting and fixing permissions..."
    
    # Check for WordPress
    if [ -f "$target_dir/wp-config.php" ]; then
        print_info "WordPress detected"
        apply_wordpress_permissions_dir "$target_dir"
        press_any_key
        return
    fi
    
    # Check for Laravel
    if [ -f "$target_dir/artisan" ]; then
        print_info "Laravel detected"
        apply_laravel_permissions_dir "$target_dir"
        press_any_key
        return
    fi
    
    # Apply general secure permissions
    print_info "Applying general secure permissions"
    apply_secure_permissions "$target_dir"
    
    press_any_key
}

# Set custom CHMOD
set_custom_chmod() {
    show_header
    echo -e "${CYAN}Set Custom CHMOD${NC}"
    echo ""
    
    read -p "Enter path (file or directory): " target_path
    
    if [ ! -e "$target_path" ]; then
        print_error "Path not found"
        press_any_key
        return
    fi
    
    read -p "Enter permission (e.g., 755): " permission
    
    if [[ ! "$permission" =~ ^[0-7]{3,4}$ ]]; then
        print_error "Invalid permission format"
        press_any_key
        return
    fi
    
    read -p "Apply recursively? (yes/no): " recursive
    
    if [ "$recursive" = "yes" ]; then
        chmod -R "$permission" "$target_path"
    else
        chmod "$permission" "$target_path"
    fi
    
    print_success "Permission $permission applied to $target_path"
    press_any_key
}

# Change owner
change_owner() {
    show_header
    echo -e "${CYAN}Change Owner${NC}"
    echo ""
    
    read -p "Enter path: " target_path
    
    if [ ! -e "$target_path" ]; then
        print_error "Path not found"
        press_any_key
        return
    fi
    
    read -p "Enter owner (user:group, e.g., www-data:www-data): " owner
    
    if [ -z "$owner" ]; then
        print_error "Owner cannot be empty"
        press_any_key
        return
    fi
    
    read -p "Apply recursively? (yes/no): " recursive
    
    if [ "$recursive" = "yes" ]; then
        chown -R "$owner" "$target_path"
    else
        chown "$owner" "$target_path"
    fi
    
    print_success "Owner changed to $owner for $target_path"
    press_any_key
}

# View permissions
view_permissions() {
    show_header
    echo -e "${CYAN}View Current Permissions${NC}"
    echo ""
    
    read -p "Enter path: " target_path
    
    if [ ! -e "$target_path" ]; then
        print_error "Path not found"
        press_any_key
        return
    fi
    
    echo ""
    echo "Detailed permissions:"
    ls -lah "$target_path"
    
    if [ -d "$target_path" ]; then
        echo ""
        echo "Directory contents:"
        ls -lah "$target_path/" | head -20
    fi
    
    echo ""
    press_any_key
}

# Apply WordPress permissions (menu option)
apply_wordpress_permissions() {
    show_header
    echo -e "${CYAN}Apply WordPress Permissions${NC}"
    echo ""
    
    read -p "Enter WordPress directory path: " wp_dir
    
    if [ ! -d "$wp_dir" ]; then
        print_error "Directory not found"
        press_any_key
        return
    fi
    
    if [ ! -f "$wp_dir/wp-config.php" ]; then
        print_warning "wp-config.php not found. Are you sure this is a WordPress installation?"
        read -p "Continue anyway? (yes/no): " confirm
        if [ "$confirm" != "yes" ]; then
            press_any_key
            return
        fi
    fi
    
    apply_wordpress_permissions_dir "$wp_dir"
    
    # Set owner to www-data
    read -p "Set owner to www-data? (yes/no): " set_owner
    if [ "$set_owner" = "yes" ]; then
        chown -R www-data:www-data "$wp_dir"
        print_success "Owner set to www-data"
    fi
    
    press_any_key
}

# Apply Laravel permissions (menu option)
apply_laravel_permissions() {
    show_header
    echo -e "${CYAN}Apply Laravel Permissions${NC}"
    echo ""
    
    read -p "Enter Laravel project path: " laravel_dir
    
    if [ ! -d "$laravel_dir" ]; then
        print_error "Directory not found"
        press_any_key
        return
    fi
    
    if [ ! -f "$laravel_dir/artisan" ]; then
        print_warning "artisan file not found. Are you sure this is a Laravel project?"
        read -p "Continue anyway? (yes/no): " confirm
        if [ "$confirm" != "yes" ]; then
            press_any_key
            return
        fi
    fi
    
    apply_laravel_permissions_dir "$laravel_dir"
    
    # Set owner to www-data
    read -p "Set owner to www-data? (yes/no): " set_owner
    if [ "$set_owner" = "yes" ]; then
        chown -R www-data:www-data "$laravel_dir"
        print_success "Owner set to www-data"
    fi
    
    press_any_key
}

# Apply general web permissions
apply_web_permissions() {
    show_header
    echo -e "${CYAN}Apply General Web Permissions${NC}"
    echo ""
    
    read -p "Enter web directory path: " web_dir
    
    if [ ! -d "$web_dir" ]; then
        print_error "Directory not found"
        press_any_key
        return
    fi
    
    apply_secure_permissions "$web_dir"
    
    # Set owner to www-data
    read -p "Set owner to www-data? (yes/no): " set_owner
    if [ "$set_owner" = "yes" ]; then
        chown -R www-data:www-data "$web_dir"
        print_success "Owner set to www-data"
    fi
    
    press_any_key
}
