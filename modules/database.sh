#!/bin/bash

################################################################################
# RocketVPS - Database Management Module
################################################################################

# Database menu
database_menu() {
    while true; do
        show_header
        echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║                  DATABASE MANAGEMENT                          ║${NC}"
        echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo "  1)  Install Database (MariaDB/MySQL/PostgreSQL)"
        echo "  2)  Create Database"
        echo "  3)  Create Database User"
        echo "  4)  Delete Database"
        echo "  5)  Delete Database User"
        echo "  6)  List All Databases"
        echo "  7)  List All Users"
        echo "  8)  Backup Database"
        echo "  9)  Restore Database"
        echo "  10) Setup Auto Backup"
        echo "  11) Configure Cloud Backup (Google Drive/S3)"
        echo "  12) Optimize Database"
        echo "  13) Database Security"
        echo ""
        echo -e "${YELLOW}  === Domain Database Management ===${NC}"
        echo "  14) List All Domain Databases"
        echo "  15) View Domain Database Info"
        echo "  16) Delete Domain Databases"
        echo "  17) Auto-Install All Databases (MySQL/PostgreSQL/ProxySQL)"
        echo ""
        echo "  0) Back to Main Menu"
        echo ""
        echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
        
        read -p "Enter your choice [0-17]: " db_choice
        
        case $db_choice in
            1) install_database ;;
            2) create_database ;;
            3) create_db_user ;;
            4) delete_database ;;
            5) delete_db_user ;;
            6) list_databases ;;
            7) list_db_users ;;
            8) backup_database ;;
            9) restore_database ;;
            10) setup_auto_backup ;;
            11) configure_cloud_backup ;;
            12) optimize_database ;;
            13) database_security ;;
            14) list_all_domain_databases ;;
            15) view_domain_database_info ;;
            16) 
                show_header
                echo -e "${CYAN}Delete Domain Databases${NC}"
                echo ""
                list_domains
                echo ""
                read -p "Enter domain name: " domain_name
                if [ -n "$domain_name" ]; then
                    delete_domain_databases "$domain_name"
                fi
                press_any_key
                ;;
            17) auto_install_databases ;;
            0) return ;;
            *)
                print_error "Invalid choice"
                sleep 2
                ;;
        esac
    done
}

# Install database
install_database() {
    show_header
    echo -e "${CYAN}Install Database System${NC}"
    echo ""
    echo "Select database to install:"
    echo "  1) MariaDB (Recommended)"
    echo "  2) MySQL"
    echo "  3) PostgreSQL"
    echo ""
    read -p "Enter choice [1-3]: " db_type
    
    case $db_type in
        1) install_mariadb ;;
        2) install_mysql ;;
        3) install_postgresql ;;
        *)
            print_error "Invalid choice"
            press_any_key
            ;;
    esac
}

# Install MariaDB
install_mariadb() {
    print_info "Installing MariaDB..."
    
    if command -v mysql &> /dev/null; then
        print_warning "MariaDB/MySQL is already installed"
        mysql --version
        press_any_key
        return
    fi
    
    if [[ "$OS" == "ubuntu" || "$OS" == "debian" ]]; then
        apt-get update
        apt-get install -y mariadb-server mariadb-client
    elif [[ "$OS" == "centos" || "$OS" == "rhel" ]]; then
        yum install -y mariadb-server mariadb
    fi
    
    systemctl enable mariadb
    systemctl start mariadb
    
    if systemctl is-active --quiet mariadb; then
        print_success "MariaDB installed successfully"
        mysql --version
        
        # Run secure installation
        print_info "Running MariaDB secure installation..."
        mysql_secure_installation_auto
        
        # Save DB type
        echo "DB_TYPE=mariadb" > "${CONFIG_DIR}/database.conf"
    else
        print_error "MariaDB installation failed"
    fi
    
    press_any_key
}

# Install MySQL
install_mysql() {
    print_info "Installing MySQL..."
    
    if command -v mysql &> /dev/null; then
        print_warning "MySQL/MariaDB is already installed"
        mysql --version
        press_any_key
        return
    fi
    
    if [[ "$OS" == "ubuntu" || "$OS" == "debian" ]]; then
        apt-get update
        apt-get install -y mysql-server mysql-client
    elif [[ "$OS" == "centos" || "$OS" == "rhel" ]]; then
        yum install -y mysql-server mysql
    fi
    
    systemctl enable mysqld 2>/dev/null || systemctl enable mysql 2>/dev/null
    systemctl start mysqld 2>/dev/null || systemctl start mysql 2>/dev/null
    
    if systemctl is-active --quiet mysqld || systemctl is-active --quiet mysql; then
        print_success "MySQL installed successfully"
        mysql --version
        
        # Run secure installation
        print_info "Running MySQL secure installation..."
        mysql_secure_installation_auto
        
        # Save DB type
        echo "DB_TYPE=mysql" > "${CONFIG_DIR}/database.conf"
    else
        print_error "MySQL installation failed"
    fi
    
    press_any_key
}

# Install PostgreSQL
install_postgresql() {
    print_info "Installing PostgreSQL..."
    
    if command -v psql &> /dev/null; then
        print_warning "PostgreSQL is already installed"
        psql --version
        press_any_key
        return
    fi
    
    if [[ "$OS" == "ubuntu" || "$OS" == "debian" ]]; then
        apt-get update
        apt-get install -y postgresql postgresql-contrib
    elif [[ "$OS" == "centos" || "$OS" == "rhel" ]]; then
        yum install -y postgresql-server postgresql-contrib
        postgresql-setup initdb
    fi
    
    systemctl enable postgresql
    systemctl start postgresql
    
    if systemctl is-active --quiet postgresql; then
        print_success "PostgreSQL installed successfully"
        psql --version
        
        # Save DB type
        echo "DB_TYPE=postgresql" > "${CONFIG_DIR}/database.conf"
    else
        print_error "PostgreSQL installation failed"
    fi
    
    press_any_key
}

# Automatic MySQL secure installation
mysql_secure_installation_auto() {
    local root_password=$(openssl rand -base64 32)
    
    # Set root password and secure installation
    mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${root_password}';" 2>/dev/null
    mysql -u root -p"${root_password}" -e "DELETE FROM mysql.user WHERE User='';" 2>/dev/null
    mysql -u root -p"${root_password}" -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');" 2>/dev/null
    mysql -u root -p"${root_password}" -e "DROP DATABASE IF EXISTS test;" 2>/dev/null
    mysql -u root -p"${root_password}" -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';" 2>/dev/null
    mysql -u root -p"${root_password}" -e "FLUSH PRIVILEGES;" 2>/dev/null
    
    # Save root password
    cat > "${CONFIG_DIR}/mysql_root.cnf" <<EOF
[client]
user=root
password=${root_password}
EOF
    chmod 600 "${CONFIG_DIR}/mysql_root.cnf"
    
    print_success "Database secured. Root credentials saved to ${CONFIG_DIR}/mysql_root.cnf"
}

# Create database
create_database() {
    show_header
    echo -e "${CYAN}Create Database${NC}"
    echo ""
    
    if [ ! -f "${CONFIG_DIR}/database.conf" ]; then
        print_error "No database system detected. Please install one first."
        press_any_key
        return
    fi
    
    source "${CONFIG_DIR}/database.conf"
    
    read -p "Enter database name: " db_name
    
    if [ -z "$db_name" ]; then
        print_error "Database name cannot be empty"
        press_any_key
        return
    fi
    
    if [ "$DB_TYPE" = "postgresql" ]; then
        sudo -u postgres psql -c "CREATE DATABASE ${db_name};"
        if [ $? -eq 0 ]; then
            print_success "Database $db_name created successfully"
        else
            print_error "Failed to create database"
        fi
    else
        mysql --defaults-extra-file="${CONFIG_DIR}/mysql_root.cnf" -e "CREATE DATABASE ${db_name};"
        if [ $? -eq 0 ]; then
            print_success "Database $db_name created successfully"
        else
            print_error "Failed to create database"
        fi
    fi
    
    press_any_key
}

# Create database user
create_db_user() {
    show_header
    echo -e "${CYAN}Create Database User${NC}"
    echo ""
    
    if [ ! -f "${CONFIG_DIR}/database.conf" ]; then
        print_error "No database system detected"
        press_any_key
        return
    fi
    
    source "${CONFIG_DIR}/database.conf"
    
    read -p "Enter username: " db_user
    read -s -p "Enter password: " db_password
    echo ""
    read -p "Enter database name (or leave empty for all): " db_name
    
    if [ -z "$db_user" ] || [ -z "$db_password" ]; then
        print_error "Username and password cannot be empty"
        press_any_key
        return
    fi
    
    if [ "$DB_TYPE" = "postgresql" ]; then
        sudo -u postgres psql -c "CREATE USER ${db_user} WITH PASSWORD '${db_password}';"
        if [ -n "$db_name" ]; then
            sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE ${db_name} TO ${db_user};"
        fi
        print_success "PostgreSQL user $db_user created"
    else
        if [ -z "$db_name" ]; then
            mysql --defaults-extra-file="${CONFIG_DIR}/mysql_root.cnf" -e \
                "CREATE USER '${db_user}'@'localhost' IDENTIFIED BY '${db_password}'; 
                 GRANT ALL PRIVILEGES ON *.* TO '${db_user}'@'localhost';
                 FLUSH PRIVILEGES;"
        else
            mysql --defaults-extra-file="${CONFIG_DIR}/mysql_root.cnf" -e \
                "CREATE USER '${db_user}'@'localhost' IDENTIFIED BY '${db_password}'; 
                 GRANT ALL PRIVILEGES ON ${db_name}.* TO '${db_user}'@'localhost';
                 FLUSH PRIVILEGES;"
        fi
        print_success "MySQL/MariaDB user $db_user created"
    fi
    
    press_any_key
}

# Delete database
delete_database() {
    list_databases
    echo ""
    read -p "Enter database name to delete: " db_name
    
    if [ -z "$db_name" ]; then
        print_error "Database name cannot be empty"
        press_any_key
        return
    fi
    
    print_warning "This will permanently delete database: $db_name"
    read -p "Are you sure? Type 'DELETE' to confirm: " confirm
    
    if [ "$confirm" != "DELETE" ]; then
        print_info "Deletion cancelled"
        press_any_key
        return
    fi
    
    # Backup before delete
    print_info "Creating backup before deletion..."
    backup_single_database "$db_name"
    
    source "${CONFIG_DIR}/database.conf"
    
    if [ "$DB_TYPE" = "postgresql" ]; then
        sudo -u postgres psql -c "DROP DATABASE ${db_name};"
    else
        mysql --defaults-extra-file="${CONFIG_DIR}/mysql_root.cnf" -e "DROP DATABASE ${db_name};"
    fi
    
    print_success "Database $db_name deleted. Backup saved to ${BACKUP_DIR}/"
    press_any_key
}

# Delete database user
delete_db_user() {
    list_db_users
    echo ""
    read -p "Enter username to delete: " db_user
    
    if [ -z "$db_user" ]; then
        print_error "Username cannot be empty"
        press_any_key
        return
    fi
    
    print_warning "This will permanently delete user: $db_user"
    read -p "Are you sure? (yes/no): " confirm
    
    if [ "$confirm" != "yes" ]; then
        print_info "Deletion cancelled"
        press_any_key
        return
    fi
    
    source "${CONFIG_DIR}/database.conf"
    
    if [ "$DB_TYPE" = "postgresql" ]; then
        sudo -u postgres psql -c "DROP USER ${db_user};"
    else
        mysql --defaults-extra-file="${CONFIG_DIR}/mysql_root.cnf" -e "DROP USER '${db_user}'@'localhost';"
    fi
    
    print_success "User $db_user deleted"
    press_any_key
}

# List databases
list_databases() {
    show_header
    echo -e "${CYAN}All Databases:${NC}"
    echo ""
    
    if [ ! -f "${CONFIG_DIR}/database.conf" ]; then
        print_error "No database system detected"
        press_any_key
        return
    fi
    
    source "${CONFIG_DIR}/database.conf"
    
    if [ "$DB_TYPE" = "postgresql" ]; then
        sudo -u postgres psql -l
    else
        mysql --defaults-extra-file="${CONFIG_DIR}/mysql_root.cnf" -e "SHOW DATABASES;"
    fi
    
    echo ""
    press_any_key
}

# List database users
list_db_users() {
    show_header
    echo -e "${CYAN}All Database Users:${NC}"
    echo ""
    
    if [ ! -f "${CONFIG_DIR}/database.conf" ]; then
        print_error "No database system detected"
        press_any_key
        return
    fi
    
    source "${CONFIG_DIR}/database.conf"
    
    if [ "$DB_TYPE" = "postgresql" ]; then
        sudo -u postgres psql -c "\du"
    else
        mysql --defaults-extra-file="${CONFIG_DIR}/mysql_root.cnf" -e "SELECT User, Host FROM mysql.user;"
    fi
    
    echo ""
    press_any_key
}

# Backup database
backup_database() {
    show_header
    echo -e "${CYAN}Backup Database${NC}"
    echo ""
    
    list_databases
    echo ""
    read -p "Enter database name (or 'all' for all databases): " db_name
    
    if [ -z "$db_name" ]; then
        print_error "Database name cannot be empty"
        press_any_key
        return
    fi
    
    backup_single_database "$db_name"
    press_any_key
}

# Backup single database
backup_single_database() {
    local db_name=$1
    local backup_file="${BACKUP_DIR}/db_${db_name}_$(date +%Y%m%d_%H%M%S).sql"
    
    source "${CONFIG_DIR}/database.conf"
    
    print_info "Backing up database: $db_name..."
    
    if [ "$DB_TYPE" = "postgresql" ]; then
        if [ "$db_name" = "all" ]; then
            sudo -u postgres pg_dumpall > "$backup_file"
        else
            sudo -u postgres pg_dump "$db_name" > "$backup_file"
        fi
    else
        if [ "$db_name" = "all" ]; then
            mysqldump --defaults-extra-file="${CONFIG_DIR}/mysql_root.cnf" --all-databases > "$backup_file"
        else
            mysqldump --defaults-extra-file="${CONFIG_DIR}/mysql_root.cnf" "$db_name" > "$backup_file"
        fi
    fi
    
    # Compress backup
    gzip "$backup_file"
    backup_file="${backup_file}.gz"
    
    if [ -f "$backup_file" ]; then
        local size=$(du -h "$backup_file" | cut -f1)
        print_success "Backup completed: $backup_file (Size: $size)"
        
        # Upload to cloud if configured
        upload_to_cloud "$backup_file"
    else
        print_error "Backup failed"
    fi
}

# Restore database
restore_database() {
    show_header
    echo -e "${CYAN}Restore Database${NC}"
    echo ""
    
    echo "Available backups:"
    ls -lh "${BACKUP_DIR}"/db_*.sql.gz 2>/dev/null | awk '{print $9, "(" $5 ")"}'
    echo ""
    
    read -p "Enter full path to backup file: " backup_file
    
    if [ ! -f "$backup_file" ]; then
        print_error "Backup file not found"
        press_any_key
        return
    fi
    
    read -p "Enter database name to restore to: " db_name
    
    print_warning "This will overwrite database: $db_name"
    read -p "Are you sure? (yes/no): " confirm
    
    if [ "$confirm" != "yes" ]; then
        print_info "Restore cancelled"
        press_any_key
        return
    fi
    
    source "${CONFIG_DIR}/database.conf"
    
    print_info "Restoring database..."
    
    # Decompress if needed
    if [[ "$backup_file" == *.gz ]]; then
        gunzip -c "$backup_file" > "${backup_file%.gz}"
        backup_file="${backup_file%.gz}"
    fi
    
    if [ "$DB_TYPE" = "postgresql" ]; then
        sudo -u postgres psql "$db_name" < "$backup_file"
    else
        mysql --defaults-extra-file="${CONFIG_DIR}/mysql_root.cnf" "$db_name" < "$backup_file"
    fi
    
    if [ $? -eq 0 ]; then
        print_success "Database restored successfully"
    else
        print_error "Database restore failed"
    fi
    
    press_any_key
}

# Setup auto backup
setup_auto_backup() {
    show_header
    echo -e "${CYAN}Setup Automatic Database Backup${NC}"
    echo ""
    
    echo "Select backup frequency:"
    echo "  1) Daily (3 AM)"
    echo "  2) Every 12 hours"
    echo "  3) Every 6 hours"
    echo "  4) Weekly (Sunday 3 AM)"
    echo "  5) Custom cron expression"
    echo ""
    read -p "Enter choice [1-5]: " freq_choice
    
    case $freq_choice in
        1) cron_schedule="0 3 * * *" ;;
        2) cron_schedule="0 */12 * * *" ;;
        3) cron_schedule="0 */6 * * *" ;;
        4) cron_schedule="0 3 * * 0" ;;
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
    cat > "${ROCKETVPS_DIR}/db_backup.sh" <<'EOF'
#!/bin/bash

source /opt/rocketvps/rocketvps.sh
backup_single_database "all"

# Cleanup old backups (keep last 7 days)
find /opt/rocketvps/backups/ -name "db_*.sql.gz" -mtime +7 -delete
EOF
    
    chmod +x "${ROCKETVPS_DIR}/db_backup.sh"
    
    # Add to crontab
    local cron_job="${cron_schedule} ${ROCKETVPS_DIR}/db_backup.sh >> ${LOG_DIR}/auto_backup.log 2>&1"
    
    # Remove existing backup job
    crontab -l 2>/dev/null | grep -v "db_backup.sh" | crontab -
    
    # Add new job
    (crontab -l 2>/dev/null; echo "$cron_job") | crontab -
    
    print_success "Automatic backup configured"
    print_info "Schedule: $cron_schedule"
    print_info "Old backups will be deleted after 7 days"
    
    press_any_key
}

# Configure cloud backup
configure_cloud_backup() {
    show_header
    echo -e "${CYAN}Configure Cloud Backup${NC}"
    echo ""
    echo "Select cloud provider:"
    echo "  1) Google Drive (rclone)"
    echo "  2) Amazon S3"
    echo "  3) Disable cloud backup"
    echo ""
    read -p "Enter choice [1-3]: " cloud_choice
    
    case $cloud_choice in
        1) configure_google_drive ;;
        2) configure_amazon_s3 ;;
        3) 
            rm -f "${CONFIG_DIR}/cloud_backup.conf"
            print_success "Cloud backup disabled"
            ;;
        *)
            print_error "Invalid choice"
            ;;
    esac
    
    press_any_key
}

# Configure Google Drive
configure_google_drive() {
    print_info "Installing rclone..."
    
    if ! command -v rclone &> /dev/null; then
        curl https://rclone.org/install.sh | bash
    fi
    
    print_info "Please configure rclone for Google Drive:"
    print_info "Run: rclone config"
    print_info "Then return here and enter the remote name"
    echo ""
    
    read -p "Enter rclone remote name: " remote_name
    read -p "Enter folder path on Google Drive: " remote_path
    
    cat > "${CONFIG_DIR}/cloud_backup.conf" <<EOF
CLOUD_PROVIDER=gdrive
RCLONE_REMOTE=${remote_name}
REMOTE_PATH=${remote_path}
EOF
    
    print_success "Google Drive backup configured"
}

# Configure Amazon S3
configure_amazon_s3() {
    read -p "Enter S3 bucket name: " s3_bucket
    read -p "Enter AWS Access Key ID: " aws_key
    read -s -p "Enter AWS Secret Access Key: " aws_secret
    echo ""
    read -p "Enter AWS Region (e.g., us-east-1): " aws_region
    
    cat > "${CONFIG_DIR}/cloud_backup.conf" <<EOF
CLOUD_PROVIDER=s3
S3_BUCKET=${s3_bucket}
AWS_ACCESS_KEY_ID=${aws_key}
AWS_SECRET_ACCESS_KEY=${aws_secret}
AWS_REGION=${aws_region}
EOF
    
    chmod 600 "${CONFIG_DIR}/cloud_backup.conf"
    
    # Install AWS CLI if not present
    if ! command -v aws &> /dev/null; then
        print_info "Installing AWS CLI..."
        curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
        unzip -q awscliv2.zip
        ./aws/install
        rm -rf aws awscliv2.zip
    fi
    
    print_success "Amazon S3 backup configured"
}

# Upload to cloud
upload_to_cloud() {
    local file=$1
    
    if [ ! -f "${CONFIG_DIR}/cloud_backup.conf" ]; then
        return
    fi
    
    source "${CONFIG_DIR}/cloud_backup.conf"
    
    if [ "$CLOUD_PROVIDER" = "gdrive" ]; then
        print_info "Uploading to Google Drive..."
        rclone copy "$file" "${RCLONE_REMOTE}:${REMOTE_PATH}"
    elif [ "$CLOUD_PROVIDER" = "s3" ]; then
        print_info "Uploading to Amazon S3..."
        aws s3 cp "$file" "s3://${S3_BUCKET}/" --region "$AWS_REGION"
    fi
    
    if [ $? -eq 0 ]; then
        print_success "Uploaded to cloud"
    fi
}

# Optimize database
optimize_database() {
    show_header
    echo -e "${CYAN}Optimize Database${NC}"
    echo ""
    
    source "${CONFIG_DIR}/database.conf"
    
    if [ "$DB_TYPE" = "postgresql" ]; then
        print_info "Optimizing PostgreSQL..."
        sudo -u postgres vacuumdb --all --analyze
        print_success "PostgreSQL optimized"
    else
        print_info "Optimizing MySQL/MariaDB..."
        mysqlcheck --defaults-extra-file="${CONFIG_DIR}/mysql_root.cnf" --optimize --all-databases
        print_success "MySQL/MariaDB optimized"
    fi
    
    press_any_key
}

# Database security
database_security() {
    show_header
    echo -e "${CYAN}Database Security${NC}"
    echo ""
    echo "  1) Change root password"
    echo "  2) Remove anonymous users"
    echo "  3) Disable remote root login"
    echo "  4) View security status"
    echo "  0) Back"
    echo ""
    read -p "Enter choice: " sec_choice
    
    source "${CONFIG_DIR}/database.conf"
    
    case $sec_choice in
        1)
            read -s -p "Enter new root password: " new_pass
            echo ""
            if [ "$DB_TYPE" = "postgresql" ]; then
                sudo -u postgres psql -c "ALTER USER postgres PASSWORD '${new_pass}';"
            else
                mysql --defaults-extra-file="${CONFIG_DIR}/mysql_root.cnf" -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${new_pass}';"
                # Update config file
                sed -i "s/password=.*/password=${new_pass}/" "${CONFIG_DIR}/mysql_root.cnf"
            fi
            print_success "Root password changed"
            ;;
        2)
            if [ "$DB_TYPE" != "postgresql" ]; then
                mysql --defaults-extra-file="${CONFIG_DIR}/mysql_root.cnf" -e "DELETE FROM mysql.user WHERE User='';"
                print_success "Anonymous users removed"
            fi
            ;;
        3)
            if [ "$DB_TYPE" != "postgresql" ]; then
                mysql --defaults-extra-file="${CONFIG_DIR}/mysql_root.cnf" -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
                print_success "Remote root login disabled"
            fi
            ;;
        4)
            if [ "$DB_TYPE" = "postgresql" ]; then
                sudo -u postgres psql -c "\du"
            else
                mysql --defaults-extra-file="${CONFIG_DIR}/mysql_root.cnf" -e "SELECT User, Host FROM mysql.user;"
            fi
            ;;
        0) return ;;
    esac
    
    press_any_key
}
