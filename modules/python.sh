#!/bin/bash

################################################################################
# RocketVPS - Python Multi-Version Management Module
# Manage multiple Python versions using pyenv
################################################################################

PYENV_ROOT="/opt/pyenv"
PYTHON_CONFIG="${CONFIG_DIR}/python.conf"

# Python menu
python_menu() {
    while true; do
        show_header
        echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║                PYTHON VERSION MANAGEMENT                      ║${NC}"
        echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo "  ${CYAN}Installation:${NC}"
        echo "  1) Install pyenv"
        echo "  2) Install Python Version"
        echo "  3) Uninstall Python Version"
        echo "  4) List Installed Versions"
        echo ""
        echo "  ${CYAN}Configuration:${NC}"
        echo "  5) Set Global Python Version"
        echo "  6) Set Local Python Version (per directory)"
        echo "  7) Set Python Version for Domain"
        echo ""
        echo "  ${CYAN}Virtual Environments:${NC}"
        echo "  8) Create Virtual Environment"
        echo "  9) List Virtual Environments"
        echo "  10) Activate Virtual Environment"
        echo "  11) Remove Virtual Environment"
        echo ""
        echo "  ${CYAN}Package Management:${NC}"
        echo "  12) Install Package (pip)"
        echo "  13) List Installed Packages"
        echo "  14) Update pip"
        echo "  15) Create requirements.txt"
        echo ""
        echo "  ${CYAN}System:${NC}"
        echo "  16) Python Info"
        echo "  17) Update pyenv"
        echo ""
        echo "  0) Back to Main Menu"
        echo ""
        echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
        
        read -p "Enter your choice [0-17]: " python_choice
        
        case $python_choice in
            1) install_pyenv ;;
            2) install_python_version ;;
            3) uninstall_python_version ;;
            4) list_python_versions ;;
            5) set_global_python ;;
            6) set_local_python ;;
            7) set_domain_python ;;
            8) create_virtualenv ;;
            9) list_virtualenvs ;;
            10) activate_virtualenv ;;
            11) remove_virtualenv ;;
            12) install_python_package ;;
            13) list_python_packages ;;
            14) update_pip ;;
            15) create_requirements ;;
            16) python_info ;;
            17) update_pyenv ;;
            0) return ;;
            *)
                print_error "Invalid choice"
                sleep 2
                ;;
        esac
    done
}

# Install pyenv
install_pyenv() {
    show_header
    print_info "Installing pyenv..."
    
    # Check if already installed
    if [ -d "$PYENV_ROOT" ]; then
        print_warning "pyenv is already installed"
        read -p "Reinstall? (y/n): " reinstall
        if [[ ! "$reinstall" =~ ^[Yy]$ ]]; then
            press_any_key
            return
        fi
        rm -rf "$PYENV_ROOT"
    fi
    
    # Install dependencies
    if [[ "$OS" == "ubuntu" || "$OS" == "debian" ]]; then
        apt-get update
        apt-get install -y \
            make build-essential libssl-dev zlib1g-dev \
            libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm \
            libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev \
            libffi-dev liblzma-dev git
    elif [[ "$OS" == "centos" || "$OS" == "rhel" ]]; then
        yum groupinstall -y "Development Tools"
        yum install -y \
            zlib-devel bzip2 bzip2-devel readline-devel sqlite sqlite-devel \
            openssl-devel tk-devel libffi-devel xz-devel git
    fi
    
    # Install pyenv
    export PYENV_ROOT="$PYENV_ROOT"
    curl https://pyenv.run | bash
    
    # Configure shell
    cat >> ~/.bashrc <<'EOF'

# Pyenv configuration
export PYENV_ROOT="/opt/pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init --path)"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"
EOF

    # Source for current session
    export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init --path)"
    eval "$(pyenv init -)"
    
    if command -v pyenv &> /dev/null; then
        print_success "pyenv installed successfully"
        pyenv --version
        print_info "Please restart your shell or run: source ~/.bashrc"
    else
        print_error "pyenv installation failed"
    fi
    
    log_action "pyenv installed"
    press_any_key
}

# Install Python version
install_python_version() {
    show_header
    print_info "Install Python Version"
    echo ""
    
    if ! command -v pyenv &> /dev/null; then
        print_error "pyenv not installed. Please install pyenv first."
        press_any_key
        return
    fi
    
    echo "Popular Python versions:"
    echo "  1) Python 3.12 (latest)"
    echo "  2) Python 3.11"
    echo "  3) Python 3.10"
    echo "  4) Python 3.9"
    echo "  5) Python 2.7 (legacy)"
    echo "  6) Custom version"
    echo ""
    read -p "Select version [1-6]: " version_choice
    
    case $version_choice in
        1) py_version="3.12.0" ;;
        2) py_version="3.11.6" ;;
        3) py_version="3.10.13" ;;
        4) py_version="3.9.18" ;;
        5) py_version="2.7.18" ;;
        6)
            echo ""
            echo "Available versions: $(pyenv install --list | grep -E '^\s*[0-9]+\.[0-9]+\.[0-9]+$' | head -20 | tr '\n' ' ')"
            echo ""
            read -p "Enter version (e.g., 3.11.5): " py_version
            ;;
        *)
            print_error "Invalid choice"
            press_any_key
            return
            ;;
    esac
    
    print_info "Installing Python $py_version..."
    print_warning "This may take 5-10 minutes..."
    
    pyenv install "$py_version"
    
    if [ $? -eq 0 ]; then
        print_success "Python $py_version installed successfully"
        
        # Save to config
        echo "$py_version" >> "$PYTHON_CONFIG"
        sort -u "$PYTHON_CONFIG" -o "$PYTHON_CONFIG"
        
        read -p "Set as global version? (y/n): " set_global
        if [[ "$set_global" =~ ^[Yy]$ ]]; then
            pyenv global "$py_version"
            print_success "Python $py_version set as global version"
        fi
    else
        print_error "Installation failed"
    fi
    
    press_any_key
}

# Uninstall Python version
uninstall_python_version() {
    list_python_versions
    echo ""
    read -p "Enter Python version to uninstall (e.g., 3.11.5): " py_version
    
    if [ -z "$py_version" ]; then
        print_error "Version required"
        press_any_key
        return
    fi
    
    print_warning "This will remove Python $py_version"
    read -p "Continue? (y/n): " confirm
    
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        pyenv uninstall -f "$py_version"
        
        # Remove from config
        sed -i "/^${py_version}$/d" "$PYTHON_CONFIG"
        
        print_success "Python $py_version uninstalled"
    fi
    
    press_any_key
}

# List Python versions
list_python_versions() {
    show_header
    echo -e "${CYAN}Installed Python Versions:${NC}"
    echo ""
    
    if ! command -v pyenv &> /dev/null; then
        print_error "pyenv not installed"
        press_any_key
        return
    fi
    
    pyenv versions
    
    echo ""
    echo -e "${CYAN}Global Version:${NC}"
    pyenv global
    
    echo ""
    press_any_key
}

# Set global Python
set_global_python() {
    list_python_versions
    echo ""
    read -p "Enter version to set as global (e.g., 3.11.5): " py_version
    
    if [ -z "$py_version" ]; then
        print_error "Version required"
        press_any_key
        return
    fi
    
    pyenv global "$py_version"
    
    if [ $? -eq 0 ]; then
        print_success "Global Python version set to $py_version"
        python --version
    else
        print_error "Failed to set version"
    fi
    
    press_any_key
}

# Set local Python
set_local_python() {
    list_python_versions
    echo ""
    read -p "Enter directory path: " dir_path
    read -p "Enter Python version: " py_version
    
    if [ ! -d "$dir_path" ]; then
        print_error "Directory not found"
        press_any_key
        return
    fi
    
    cd "$dir_path"
    pyenv local "$py_version"
    
    if [ $? -eq 0 ]; then
        print_success "Local Python version set to $py_version for $dir_path"
        print_info "File created: ${dir_path}/.python-version"
    else
        print_error "Failed to set version"
    fi
    
    press_any_key
}

# Set domain Python
set_domain_python() {
    list_domains
    echo ""
    read -p "Enter domain name: " domain_name
    
    if [ ! -f "${NGINX_VHOST_DIR}/${domain_name}" ]; then
        print_error "Domain not found"
        press_any_key
        return
    fi
    
    list_python_versions
    echo ""
    read -p "Enter Python version: " py_version
    
    # Get domain root
    local doc_root=$(grep "root " "${NGINX_VHOST_DIR}/${domain_name}" | head -1 | awk '{print $2}' | tr -d ';')
    
    # Set local version
    cd "$doc_root"
    pyenv local "$py_version"
    
    print_success "Python $py_version set for domain $domain_name"
    print_info "Directory: $doc_root"
    
    press_any_key
}

# Create virtual environment
create_virtualenv() {
    show_header
    print_info "Create Virtual Environment"
    echo ""
    
    read -p "Enter environment name: " venv_name
    read -p "Enter Python version (leave empty for current): " py_version
    
    if [ -z "$venv_name" ]; then
        print_error "Name required"
        press_any_key
        return
    fi
    
    if [ -n "$py_version" ]; then
        pyenv virtualenv "$py_version" "$venv_name"
    else
        pyenv virtualenv "$venv_name"
    fi
    
    if [ $? -eq 0 ]; then
        print_success "Virtual environment $venv_name created"
        print_info "Activate with: pyenv activate $venv_name"
    else
        print_error "Failed to create virtual environment"
    fi
    
    press_any_key
}

# List virtual environments
list_virtualenvs() {
    show_header
    echo -e "${CYAN}Virtual Environments:${NC}"
    echo ""
    
    pyenv virtualenvs
    
    press_any_key
}

# Activate virtual environment
activate_virtualenv() {
    list_virtualenvs
    echo ""
    read -p "Enter environment name to activate: " venv_name
    
    print_info "To activate in your shell, run:"
    echo "  pyenv activate $venv_name"
    echo ""
    print_info "To deactivate, run:"
    echo "  pyenv deactivate"
    
    press_any_key
}

# Remove virtual environment
remove_virtualenv() {
    list_virtualenvs
    echo ""
    read -p "Enter environment name to remove: " venv_name
    
    pyenv uninstall -f "$venv_name"
    
    print_success "Virtual environment $venv_name removed"
    press_any_key
}

# Install Python package
install_python_package() {
    show_header
    print_info "Install Python Package"
    echo ""
    
    read -p "Enter package name(s) separated by space: " packages
    
    if [ -z "$packages" ]; then
        print_error "Package name required"
        press_any_key
        return
    fi
    
    pip install $packages
    
    if [ $? -eq 0 ]; then
        print_success "Package(s) installed"
    else
        print_error "Installation failed"
    fi
    
    press_any_key
}

# List Python packages
list_python_packages() {
    show_header
    echo -e "${CYAN}Installed Packages:${NC}"
    echo ""
    
    pip list
    
    press_any_key
}

# Update pip
update_pip() {
    show_header
    print_info "Updating pip..."
    
    python -m pip install --upgrade pip
    
    print_success "pip updated"
    pip --version
    
    press_any_key
}

# Create requirements.txt
create_requirements() {
    show_header
    print_info "Create requirements.txt"
    echo ""
    
    read -p "Enter directory path (current dir if empty): " dir_path
    dir_path=${dir_path:-$(pwd)}
    
    cd "$dir_path"
    pip freeze > requirements.txt
    
    print_success "requirements.txt created in $dir_path"
    echo ""
    echo "Contents:"
    cat requirements.txt
    
    press_any_key
}

# Python info
python_info() {
    show_header
    echo -e "${CYAN}Python Information:${NC}"
    echo ""
    
    echo "Python version:"
    python --version
    echo ""
    
    echo "Python path:"
    which python
    echo ""
    
    echo "pip version:"
    pip --version
    echo ""
    
    if command -v pyenv &> /dev/null; then
        echo "pyenv version:"
        pyenv --version
        echo ""
        
        echo "pyenv root:"
        echo "$PYENV_ROOT"
    fi
    
    press_any_key
}

# Update pyenv
update_pyenv() {
    show_header
    print_info "Updating pyenv..."
    
    cd "$PYENV_ROOT" && git pull
    
    print_success "pyenv updated"
    pyenv --version
    
    press_any_key
}
