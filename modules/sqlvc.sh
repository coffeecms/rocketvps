#!/bin/bash

################################################################################
# RocketVPS - SQL Version Control Module
# Database schema tracking and migration management using infostreams/db
################################################################################

SQLVC_DIR="/opt/sqlvc"
SQLVC_CONFIG="${CONFIG_DIR}/sqlvc.conf"

# SQL Version Control menu
sqlvc_menu() {
    while true; do
        show_header
        echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║                SQL VERSION CONTROL                            ║${NC}"
        echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo "  ${CYAN}Setup:${NC}"
        echo "  1) Install SQL Version Control"
        echo "  2) Initialize Database Tracking"
        echo "  3) Uninstall"
        echo ""
        echo "  ${CYAN}Schema Management:${NC}"
        echo "  4) Capture Current Schema"
        echo "  5) View Schema History"
        echo "  6) Compare Schemas"
        echo "  7) Generate Schema Diff"
        echo ""
        echo "  ${CYAN}Migrations:${NC}"
        echo "  8) Create Migration"
        echo "  9) Apply Migration"
        echo "  10) Rollback Migration"
        echo "  11) List Migrations"
        echo "  12) View Migration Status"
        echo ""
        echo "  ${CYAN}Database Operations:${NC}"
        echo "  13) Add Database Connection"
        echo "  14) List Tracked Databases"
        echo "  15) Remove Database Tracking"
        echo "  16) Sync Database"
        echo ""
        echo "  ${CYAN}Utilities:${NC}"
        echo "  17) Export Schema"
        echo "  18) Import Schema"
        echo "  19) Backup All Schemas"
        echo ""
        echo "  0) Back to Main Menu"
        echo ""
        echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
        
        read -p "Enter your choice [0-19]: " sqlvc_choice
        
        case $sqlvc_choice in
            1) install_sqlvc ;;
            2) init_sqlvc_database ;;
            3) uninstall_sqlvc ;;
            4) capture_schema ;;
            5) view_schema_history ;;
            6) compare_schemas ;;
            7) generate_schema_diff ;;
            8) create_migration ;;
            9) apply_migration ;;
            10) rollback_migration ;;
            11) list_migrations ;;
            12) view_migration_status ;;
            13) add_database_connection ;;
            14) list_tracked_databases ;;
            15) remove_database_tracking ;;
            16) sync_database ;;
            17) export_schema ;;
            18) import_schema ;;
            19) backup_all_schemas ;;
            0) return ;;
            *)
                print_error "Invalid choice"
                sleep 2
                ;;
        esac
    done
}

# Install SQL Version Control
install_sqlvc() {
    show_header
    print_info "Installing SQL Version Control..."
    
    # Check requirements
    if ! command -v git &> /dev/null; then
        print_error "Git is required"
        apt-get install -y git
    fi
    
    # Create directory
    mkdir -p "$SQLVC_DIR"/{schemas,migrations,backups}
    cd "$SQLVC_DIR"
    
    # Clone infostreams/db
    if [ ! -d "db" ]; then
        print_info "Cloning infostreams/db..."
        git clone https://github.com/infostreams/db.git
    fi
    
    # Make executable
    chmod +x db/db
    
    # Create symlink
    ln -sf "$SQLVC_DIR/db/db" /usr/local/bin/dbvc
    
    # Initialize git repo for schemas
    cd schemas
    git init
    git config user.email "rocketvps@localhost"
    git config user.name "RocketVPS"
    
    # Create config
    cat > "$SQLVC_CONFIG" <<EOF
SQLVC_DIR=${SQLVC_DIR}
SCHEMAS_DIR=${SQLVC_DIR}/schemas
MIGRATIONS_DIR=${SQLVC_DIR}/migrations
BACKUPS_DIR=${SQLVC_DIR}/backups
INSTALLED_DATE=$(date +%Y-%m-%d)
EOF

    # Install PHP if not present (required for db tool)
    if ! command -v php &> /dev/null; then
        print_info "Installing PHP..."
        if [[ "$OS" == "ubuntu" || "$OS" == "debian" ]]; then
            apt-get install -y php-cli php-mysql php-pgsql
        elif [[ "$OS" == "centos" || "$OS" == "rhel" ]]; then
            yum install -y php-cli php-mysqlnd php-pgsql
        fi
    fi
    
    if command -v dbvc &> /dev/null; then
        print_success "SQL Version Control installed successfully"
        dbvc --version
    else
        print_error "Installation failed"
    fi
    
    log_action "SQL Version Control installed"
    press_any_key
}

# Initialize database tracking
init_sqlvc_database() {
    show_header
    print_info "Initialize Database Tracking"
    echo ""
    
    echo "Database type:"
    echo "  1) MySQL/MariaDB"
    echo "  2) PostgreSQL"
    echo ""
    read -p "Select type [1-2]: " db_type
    
    case $db_type in
        1)
            db_driver="mysql"
            read -p "Host (default: localhost): " db_host
            db_host=${db_host:-localhost}
            read -p "Port (default: 3306): " db_port
            db_port=${db_port:-3306}
            ;;
        2)
            db_driver="pgsql"
            read -p "Host (default: localhost): " db_host
            db_host=${db_host:-localhost}
            read -p "Port (default: 5432): " db_port
            db_port=${db_port:-5432}
            ;;
        *)
            print_error "Invalid choice"
            press_any_key
            return
            ;;
    esac
    
    read -p "Database name: " db_name
    read -p "Username: " db_user
    read -p "Password: " -s db_pass
    echo ""
    
    if [ -z "$db_name" ] || [ -z "$db_user" ]; then
        print_error "Database name and username required"
        press_any_key
        return
    fi
    
    # Create connection config
    local config_file="${SQLVC_DIR}/schemas/${db_name}.ini"
    
    cat > "$config_file" <<EOF
[database]
driver = ${db_driver}
host = ${db_host}
port = ${db_port}
database = ${db_name}
username = ${db_user}
password = ${db_pass}
EOF

    chmod 600 "$config_file"
    
    # Capture initial schema
    print_info "Capturing initial schema..."
    cd "${SQLVC_DIR}/schemas"
    
    dbvc --config="$config_file" dump "${db_name}_initial.sql"
    
    # Commit to git
    git add .
    git commit -m "Initial schema for ${db_name}"
    
    print_success "Database ${db_name} initialized for tracking"
    print_info "Config saved: $config_file"
    
    press_any_key
}

# Uninstall
uninstall_sqlvc() {
    show_header
    print_warning "This will remove SQL Version Control"
    read -p "Keep schema backups? (y/n): " keep_backups
    
    read -p "Proceed with uninstallation? (yes/no): " confirm
    
    if [ "$confirm" != "yes" ]; then
        return
    fi
    
    rm -f /usr/local/bin/dbvc
    
    if [[ "$keep_backups" =~ ^[Yy]$ ]]; then
        mv "${SQLVC_DIR}/schemas" "${BACKUP_DIR}/sqlvc_schemas_$(date +%Y%m%d)"
        mv "${SQLVC_DIR}/migrations" "${BACKUP_DIR}/sqlvc_migrations_$(date +%Y%m%d)"
    fi
    
    rm -rf "$SQLVC_DIR"
    rm -f "$SQLVC_CONFIG"
    
    print_success "SQL Version Control uninstalled"
    press_any_key
}

# Capture schema
capture_schema() {
    show_header
    print_info "Capture Current Schema"
    
    list_tracked_databases
    echo ""
    read -p "Enter database name: " db_name
    
    local config_file="${SQLVC_DIR}/schemas/${db_name}.ini"
    
    if [ ! -f "$config_file" ]; then
        print_error "Database not tracked. Please initialize first."
        press_any_key
        return
    fi
    
    read -p "Enter description: " description
    description=${description:-"Schema snapshot"}
    
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local schema_file="${SQLVC_DIR}/schemas/${db_name}_${timestamp}.sql"
    
    cd "${SQLVC_DIR}/schemas"
    dbvc --config="$config_file" dump "$schema_file"
    
    # Commit to git
    git add .
    git commit -m "${db_name}: ${description}"
    
    print_success "Schema captured: $schema_file"
    press_any_key
}

# View schema history
view_schema_history() {
    show_header
    echo -e "${CYAN}Schema History:${NC}"
    echo ""
    
    cd "${SQLVC_DIR}/schemas"
    git log --oneline --graph --all --decorate
    
    press_any_key
}

# Compare schemas
compare_schemas() {
    show_header
    print_info "Compare Schemas"
    echo ""
    
    list_tracked_databases
    echo ""
    read -p "Enter database name: " db_name
    
    cd "${SQLVC_DIR}/schemas"
    
    echo ""
    echo "Available snapshots:"
    git log --oneline --all | grep "$db_name"
    echo ""
    
    read -p "Enter first commit hash: " commit1
    read -p "Enter second commit hash (or press Enter for current): " commit2
    
    if [ -z "$commit2" ]; then
        git diff "$commit1" -- "${db_name}*.sql"
    else
        git diff "$commit1" "$commit2" -- "${db_name}*.sql"
    fi
    
    press_any_key
}

# Generate schema diff
generate_schema_diff() {
    show_header
    print_info "Generate Schema Diff"
    
    list_tracked_databases
    echo ""
    read -p "Enter source database: " db_source
    read -p "Enter target database: " db_target
    
    local config_source="${SQLVC_DIR}/schemas/${db_source}.ini"
    local config_target="${SQLVC_DIR}/schemas/${db_target}.ini"
    
    if [ ! -f "$config_source" ] || [ ! -f "$config_target" ]; then
        print_error "Database configuration not found"
        press_any_key
        return
    fi
    
    local diff_file="${SQLVC_DIR}/migrations/diff_${db_source}_to_${db_target}_$(date +%Y%m%d_%H%M%S).sql"
    
    dbvc --config="$config_source" diff --target-config="$config_target" > "$diff_file"
    
    print_success "Diff generated: $diff_file"
    echo ""
    echo "Preview:"
    head -50 "$diff_file"
    
    press_any_key
}

# Create migration
create_migration() {
    show_header
    print_info "Create Migration"
    echo ""
    
    read -p "Enter migration name: " migration_name
    read -p "Enter database name: " db_name
    
    if [ -z "$migration_name" ] || [ -z "$db_name" ]; then
        print_error "Migration name and database required"
        press_any_key
        return
    fi
    
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local migration_file="${SQLVC_DIR}/migrations/${timestamp}_${migration_name}.sql"
    
    cat > "$migration_file" <<EOF
-- Migration: ${migration_name}
-- Database: ${db_name}
-- Created: $(date)
-- Description: 

-- UP Migration
-- Add your SQL statements here


-- DOWN Migration (for rollback)
-- Add rollback SQL statements here

EOF

    print_success "Migration created: $migration_file"
    print_info "Edit the file to add SQL statements"
    
    read -p "Open in editor now? (y/n): " open_editor
    if [[ "$open_editor" =~ ^[Yy]$ ]]; then
        ${EDITOR:-nano} "$migration_file"
    fi
    
    press_any_key
}

# Apply migration
apply_migration() {
    show_header
    print_info "Apply Migration"
    
    echo "Available migrations:"
    ls -1 "${SQLVC_DIR}/migrations"/*.sql 2>/dev/null | xargs -n 1 basename
    echo ""
    
    read -p "Enter migration filename: " migration_file
    read -p "Enter database name: " db_name
    
    local config_file="${SQLVC_DIR}/schemas/${db_name}.ini"
    local full_path="${SQLVC_DIR}/migrations/${migration_file}"
    
    if [ ! -f "$config_file" ]; then
        print_error "Database configuration not found"
        press_any_key
        return
    fi
    
    if [ ! -f "$full_path" ]; then
        print_error "Migration file not found"
        press_any_key
        return
    fi
    
    print_warning "This will apply migration to ${db_name}"
    read -p "Continue? (y/n): " confirm
    
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        # Backup current schema first
        capture_schema
        
        # Apply migration
        dbvc --config="$config_file" exec < "$full_path"
        
        if [ $? -eq 0 ]; then
            print_success "Migration applied successfully"
            
            # Record in migration log
            echo "$(date): Applied ${migration_file} to ${db_name}" >> "${SQLVC_DIR}/migrations/migration.log"
        else
            print_error "Migration failed"
        fi
    fi
    
    press_any_key
}

# Rollback migration
rollback_migration() {
    show_header
    print_info "Rollback Migration"
    
    echo "Recent migrations:"
    tail -10 "${SQLVC_DIR}/migrations/migration.log"
    echo ""
    
    read -p "Enter migration filename to rollback: " migration_file
    read -p "Enter database name: " db_name
    
    local config_file="${SQLVC_DIR}/schemas/${db_name}.ini"
    
    print_warning "This will rollback migration from ${db_name}"
    print_info "Make sure the migration file has DOWN statements"
    read -p "Continue? (y/n): " confirm
    
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        # Backup first
        capture_schema
        
        print_info "Please execute the DOWN statements manually or restore from backup"
        print_info "Schema backups available in: ${SQLVC_DIR}/schemas/"
    fi
    
    press_any_key
}

# List migrations
list_migrations() {
    show_header
    echo -e "${CYAN}Available Migrations:${NC}"
    echo ""
    
    ls -lh "${SQLVC_DIR}/migrations"/*.sql 2>/dev/null
    
    echo ""
    echo -e "${CYAN}Migration Log:${NC}"
    echo ""
    
    if [ -f "${SQLVC_DIR}/migrations/migration.log" ]; then
        cat "${SQLVC_DIR}/migrations/migration.log"
    else
        echo "No migrations applied yet"
    fi
    
    press_any_key
}

# View migration status
view_migration_status() {
    show_header
    echo -e "${CYAN}Migration Status:${NC}"
    echo ""
    
    if [ -f "${SQLVC_DIR}/migrations/migration.log" ]; then
        echo "Total migrations applied: $(wc -l < "${SQLVC_DIR}/migrations/migration.log")"
        echo ""
        echo "Last 5 migrations:"
        tail -5 "${SQLVC_DIR}/migrations/migration.log"
    else
        echo "No migrations applied yet"
    fi
    
    press_any_key
}

# Add database connection
add_database_connection() {
    init_sqlvc_database
}

# List tracked databases
list_tracked_databases() {
    echo -e "${CYAN}Tracked Databases:${NC}"
    echo ""
    
    if [ -d "${SQLVC_DIR}/schemas" ]; then
        for config in "${SQLVC_DIR}/schemas"/*.ini; do
            if [ -f "$config" ]; then
                local db_name=$(basename "$config" .ini)
                local db_driver=$(grep "^driver" "$config" | cut -d= -f2 | tr -d ' ')
                local db_host=$(grep "^host" "$config" | cut -d= -f2 | tr -d ' ')
                echo "  - ${db_name} (${db_driver} @ ${db_host})"
            fi
        done
    else
        echo "No databases tracked yet"
    fi
}

# Remove database tracking
remove_database_tracking() {
    show_header
    list_tracked_databases
    echo ""
    read -p "Enter database name to remove: " db_name
    
    local config_file="${SQLVC_DIR}/schemas/${db_name}.ini"
    
    if [ ! -f "$config_file" ]; then
        print_error "Database not found"
        press_any_key
        return
    fi
    
    print_warning "This will stop tracking ${db_name}"
    read -p "Keep schema history? (y/n): " keep_history
    
    rm -f "$config_file"
    
    if [[ ! "$keep_history" =~ ^[Yy]$ ]]; then
        cd "${SQLVC_DIR}/schemas"
        git rm "${db_name}"*.sql 2>/dev/null
        git commit -m "Removed tracking for ${db_name}"
    fi
    
    print_success "Database tracking removed"
    press_any_key
}

# Sync database
sync_database() {
    show_header
    print_info "Sync Database Schema"
    
    list_tracked_databases
    echo ""
    read -p "Enter source database: " db_source
    read -p "Enter target database: " db_target
    
    local config_source="${SQLVC_DIR}/schemas/${db_source}.ini"
    local config_target="${SQLVC_DIR}/schemas/${db_target}.ini"
    
    if [ ! -f "$config_source" ] || [ ! -f "$config_target" ]; then
        print_error "Database configuration not found"
        press_any_key
        return
    fi
    
    print_warning "This will sync ${db_target} to match ${db_source}"
    read -p "Continue? (y/n): " confirm
    
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        # Generate diff
        local sync_file="${SQLVC_DIR}/migrations/sync_$(date +%Y%m%d_%H%M%S).sql"
        dbvc --config="$config_source" diff --target-config="$config_target" > "$sync_file"
        
        # Apply to target
        dbvc --config="$config_target" exec < "$sync_file"
        
        print_success "Databases synced"
        print_info "Sync script saved: $sync_file"
    fi
    
    press_any_key
}

# Export schema
export_schema() {
    show_header
    list_tracked_databases
    echo ""
    read -p "Enter database name: " db_name
    
    local config_file="${SQLVC_DIR}/schemas/${db_name}.ini"
    
    if [ ! -f "$config_file" ]; then
        print_error "Database not found"
        press_any_key
        return
    fi
    
    local export_file="${BACKUP_DIR}/schema_${db_name}_$(date +%Y%m%d_%H%M%S).sql"
    
    dbvc --config="$config_file" dump "$export_file"
    
    print_success "Schema exported: $export_file"
    press_any_key
}

# Import schema
import_schema() {
    show_header
    read -p "Enter schema file path: " schema_file
    
    if [ ! -f "$schema_file" ]; then
        print_error "File not found"
        press_any_key
        return
    fi
    
    list_tracked_databases
    echo ""
    read -p "Enter target database: " db_name
    
    local config_file="${SQLVC_DIR}/schemas/${db_name}.ini"
    
    if [ ! -f "$config_file" ]; then
        print_error "Database not found"
        press_any_key
        return
    fi
    
    print_warning "This will import schema to ${db_name}"
    read -p "Continue? (y/n): " confirm
    
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        dbvc --config="$config_file" exec < "$schema_file"
        print_success "Schema imported"
    fi
    
    press_any_key
}

# Backup all schemas
backup_all_schemas() {
    show_header
    print_info "Backing up all schemas..."
    
    local backup_archive="${BACKUP_DIR}/all_schemas_$(date +%Y%m%d_%H%M%S).tar.gz"
    
    tar -czf "$backup_archive" -C "$SQLVC_DIR" schemas migrations
    
    print_success "All schemas backed up: $backup_archive"
    press_any_key
}
