#!/bin/bash

################################################################################
# RocketVPS - Domain Management with Profile Integration
# Version: 2.2.0
# Description: Enhanced domain management with one-click profile setup
################################################################################

# Source required modules
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/profiles.sh" 2>/dev/null || {
    echo "Error: profiles.sh not found"
    exit 1
}

#==============================================================================
# Enhanced Domain Management Menu
#==============================================================================

domain_profiles_menu() {
    while true; do
        clear
        echo "╔════════════════════════════════════════════════════════════════╗"
        echo "║            DOMAIN MANAGEMENT WITH PROFILES v2.2.0             ║"
        echo "╚════════════════════════════════════════════════════════════════╝"
        echo ""
        echo "  🚀 QUICK SETUP (Recommended)"
        echo "  ───────────────────────────────────────────────────────────────"
        echo "  1) Add Domain with Profile"
        echo "     └─ One-click setup: WordPress, Laravel, Node.js, etc."
        echo ""
        echo "  📋 DOMAIN MANAGEMENT"
        echo "  ───────────────────────────────────────────────────────────────"
        echo "  2) List All Domains"
        echo "  3) View Domain Details"
        echo "  4) Delete Domain"
        echo "  5) Enable/Disable Domain"
        echo ""
        echo "  🔧 ADVANCED"
        echo "  ───────────────────────────────────────────────────────────────"
        echo "  6) Add Domain (Manual Setup)"
        echo "  7) Apply Profile to Existing Domain"
        echo "  8) View All Profiles"
        echo ""
        echo "  0) Back to Main Menu"
        echo ""
        echo "────────────────────────────────────────────────────────────────"
        
        read -p "Enter your choice [0-8]: " choice
        
        case $choice in
            1) add_domain_with_profile ;;
            2) list_domains_with_profiles ;;
            3) view_domain_details ;;
            4) delete_domain_with_cleanup ;;
            5) toggle_domain_status ;;
            6) add_domain_manual ;;
            7) apply_profile_to_existing ;;
            8) show_all_profiles_info ;;
            0) return 0 ;;
            *)
                print_error "Invalid choice. Please try again."
                sleep 2
                ;;
        esac
    done
}

#==============================================================================
# Add Domain with Profile (Main Feature)
#==============================================================================

add_domain_with_profile() {
    clear
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║              ADD DOMAIN WITH PROFILE                           ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""
    
    # Step 1: Get domain name
    read -p "📌 Enter domain name (e.g., example.com): " domain_name
    
    if [ -z "$domain_name" ]; then
        print_error "Domain name cannot be empty"
        sleep 2
        return 1
    fi
    
    # Validate domain name format
    if ! [[ "$domain_name" =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z]{2,})+$ ]]; then
        print_error "Invalid domain name format"
        sleep 2
        return 1
    fi
    
    # Check if domain already exists
    if [ -d "/var/www/$domain_name" ]; then
        print_error "Domain $domain_name already exists"
        sleep 2
        return 1
    fi
    
    # Step 2: Show profile selection
    echo ""
    show_profile_menu
    
    read -p "Select profile [1-7]: " profile_choice
    
    local profile=""
    case $profile_choice in
        1) profile="wordpress" ;;
        2) profile="laravel" ;;
        3) profile="nodejs" ;;
        4) profile="static" ;;
        5) profile="ecommerce" ;;
        6) profile="saas" ;;
        7) 
            print_info "Opening manual setup..."
            add_domain_manual
            return 0
            ;;
        *)
            print_error "Invalid profile choice"
            sleep 2
            return 1
            ;;
    esac
    
    # Step 3: Confirm setup
    echo ""
    echo "════════════════════════════════════════════════════════════════"
    print_info "Domain:  $domain_name"
    print_info "Profile: $profile"
    echo "════════════════════════════════════════════════════════════════"
    echo ""
    read -p "Continue with setup? (y/n): " confirm
    
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        print_warning "Setup cancelled"
        sleep 2
        return 0
    fi
    
    # Step 4: Execute profile setup
    echo ""
    print_info "Starting setup... This may take a few minutes."
    echo ""
    
    if execute_profile "$domain_name" "$profile"; then
        # Save profile information
        save_domain_profile_info "$domain_name" "$profile"
        
        echo ""
        print_success "✓ Domain $domain_name successfully set up with $profile profile!"
        echo ""
        
        # Show next steps
        show_next_steps "$domain_name" "$profile"
    else
        print_error "✗ Setup failed! Please check the logs."
    fi
    
    echo ""
    read -p "Press any key to continue..."
}

#==============================================================================
# Save Domain Profile Information
#==============================================================================

save_domain_profile_info() {
    local domain=$1
    local profile=$2
    
    mkdir -p "/opt/rocketvps/config/domains"
    
    cat > "/opt/rocketvps/config/domains/${domain}.info" <<EOF
# Domain Profile Information
DOMAIN="$domain"
PROFILE="$profile"
CREATED_DATE="$(date -Iseconds)"
DOCUMENT_ROOT="/var/www/$domain"
STATUS="active"
EOF
    
    chmod 600 "/opt/rocketvps/config/domains/${domain}.info"
}

#==============================================================================
# List Domains with Profiles
#==============================================================================

list_domains_with_profiles() {
    clear
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║                    ALL DOMAINS                                 ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""
    
    if [ ! -d "/opt/rocketvps/config/domains" ]; then
        print_warning "No domains found"
        echo ""
        read -p "Press any key to continue..."
        return
    fi
    
    # Header
    printf "%-30s %-15s %-10s\n" "DOMAIN" "PROFILE" "STATUS"
    echo "────────────────────────────────────────────────────────────────"
    
    # List all domains
    for domain_file in /opt/rocketvps/config/domains/*.info; do
        if [ -f "$domain_file" ]; then
            source "$domain_file"
            
            # Determine status
            local status_icon="✓"
            local status_color="${GREEN}"
            if [ "$STATUS" != "active" ]; then
                status_icon="✗"
                status_color="${RED}"
            fi
            
            printf "%-30s %-15s ${status_color}%-10s${NC}\n" "$DOMAIN" "$PROFILE" "$status_icon $STATUS"
        fi
    done
    
    echo ""
    read -p "Press any key to continue..."
}

#==============================================================================
# View Domain Details
#==============================================================================

view_domain_details() {
    clear
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║                  DOMAIN DETAILS                                ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""
    
    read -p "Enter domain name: " domain_name
    
    if [ -z "$domain_name" ]; then
        print_error "Domain name cannot be empty"
        sleep 2
        return
    fi
    
    local domain_info="/opt/rocketvps/config/domains/${domain_name}.info"
    
    if [ ! -f "$domain_info" ]; then
        print_error "Domain not found: $domain_name"
        sleep 2
        return
    fi
    
    # Load domain info
    source "$domain_info"
    
    echo "🌐 DOMAIN INFORMATION:"
    echo "   Domain:         $DOMAIN"
    echo "   Profile:        $PROFILE"
    echo "   Status:         $STATUS"
    echo "   Created:        $CREATED_DATE"
    echo "   Document Root:  $DOCUMENT_ROOT"
    echo ""
    
    # Show profile-specific information
    case $PROFILE in
        "wordpress")
            if [ -f "/opt/rocketvps/config/wordpress/${domain_name}_admin.conf" ]; then
                source "/opt/rocketvps/config/wordpress/${domain_name}_admin.conf"
                echo "🔐 WORDPRESS ACCESS:"
                echo "   Admin URL:  $WP_ADMIN_URL"
                echo "   Username:   $WP_ADMIN_USER"
                echo "   Password:   $WP_ADMIN_PASSWORD"
                echo ""
            fi
            ;;
        "laravel"|"nodejs"|"saas")
            echo "📂 APPLICATION PATH:"
            echo "   Path: $DOCUMENT_ROOT"
            echo ""
            ;;
    esac
    
    # Database credentials
    if [ -f "/opt/rocketvps/config/database_credentials/${domain_name}.conf" ]; then
        source "/opt/rocketvps/config/database_credentials/${domain_name}.conf"
        echo "🗄️  DATABASE ACCESS:"
        echo "   Database: ${MYSQL_DATABASE}${PGSQL_DATABASE}"
        echo "   Username: ${MYSQL_USER}${PGSQL_USER}"
        echo "   Password: ${MYSQL_PASSWORD}${PGSQL_PASSWORD}"
        echo "   Host:     ${MYSQL_HOST}${PGSQL_HOST}"
        echo ""
    fi
    
    echo ""
    read -p "Press any key to continue..."
}

#==============================================================================
# Delete Domain with Cleanup
#==============================================================================

delete_domain_with_cleanup() {
    clear
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║                    DELETE DOMAIN                               ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""
    
    read -p "Enter domain name to delete: " domain_name
    
    if [ -z "$domain_name" ]; then
        print_error "Domain name cannot be empty"
        sleep 2
        return
    fi
    
    local domain_info="/opt/rocketvps/config/domains/${domain_name}.info"
    
    if [ ! -f "$domain_info" ]; then
        print_error "Domain not found: $domain_name"
        sleep 2
        return
    fi
    
    # Load domain info
    source "$domain_info"
    
    echo "⚠️  WARNING: This will permanently delete:"
    echo "   - Website files: /var/www/$domain_name"
    echo "   - Database: ${domain_name//./_}"
    echo "   - Nginx configuration"
    echo "   - SSL certificates"
    echo "   - All credentials"
    echo ""
    
    read -p "Type domain name to confirm deletion: " confirm
    
    if [ "$confirm" != "$domain_name" ]; then
        print_warning "Deletion cancelled"
        sleep 2
        return
    fi
    
    print_info "Deleting domain..."
    
    # Delete website files
    rm -rf "/var/www/$domain_name"
    
    # Delete database
    local db_name="${domain_name//./_}"
    mysql -e "DROP DATABASE IF EXISTS \`${db_name}\`;" 2>/dev/null
    mysql -e "DROP USER IF EXISTS '${db_name}'@'localhost';" 2>/dev/null
    sudo -u postgres psql -c "DROP DATABASE IF EXISTS ${db_name};" 2>/dev/null
    sudo -u postgres psql -c "DROP USER IF EXISTS ${db_name};" 2>/dev/null
    
    # Delete Nginx configuration
    rm -f "/etc/nginx/sites-available/${domain_name}"
    rm -f "/etc/nginx/sites-enabled/${domain_name}"
    nginx -s reload 2>/dev/null
    
    # Delete SSL certificates
    certbot delete --cert-name "$domain_name" --non-interactive 2>/dev/null
    
    # Delete credentials
    rm -f "/opt/rocketvps/config/wordpress/${domain_name}_admin.conf"
    rm -f "/opt/rocketvps/config/database_credentials/${domain_name}.conf"
    rm -f "/opt/rocketvps/config/ftp/${domain_name}.conf"
    rm -f "/opt/rocketvps/config/domains/${domain_name}.info"
    
    # Delete backup script
    rm -f "/opt/rocketvps/scripts/backup_${domain_name}.sh"
    crontab -l | grep -v "backup_${domain_name}.sh" | crontab - 2>/dev/null
    
    # Stop PM2 process (for Node.js)
    pm2 delete "$domain_name" 2>/dev/null
    
    # Stop queue workers (for Laravel)
    supervisorctl stop "laravel-worker-${domain_name}:*" 2>/dev/null
    rm -f "/etc/supervisor/conf.d/laravel-worker-${domain_name}.conf"
    
    print_success "Domain $domain_name deleted successfully!"
    sleep 2
}

#==============================================================================
# Toggle Domain Status
#==============================================================================

toggle_domain_status() {
    clear
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║               ENABLE/DISABLE DOMAIN                            ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""
    
    read -p "Enter domain name: " domain_name
    
    if [ -z "$domain_name" ]; then
        print_error "Domain name cannot be empty"
        sleep 2
        return
    fi
    
    local domain_info="/opt/rocketvps/config/domains/${domain_name}.info"
    
    if [ ! -f "$domain_info" ]; then
        print_error "Domain not found: $domain_name"
        sleep 2
        return
    fi
    
    # Load domain info
    source "$domain_info"
    
    if [ "$STATUS" = "active" ]; then
        # Disable domain
        rm -f "/etc/nginx/sites-enabled/${domain_name}"
        sed -i 's/STATUS="active"/STATUS="disabled"/' "$domain_info"
        print_success "Domain $domain_name disabled"
    else
        # Enable domain
        ln -sf "/etc/nginx/sites-available/${domain_name}" "/etc/nginx/sites-enabled/${domain_name}"
        sed -i 's/STATUS="disabled"/STATUS="active"/' "$domain_info"
        print_success "Domain $domain_name enabled"
    fi
    
    nginx -s reload 2>/dev/null
    sleep 2
}

#==============================================================================
# Manual Domain Setup
#==============================================================================

add_domain_manual() {
    print_info "Manual domain setup (legacy mode)"
    print_warning "Consider using profile-based setup for better automation"
    sleep 2
    
    # Call original add_domain function if available
    if command -v add_domain &> /dev/null; then
        add_domain
    else
        print_error "Legacy add_domain function not available"
        sleep 2
    fi
}

#==============================================================================
# Apply Profile to Existing Domain
#==============================================================================

apply_profile_to_existing() {
    clear
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║          APPLY PROFILE TO EXISTING DOMAIN                      ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""
    
    read -p "Enter existing domain name: " domain_name
    
    if [ -z "$domain_name" ]; then
        print_error "Domain name cannot be empty"
        sleep 2
        return
    fi
    
    if [ ! -d "/var/www/$domain_name" ]; then
        print_error "Domain directory not found: /var/www/$domain_name"
        sleep 2
        return
    fi
    
    echo ""
    show_profile_menu
    
    read -p "Select profile to apply [1-7]: " profile_choice
    
    local profile=""
    case $profile_choice in
        1) profile="wordpress" ;;
        2) profile="laravel" ;;
        3) profile="nodejs" ;;
        4) profile="static" ;;
        5) profile="ecommerce" ;;
        6) profile="saas" ;;
        7) return 0 ;;
        *)
            print_error "Invalid profile choice"
            sleep 2
            return
            ;;
    esac
    
    print_warning "⚠️  This will modify the existing domain configuration"
    read -p "Continue? (y/n): " confirm
    
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        print_warning "Operation cancelled"
        sleep 2
        return
    fi
    
    # Execute profile
    if execute_profile "$domain_name" "$profile"; then
        save_domain_profile_info "$domain_name" "$profile"
        print_success "Profile applied successfully!"
    else
        print_error "Profile application failed!"
    fi
    
    sleep 2
}

#==============================================================================
# Show All Profiles Information
#==============================================================================

show_all_profiles_info() {
    clear
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║                  AVAILABLE PROFILES                            ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""
    
    echo "1️⃣  WORDPRESS HOSTING"
    echo "   Perfect for: Blogs, Business Websites, Portfolios"
    echo "   Includes: WordPress + MySQL + phpMyAdmin + SSL + Plugins"
    echo "   Setup Time: ~2-3 minutes"
    echo ""
    
    echo "2️⃣  LARAVEL APPLICATION"
    echo "   Perfect for: Modern PHP APIs, Web Applications"
    echo "   Includes: Laravel + Composer + Queue Workers + Redis"
    echo "   Setup Time: ~3-4 minutes"
    echo ""
    
    echo "3️⃣  NODE.JS APPLICATION"
    echo "   Perfect for: Express, Next.js, Custom Node.js Apps"
    echo "   Includes: Node.js + PM2 + Nginx Reverse Proxy"
    echo "   Setup Time: ~2-3 minutes"
    echo ""
    
    echo "4️⃣  STATIC HTML"
    echo "   Perfect for: Landing Pages, Simple Websites"
    echo "   Includes: Optimized Nginx + Gzip + SSL"
    echo "   Setup Time: ~1-2 minutes"
    echo ""
    
    echo "5️⃣  E-COMMERCE STORE"
    echo "   Perfect for: Online Stores with WooCommerce"
    echo "   Includes: High-Performance PHP + Redis + Payments"
    echo "   Setup Time: ~4-5 minutes"
    echo ""
    
    echo "6️⃣  MULTI-TENANT SAAS"
    echo "   Perfect for: Software-as-a-Service Platforms"
    echo "   Includes: Wildcard DNS + Per-tenant DB + Rate Limiting"
    echo "   Setup Time: ~5-7 minutes"
    echo ""
    
    echo ""
    read -p "Press any key to continue..."
}

#==============================================================================
# Show Next Steps After Setup
#==============================================================================

show_next_steps() {
    local domain=$1
    local profile=$2
    
    echo "📋 NEXT STEPS:"
    echo ""
    
    case $profile in
        "wordpress")
            echo "   1. Visit https://$domain/wp-admin and log in"
            echo "   2. Customize your website appearance"
            echo "   3. Install additional themes/plugins as needed"
            echo "   4. Configure SEO settings (Yoast SEO plugin)"
            ;;
        "laravel")
            echo "   1. SSH into server and navigate to /var/www/$domain"
            echo "   2. Run database migrations: php artisan migrate"
            echo "   3. Configure your application logic"
            echo "   4. Monitor queue workers: supervisorctl status"
            ;;
        "nodejs")
            echo "   1. Upload your Node.js application to /var/www/$domain"
            echo "   2. Update index.js or package.json as needed"
            echo "   3. Restart app: pm2 restart $domain"
            echo "   4. Check logs: pm2 logs $domain"
            ;;
        "static")
            echo "   1. Upload your HTML/CSS/JS files to /var/www/$domain/public"
            echo "   2. Visit https://$domain to see your website"
            echo "   3. Update content as needed via FTP/SSH"
            ;;
        "ecommerce")
            echo "   1. Complete WooCommerce setup wizard"
            echo "   2. Configure payment gateways (Stripe/PayPal)"
            echo "   3. Set up shipping zones and tax settings"
            echo "   4. Add your products and start selling!"
            ;;
        "saas")
            echo "   1. Install multi-tenancy package: composer require spatie/laravel-multitenancy"
            echo "   2. Configure tenant provisioning logic"
            echo "   3. Create first tenant: ./scripts/create-tenant.sh customer1"
            echo "   4. Set up wildcard SSL certificate (requires DNS validation)"
            ;;
    esac
}

# Export functions
export -f add_domain_with_profile
export -f list_domains_with_profiles
export -f view_domain_details
export -f delete_domain_with_cleanup

# Main entry point if script is executed directly
if [ "${BASH_SOURCE[0]}" -eq "$0" ]; then
    domain_profiles_menu
fi
