#!/bin/bash

################################################################################
# RocketVPS - Auto Database Setup Module
# Automatic installation of MySQL, PostgreSQL, ProxySQL
# Automatic database/user creation for new domains
################################################################################

DB_CREDENTIALS_DIR="${CONFIG_DIR}/database_credentials"
MYSQL_ROOT_PASSWORD_FILE="${CONFIG_DIR}/mysql_root_password"
POSTGRESQL_PASSWORD_FILE="${CONFIG_DIR}/postgresql_password"

# Initialize database credentials directory
init_db_credentials_dir() {
    mkdir -p "$DB_CREDENTIALS_DIR"
    chmod 700 "$DB_CREDENTIALS_DIR"
}

# Auto-install all databases on first run
auto_install_databases() {
    show_header
    print_info "RocketVPS Initial Database Setup"
    echo ""
    print_info "This will automatically install:"
    echo "  - MySQL/MariaDB"
    echo "  - PostgreSQL"
    echo "  - ProxySQL"
    echo ""
    
    read -p "Proceed with automatic database installation? (y/n): " proceed
    
    if [[ ! "$proceed" =~ ^[Yy]$ ]]; then
        print_warning "Database installation skipped"
        return
    fi
    
    # Install MySQL/MariaDB
    print_info "Installing MySQL/MariaDB..."
    auto_install_mysql
    
    # Install PostgreSQL
    print_info "Installing PostgreSQL..."
    auto_install_postgresql
    
    # Install ProxySQL
    print_info "Installing ProxySQL..."
    auto_install_proxysql
    
    # Mark as installed
    touch "${CONFIG_DIR}/.databases_installed"
    
    print_success "All databases installed successfully!"
    echo ""
    print_info "Credentials saved in: ${DB_CREDENTIALS_DIR}/"
    echo ""
    press_any_key
}

# Auto-install MySQL
auto_install_mysql() {
    # Check if already installed
    if command -v mysql &> /dev/null; then
        print_warning "MySQL already installed"
        return
    fi
    
    # Generate random root password
    local mysql_root_pass=$(openssl rand -base64 24)
    
    # Install based on OS
    if [[ "$OS" == "ubuntu" || "$OS" == "debian" ]]; then
        # Set non-interactive mode
        export DEBIAN_FRONTEND=noninteractive
        
        # Pre-configure MySQL root password
        debconf-set-selections <<< "mysql-server mysql-server/root_password password $mysql_root_pass"
        debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $mysql_root_pass"
        
        apt-get update
        apt-get install -y mariadb-server mariadb-client
        
    elif [[ "$OS" == "centos" || "$OS" == "rhel" ]]; then
        yum install -y mariadb-server mariadb
        systemctl start mariadb
        systemctl enable mariadb
        
        # Secure installation
        mysql -e "UPDATE mysql.user SET Password=PASSWORD('${mysql_root_pass}') WHERE User='root';"
        mysql -e "DELETE FROM mysql.user WHERE User='';"
        mysql -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
        mysql -e "DROP DATABASE IF EXISTS test;"
        mysql -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';"
        mysql -e "FLUSH PRIVILEGES;"
    fi
    
    # Start and enable service
    systemctl start mysql 2>/dev/null || systemctl start mariadb
    systemctl enable mysql 2>/dev/null || systemctl enable mariadb
    
    # Save root password
    echo "$mysql_root_pass" > "$MYSQL_ROOT_PASSWORD_FILE"
    chmod 600 "$MYSQL_ROOT_PASSWORD_FILE"
    
    # Create .my.cnf for easy root access
    cat > /root/.my.cnf <<EOF
[client]
user=root
password=${mysql_root_pass}
EOF
    chmod 600 /root/.my.cnf
    
    print_success "MySQL installed with root password saved"
}

# Auto-install PostgreSQL
auto_install_postgresql() {
    # Check if already installed
    if command -v psql &> /dev/null; then
        print_warning "PostgreSQL already installed"
        return
    fi
    
    # Generate random postgres password
    local postgres_pass=$(openssl rand -base64 24)
    
    # Install based on OS
    if [[ "$OS" == "ubuntu" || "$OS" == "debian" ]]; then
        apt-get update
        apt-get install -y postgresql postgresql-contrib
        
    elif [[ "$OS" == "centos" || "$OS" == "rhel" ]]; then
        yum install -y postgresql-server postgresql-contrib
        postgresql-setup initdb
    fi
    
    # Start and enable service
    systemctl start postgresql
    systemctl enable postgresql
    
    # Set postgres user password
    sudo -u postgres psql -c "ALTER USER postgres PASSWORD '${postgres_pass}';"
    
    # Configure authentication
    local pg_hba_conf=$(sudo -u postgres psql -t -P format=unaligned -c 'SHOW hba_file;')
    
    # Backup original
    cp "$pg_hba_conf" "${pg_hba_conf}.backup"
    
    # Allow md5 authentication
    sed -i 's/local.*all.*all.*peer/local   all             all                                     md5/' "$pg_hba_conf"
    sed -i 's/host.*all.*all.*127.0.0.1\/32.*ident/host    all             all             127.0.0.1\/32            md5/' "$pg_hba_conf"
    
    # Reload PostgreSQL
    systemctl reload postgresql
    
    # Save password
    echo "$postgres_pass" > "$POSTGRESQL_PASSWORD_FILE"
    chmod 600 "$POSTGRESQL_PASSWORD_FILE"
    
    # Create .pgpass for easy access
    cat > /root/.pgpass <<EOF
localhost:5432:*:postgres:${postgres_pass}
EOF
    chmod 600 /root/.pgpass
    
    print_success "PostgreSQL installed with postgres password saved"
}

# Auto-install ProxySQL
auto_install_proxysql() {
    # Check if already installed
    if command -v proxysql &> /dev/null; then
        print_warning "ProxySQL already installed"
        return
    fi
    
    # Install MySQL client if needed
    if ! command -v mysql &> /dev/null; then
        if [[ "$OS" == "ubuntu" || "$OS" == "debian" ]]; then
            apt-get install -y mysql-client
        elif [[ "$OS" == "centos" || "$OS" == "rhel" ]]; then
            yum install -y mysql
        fi
    fi
    
    # Install ProxySQL
    if [[ "$OS" == "ubuntu" || "$OS" == "debian" ]]; then
        apt-get install -y lsb-release wget
        wget -O - 'https://repo.proxysql.com/ProxySQL/proxysql-2.5.x/repo_pub_key' | apt-key add -
        echo "deb https://repo.proxysql.com/ProxySQL/proxysql-2.5.x/$(lsb_release -sc)/ ./" \
            > /etc/apt/sources.list.d/proxysql.list
        apt-get update
        apt-get install -y proxysql
        
    elif [[ "$OS" == "centos" || "$OS" == "rhel" ]]; then
        cat > /etc/yum.repos.d/proxysql.repo <<'EOF'
[proxysql]
name=ProxySQL YUM repository
baseurl=https://repo.proxysql.com/ProxySQL/proxysql-2.5.x/centos/$releasever
gpgcheck=1
gpgkey=https://repo.proxysql.com/ProxySQL/proxysql-2.5.x/repo_pub_key
EOF
        yum install -y proxysql
    fi
    
    # Generate random admin password
    local admin_password=$(openssl rand -base64 16)
    local monitor_password=$(openssl rand -base64 16)
    
    # Start ProxySQL
    systemctl start proxysql
    systemctl enable proxysql
    
    sleep 3
    
    # Configure ProxySQL
    mysql -h127.0.0.1 -P6032 -uadmin -padmin <<EOF
UPDATE global_variables SET variable_value='admin:${admin_password}' WHERE variable_name='admin-admin_credentials';
UPDATE global_variables SET variable_value='${monitor_password}' WHERE variable_name='mysql-monitor_password';
LOAD ADMIN VARIABLES TO RUNTIME;
SAVE ADMIN VARIABLES TO DISK;
LOAD MYSQL VARIABLES TO RUNTIME;
SAVE MYSQL VARIABLES TO DISK;
EOF

    # Save ProxySQL config
    local proxysql_config="${CONFIG_DIR}/proxysql.conf"
    cat > "$proxysql_config" <<EOF
ADMIN_USER=admin
ADMIN_PASSWORD=${admin_password}
ADMIN_PORT=6032
MYSQL_PORT=6033
MONITOR_PASSWORD=${monitor_password}
INSTALLED_DATE=$(date +%Y-%m-%d)
EOF
    chmod 600 "$proxysql_config"
    
    # Add local MySQL to ProxySQL backend
    local mysql_root_pass=$(cat "$MYSQL_ROOT_PASSWORD_FILE")
    
    mysql -h127.0.0.1 -P6032 -uadmin -p"${admin_password}" <<EOF
-- Add MySQL backend server (localhost)
INSERT INTO mysql_servers(hostgroup_id, hostname, port, weight) 
VALUES (0, '127.0.0.1', 3306, 1);

-- Add root user for ProxySQL
INSERT INTO mysql_users(username, password, default_hostgroup, active) 
VALUES ('root', '${mysql_root_pass}', 0, 1);

LOAD MYSQL SERVERS TO RUNTIME;
SAVE MYSQL SERVERS TO DISK;
LOAD MYSQL USERS TO RUNTIME;
SAVE MYSQL USERS TO DISK;
EOF

    print_success "ProxySQL installed and configured"
}

# Auto-create database accounts for a domain
auto_create_domain_databases() {
    local domain_name=$1
    
    if [ -z "$domain_name" ]; then
        print_error "Domain name required"
        return 1
    fi
    
    # Clean domain name for database naming (remove dots, dashes)
    local db_name=$(echo "$domain_name" | sed 's/[.-]/_/g' | cut -c1-64)
    local db_user="${db_name}"
    local db_password=$(openssl rand -base64 16)
    
    init_db_credentials_dir
    
    local cred_file="${DB_CREDENTIALS_DIR}/${domain_name}.conf"
    
    print_info "Creating database accounts for domain: ${domain_name}"
    echo ""
    
    # Create MySQL database and user
    print_info "Creating MySQL database..."
    if create_mysql_database "$db_name" "$db_user" "$db_password"; then
        echo "MYSQL_DB_NAME=${db_name}" >> "$cred_file"
        echo "MYSQL_DB_USER=${db_user}" >> "$cred_file"
        echo "MYSQL_DB_PASSWORD=${db_password}" >> "$cred_file"
        print_success "MySQL database created: ${db_name}"
    fi
    
    # Create PostgreSQL database and user
    print_info "Creating PostgreSQL database..."
    if create_postgresql_database "$db_name" "$db_user" "$db_password"; then
        echo "POSTGRESQL_DB_NAME=${db_name}" >> "$cred_file"
        echo "POSTGRESQL_DB_USER=${db_user}" >> "$cred_file"
        echo "POSTGRESQL_DB_PASSWORD=${db_password}" >> "$cred_file"
        print_success "PostgreSQL database created: ${db_name}"
    fi
    
    # Add user to ProxySQL
    print_info "Adding user to ProxySQL..."
    if add_proxysql_user "$db_user" "$db_password"; then
        echo "PROXYSQL_USER=${db_user}" >> "$cred_file"
        echo "PROXYSQL_PASSWORD=${db_password}" >> "$cred_file"
        echo "PROXYSQL_HOST=127.0.0.1" >> "$cred_file"
        echo "PROXYSQL_PORT=6033" >> "$cred_file"
        print_success "ProxySQL user added: ${db_user}"
    fi
    
    # Set file permissions
    chmod 600 "$cred_file"
    
    # Save metadata
    echo "DOMAIN=${domain_name}" >> "$cred_file"
    echo "CREATED_DATE=$(date '+%Y-%m-%d %H:%M:%S')" >> "$cred_file"
    
    return 0
}

# Create MySQL database and user
create_mysql_database() {
    local db_name=$1
    local db_user=$2
    local db_password=$3
    
    # Check if MySQL is installed
    if ! command -v mysql &> /dev/null; then
        print_warning "MySQL not installed, skipping"
        return 1
    fi
    
    # Create database
    mysql -e "CREATE DATABASE IF NOT EXISTS \`${db_name}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" 2>/dev/null
    
    if [ $? -ne 0 ]; then
        print_error "Failed to create MySQL database"
        return 1
    fi
    
    # Create user and grant privileges
    mysql <<EOF
CREATE USER IF NOT EXISTS '${db_user}'@'localhost' IDENTIFIED BY '${db_password}';
GRANT ALL PRIVILEGES ON \`${db_name}\`.* TO '${db_user}'@'localhost';
CREATE USER IF NOT EXISTS '${db_user}'@'%' IDENTIFIED BY '${db_password}';
GRANT ALL PRIVILEGES ON \`${db_name}\`.* TO '${db_user}'@'%';
FLUSH PRIVILEGES;
EOF

    return 0
}

# Create PostgreSQL database and user
create_postgresql_database() {
    local db_name=$1
    local db_user=$2
    local db_password=$3
    
    # Check if PostgreSQL is installed
    if ! command -v psql &> /dev/null; then
        print_warning "PostgreSQL not installed, skipping"
        return 1
    fi
    
    # Create user
    sudo -u postgres psql <<EOF
-- Create user if not exists
DO \$\$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_user WHERE usename = '${db_user}') THEN
        CREATE USER ${db_user} WITH PASSWORD '${db_password}';
    END IF;
END
\$\$;

-- Create database
CREATE DATABASE ${db_name} OWNER ${db_user};

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE ${db_name} TO ${db_user};
EOF

    if [ $? -ne 0 ]; then
        print_error "Failed to create PostgreSQL database"
        return 1
    fi
    
    return 0
}

# Add user to ProxySQL
add_proxysql_user() {
    local db_user=$1
    local db_password=$2
    
    # Check if ProxySQL is installed
    if ! command -v proxysql &> /dev/null; then
        print_warning "ProxySQL not installed, skipping"
        return 1
    fi
    
    # Read ProxySQL admin credentials
    local proxysql_config="${CONFIG_DIR}/proxysql.conf"
    if [ ! -f "$proxysql_config" ]; then
        print_warning "ProxySQL config not found, skipping"
        return 1
    fi
    
    source "$proxysql_config"
    
    # Add user to ProxySQL
    mysql -h127.0.0.1 -P"$ADMIN_PORT" -u"$ADMIN_USER" -p"$ADMIN_PASSWORD" <<EOF
INSERT INTO mysql_users(username, password, default_hostgroup, active) 
VALUES ('${db_user}', '${db_password}', 0, 1)
ON DUPLICATE KEY UPDATE password='${db_password}';

LOAD MYSQL USERS TO RUNTIME;
SAVE MYSQL USERS TO DISK;
EOF

    if [ $? -ne 0 ]; then
        print_error "Failed to add user to ProxySQL"
        return 1
    fi
    
    return 0
}

# Display database credentials for a domain
display_domain_database_info() {
    local domain_name=$1
    
    local cred_file="${DB_CREDENTIALS_DIR}/${domain_name}.conf"
    
    if [ ! -f "$cred_file" ]; then
        print_warning "No database credentials found for domain: ${domain_name}"
        return 1
    fi
    
    # Load credentials
    source "$cred_file"
    
    # Display beautiful formatted output
    echo ""
    echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║          DATABASE CREDENTIALS FOR ${domain_name}              ${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # MySQL Information
    if [ -n "$MYSQL_DB_NAME" ]; then
        echo -e "${CYAN}═══ MySQL Database ═══${NC}"
        echo -e "  ${YELLOW}Database Name:${NC}    ${MYSQL_DB_NAME}"
        echo -e "  ${YELLOW}Username:${NC}         ${MYSQL_DB_USER}"
        echo -e "  ${YELLOW}Password:${NC}         ${MYSQL_DB_PASSWORD}"
        echo -e "  ${YELLOW}Host:${NC}             localhost"
        echo -e "  ${YELLOW}Port:${NC}             3306"
        echo ""
        echo -e "  ${GREEN}Connection String:${NC}"
        echo -e "  mysql -u${MYSQL_DB_USER} -p'${MYSQL_DB_PASSWORD}' ${MYSQL_DB_NAME}"
        echo ""
        echo -e "  ${GREEN}PHP Connection (mysqli):${NC}"
        echo -e "  \$conn = new mysqli('localhost', '${MYSQL_DB_USER}', '${MYSQL_DB_PASSWORD}', '${MYSQL_DB_NAME}');"
        echo ""
    fi
    
    # PostgreSQL Information
    if [ -n "$POSTGRESQL_DB_NAME" ]; then
        echo -e "${CYAN}═══ PostgreSQL Database ═══${NC}"
        echo -e "  ${YELLOW}Database Name:${NC}    ${POSTGRESQL_DB_NAME}"
        echo -e "  ${YELLOW}Username:${NC}         ${POSTGRESQL_DB_USER}"
        echo -e "  ${YELLOW}Password:${NC}         ${POSTGRESQL_DB_PASSWORD}"
        echo -e "  ${YELLOW}Host:${NC}             localhost"
        echo -e "  ${YELLOW}Port:${NC}             5432"
        echo ""
        echo -e "  ${GREEN}Connection String:${NC}"
        echo -e "  psql -U ${POSTGRESQL_DB_USER} -d ${POSTGRESQL_DB_NAME}"
        echo ""
        echo -e "  ${GREEN}PHP Connection (PDO):${NC}"
        echo -e "  \$conn = new PDO('pgsql:host=localhost;dbname=${POSTGRESQL_DB_NAME}', '${POSTGRESQL_DB_USER}', '${POSTGRESQL_DB_PASSWORD}');"
        echo ""
    fi
    
    # ProxySQL Information
    if [ -n "$PROXYSQL_USER" ]; then
        echo -e "${CYAN}═══ ProxySQL Connection ═══${NC}"
        echo -e "  ${YELLOW}Username:${NC}         ${PROXYSQL_USER}"
        echo -e "  ${YELLOW}Password:${NC}         ${PROXYSQL_PASSWORD}"
        echo -e "  ${YELLOW}Host:${NC}             ${PROXYSQL_HOST}"
        echo -e "  ${YELLOW}Port:${NC}             ${PROXYSQL_PORT}"
        echo ""
        echo -e "  ${GREEN}Connection String:${NC}"
        echo -e "  mysql -h${PROXYSQL_HOST} -P${PROXYSQL_PORT} -u${PROXYSQL_USER} -p'${PROXYSQL_PASSWORD}' ${MYSQL_DB_NAME}"
        echo ""
        echo -e "  ${GREEN}PHP Connection via ProxySQL:${NC}"
        echo -e "  \$conn = new mysqli('${PROXYSQL_HOST}', '${PROXYSQL_USER}', '${PROXYSQL_PASSWORD}', '${MYSQL_DB_NAME}', ${PROXYSQL_PORT});"
        echo ""
    fi
    
    echo -e "${CYAN}═══ Additional Information ═══${NC}"
    echo -e "  ${YELLOW}Domain:${NC}           ${DOMAIN}"
    echo -e "  ${YELLOW}Created:${NC}          ${CREATED_DATE}"
    echo -e "  ${YELLOW}Credentials File:${NC} ${cred_file}"
    echo ""
    
    echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║  ${YELLOW}⚠ IMPORTANT: Save these credentials securely!${GREEN}              ║${NC}"
    echo -e "${GREEN}║  Credentials are stored in: ${cred_file}  ${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    return 0
}

# List all domain database credentials
list_all_domain_databases() {
    show_header
    echo -e "${CYAN}All Domain Database Credentials${NC}"
    echo ""
    
    if [ ! -d "$DB_CREDENTIALS_DIR" ] || [ -z "$(ls -A $DB_CREDENTIALS_DIR 2>/dev/null)" ]; then
        print_warning "No domain database credentials found"
        press_any_key
        return
    fi
    
    echo -e "${YELLOW}Domain${NC}                          ${YELLOW}MySQL DB${NC}              ${YELLOW}PostgreSQL DB${NC}"
    echo "─────────────────────────────────────────────────────────────────"
    
    for cred_file in "$DB_CREDENTIALS_DIR"/*.conf; do
        if [ -f "$cred_file" ]; then
            source "$cred_file"
            local domain=$(basename "$cred_file" .conf)
            printf "%-30s %-20s %-20s\n" "$domain" "${MYSQL_DB_NAME:-N/A}" "${POSTGRESQL_DB_NAME:-N/A}"
        fi
    done
    
    echo ""
    print_info "Use 'View Domain Database Info' to see full credentials"
    press_any_key
}

# View specific domain database info
view_domain_database_info() {
    show_header
    echo -e "${CYAN}View Domain Database Information${NC}"
    echo ""
    
    list_domains
    echo ""
    
    read -p "Enter domain name: " domain_name
    
    if [ -z "$domain_name" ]; then
        return
    fi
    
    display_domain_database_info "$domain_name"
    press_any_key
}

# Delete domain databases
delete_domain_databases() {
    local domain_name=$1
    
    if [ -z "$domain_name" ]; then
        print_error "Domain name required"
        return 1
    fi
    
    local cred_file="${DB_CREDENTIALS_DIR}/${domain_name}.conf"
    
    if [ ! -f "$cred_file" ]; then
        print_warning "No database credentials found for domain: ${domain_name}"
        return 1
    fi
    
    # Load credentials
    source "$cred_file"
    
    print_warning "This will delete all databases and users for: ${domain_name}"
    read -p "Are you sure? (yes/no): " confirm
    
    if [ "$confirm" != "yes" ]; then
        print_info "Deletion cancelled"
        return 0
    fi
    
    # Delete MySQL database
    if [ -n "$MYSQL_DB_NAME" ] && command -v mysql &> /dev/null; then
        mysql -e "DROP DATABASE IF EXISTS \`${MYSQL_DB_NAME}\`;"
        mysql -e "DROP USER IF EXISTS '${MYSQL_DB_USER}'@'localhost';"
        mysql -e "DROP USER IF EXISTS '${MYSQL_DB_USER}'@'%';"
        mysql -e "FLUSH PRIVILEGES;"
        print_success "MySQL database deleted: ${MYSQL_DB_NAME}"
    fi
    
    # Delete PostgreSQL database
    if [ -n "$POSTGRESQL_DB_NAME" ] && command -v psql &> /dev/null; then
        sudo -u postgres psql <<EOF
DROP DATABASE IF EXISTS ${POSTGRESQL_DB_NAME};
DROP USER IF EXISTS ${POSTGRESQL_DB_USER};
EOF
        print_success "PostgreSQL database deleted: ${POSTGRESQL_DB_NAME}"
    fi
    
    # Remove user from ProxySQL
    if [ -n "$PROXYSQL_USER" ] && command -v proxysql &> /dev/null; then
        local proxysql_config="${CONFIG_DIR}/proxysql.conf"
        if [ -f "$proxysql_config" ]; then
            source "$proxysql_config"
            mysql -h127.0.0.1 -P"$ADMIN_PORT" -u"$ADMIN_USER" -p"$ADMIN_PASSWORD" <<EOF
DELETE FROM mysql_users WHERE username='${PROXYSQL_USER}';
LOAD MYSQL USERS TO RUNTIME;
SAVE MYSQL USERS TO DISK;
EOF
            print_success "ProxySQL user removed: ${PROXYSQL_USER}"
        fi
    fi
    
    # Delete credentials file
    rm -f "$cred_file"
    print_success "Credentials file deleted"
    
    return 0
}
