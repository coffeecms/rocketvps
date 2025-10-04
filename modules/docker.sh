#!/bin/bash

################################################################################
# RocketVPS - Docker Management Module
# Manage Docker, Docker Compose, containers, images, volumes, networks
################################################################################

# Docker menu
docker_menu() {
    while true; do
        show_header
        echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║                   DOCKER MANAGEMENT                           ║${NC}"
        echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo "  ${CYAN}Installation:${NC}"
        echo "  1) Install Docker"
        echo "  2) Install Docker Compose"
        echo "  3) Uninstall Docker"
        echo ""
        echo "  ${CYAN}Container Management:${NC}"
        echo "  4) List Containers"
        echo "  5) Start Container"
        echo "  6) Stop Container"
        echo "  7) Restart Container"
        echo "  8) Remove Container"
        echo "  9) View Container Logs"
        echo "  10) Execute Command in Container"
        echo ""
        echo "  ${CYAN}Image Management:${NC}"
        echo "  11) List Images"
        echo "  12) Pull Image"
        echo "  13) Remove Image"
        echo "  14) Prune Unused Images"
        echo ""
        echo "  ${CYAN}Volume & Network:${NC}"
        echo "  15) List Volumes"
        echo "  16) Remove Volume"
        echo "  17) List Networks"
        echo "  18) Create Network"
        echo ""
        echo "  ${CYAN}System:${NC}"
        echo "  19) Docker Stats"
        echo "  20) Docker Info"
        echo "  21) System Prune"
        echo ""
        echo "  0) Back to Main Menu"
        echo ""
        echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
        
        read -p "Enter your choice [0-21]: " docker_choice
        
        case $docker_choice in
            1) install_docker ;;
            2) install_docker_compose ;;
            3) uninstall_docker ;;
            4) list_containers ;;
            5) start_container ;;
            6) stop_container ;;
            7) restart_container ;;
            8) remove_container ;;
            9) view_container_logs ;;
            10) exec_container ;;
            11) list_images ;;
            12) pull_image ;;
            13) remove_image ;;
            14) prune_images ;;
            15) list_volumes ;;
            16) remove_volume ;;
            17) list_networks ;;
            18) create_network ;;
            19) docker_stats ;;
            20) docker_info ;;
            21) system_prune ;;
            0) return ;;
            *)
                print_error "Invalid choice"
                sleep 2
                ;;
        esac
    done
}

# Install Docker
install_docker() {
    show_header
    print_info "Installing Docker..."
    
    # Check if already installed
    if command -v docker &> /dev/null; then
        print_warning "Docker is already installed"
        docker --version
        read -p "Do you want to reinstall? (y/n): " reinstall
        if [[ ! "$reinstall" =~ ^[Yy]$ ]]; then
            press_any_key
            return
        fi
    fi
    
    if [[ "$OS" == "ubuntu" || "$OS" == "debian" ]]; then
        # Remove old versions
        apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true
        
        # Install dependencies
        apt-get update
        apt-get install -y \
            apt-transport-https \
            ca-certificates \
            curl \
            gnupg \
            lsb-release
        
        # Add Docker's official GPG key
        mkdir -p /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/${OS}/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        
        # Set up repository
        echo \
          "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/${OS} \
          $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
        
        # Install Docker Engine
        apt-get update
        apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        
    elif [[ "$OS" == "centos" || "$OS" == "rhel" ]]; then
        # Remove old versions
        yum remove -y docker docker-client docker-client-latest docker-common docker-latest \
                      docker-latest-logrotate docker-logrotate docker-engine 2>/dev/null || true
        
        # Install dependencies
        yum install -y yum-utils
        
        # Set up repository
        yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
        
        # Install Docker Engine
        yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    fi
    
    # Start and enable Docker
    systemctl start docker
    systemctl enable docker
    
    # Add current user to docker group (if not root)
    if [ "$EUID" -ne 0 ]; then
        usermod -aG docker $USER
        print_info "User added to docker group. Please log out and back in for changes to take effect."
    fi
    
    # Verify installation
    if docker --version && docker compose version; then
        print_success "Docker installed successfully"
        echo ""
        docker --version
        docker compose version
        echo ""
        
        # Run hello-world test
        print_info "Running test container..."
        docker run hello-world
        
        log_action "Docker installed"
    else
        print_error "Docker installation failed"
    fi
    
    press_any_key
}

# Install Docker Compose (standalone - legacy)
install_docker_compose() {
    show_header
    print_info "Installing Docker Compose..."
    
    # Check if Docker is installed
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install Docker first."
        press_any_key
        return
    fi
    
    # Check if already installed
    if command -v docker-compose &> /dev/null; then
        print_warning "Docker Compose is already installed"
        docker-compose --version
        read -p "Do you want to reinstall? (y/n): " reinstall
        if [[ ! "$reinstall" =~ ^[Yy]$ ]]; then
            press_any_key
            return
        fi
    fi
    
    # Get latest version
    COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d\" -f4)
    
    if [ -z "$COMPOSE_VERSION" ]; then
        COMPOSE_VERSION="v2.23.0"
        print_warning "Could not detect latest version, using $COMPOSE_VERSION"
    fi
    
    print_info "Installing Docker Compose $COMPOSE_VERSION..."
    
    # Download and install
    curl -L "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" \
         -o /usr/local/bin/docker-compose
    
    chmod +x /usr/local/bin/docker-compose
    
    # Create symlink
    ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose
    
    if docker-compose --version; then
        print_success "Docker Compose installed successfully"
        docker-compose --version
    else
        print_error "Docker Compose installation failed"
    fi
    
    press_any_key
}

# Uninstall Docker
uninstall_docker() {
    show_header
    print_warning "This will remove Docker and all containers, images, volumes!"
    read -p "Are you sure? (yes/no): " confirm
    
    if [ "$confirm" != "yes" ]; then
        print_info "Uninstallation cancelled"
        press_any_key
        return
    fi
    
    print_info "Stopping Docker..."
    systemctl stop docker
    
    if [[ "$OS" == "ubuntu" || "$OS" == "debian" ]]; then
        apt-get purge -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        apt-get autoremove -y
        rm -rf /var/lib/docker
        rm -rf /var/lib/containerd
    elif [[ "$OS" == "centos" || "$OS" == "rhel" ]]; then
        yum remove -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        rm -rf /var/lib/docker
        rm -rf /var/lib/containerd
    fi
    
    # Remove docker-compose standalone
    rm -f /usr/local/bin/docker-compose
    rm -f /usr/bin/docker-compose
    
    print_success "Docker uninstalled"
    log_action "Docker uninstalled"
    
    press_any_key
}

# List containers
list_containers() {
    show_header
    echo -e "${CYAN}Docker Containers:${NC}"
    echo ""
    
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed"
        press_any_key
        return
    fi
    
    echo "1) Running containers"
    echo "2) All containers (including stopped)"
    read -p "Choice [1-2]: " list_choice
    
    echo ""
    if [ "$list_choice" = "2" ]; then
        docker ps -a
    else
        docker ps
    fi
    
    echo ""
    press_any_key
}

# Start container
start_container() {
    list_containers
    echo ""
    read -p "Enter container ID or name: " container
    
    if [ -z "$container" ]; then
        print_error "Container ID/name required"
        press_any_key
        return
    fi
    
    docker start "$container"
    
    if [ $? -eq 0 ]; then
        print_success "Container $container started"
    else
        print_error "Failed to start container"
    fi
    
    press_any_key
}

# Stop container
stop_container() {
    list_containers
    echo ""
    read -p "Enter container ID or name: " container
    
    if [ -z "$container" ]; then
        print_error "Container ID/name required"
        press_any_key
        return
    fi
    
    docker stop "$container"
    
    if [ $? -eq 0 ]; then
        print_success "Container $container stopped"
    else
        print_error "Failed to stop container"
    fi
    
    press_any_key
}

# Restart container
restart_container() {
    list_containers
    echo ""
    read -p "Enter container ID or name: " container
    
    if [ -z "$container" ]; then
        print_error "Container ID/name required"
        press_any_key
        return
    fi
    
    docker restart "$container"
    
    if [ $? -eq 0 ]; then
        print_success "Container $container restarted"
    else
        print_error "Failed to restart container"
    fi
    
    press_any_key
}

# Remove container
remove_container() {
    list_containers
    echo ""
    read -p "Enter container ID or name: " container
    
    if [ -z "$container" ]; then
        print_error "Container ID/name required"
        press_any_key
        return
    fi
    
    read -p "Force remove? (y/n): " force
    
    if [[ "$force" =~ ^[Yy]$ ]]; then
        docker rm -f "$container"
    else
        docker rm "$container"
    fi
    
    if [ $? -eq 0 ]; then
        print_success "Container $container removed"
    else
        print_error "Failed to remove container"
    fi
    
    press_any_key
}

# View container logs
view_container_logs() {
    list_containers
    echo ""
    read -p "Enter container ID or name: " container
    
    if [ -z "$container" ]; then
        print_error "Container ID/name required"
        press_any_key
        return
    fi
    
    echo ""
    echo "1) View last 100 lines"
    echo "2) Follow logs (real-time)"
    echo "3) View all logs"
    read -p "Choice [1-3]: " log_choice
    
    case $log_choice in
        1) docker logs --tail 100 "$container" | less ;;
        2) docker logs -f "$container" ;;
        3) docker logs "$container" | less ;;
        *) docker logs --tail 100 "$container" | less ;;
    esac
    
    press_any_key
}

# Execute command in container
exec_container() {
    list_containers
    echo ""
    read -p "Enter container ID or name: " container
    
    if [ -z "$container" ]; then
        print_error "Container ID/name required"
        press_any_key
        return
    fi
    
    echo ""
    echo "1) Open bash shell"
    echo "2) Open sh shell"
    echo "3) Run custom command"
    read -p "Choice [1-3]: " exec_choice
    
    case $exec_choice in
        1) docker exec -it "$container" bash ;;
        2) docker exec -it "$container" sh ;;
        3)
            read -p "Enter command: " cmd
            docker exec -it "$container" $cmd
            ;;
    esac
    
    press_any_key
}

# List images
list_images() {
    show_header
    echo -e "${CYAN}Docker Images:${NC}"
    echo ""
    
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed"
        press_any_key
        return
    fi
    
    docker images
    
    echo ""
    press_any_key
}

# Pull image
pull_image() {
    show_header
    echo -e "${CYAN}Pull Docker Image${NC}"
    echo ""
    
    read -p "Enter image name (e.g., nginx:latest): " image
    
    if [ -z "$image" ]; then
        print_error "Image name required"
        press_any_key
        return
    fi
    
    print_info "Pulling image $image..."
    docker pull "$image"
    
    if [ $? -eq 0 ]; then
        print_success "Image $image pulled successfully"
    else
        print_error "Failed to pull image"
    fi
    
    press_any_key
}

# Remove image
remove_image() {
    list_images
    echo ""
    read -p "Enter image ID or name: " image
    
    if [ -z "$image" ]; then
        print_error "Image ID/name required"
        press_any_key
        return
    fi
    
    read -p "Force remove? (y/n): " force
    
    if [[ "$force" =~ ^[Yy]$ ]]; then
        docker rmi -f "$image"
    else
        docker rmi "$image"
    fi
    
    if [ $? -eq 0 ]; then
        print_success "Image $image removed"
    else
        print_error "Failed to remove image"
    fi
    
    press_any_key
}

# Prune unused images
prune_images() {
    show_header
    print_warning "This will remove all dangling images"
    read -p "Continue? (y/n): " confirm
    
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        docker image prune -f
        print_success "Dangling images removed"
    fi
    
    press_any_key
}

# List volumes
list_volumes() {
    show_header
    echo -e "${CYAN}Docker Volumes:${NC}"
    echo ""
    
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed"
        press_any_key
        return
    fi
    
    docker volume ls
    
    echo ""
    press_any_key
}

# Remove volume
remove_volume() {
    list_volumes
    echo ""
    read -p "Enter volume name: " volume
    
    if [ -z "$volume" ]; then
        print_error "Volume name required"
        press_any_key
        return
    fi
    
    docker volume rm "$volume"
    
    if [ $? -eq 0 ]; then
        print_success "Volume $volume removed"
    else
        print_error "Failed to remove volume"
    fi
    
    press_any_key
}

# List networks
list_networks() {
    show_header
    echo -e "${CYAN}Docker Networks:${NC}"
    echo ""
    
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed"
        press_any_key
        return
    fi
    
    docker network ls
    
    echo ""
    press_any_key
}

# Create network
create_network() {
    show_header
    echo -e "${CYAN}Create Docker Network${NC}"
    echo ""
    
    read -p "Enter network name: " network
    
    if [ -z "$network" ]; then
        print_error "Network name required"
        press_any_key
        return
    fi
    
    echo ""
    echo "1) Bridge (default)"
    echo "2) Host"
    echo "3) Overlay"
    read -p "Network driver [1-3]: " driver_choice
    
    case $driver_choice in
        1) driver="bridge" ;;
        2) driver="host" ;;
        3) driver="overlay" ;;
        *) driver="bridge" ;;
    esac
    
    docker network create --driver "$driver" "$network"
    
    if [ $? -eq 0 ]; then
        print_success "Network $network created"
    else
        print_error "Failed to create network"
    fi
    
    press_any_key
}

# Docker stats
docker_stats() {
    show_header
    echo -e "${CYAN}Docker Container Stats (Ctrl+C to exit)${NC}"
    echo ""
    
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed"
        press_any_key
        return
    fi
    
    docker stats
}

# Docker info
docker_info() {
    show_header
    echo -e "${CYAN}Docker System Information${NC}"
    echo ""
    
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed"
        press_any_key
        return
    fi
    
    docker info | less
    
    press_any_key
}

# System prune
system_prune() {
    show_header
    print_warning "This will remove:"
    echo "  - All stopped containers"
    echo "  - All networks not used by at least one container"
    echo "  - All dangling images"
    echo "  - All dangling build cache"
    echo ""
    read -p "Continue? (yes/no): " confirm
    
    if [ "$confirm" = "yes" ]; then
        docker system prune -f
        print_success "System pruned"
        
        echo ""
        read -p "Also remove all unused volumes? (y/n): " prune_volumes
        if [[ "$prune_volumes" =~ ^[Yy]$ ]]; then
            docker system prune --volumes -f
            print_success "Volumes pruned"
        fi
    fi
    
    press_any_key
}
