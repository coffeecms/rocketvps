#!/bin/bash

################################################################################
# RocketVPS - ProxySQL Management Module
# High-performance MySQL Proxy with load balancing and query caching
# Reference: https://github.com/sysown/proxysql
################################################################################

PROXYSQL_DIR="/opt/proxysql"
PROXYSQL_CONFIG="${CONFIG_DIR}/proxysql.conf"
PROXYSQL_ADMIN_PORT="6032"
PROXYSQL_MYSQL_PORT="6033"

# ProxySQL menu
proxysql_menu() {
    while true; do
        show_header
        echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║                  PROXYSQL MANAGEMENT                          ║${NC}"
        echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo "  ${CYAN}Setup:${NC}"
        echo "  1) Install ProxySQL"
        echo "  2) Uninstall ProxySQL"
        echo "  3) Upgrade ProxySQL"
        echo ""
        echo "  ${CYAN}Server Management:${NC}"
        echo "  4) Add MySQL Backend Server"
        echo "  5) List Backend Servers"
        echo "  6) Remove Backend Server"
        echo "  7) Configure Server Groups"
        echo "  8) Test Server Connectivity"
        echo ""
        echo "  ${CYAN}User Management:${NC}"
        echo "  9) Add MySQL User"
        echo "  10) List MySQL Users"
        echo "  11) Delete MySQL User"
        echo "  12) Configure User Privileges"
        echo ""
        echo "  ${CYAN}Query Rules:${NC}"
        echo "  13) Add Query Rule"
        echo "  14) List Query Rules"
        echo "  15) Delete Query Rule"
        echo "  16) Configure Read/Write Split"
        echo ""
        echo "  ${CYAN}Monitoring:${NC}"
        echo "  17) View ProxySQL Status"
        echo "  18) View Connection Stats"
        echo "  19) View Query Stats"
        echo "  20) View Error Log"
        echo "  21) View Slow Query Log"
        echo ""
        echo "  ${CYAN}Configuration:${NC}"
        echo "  22) Configure Admin Interface"
        echo "  23) Configure Connection Pool"
        echo "  24) Configure Query Cache"
        echo "  25) Configure Load Balancing"
        echo "  26) Backup Configuration"
        echo "  27) Restore Configuration"
        echo ""
        echo "  ${CYAN}Operations:${NC}"
        echo "  28) Start ProxySQL"
        echo "  29) Stop ProxySQL"
        echo "  30) Restart ProxySQL"
        echo "  31) Reload Configuration"
        echo "  32) Save Configuration"
        echo ""
        echo "  0) Back to Main Menu"
        echo ""
        echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
        
        read -p "Enter your choice [0-32]: " proxysql_choice
        
        case $proxysql_choice in
            1) install_proxysql ;;
            2) uninstall_proxysql ;;
            3) upgrade_proxysql ;;
            4) add_backend_server ;;
            5) list_backend_servers ;;
            6) remove_backend_server ;;
            7) configure_server_groups ;;
            8) test_server_connectivity ;;
            9) add_mysql_user ;;
            10) list_mysql_users ;;
            11) delete_mysql_user ;;
            12) configure_user_privileges ;;
            13) add_query_rule ;;
            14) list_query_rules ;;
            15) delete_query_rule ;;
            16) configure_read_write_split ;;
            17) view_proxysql_status ;;
            18) view_connection_stats ;;
            19) view_query_stats ;;
            20) view_error_log ;;
            21) view_slow_query_log ;;
            22) configure_admin_interface ;;
            23) configure_connection_pool ;;
            24) configure_query_cache ;;
            25) configure_load_balancing ;;
            26) backup_proxysql_config ;;
            27) restore_proxysql_config ;;
            28) start_proxysql ;;
            29) stop_proxysql ;;
            30) restart_proxysql ;;
            31) reload_proxysql_config ;;
            32) save_proxysql_config ;;
            0) return ;;
            *)
                print_error "Invalid choice"
                sleep 2
                ;;
        esac
    done
}

# Install ProxySQL
install_proxysql() {
    show_header
    print_info "Installing ProxySQL..."
    
    # Check if MySQL client is installed
    if ! command -v mysql &> /dev/null; then
        print_warning "MySQL client not found. Installing..."
        if [[ "$OS" == "ubuntu" || "$OS" == "debian" ]]; then
            apt-get install -y mysql-client
        elif [[ "$OS" == "centos" || "$OS" == "rhel" ]]; then
            yum install -y mysql
        fi
    fi
    
    # Create directory
    mkdir -p "$PROXYSQL_DIR"/{config,backup,logs}
    
    # Install based on OS
    if [[ "$OS" == "ubuntu" || "$OS" == "debian" ]]; then
        install_proxysql_debian
    elif [[ "$OS" == "centos" || "$OS" == "rhel" ]]; then
        install_proxysql_centos
    fi
    
    # Generate random admin password
    local admin_password=$(openssl rand -base64 16)
    local monitor_password=$(openssl rand -base64 16)
    
    # Configure ProxySQL
    print_info "Configuring ProxySQL..."
    
    # Update admin credentials in config
    mysql -h127.0.0.1 -P6032 -uadmin -padmin <<EOF
UPDATE global_variables SET variable_value='admin:${admin_password}' WHERE variable_name='admin-admin_credentials';
UPDATE global_variables SET variable_value='${monitor_password}' WHERE variable_name='mysql-monitor_password';
LOAD ADMIN VARIABLES TO RUNTIME;
SAVE ADMIN VARIABLES TO DISK;
LOAD MYSQL VARIABLES TO RUNTIME;
SAVE MYSQL VARIABLES TO DISK;
EOF

    # Save configuration
    cat > "$PROXYSQL_CONFIG" <<EOF
ADMIN_USER=admin
ADMIN_PASSWORD=${admin_password}
ADMIN_PORT=${PROXYSQL_ADMIN_PORT}
MYSQL_PORT=${PROXYSQL_MYSQL_PORT}
MONITOR_PASSWORD=${monitor_password}
INSTALLED_DATE=$(date +%Y-%m-%d)
VERSION=$(proxysql --version | head -1)
EOF

    chmod 600 "$PROXYSQL_CONFIG"
    
    # Enable and start service
    systemctl enable proxysql
    systemctl start proxysql
    
    # Wait for startup
    sleep 5
    
    if systemctl is-active --quiet proxysql; then
        print_success "ProxySQL installed successfully!"
        echo ""
        print_info "Admin Interface:"
        echo "  Host: 127.0.0.1"
        echo "  Port: ${PROXYSQL_ADMIN_PORT}"
        echo "  User: admin"
        echo "  Password: ${admin_password}"
        echo ""
        print_info "MySQL Interface:"
        echo "  Host: 127.0.0.1"
        echo "  Port: ${PROXYSQL_MYSQL_PORT}"
        echo ""
        print_warning "IMPORTANT: Save admin password in secure location!"
        echo ""
        print_info "Configuration saved to: ${PROXYSQL_CONFIG}"
    else
        print_error "ProxySQL installation failed"
    fi
    
    log_action "ProxySQL installed"
    press_any_key
}

# Install ProxySQL on Debian/Ubuntu
install_proxysql_debian() {
    # Add ProxySQL repository
    apt-get install -y lsb-release wget
    
    wget -O - 'https://repo.proxysql.com/ProxySQL/proxysql-2.5.x/repo_pub_key' | apt-key add -
    
    echo "deb https://repo.proxysql.com/ProxySQL/proxysql-2.5.x/$(lsb_release -sc)/ ./" \
        > /etc/apt/sources.list.d/proxysql.list
    
    apt-get update
    apt-get install -y proxysql
}

# Install ProxySQL on CentOS/RHEL
install_proxysql_centos() {
    # Add ProxySQL repository
    cat > /etc/yum.repos.d/proxysql.repo <<'EOF'
[proxysql]
name=ProxySQL YUM repository
baseurl=https://repo.proxysql.com/ProxySQL/proxysql-2.5.x/centos/$releasever
gpgcheck=1
gpgkey=https://repo.proxysql.com/ProxySQL/proxysql-2.5.x/repo_pub_key
EOF

    yum install -y proxysql
}

# Uninstall ProxySQL
uninstall_proxysql() {
    show_header
    print_warning "This will remove ProxySQL and all configurations!"
    read -p "Create backup before uninstalling? (y/n): " do_backup
    
    if [[ "$do_backup" =~ ^[Yy]$ ]]; then
        backup_proxysql_config
    fi
    
    read -p "Proceed with uninstallation? (yes/no): " confirm
    
    if [ "$confirm" != "yes" ]; then
        return
    fi
    
    # Stop service
    systemctl stop proxysql
    systemctl disable proxysql
    
    # Uninstall
    if [[ "$OS" == "ubuntu" || "$OS" == "debian" ]]; then
        apt-get remove --purge -y proxysql
        rm -f /etc/apt/sources.list.d/proxysql.list
    elif [[ "$OS" == "centos" || "$OS" == "rhel" ]]; then
        yum remove -y proxysql
        rm -f /etc/yum.repos.d/proxysql.repo
    fi
    
    read -p "Delete all data and configuration? (y/n): " delete_data
    if [[ "$delete_data" =~ ^[Yy]$ ]]; then
        rm -rf "$PROXYSQL_DIR"
        rm -rf /var/lib/proxysql
    fi
    
    rm -f "$PROXYSQL_CONFIG"
    
    print_success "ProxySQL uninstalled"
    press_any_key
}

# Upgrade ProxySQL
upgrade_proxysql() {
    show_header
    print_info "Upgrading ProxySQL..."
    
    backup_proxysql_config
    
    if [[ "$OS" == "ubuntu" || "$OS" == "debian" ]]; then
        apt-get update
        apt-get upgrade -y proxysql
    elif [[ "$OS" == "centos" || "$OS" == "rhel" ]]; then
        yum update -y proxysql
    fi
    
    systemctl restart proxysql
    
    print_success "ProxySQL upgraded"
    proxysql --version
    
    press_any_key
}

# Add MySQL backend server
add_backend_server() {
    show_header
    print_info "Add MySQL Backend Server"
    echo ""
    
    source "$PROXYSQL_CONFIG"
    
    read -p "MySQL server hostname/IP: " mysql_host
    read -p "MySQL server port (default 3306): " mysql_port
    mysql_port=${mysql_port:-3306}
    
    echo ""
    echo "Host Group (for read/write split):"
    echo "  0 = Write group (Master)"
    echo "  1 = Read group (Slaves)"
    read -p "Host group ID: " hostgroup_id
    
    read -p "Server weight (1-1000, default 1): " weight
    weight=${weight:-1}
    
    read -p "Max connections (default 1000): " max_connections
    max_connections=${max_connections:-1000}
    
    if [ -z "$mysql_host" ] || [ -z "$hostgroup_id" ]; then
        print_error "Hostname and host group required"
        press_any_key
        return
    fi
    
    # Add server
    mysql -h127.0.0.1 -P"$ADMIN_PORT" -u"$ADMIN_USER" -p"$ADMIN_PASSWORD" <<EOF
INSERT INTO mysql_servers(hostgroup_id, hostname, port, weight, max_connections) 
VALUES (${hostgroup_id}, '${mysql_host}', ${mysql_port}, ${weight}, ${max_connections});

LOAD MYSQL SERVERS TO RUNTIME;
SAVE MYSQL SERVERS TO DISK;
EOF

    if [ $? -eq 0 ]; then
        print_success "Backend server added: ${mysql_host}:${mysql_port} (hostgroup ${hostgroup_id})"
    else
        print_error "Failed to add backend server"
    fi
    
    press_any_key
}

# List backend servers
list_backend_servers() {
    show_header
    echo -e "${CYAN}MySQL Backend Servers:${NC}"
    echo ""
    
    source "$PROXYSQL_CONFIG"
    
    mysql -h127.0.0.1 -P"$ADMIN_PORT" -u"$ADMIN_USER" -p"$ADMIN_PASSWORD" -e \
        "SELECT hostgroup_id, hostname, port, status, weight, max_connections FROM mysql_servers ORDER BY hostgroup_id, hostname;"
    
    echo ""
    echo -e "${CYAN}Server Status:${NC}"
    mysql -h127.0.0.1 -P"$ADMIN_PORT" -u"$ADMIN_USER" -p"$ADMIN_PASSWORD" -e \
        "SELECT * FROM stats_mysql_connection_pool ORDER BY hostgroup, srv_host;"
    
    press_any_key
}

# Remove backend server
remove_backend_server() {
    list_backend_servers
    echo ""
    
    source "$PROXYSQL_CONFIG"
    
    read -p "Enter server hostname to remove: " mysql_host
    read -p "Enter server port: " mysql_port
    read -p "Enter hostgroup ID: " hostgroup_id
    
    if [ -z "$mysql_host" ]; then
        return
    fi
    
    print_warning "This will remove ${mysql_host}:${mysql_port} from hostgroup ${hostgroup_id}"
    read -p "Continue? (y/n): " confirm
    
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        mysql -h127.0.0.1 -P"$ADMIN_PORT" -u"$ADMIN_USER" -p"$ADMIN_PASSWORD" <<EOF
DELETE FROM mysql_servers WHERE hostname='${mysql_host}' AND port=${mysql_port} AND hostgroup_id=${hostgroup_id};
LOAD MYSQL SERVERS TO RUNTIME;
SAVE MYSQL SERVERS TO DISK;
EOF
        print_success "Backend server removed"
    fi
    
    press_any_key
}

# Configure server groups
configure_server_groups() {
    show_header
    print_info "Configure Server Groups (Read/Write Split)"
    echo ""
    
    source "$PROXYSQL_CONFIG"
    
    echo "Current replication hostgroups:"
    mysql -h127.0.0.1 -P"$ADMIN_PORT" -u"$ADMIN_USER" -p"$ADMIN_PASSWORD" -e \
        "SELECT * FROM mysql_replication_hostgroups;"
    
    echo ""
    read -p "Writer hostgroup ID (default 0): " writer_hg
    writer_hg=${writer_hg:-0}
    
    read -p "Reader hostgroup ID (default 1): " reader_hg
    reader_hg=${reader_hg:-1}
    
    read -p "Comment: " comment
    comment=${comment:-"Read/Write Split"}
    
    mysql -h127.0.0.1 -P"$ADMIN_PORT" -u"$ADMIN_USER" -p"$ADMIN_PASSWORD" <<EOF
DELETE FROM mysql_replication_hostgroups;
INSERT INTO mysql_replication_hostgroups (writer_hostgroup, reader_hostgroup, comment)
VALUES (${writer_hg}, ${reader_hg}, '${comment}');

LOAD MYSQL SERVERS TO RUNTIME;
SAVE MYSQL SERVERS TO DISK;
EOF

    print_success "Server groups configured"
    print_info "Writer group: ${writer_hg}"
    print_info "Reader group: ${reader_hg}"
    
    press_any_key
}

# Test server connectivity
test_server_connectivity() {
    show_header
    print_info "Testing Backend Server Connectivity..."
    echo ""
    
    source "$PROXYSQL_CONFIG"
    
    mysql -h127.0.0.1 -P"$ADMIN_PORT" -u"$ADMIN_USER" -p"$ADMIN_PASSWORD" -e \
        "SELECT hostgroup_id, hostname, port, status, Latency_us, Queries FROM stats_mysql_connection_pool ORDER BY hostgroup_id;"
    
    echo ""
    print_info "Legend:"
    echo "  ONLINE = Server is healthy"
    echo "  SHUNNED = Server temporarily unavailable"
    echo "  OFFLINE_SOFT = Server being drained"
    echo "  OFFLINE_HARD = Server disabled"
    
    press_any_key
}

# Add MySQL user
add_mysql_user() {
    show_header
    print_info "Add MySQL User to ProxySQL"
    echo ""
    
    source "$PROXYSQL_CONFIG"
    
    read -p "MySQL username: " mysql_user
    read -p "MySQL password: " -s mysql_pass
    echo ""
    read -p "Default hostgroup (0=writer, 1=reader): " default_hostgroup
    default_hostgroup=${default_hostgroup:-0}
    
    read -p "Max connections (default 1000): " max_connections
    max_connections=${max_connections:-1000}
    
    if [ -z "$mysql_user" ] || [ -z "$mysql_pass" ]; then
        print_error "Username and password required"
        press_any_key
        return
    fi
    
    mysql -h127.0.0.1 -P"$ADMIN_PORT" -u"$ADMIN_USER" -p"$ADMIN_PASSWORD" <<EOF
INSERT INTO mysql_users(username, password, default_hostgroup, max_connections, active)
VALUES ('${mysql_user}', '${mysql_pass}', ${default_hostgroup}, ${max_connections}, 1);

LOAD MYSQL USERS TO RUNTIME;
SAVE MYSQL USERS TO DISK;
EOF

    if [ $? -eq 0 ]; then
        print_success "MySQL user '${mysql_user}' added to ProxySQL"
        print_info "Default hostgroup: ${default_hostgroup}"
    else
        print_error "Failed to add user"
    fi
    
    press_any_key
}

# List MySQL users
list_mysql_users() {
    show_header
    echo -e "${CYAN}MySQL Users in ProxySQL:${NC}"
    echo ""
    
    source "$PROXYSQL_CONFIG"
    
    mysql -h127.0.0.1 -P"$ADMIN_PORT" -u"$ADMIN_USER" -p"$ADMIN_PASSWORD" -e \
        "SELECT username, default_hostgroup, max_connections, active, transaction_persistent FROM mysql_users;"
    
    press_any_key
}

# Delete MySQL user
delete_mysql_user() {
    list_mysql_users
    echo ""
    
    source "$PROXYSQL_CONFIG"
    
    read -p "Enter username to delete: " mysql_user
    
    if [ -z "$mysql_user" ]; then
        return
    fi
    
    print_warning "This will delete user '${mysql_user}' from ProxySQL"
    read -p "Continue? (y/n): " confirm
    
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        mysql -h127.0.0.1 -P"$ADMIN_PORT" -u"$ADMIN_USER" -p"$ADMIN_PASSWORD" <<EOF
DELETE FROM mysql_users WHERE username='${mysql_user}';
LOAD MYSQL USERS TO RUNTIME;
SAVE MYSQL USERS TO DISK;
EOF
        print_success "User '${mysql_user}' deleted"
    fi
    
    press_any_key
}

# Configure user privileges
configure_user_privileges() {
    show_header
    print_info "Configure User Privileges"
    echo ""
    
    list_mysql_users
    echo ""
    
    source "$PROXYSQL_CONFIG"
    
    read -p "Username: " mysql_user
    read -p "New default hostgroup: " new_hostgroup
    read -p "Transaction persistent (0/1): " trans_persist
    
    if [ -n "$mysql_user" ] && [ -n "$new_hostgroup" ]; then
        mysql -h127.0.0.1 -P"$ADMIN_PORT" -u"$ADMIN_USER" -p"$ADMIN_PASSWORD" <<EOF
UPDATE mysql_users SET default_hostgroup=${new_hostgroup}, transaction_persistent=${trans_persist}
WHERE username='${mysql_user}';

LOAD MYSQL USERS TO RUNTIME;
SAVE MYSQL USERS TO DISK;
EOF
        print_success "User privileges updated"
    fi
    
    press_any_key
}

# Add query rule
add_query_rule() {
    show_header
    print_info "Add Query Rule"
    echo ""
    
    source "$PROXYSQL_CONFIG"
    
    echo "Rule types:"
    echo "  1) Route to specific hostgroup"
    echo "  2) Cache query result"
    echo "  3) Rewrite query"
    echo "  4) Block query"
    echo ""
    read -p "Select type [1-4]: " rule_type
    
    read -p "Match pattern (regex): " match_pattern
    read -p "Destination hostgroup: " dest_hostgroup
    read -p "Apply (0=don't apply, 1=apply): " apply
    apply=${apply:-1}
    
    case $rule_type in
        1)
            # Route rule
            mysql -h127.0.0.1 -P"$ADMIN_PORT" -u"$ADMIN_USER" -p"$ADMIN_PASSWORD" <<EOF
INSERT INTO mysql_query_rules(match_pattern, destination_hostgroup, apply, active)
VALUES ('${match_pattern}', ${dest_hostgroup}, ${apply}, 1);

LOAD MYSQL QUERY RULES TO RUNTIME;
SAVE MYSQL QUERY RULES TO DISK;
EOF
            ;;
        2)
            read -p "Cache TTL (seconds): " cache_ttl
            mysql -h127.0.0.1 -P"$ADMIN_PORT" -u"$ADMIN_USER" -p"$ADMIN_PASSWORD" <<EOF
INSERT INTO mysql_query_rules(match_pattern, cache_ttl, apply, active)
VALUES ('${match_pattern}', ${cache_ttl}, ${apply}, 1);

LOAD MYSQL QUERY RULES TO RUNTIME;
SAVE MYSQL QUERY RULES TO DISK;
EOF
            ;;
        3)
            read -p "Replace pattern: " replace_pattern
            mysql -h127.0.0.1 -P"$ADMIN_PORT" -u"$ADMIN_USER" -p"$ADMIN_PASSWORD" <<EOF
INSERT INTO mysql_query_rules(match_pattern, replace_pattern, apply, active)
VALUES ('${match_pattern}', '${replace_pattern}', ${apply}, 1);

LOAD MYSQL QUERY RULES TO RUNTIME;
SAVE MYSQL QUERY RULES TO DISK;
EOF
            ;;
        4)
            mysql -h127.0.0.1 -P"$ADMIN_PORT" -u"$ADMIN_USER" -p"$ADMIN_PASSWORD" <<EOF
INSERT INTO mysql_query_rules(match_pattern, error_msg, apply, active)
VALUES ('${match_pattern}', 'Query blocked by ProxySQL rule', ${apply}, 1);

LOAD MYSQL QUERY RULES TO RUNTIME;
SAVE MYSQL QUERY RULES TO DISK;
EOF
            ;;
    esac
    
    print_success "Query rule added"
    press_any_key
}

# List query rules
list_query_rules() {
    show_header
    echo -e "${CYAN}Query Rules:${NC}"
    echo ""
    
    source "$PROXYSQL_CONFIG"
    
    mysql -h127.0.0.1 -P"$ADMIN_PORT" -u"$ADMIN_USER" -p"$ADMIN_PASSWORD" -e \
        "SELECT rule_id, match_pattern, destination_hostgroup, cache_ttl, apply, active FROM mysql_query_rules ORDER BY rule_id;"
    
    press_any_key
}

# Delete query rule
delete_query_rule() {
    list_query_rules
    echo ""
    
    source "$PROXYSQL_CONFIG"
    
    read -p "Enter rule ID to delete: " rule_id
    
    if [ -z "$rule_id" ]; then
        return
    fi
    
    mysql -h127.0.0.1 -P"$ADMIN_PORT" -u"$ADMIN_USER" -p"$ADMIN_PASSWORD" <<EOF
DELETE FROM mysql_query_rules WHERE rule_id=${rule_id};
LOAD MYSQL QUERY RULES TO RUNTIME;
SAVE MYSQL QUERY RULES TO DISK;
EOF

    print_success "Query rule deleted"
    press_any_key
}

# Configure read/write split
configure_read_write_split() {
    show_header
    print_info "Configure Read/Write Split"
    echo ""
    
    source "$PROXYSQL_CONFIG"
    
    print_info "This will create query rules to split read and write traffic"
    echo ""
    
    # Route SELECT to readers (hostgroup 1)
    # Route INSERT, UPDATE, DELETE to writers (hostgroup 0)
    
    mysql -h127.0.0.1 -P"$ADMIN_PORT" -u"$ADMIN_USER" -p"$ADMIN_PASSWORD" <<'EOF'
DELETE FROM mysql_query_rules;

-- Route SELECT FOR UPDATE to writers
INSERT INTO mysql_query_rules(rule_id, match_pattern, destination_hostgroup, apply, active)
VALUES (1, '^SELECT.*FOR UPDATE', 0, 1, 1);

-- Route all other SELECT to readers
INSERT INTO mysql_query_rules(rule_id, match_pattern, destination_hostgroup, apply, active)
VALUES (2, '^SELECT', 1, 1, 1);

-- Route writes to writers (default is already 0)
INSERT INTO mysql_query_rules(rule_id, match_pattern, destination_hostgroup, apply, active)
VALUES (3, '^(INSERT|UPDATE|DELETE)', 0, 1, 1);

LOAD MYSQL QUERY RULES TO RUNTIME;
SAVE MYSQL QUERY RULES TO DISK;
EOF

    print_success "Read/Write split configured"
    print_info "SELECT queries → Readers (hostgroup 1)"
    print_info "Write queries → Writers (hostgroup 0)"
    print_info "SELECT FOR UPDATE → Writers (hostgroup 0)"
    
    press_any_key
}

# View ProxySQL status
view_proxysql_status() {
    show_header
    echo -e "${CYAN}ProxySQL Status:${NC}"
    echo ""
    
    systemctl status proxysql --no-pager
    
    echo ""
    echo -e "${CYAN}Version:${NC}"
    proxysql --version
    
    echo ""
    echo -e "${CYAN}Process Info:${NC}"
    ps aux | grep proxysql | grep -v grep
    
    press_any_key
}

# View connection stats
view_connection_stats() {
    show_header
    echo -e "${CYAN}Connection Statistics:${NC}"
    echo ""
    
    source "$PROXYSQL_CONFIG"
    
    echo "Frontend connections:"
    mysql -h127.0.0.1 -P"$ADMIN_PORT" -u"$ADMIN_USER" -p"$ADMIN_PASSWORD" -e \
        "SELECT * FROM stats_mysql_global WHERE Variable_Name LIKE 'Client_%';"
    
    echo ""
    echo "Backend connections:"
    mysql -h127.0.0.1 -P"$ADMIN_PORT" -u"$ADMIN_USER" -p"$ADMIN_PASSWORD" -e \
        "SELECT hostgroup, srv_host, srv_port, status, Queries, Bytes_data_sent, Bytes_data_recv FROM stats_mysql_connection_pool;"
    
    press_any_key
}

# View query stats
view_query_stats() {
    show_header
    echo -e "${CYAN}Query Statistics:${NC}"
    echo ""
    
    source "$PROXYSQL_CONFIG"
    
    echo "Top 20 queries by execution count:"
    mysql -h127.0.0.1 -P"$ADMIN_PORT" -u"$ADMIN_USER" -p"$ADMIN_PASSWORD" -e \
        "SELECT hostgroup, digest_text, count_star, sum_time, min_time, max_time FROM stats_mysql_query_digest ORDER BY count_star DESC LIMIT 20;"
    
    press_any_key
}

# View error log
view_error_log() {
    show_header
    echo -e "${CYAN}ProxySQL Error Log:${NC}"
    echo ""
    
    if [ -f /var/lib/proxysql/proxysql.log ]; then
        tail -100 /var/lib/proxysql/proxysql.log
    else
        print_warning "Log file not found"
    fi
    
    press_any_key
}

# View slow query log
view_slow_query_log() {
    show_header
    echo -e "${CYAN}Slow Queries:${NC}"
    echo ""
    
    source "$PROXYSQL_CONFIG"
    
    mysql -h127.0.0.1 -P"$ADMIN_PORT" -u"$ADMIN_USER" -p"$ADMIN_PASSWORD" -e \
        "SELECT hostgroup, username, digest_text, count_star, sum_time, sum_time/count_star as avg_time FROM stats_mysql_query_digest WHERE sum_time > 1000000 ORDER BY avg_time DESC LIMIT 20;"
    
    press_any_key
}

# Configure admin interface
configure_admin_interface() {
    show_header
    print_info "Configure Admin Interface"
    echo ""
    
    source "$PROXYSQL_CONFIG"
    
    read -p "New admin password (leave empty to keep current): " new_pass
    
    if [ -n "$new_pass" ]; then
        mysql -h127.0.0.1 -P"$ADMIN_PORT" -u"$ADMIN_USER" -p"$ADMIN_PASSWORD" <<EOF
UPDATE global_variables SET variable_value='admin:${new_pass}' WHERE variable_name='admin-admin_credentials';
LOAD ADMIN VARIABLES TO RUNTIME;
SAVE ADMIN VARIABLES TO DISK;
EOF
        
        # Update config file
        sed -i "s/ADMIN_PASSWORD=.*/ADMIN_PASSWORD=${new_pass}/" "$PROXYSQL_CONFIG"
        
        print_success "Admin password updated"
    fi
    
    press_any_key
}

# Configure connection pool
configure_connection_pool() {
    show_header
    print_info "Configure Connection Pool"
    echo ""
    
    source "$PROXYSQL_CONFIG"
    
    echo "Current settings:"
    mysql -h127.0.0.1 -P"$ADMIN_PORT" -u"$ADMIN_USER" -p"$ADMIN_PASSWORD" -e \
        "SELECT * FROM global_variables WHERE variable_name LIKE 'mysql-max%' OR variable_name LIKE 'mysql-connect%';"
    
    echo ""
    read -p "Max connections per server (default 1000): " max_conn
    read -p "Connect timeout ms (default 1000): " conn_timeout
    
    if [ -n "$max_conn" ]; then
        mysql -h127.0.0.1 -P"$ADMIN_PORT" -u"$ADMIN_USER" -p"$ADMIN_PASSWORD" <<EOF
UPDATE global_variables SET variable_value='${max_conn}' WHERE variable_name='mysql-max_connections';
UPDATE global_variables SET variable_value='${conn_timeout}' WHERE variable_name='mysql-connect_timeout_server_max';
LOAD MYSQL VARIABLES TO RUNTIME;
SAVE MYSQL VARIABLES TO DISK;
EOF
        print_success "Connection pool configured"
    fi
    
    press_any_key
}

# Configure query cache
configure_query_cache() {
    show_header
    print_info "Configure Query Cache"
    echo ""
    
    source "$PROXYSQL_CONFIG"
    
    read -p "Enable query cache? (y/n): " enable_cache
    
    if [[ "$enable_cache" =~ ^[Yy]$ ]]; then
        read -p "Default cache TTL (seconds, default 3600): " cache_ttl
        cache_ttl=${cache_ttl:-3600}
        
        mysql -h127.0.0.1 -P"$ADMIN_PORT" -u"$ADMIN_USER" -p"$ADMIN_PASSWORD" <<EOF
UPDATE global_variables SET variable_value='${cache_ttl}' WHERE variable_name='mysql-default_query_timeout';
LOAD MYSQL VARIABLES TO RUNTIME;
SAVE MYSQL VARIABLES TO DISK;
EOF
        print_success "Query cache configured (TTL: ${cache_ttl}s)"
    fi
    
    press_any_key
}

# Configure load balancing
configure_load_balancing() {
    show_header
    print_info "Configure Load Balancing"
    echo ""
    
    list_backend_servers
    echo ""
    
    source "$PROXYSQL_CONFIG"
    
    read -p "Enter hostname to modify: " mysql_host
    read -p "Enter new weight (1-1000): " new_weight
    
    if [ -n "$mysql_host" ] && [ -n "$new_weight" ]; then
        mysql -h127.0.0.1 -P"$ADMIN_PORT" -u"$ADMIN_USER" -p"$ADMIN_PASSWORD" <<EOF
UPDATE mysql_servers SET weight=${new_weight} WHERE hostname='${mysql_host}';
LOAD MYSQL SERVERS TO RUNTIME;
SAVE MYSQL SERVERS TO DISK;
EOF
        print_success "Load balancing weight updated"
    fi
    
    press_any_key
}

# Backup configuration
backup_proxysql_config() {
    show_header
    print_info "Backing up ProxySQL configuration..."
    
    local backup_file="${PROXYSQL_DIR}/backup/proxysql_config_$(date +%Y%m%d_%H%M%S).sql"
    
    source "$PROXYSQL_CONFIG"
    
    # Dump all configuration tables
    mysql -h127.0.0.1 -P"$ADMIN_PORT" -u"$ADMIN_USER" -p"$ADMIN_PASSWORD" <<EOF > "$backup_file"
SELECT 'mysql_servers' AS table_name;
SELECT * FROM mysql_servers;
SELECT 'mysql_users' AS table_name;
SELECT * FROM mysql_users;
SELECT 'mysql_query_rules' AS table_name;
SELECT * FROM mysql_query_rules;
SELECT 'mysql_replication_hostgroups' AS table_name;
SELECT * FROM mysql_replication_hostgroups;
SELECT 'global_variables' AS table_name;
SELECT * FROM global_variables;
EOF

    # Also backup the SQLite database
    cp /var/lib/proxysql/proxysql.db "${PROXYSQL_DIR}/backup/proxysql_$(date +%Y%m%d_%H%M%S).db"
    
    print_success "Backup created: $backup_file"
    press_any_key
}

# Restore configuration
restore_proxysql_config() {
    show_header
    echo "Available backups:"
    ls -lh "${PROXYSQL_DIR}/backup/"*.db
    echo ""
    
    read -p "Enter backup file path: " backup_file
    
    if [ ! -f "$backup_file" ]; then
        print_error "Backup file not found"
        press_any_key
        return
    fi
    
    print_warning "This will replace current configuration!"
    read -p "Continue? (y/n): " confirm
    
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        systemctl stop proxysql
        cp "$backup_file" /var/lib/proxysql/proxysql.db
        systemctl start proxysql
        
        print_success "Configuration restored"
    fi
    
    press_any_key
}

# Start/Stop/Restart ProxySQL
start_proxysql() {
    print_info "Starting ProxySQL..."
    systemctl start proxysql
    sleep 2
    
    if systemctl is-active --quiet proxysql; then
        print_success "ProxySQL started"
    else
        print_error "Failed to start ProxySQL"
    fi
    press_any_key
}

stop_proxysql() {
    print_info "Stopping ProxySQL..."
    systemctl stop proxysql
    print_success "ProxySQL stopped"
    press_any_key
}

restart_proxysql() {
    print_info "Restarting ProxySQL..."
    systemctl restart proxysql
    sleep 2
    
    if systemctl is-active --quiet proxysql; then
        print_success "ProxySQL restarted"
    else
        print_error "Failed to restart ProxySQL"
    fi
    press_any_key
}

# Reload configuration
reload_proxysql_config() {
    show_header
    print_info "Reloading ProxySQL configuration..."
    
    source "$PROXYSQL_CONFIG"
    
    mysql -h127.0.0.1 -P"$ADMIN_PORT" -u"$ADMIN_USER" -p"$ADMIN_PASSWORD" <<'EOF'
LOAD MYSQL SERVERS TO RUNTIME;
LOAD MYSQL USERS TO RUNTIME;
LOAD MYSQL QUERY RULES TO RUNTIME;
LOAD MYSQL VARIABLES TO RUNTIME;
LOAD ADMIN VARIABLES TO RUNTIME;
EOF

    print_success "Configuration reloaded to runtime"
    press_any_key
}

# Save configuration
save_proxysql_config() {
    show_header
    print_info "Saving ProxySQL configuration to disk..."
    
    source "$PROXYSQL_CONFIG"
    
    mysql -h127.0.0.1 -P"$ADMIN_PORT" -u"$ADMIN_USER" -p"$ADMIN_PASSWORD" <<'EOF'
SAVE MYSQL SERVERS TO DISK;
SAVE MYSQL USERS TO DISK;
SAVE MYSQL QUERY RULES TO DISK;
SAVE MYSQL VARIABLES TO DISK;
SAVE ADMIN VARIABLES TO DISK;
EOF

    print_success "Configuration saved to disk"
    press_any_key
}
