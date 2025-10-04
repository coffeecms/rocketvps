#!/bin/bash

################################################################################
# RocketVPS Installation Script
# Version: 1.0.0
# Description: Automated installation script for RocketVPS
################################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

INSTALL_DIR="/opt/rocketvps"

# Print functions
print_header() {
    clear
    echo -e "${CYAN}"
    echo "═══════════════════════════════════════════════════════════════"
    echo "                  🚀 RocketVPS Installer 🚀                   "
    echo "            Professional VPS Management System v1.0            "
    echo "═══════════════════════════════════════════════════════════════"
    echo -e "${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${CYAN}ℹ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
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
        print_info "Detected OS: $OS $VER"
    else
        print_error "Cannot detect OS"
        exit 1
    fi
    
    if [[ "$OS" != "ubuntu" && "$OS" != "debian" && "$OS" != "centos" && "$OS" != "rhel" ]]; then
        print_error "Unsupported OS: $OS"
        print_info "Supported: Ubuntu, Debian, CentOS, RHEL"
        exit 1
    fi
}

# Install dependencies
install_dependencies() {
    print_info "Installing dependencies..."
    
    if [[ "$OS" == "ubuntu" || "$OS" == "debian" ]]; then
        apt-get update -qq
        apt-get install -y curl wget git tar gzip sudo bc net-tools >/dev/null 2>&1
    elif [[ "$OS" == "centos" || "$OS" == "rhel" ]]; then
        yum install -y curl wget git tar gzip sudo bc net-tools >/dev/null 2>&1
    fi
    
    print_success "Dependencies installed"
}

# Create directory structure
create_directories() {
    print_info "Creating directory structure..."
    
    mkdir -p "${INSTALL_DIR}"
    mkdir -p "${INSTALL_DIR}/modules"
    mkdir -p "${INSTALL_DIR}/config"
    mkdir -p "${INSTALL_DIR}/backups"
    mkdir -p "${INSTALL_DIR}/logs"
    
    print_success "Directories created"
}

# Copy files
copy_files() {
    print_info "Copying RocketVPS files..."
    
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    
    # Copy main script
    if [ -f "${script_dir}/rocketvps.sh" ]; then
        cp "${script_dir}/rocketvps.sh" "${INSTALL_DIR}/"
    fi
    
    # Copy modules
    if [ -d "${script_dir}/modules" ]; then
        cp -r "${script_dir}/modules"/* "${INSTALL_DIR}/modules/"
    fi
    
    # Set permissions
    chmod +x "${INSTALL_DIR}/rocketvps.sh"
    chmod +x "${INSTALL_DIR}/modules"/*.sh 2>/dev/null || true
    
    print_success "Files copied"
}

# Create symlink
create_symlink() {
    print_info "Creating command symlink..."
    
    ln -sf "${INSTALL_DIR}/rocketvps.sh" /usr/local/bin/rocketvps
    
    print_success "Symlink created: rocketvps command available"
}

# Initialize configuration
initialize_config() {
    print_info "Initializing configuration..."
    
    # Create initial config files
    touch "${INSTALL_DIR}/config/domains.list"
    touch "${INSTALL_DIR}/config/php_versions.conf"
    
    print_success "Configuration initialized"
}

# Display completion message
show_completion() {
    print_header
    echo ""
    print_success "RocketVPS installed successfully!"
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${GREEN}Installation Directory:${NC} ${INSTALL_DIR}"
    echo -e "${GREEN}Command:${NC} rocketvps"
    echo ""
    echo -e "${YELLOW}Quick Start:${NC}"
    echo "  1. Run: ${CYAN}rocketvps${NC}"
    echo "  2. Choose option 1 to install Nginx"
    echo "  3. Choose option 2 to add your first domain"
    echo "  4. Choose option 3 to setup SSL certificates"
    echo ""
    echo -e "${YELLOW}Recommended Next Steps:${NC}"
    echo "  • Apply security settings (Menu 12)"
    echo "  • Setup automatic backups (Menu 10)"
    echo "  • Configure firewall (Menu 8)"
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${GREEN}Documentation:${NC} https://github.com/yourusername/rocketvps"
    echo -e "${GREEN}Support:${NC} https://github.com/yourusername/rocketvps/issues"
    echo ""
    echo -e "${CYAN}Thank you for using RocketVPS! 🚀${NC}"
    echo ""
}

# Main installation function
main() {
    print_header
    
    echo ""
    print_info "Starting RocketVPS installation..."
    echo ""
    
    check_root
    sleep 1
    
    detect_os
    sleep 1
    
    install_dependencies
    sleep 1
    
    create_directories
    sleep 1
    
    copy_files
    sleep 1
    
    create_symlink
    sleep 1
    
    initialize_config
    sleep 1
    
    echo ""
    show_completion
}

# Run installation
main
