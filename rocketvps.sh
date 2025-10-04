#!/bin/bash

################################################################################
# RocketVPS - Professional VPS Management Script
# Version: 2.0.0
# Description: Comprehensive VPS management tool for Nginx, PHP, Database,
#              SSL, Security, Backup/Restore, Docker, Mail Server, n8n,
#              Redash, SQL Version Control, Python Multi-Version, Milvus DB,
#              ProxySQL High-Performance MySQL Proxy
################################################################################

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration paths
ROCKETVPS_DIR="/opt/rocketvps"
INSTALL_DIR="${ROCKETVPS_DIR}"
CONFIG_DIR="${ROCKETVPS_DIR}/config"
BACKUP_DIR="${ROCKETVPS_DIR}/backups"
LOG_DIR="${ROCKETVPS_DIR}/logs"
NGINX_VHOST_DIR="/etc/nginx/sites-available"
NGINX_ENABLED_DIR="/etc/nginx/sites-enabled"
PHP_VERSIONS_FILE="${CONFIG_DIR}/php_versions.conf"
DOMAIN_LIST_FILE="${CONFIG_DIR}/domains.list"
SSL_RENEWAL_SCRIPT="${ROCKETVPS_DIR}/ssl_renewal.sh"

# Initialize directories
init_directories() {
    mkdir -p "${ROCKETVPS_DIR}"
    mkdir -p "${CONFIG_DIR}"
    mkdir -p "${BACKUP_DIR}"
    mkdir -p "${LOG_DIR}"
    mkdir -p "${NGINX_VHOST_DIR}"
    mkdir -p "${NGINX_ENABLED_DIR}"
    
    touch "${DOMAIN_LIST_FILE}"
    touch "${PHP_VERSIONS_FILE}"
}

# Logging function
log_message() {
    local level=$1
    shift
    local message="$@"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [${level}] ${message}" >> "${LOG_DIR}/rocketvps.log"
}

# Print colored message
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Print success message
print_success() {
    print_message "${GREEN}" "✓ $1"
    log_message "SUCCESS" "$1"
}

# Print error message
print_error() {
    print_message "${RED}" "✗ $1"
    log_message "ERROR" "$1"
}

# Print warning message
print_warning() {
    print_message "${YELLOW}" "⚠ $1"
    log_message "WARNING" "$1"
}

# Print info message
print_info() {
    print_message "${CYAN}" "ℹ $1"
    log_message "INFO" "$1"
}

# Print header
print_header() {
    echo -e "${CYAN}"
    echo "═══════════════════════════════════════════════════════════════"
    echo "  $1"
    echo "═══════════════════════════════════════════════════════════════"
    echo -e "${NC}"
}

# Log action
log_action() {
    log_message "ACTION" "$1"
}

# Check if running as root
check_root() {
    if [ "$EUID" -ne 0 ]; then 
        print_error "Please run as root or with sudo"
        exit 1
    fi
}

# Detect OS
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        VER=$VERSION_ID
    else
        print_error "Cannot detect OS"
        exit 1
    fi
    
    if [[ "$OS" != "ubuntu" && "$OS" != "debian" && "$OS" != "centos" && "$OS" != "rhel" ]]; then
        print_error "Unsupported OS: $OS"
        exit 1
    fi
}

# Header display
show_header() {
    clear
    echo -e "${CYAN}"
    echo "═══════════════════════════════════════════════════════════════"
    echo "                       🚀 RocketVPS 🚀                         "
    echo "           Professional VPS Management System v2.0             "
    echo "═══════════════════════════════════════════════════════════════"
    echo -e "${NC}"
}

# Main menu
show_main_menu() {
    show_header
    echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                        MAIN MENU                              ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "  1)  Nginx Management"
    echo "  2)  Domain Management"
    echo "  3)  SSL Management"
    echo "  4)  Cache Management (Redis)"
    echo "  5)  PHP Management"
    echo "  6)  Database Management"
    echo "  7)  FTP Management"
    echo "  8)  CSF Firewall Management"
    echo "  9)  Permission Management"
    echo "  10) Backup & Restore"
    echo "  11) Cronjob Management"
    echo "  12) Security Enhancement"
    echo "  13) Gitea Version Control"
    echo "  14) VPS Optimization"
    echo "  15) phpMyAdmin Management"
    echo "  16) WordPress Management"
    echo "  17) System Information"
    echo "  18) View Logs"
    echo ""
    echo -e "${YELLOW}  === NEW v2.0 FEATURES ===${NC}"
    echo "  19) Docker Management"
    echo "  20) Mail Server (Mailu)"
    echo "  21) n8n Automation"
    echo "  22) Redash BI Platform"
    echo "  23) SQL Version Control"
    echo "  24) Python Multi-Version"
    echo "  25) Milvus Vector Database"
    echo "  26) ProxySQL (MySQL Proxy)"
    echo ""
    echo "  0)  Exit"
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
}

# Press any key to continue
press_any_key() {
    echo ""
    read -n 1 -s -r -p "Press any key to continue..."
}

# Source all modules
source_modules() {
    local modules_dir="${ROCKETVPS_DIR}/modules"
    
    if [ -d "$modules_dir" ]; then
        for module in "$modules_dir"/*.sh; do
            if [ -f "$module" ]; then
                source "$module"
            fi
        done
    fi
}

# Main function
main() {
    check_root
    detect_os
    init_directories
    source_modules
    
    # Check if databases need to be installed on first run
    if [ ! -f "${CONFIG_DIR}/.databases_installed" ]; then
        auto_install_databases
    fi
    
    while true; do
        show_main_menu
        read -p "Enter your choice [0-26]: " choice
        
        case $choice in
            1) nginx_menu ;;
            2) domain_menu ;;
            3) ssl_menu ;;
            4) cache_menu ;;
            5) php_menu ;;
            6) database_menu ;;
            7) ftp_menu ;;
            8) csf_menu ;;
            9) permission_menu ;;
            10) backup_menu ;;
            11) cronjob_menu ;;
            12) security_menu ;;
            13) gitea_menu ;;
            14) optimize_menu ;;
            15) phpmyadmin_menu ;;
            16) wordpress_menu ;;
            17) system_info ;;
            18) view_logs ;;
            19) docker_menu ;;
            20) mailserver_menu ;;
            21) n8n_menu ;;
            22) redash_menu ;;
            23) sqlvc_menu ;;
            24) python_menu ;;
            25) milvus_menu ;;
            26) proxysql_menu ;;
            0) 
                print_info "Thank you for using RocketVPS!"
                exit 0
                ;;
            *)
                print_error "Invalid choice. Please try again."
                sleep 2
                ;;
        esac
    done
}

# Run main function
main
