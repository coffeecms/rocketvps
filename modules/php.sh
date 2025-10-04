#!/bin/bash

################################################################################
# RocketVPS - PHP Management Module
################################################################################

# PHP menu
php_menu() {
    while true; do
        show_header
        echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║                    PHP MANAGEMENT                             ║${NC}"
        echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo "  1) Install PHP Version"
        echo "  2) List Installed PHP Versions"
        echo "  3) Set Default PHP Version"
        echo "  4) Set PHP Version for Domain"
        echo "  5) Configure PHP Settings"
        echo "  6) Install PHP Extensions"
        echo "  7) Remove PHP Version"
        echo "  8) Optimize PHP Configuration"
        echo "  9) View PHP Info"
        echo "  10) Restart PHP-FPM"
        echo ""
        echo "  0) Back to Main Menu"
        echo ""
        echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
        
        read -p "Enter your choice [0-10]: " php_choice
        
        case $php_choice in
            1) install_php_version ;;
            2) list_php_versions ;;
            3) set_default_php ;;
            4) set_domain_php ;;
            5) configure_php ;;
            6) install_php_extensions ;;
            7) remove_php_version ;;
            8) optimize_php ;;
            9) view_php_info ;;
            10) restart_php_fpm ;;
            0) return ;;
            *)
                print_error "Invalid choice"
                sleep 2
                ;;
        esac
    done
}

# Install PHP version
install_php_version() {
    show_header
    echo -e "${CYAN}Install PHP Version${NC}"
    echo ""
    echo "Available PHP versions:"
    echo "  1) PHP 7.4"
    echo "  2) PHP 8.0"
    echo "  3) PHP 8.1"
    echo "  4) PHP 8.2"
    echo "  5) PHP 8.3"
    echo ""
    read -p "Select version to install [1-5]: " version_choice
    
    case $version_choice in
        1) php_version="7.4" ;;
        2) php_version="8.0" ;;
        3) php_version="8.1" ;;
        4) php_version="8.2" ;;
        5) php_version="8.3" ;;
        *)
            print_error "Invalid choice"
            press_any_key
            return
            ;;
    esac
    
    print_info "Installing PHP $php_version..."
    
    if [[ "$OS" == "ubuntu" || "$OS" == "debian" ]]; then
        # Add PHP repository
        apt-get update
        apt-get install -y software-properties-common
        add-apt-repository -y ppa:ondrej/php
        apt-get update
        
        # Install PHP and common extensions
        apt-get install -y \
            php${php_version} \
            php${php_version}-fpm \
            php${php_version}-cli \
            php${php_version}-common \
            php${php_version}-mysql \
            php${php_version}-mysqli \
            php${php_version}-pgsql \
            php${php_version}-zip \
            php${php_version}-gd \
            php${php_version}-mbstring \
            php${php_version}-curl \
            php${php_version}-xml \
            php${php_version}-bcmath \
            php${php_version}-json \
            php${php_version}-redis \
            php${php_version}-memcached \
            php${php_version}-intl \
            php${php_version}-soap \
            php${php_version}-imagick
            
    elif [[ "$OS" == "centos" || "$OS" == "rhel" ]]; then
        # Add Remi repository
        yum install -y epel-release
        yum install -y https://rpms.remirepo.net/enterprise/remi-release-${VER}.rpm
        
        yum-config-manager --enable remi-php${php_version/./}
        
        yum install -y \
            php \
            php-fpm \
            php-cli \
            php-common \
            php-mysqlnd \
            php-pgsql \
            php-zip \
            php-gd \
            php-mbstring \
            php-curl \
            php-xml \
            php-bcmath \
            php-json \
            php-redis \
            php-memcached \
            php-intl \
            php-soap \
            php-imagick
    fi
    
    # Configure PHP-FPM
    configure_php_fpm "$php_version"
    
    # Enable and start PHP-FPM
    systemctl enable php${php_version}-fpm
    systemctl start php${php_version}-fpm
    
    # Add to installed versions
    echo "$php_version" >> "${PHP_VERSIONS_FILE}"
    sort -u "${PHP_VERSIONS_FILE}" -o "${PHP_VERSIONS_FILE}"
    
    if systemctl is-active --quiet php${php_version}-fpm; then
        print_success "PHP $php_version installed successfully"
        php${php_version} -v
    else
        print_error "PHP $php_version installation failed"
    fi
    
    press_any_key
}

# Configure PHP-FPM
configure_php_fpm() {
    local version=$1
    local fpm_conf="/etc/php/${version}/fpm/php-fpm.conf"
    local pool_conf="/etc/php/${version}/fpm/pool.d/www.conf"
    
    if [ ! -f "$pool_conf" ]; then
        pool_conf="/etc/php-fpm.d/www.conf"
    fi
    
    if [ -f "$pool_conf" ]; then
        # Backup original
        cp "$pool_conf" "${pool_conf}.bak"
        
        # Optimize pool configuration
        sed -i 's/^pm = .*/pm = dynamic/' "$pool_conf"
        sed -i 's/^pm.max_children = .*/pm.max_children = 50/' "$pool_conf"
        sed -i 's/^pm.start_servers = .*/pm.start_servers = 5/' "$pool_conf"
        sed -i 's/^pm.min_spare_servers = .*/pm.min_spare_servers = 5/' "$pool_conf"
        sed -i 's/^pm.max_spare_servers = .*/pm.max_spare_servers = 35/' "$pool_conf"
        sed -i 's/^;pm.max_requests = .*/pm.max_requests = 500/' "$pool_conf"
    fi
    
    # Optimize PHP.ini
    local php_ini="/etc/php/${version}/fpm/php.ini"
    if [ ! -f "$php_ini" ]; then
        php_ini="/etc/php.ini"
    fi
    
    if [ -f "$php_ini" ]; then
        cp "$php_ini" "${php_ini}.bak"
        
        sed -i 's/^memory_limit = .*/memory_limit = 256M/' "$php_ini"
        sed -i 's/^upload_max_filesize = .*/upload_max_filesize = 100M/' "$php_ini"
        sed -i 's/^post_max_size = .*/post_max_size = 100M/' "$php_ini"
        sed -i 's/^max_execution_time = .*/max_execution_time = 300/' "$php_ini"
        sed -i 's/^max_input_time = .*/max_input_time = 300/' "$php_ini"
        sed -i 's/^;date.timezone =.*/date.timezone = UTC/' "$php_ini"
        sed -i 's/^expose_php = .*/expose_php = Off/' "$php_ini"
    fi
}

# List installed PHP versions
list_php_versions() {
    show_header
    echo -e "${CYAN}Installed PHP Versions:${NC}"
    echo ""
    
    if [ ! -s "${PHP_VERSIONS_FILE}" ]; then
        # Try to detect installed versions
        for version in 7.4 8.0 8.1 8.2 8.3; do
            if command -v php${version} &> /dev/null; then
                echo "$version" >> "${PHP_VERSIONS_FILE}"
            fi
        done
        sort -u "${PHP_VERSIONS_FILE}" -o "${PHP_VERSIONS_FILE}"
    fi
    
    if [ ! -s "${PHP_VERSIONS_FILE}" ]; then
        print_warning "No PHP versions found"
    else
        while read -r version; do
            if command -v php${version} &> /dev/null; then
                status="✓ Active"
                if systemctl is-active --quiet php${version}-fpm; then
                    status="✓ Active (Running)"
                fi
                echo "  PHP $version - $status"
                php${version} -v | head -1
                echo ""
            fi
        done < "${PHP_VERSIONS_FILE}"
    fi
    
    # Show default version
    if command -v php &> /dev/null; then
        echo -e "${CYAN}Default PHP Version:${NC}"
        php -v | head -1
    fi
    
    echo ""
    press_any_key
}

# Set default PHP version
set_default_php() {
    list_php_versions
    echo ""
    read -p "Enter PHP version to set as default (e.g., 8.2): " php_version
    
    if ! command -v php${php_version} &> /dev/null; then
        print_error "PHP $php_version is not installed"
        press_any_key
        return
    fi
    
    # Update alternatives
    if command -v update-alternatives &> /dev/null; then
        update-alternatives --set php /usr/bin/php${php_version}
        update-alternatives --set phar /usr/bin/phar${php_version}
        update-alternatives --set phar.phar /usr/bin/phar.phar${php_version}
        
        print_success "Default PHP version set to $php_version"
        php -v | head -1
    else
        # Create symlinks for CentOS/RHEL
        ln -sf /usr/bin/php${php_version} /usr/bin/php
        print_success "Default PHP version set to $php_version"
    fi
    
    press_any_key
}

# Set PHP version for domain
set_domain_php() {
    list_domains
    echo ""
    read -p "Enter domain name: " domain_name
    
    if [ ! -f "${NGINX_VHOST_DIR}/${domain_name}" ]; then
        print_error "Domain $domain_name not found"
        press_any_key
        return
    fi
    
    list_php_versions
    echo ""
    read -p "Enter PHP version for $domain_name (e.g., 8.2): " php_version
    
    if ! command -v php${php_version} &> /dev/null; then
        print_error "PHP $php_version is not installed"
        press_any_key
        return
    fi
    
    local php_socket="/var/run/php/php${php_version}-fpm.sock"
    
    # Update domain configuration
    sed -i "s|fastcgi_pass unix:/var/run/php/php.*-fpm.sock;|fastcgi_pass unix:${php_socket};|g" \
        "${NGINX_VHOST_DIR}/${domain_name}"
    
    if nginx -t; then
        systemctl reload nginx
        print_success "PHP $php_version set for domain $domain_name"
    else
        print_error "Nginx configuration test failed"
    fi
    
    press_any_key
}

# Configure PHP settings
configure_php() {
    list_php_versions
    echo ""
    read -p "Enter PHP version to configure (e.g., 8.2): " php_version
    
    local php_ini="/etc/php/${php_version}/fpm/php.ini"
    if [ ! -f "$php_ini" ]; then
        php_ini="/etc/php.ini"
    fi
    
    if [ ! -f "$php_ini" ]; then
        print_error "PHP configuration file not found for version $php_version"
        press_any_key
        return
    fi
    
    show_header
    echo -e "${CYAN}PHP $php_version Configuration${NC}"
    echo ""
    echo "1) Set Memory Limit"
    echo "2) Set Upload Max File Size"
    echo "3) Set Max Execution Time"
    echo "4) Set Timezone"
    echo "5) Edit php.ini Directly"
    echo "0) Back"
    echo ""
    read -p "Enter choice: " config_choice
    
    case $config_choice in
        1)
            read -p "Enter memory limit (e.g., 256M): " mem_limit
            sed -i "s/^memory_limit = .*/memory_limit = $mem_limit/" "$php_ini"
            print_success "Memory limit set to $mem_limit"
            ;;
        2)
            read -p "Enter max upload size (e.g., 100M): " upload_size
            sed -i "s/^upload_max_filesize = .*/upload_max_filesize = $upload_size/" "$php_ini"
            sed -i "s/^post_max_size = .*/post_max_size = $upload_size/" "$php_ini"
            print_success "Max upload size set to $upload_size"
            ;;
        3)
            read -p "Enter max execution time in seconds (e.g., 300): " exec_time
            sed -i "s/^max_execution_time = .*/max_execution_time = $exec_time/" "$php_ini"
            print_success "Max execution time set to $exec_time seconds"
            ;;
        4)
            read -p "Enter timezone (e.g., UTC, Asia/Ho_Chi_Minh): " timezone
            sed -i "s|^;date.timezone =.*|date.timezone = $timezone|" "$php_ini"
            sed -i "s|^date.timezone =.*|date.timezone = $timezone|" "$php_ini"
            print_success "Timezone set to $timezone"
            ;;
        5)
            ${EDITOR:-nano} "$php_ini"
            ;;
        0) return ;;
    esac
    
    systemctl restart php${php_version}-fpm
    print_info "PHP-FPM restarted"
    
    press_any_key
}

# Install PHP extensions
install_php_extensions() {
    list_php_versions
    echo ""
    read -p "Enter PHP version (e.g., 8.2): " php_version
    
    if ! command -v php${php_version} &> /dev/null; then
        print_error "PHP $php_version is not installed"
        press_any_key
        return
    fi
    
    show_header
    echo -e "${CYAN}Install PHP Extensions${NC}"
    echo ""
    echo "Enter extension names separated by space"
    echo "Example: redis memcached imagick gd"
    echo ""
    read -p "Extensions: " extensions
    
    if [ -z "$extensions" ]; then
        print_error "No extensions specified"
        press_any_key
        return
    fi
    
    print_info "Installing extensions for PHP $php_version..."
    
    for ext in $extensions; do
        if [[ "$OS" == "ubuntu" || "$OS" == "debian" ]]; then
            apt-get install -y php${php_version}-${ext}
        elif [[ "$OS" == "centos" || "$OS" == "rhel" ]]; then
            yum install -y php-${ext}
        fi
    done
    
    systemctl restart php${php_version}-fpm
    
    print_success "Extensions installed and PHP-FPM restarted"
    press_any_key
}

# Remove PHP version
remove_php_version() {
    list_php_versions
    echo ""
    read -p "Enter PHP version to remove (e.g., 8.0): " php_version
    
    if ! command -v php${php_version} &> /dev/null; then
        print_error "PHP $php_version is not installed"
        press_any_key
        return
    fi
    
    print_warning "This will remove PHP $php_version and all its extensions!"
    read -p "Are you sure? (yes/no): " confirm
    
    if [ "$confirm" != "yes" ]; then
        print_info "Removal cancelled"
        press_any_key
        return
    fi
    
    systemctl stop php${php_version}-fpm
    systemctl disable php${php_version}-fpm
    
    if [[ "$OS" == "ubuntu" || "$OS" == "debian" ]]; then
        apt-get remove --purge -y php${php_version}*
        apt-get autoremove -y
    elif [[ "$OS" == "centos" || "$OS" == "rhel" ]]; then
        yum remove -y php${php_version}*
    fi
    
    # Remove from versions file
    sed -i "/^${php_version}$/d" "${PHP_VERSIONS_FILE}"
    
    print_success "PHP $php_version removed successfully"
    press_any_key
}

# Optimize PHP
optimize_php() {
    list_php_versions
    echo ""
    read -p "Enter PHP version to optimize (e.g., 8.2): " php_version
    
    if ! command -v php${php_version} &> /dev/null; then
        print_error "PHP $php_version is not installed"
        press_any_key
        return
    fi
    
    print_info "Optimizing PHP $php_version..."
    
    # Calculate optimal settings based on system resources
    local total_mem=$(free -m | awk '/^Mem:/{print $2}')
    local cpu_cores=$(nproc)
    
    # Calculate optimal PHP-FPM settings
    local max_children=$((cpu_cores * 5))
    local start_servers=$((cpu_cores + 1))
    local min_spare=$cpu_cores
    local max_spare=$((cpu_cores * 3))
    
    local pool_conf="/etc/php/${php_version}/fpm/pool.d/www.conf"
    if [ ! -f "$pool_conf" ]; then
        pool_conf="/etc/php-fpm.d/www.conf"
    fi
    
    if [ -f "$pool_conf" ]; then
        sed -i "s/^pm.max_children = .*/pm.max_children = $max_children/" "$pool_conf"
        sed -i "s/^pm.start_servers = .*/pm.start_servers = $start_servers/" "$pool_conf"
        sed -i "s/^pm.min_spare_servers = .*/pm.min_spare_servers = $min_spare/" "$pool_conf"
        sed -i "s/^pm.max_spare_servers = .*/pm.max_spare_servers = $max_spare/" "$pool_conf"
        sed -i "s/^;pm.max_requests = .*/pm.max_requests = 500/" "$pool_conf"
    fi
    
    # Optimize PHP.ini
    local php_ini="/etc/php/${php_version}/fpm/php.ini"
    if [ ! -f "$php_ini" ]; then
        php_ini="/etc/php.ini"
    fi
    
    if [ -f "$php_ini" ]; then
        sed -i 's/^;opcache.enable=.*/opcache.enable=1/' "$php_ini"
        sed -i 's/^;opcache.memory_consumption=.*/opcache.memory_consumption=128/' "$php_ini"
        sed -i 's/^;opcache.interned_strings_buffer=.*/opcache.interned_strings_buffer=8/' "$php_ini"
        sed -i 's/^;opcache.max_accelerated_files=.*/opcache.max_accelerated_files=10000/' "$php_ini"
        sed -i 's/^;opcache.validate_timestamps=.*/opcache.validate_timestamps=0/' "$php_ini"
        sed -i 's/^;opcache.save_comments=.*/opcache.save_comments=1/' "$php_ini"
    fi
    
    systemctl restart php${php_version}-fpm
    
    print_success "PHP $php_version optimized"
    print_info "Max children: $max_children"
    print_info "Start servers: $start_servers"
    print_info "OPcache enabled"
    
    press_any_key
}

# View PHP info
view_php_info() {
    read -p "Enter domain to view PHP info (or leave empty for CLI): " domain_name
    
    if [ -z "$domain_name" ]; then
        # Show CLI PHP info
        show_header
        php -i | less
    else
        # Create phpinfo file for domain
        if [ -f "${NGINX_VHOST_DIR}/${domain_name}" ]; then
            local doc_root=$(grep "root " "${NGINX_VHOST_DIR}/${domain_name}" | head -1 | awk '{print $2}' | tr -d ';')
            
            echo "<?php phpinfo(); ?>" > "${doc_root}/phpinfo.php"
            
            print_success "PHP info created at http://${domain_name}/phpinfo.php"
            print_warning "Remember to delete this file after viewing for security!"
        else
            print_error "Domain not found"
        fi
    fi
    
    press_any_key
}

# Restart PHP-FPM
restart_php_fpm() {
    list_php_versions
    echo ""
    read -p "Enter PHP version to restart (or 'all' for all): " php_version
    
    if [ "$php_version" = "all" ]; then
        if [ -s "${PHP_VERSIONS_FILE}" ]; then
            while read -r version; do
                if systemctl is-active --quiet php${version}-fpm; then
                    systemctl restart php${version}-fpm
                    print_success "PHP $version-FPM restarted"
                fi
            done < "${PHP_VERSIONS_FILE}"
        fi
    else
        if ! command -v php${php_version} &> /dev/null; then
            print_error "PHP $php_version is not installed"
            press_any_key
            return
        fi
        
        systemctl restart php${php_version}-fpm
        
        if systemctl is-active --quiet php${php_version}-fpm; then
            print_success "PHP $php_version-FPM restarted"
        else
            print_error "Failed to restart PHP $php_version-FPM"
        fi
    fi
    
    press_any_key
}
