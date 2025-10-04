#!/bin/bash

################################################################################
# RocketVPS - Milvus Vector Database Module (Docker-based)
# Vector database for AI/ML applications
################################################################################

MILVUS_DIR="/opt/milvus"
MILVUS_CONFIG="${CONFIG_DIR}/milvus.conf"

# Milvus menu
milvus_menu() {
    while true; do
        show_header
        echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║                  MILVUS VECTOR DATABASE                       ║${NC}"
        echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo "  ${CYAN}Setup:${NC}"
        echo "  1) Install Milvus (Standalone)"
        echo "  2) Install Milvus (Cluster)"
        echo "  3) Uninstall Milvus"
        echo ""
        echo "  ${CYAN}Management:${NC}"
        echo "  4) Start Milvus"
        echo "  5) Stop Milvus"
        echo "  6) Restart Milvus"
        echo "  7) View Status"
        echo "  8) View Logs"
        echo ""
        echo "  ${CYAN}Collections:${NC}"
        echo "  9) List Collections"
        echo "  10) Create Collection"
        echo "  11) Drop Collection"
        echo "  12) Collection Info"
        echo "  13) Load Collection"
        echo "  14) Release Collection"
        echo ""
        echo "  ${CYAN}Data Operations:${NC}"
        echo "  15) Insert Data"
        echo "  16) Search Vectors"
        echo "  17) Query Data"
        echo "  18) Delete Data"
        echo ""
        echo "  ${CYAN}Utilities:${NC}"
        echo "  19) Backup Data"
        echo "  20) Restore Data"
        echo "  21) System Metrics"
        echo "  22) Connection Test"
        echo ""
        echo "  0) Back to Main Menu"
        echo ""
        echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
        
        read -p "Enter your choice [0-22]: " milvus_choice
        
        case $milvus_choice in
            1) install_milvus_standalone ;;
            2) install_milvus_cluster ;;
            3) uninstall_milvus ;;
            4) start_milvus ;;
            5) stop_milvus ;;
            6) restart_milvus ;;
            7) view_milvus_status ;;
            8) view_milvus_logs ;;
            9) list_collections ;;
            10) create_collection ;;
            11) drop_collection ;;
            12) collection_info ;;
            13) load_collection ;;
            14) release_collection ;;
            15) insert_data ;;
            16) search_vectors ;;
            17) query_data ;;
            18) delete_data ;;
            19) backup_milvus ;;
            20) restore_milvus ;;
            21) system_metrics ;;
            22) connection_test ;;
            0) return ;;
            *)
                print_error "Invalid choice"
                sleep 2
                ;;
        esac
    done
}

# Install Milvus Standalone
install_milvus_standalone() {
    show_header
    print_info "Installing Milvus Standalone..."
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        print_error "Docker is required. Please install Docker first."
        press_any_key
        return
    fi
    
    # Create directory
    mkdir -p "$MILVUS_DIR"/{volumes,backup}
    cd "$MILVUS_DIR"
    
    # Download configuration
    print_info "Downloading Milvus configuration..."
    wget https://github.com/milvus-io/milvus/releases/download/v2.3.3/milvus-standalone-docker-compose.yml -O docker-compose.yml
    
    # Download and modify config
    mkdir -p volumes/milvus/conf
    wget https://raw.githubusercontent.com/milvus-io/milvus/v2.3.3/configs/milvus.yaml -O volumes/milvus/conf/milvus.yaml
    
    # Create docker-compose.yml
    cat > docker-compose.yml <<EOF
version: '3.5'

services:
  etcd:
    container_name: milvus-etcd
    image: quay.io/coreos/etcd:v3.5.5
    environment:
      - ETCD_AUTO_COMPACTION_MODE=revision
      - ETCD_AUTO_COMPACTION_RETENTION=1000
      - ETCD_QUOTA_BACKEND_BYTES=4294967296
      - ETCD_SNAPSHOT_COUNT=50000
    volumes:
      - ./volumes/etcd:/etcd
    command: etcd -advertise-client-urls=http://127.0.0.1:2379 -listen-client-urls http://0.0.0.0:2379 --data-dir /etcd
    restart: always
    networks:
      - milvus

  minio:
    container_name: milvus-minio
    image: minio/minio:RELEASE.2023-03-20T20-16-18Z
    environment:
      MINIO_ACCESS_KEY: minioadmin
      MINIO_SECRET_KEY: minioadmin
    volumes:
      - ./volumes/minio:/minio_data
    command: minio server /minio_data --console-address ":9001"
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:9000/minio/health/live"]
      interval: 30s
      timeout: 20s
      retries: 3
    restart: always
    networks:
      - milvus

  standalone:
    container_name: milvus-standalone
    image: milvusdb/milvus:v2.3.3
    command: ["milvus", "run", "standalone"]
    environment:
      ETCD_ENDPOINTS: etcd:2379
      MINIO_ADDRESS: minio:9000
    volumes:
      - ./volumes/milvus:/var/lib/milvus
    ports:
      - "19530:19530"
      - "9091:9091"
    depends_on:
      - "etcd"
      - "minio"
    restart: always
    networks:
      - milvus

  attu:
    container_name: milvus-attu
    image: zilliz/attu:latest
    environment:
      - MILVUS_URL=milvus-standalone:19530
    ports:
      - "8000:3000"
    depends_on:
      - "standalone"
    restart: always
    networks:
      - milvus

networks:
  milvus:
    name: milvus
EOF

    # Start containers
    print_info "Starting Milvus..."
    docker compose up -d
    
    # Wait for services
    print_info "Waiting for Milvus to start..."
    sleep 30
    
    # Get server IP
    local server_ip=$(hostname -I | awk '{print $1}')
    
    # Save config
    cat > "$MILVUS_CONFIG" <<EOF
MILVUS_TYPE=standalone
MILVUS_HOST=localhost
MILVUS_PORT=19530
ATTU_PORT=8000
INSTALLED_DATE=$(date +%Y-%m-%d)
SERVER_IP=${server_ip}
EOF

    # Install Python client
    print_info "Installing Python client (pymilvus)..."
    pip3 install pymilvus 2>/dev/null || apt-get install -y python3-pip && pip3 install pymilvus
    
    print_success "Milvus Standalone installed successfully!"
    echo ""
    print_info "Milvus Server: ${server_ip}:19530"
    print_info "Attu Web UI: http://${server_ip}:8000"
    print_info "MinIO Console: http://${server_ip}:9001 (minioadmin/minioadmin)"
    echo ""
    print_info "Python client installed: pymilvus"
    echo ""
    
    log_action "Milvus vector database installed (standalone)"
    press_any_key
}

# Install Milvus Cluster
install_milvus_cluster() {
    show_header
    print_info "Installing Milvus Cluster..."
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        print_error "Docker is required. Please install Docker first."
        press_any_key
        return
    fi
    
    mkdir -p "$MILVUS_DIR"/{volumes,backup}
    cd "$MILVUS_DIR"
    
    # Download cluster configuration
    wget https://github.com/milvus-io/milvus/releases/download/v2.3.3/milvus-cluster-docker-compose.yml -O docker-compose.yml
    
    print_info "Starting Milvus Cluster..."
    docker compose up -d
    
    sleep 30
    
    local server_ip=$(hostname -I | awk '{print $1}')
    
    cat > "$MILVUS_CONFIG" <<EOF
MILVUS_TYPE=cluster
MILVUS_HOST=localhost
MILVUS_PORT=19530
INSTALLED_DATE=$(date +%Y-%m-%d)
SERVER_IP=${server_ip}
EOF

    pip3 install pymilvus 2>/dev/null || apt-get install -y python3-pip && pip3 install pymilvus
    
    print_success "Milvus Cluster installed successfully!"
    echo ""
    print_info "Milvus Server: ${server_ip}:19530"
    echo ""
    
    log_action "Milvus vector database installed (cluster)"
    press_any_key
}

# Uninstall Milvus
uninstall_milvus() {
    show_header
    print_warning "This will remove Milvus and all data!"
    read -p "Create backup before uninstalling? (y/n): " do_backup
    
    if [[ "$do_backup" =~ ^[Yy]$ ]]; then
        backup_milvus
    fi
    
    read -p "Proceed with uninstallation? (yes/no): " confirm
    
    if [ "$confirm" != "yes" ]; then
        return
    fi
    
    if [ -d "$MILVUS_DIR" ]; then
        cd "$MILVUS_DIR"
        docker compose down -v
    fi
    
    read -p "Delete all data? (y/n): " delete_data
    if [[ "$delete_data" =~ ^[Yy]$ ]]; then
        rm -rf "$MILVUS_DIR"
    fi
    
    rm -f "$MILVUS_CONFIG"
    
    print_success "Milvus uninstalled"
    press_any_key
}

# Start/Stop/Restart
start_milvus() {
    print_info "Starting Milvus..."
    cd "$MILVUS_DIR"
    docker compose start
    print_success "Milvus started"
    press_any_key
}

stop_milvus() {
    print_info "Stopping Milvus..."
    cd "$MILVUS_DIR"
    docker compose stop
    print_success "Milvus stopped"
    press_any_key
}

restart_milvus() {
    print_info "Restarting Milvus..."
    cd "$MILVUS_DIR"
    docker compose restart
    print_success "Milvus restarted"
    press_any_key
}

# View status
view_milvus_status() {
    show_header
    echo -e "${CYAN}Milvus Status:${NC}"
    echo ""
    cd "$MILVUS_DIR"
    docker compose ps
    press_any_key
}

# View logs
view_milvus_logs() {
    echo "Select log:"
    echo "1) Milvus standalone/coordinator"
    echo "2) Etcd"
    echo "3) MinIO"
    echo "4) All logs"
    read -p "Choice: " log_choice
    
    cd "$MILVUS_DIR"
    case $log_choice in
        1) docker compose logs -f standalone ;;
        2) docker compose logs -f etcd ;;
        3) docker compose logs -f minio ;;
        4) docker compose logs -f ;;
    esac
}

# List collections
list_collections() {
    show_header
    echo -e "${CYAN}Milvus Collections:${NC}"
    echo ""
    
    python3 - <<'PYTHON'
from pymilvus import connections, utility

try:
    connections.connect(host="localhost", port="19530")
    collections = utility.list_collections()
    
    if collections:
        for col in collections:
            print(f"  - {col}")
    else:
        print("  No collections found")
    
    connections.disconnect("default")
except Exception as e:
    print(f"Error: {e}")
PYTHON

    press_any_key
}

# Create collection
create_collection() {
    show_header
    print_info "Create Collection"
    echo ""
    
    read -p "Collection name: " col_name
    read -p "Vector dimension: " dim
    read -p "Metric type (L2/IP/COSINE): " metric
    metric=${metric:-L2}
    
    if [ -z "$col_name" ] || [ -z "$dim" ]; then
        print_error "Collection name and dimension required"
        press_any_key
        return
    fi
    
    python3 - <<PYTHON
from pymilvus import connections, Collection, FieldSchema, CollectionSchema, DataType

try:
    connections.connect(host="localhost", port="19530")
    
    # Define schema
    fields = [
        FieldSchema(name="id", dtype=DataType.INT64, is_primary=True, auto_id=True),
        FieldSchema(name="embedding", dtype=DataType.FLOAT_VECTOR, dim=${dim})
    ]
    
    schema = CollectionSchema(fields=fields, description="${col_name}")
    collection = Collection(name="${col_name}", schema=schema)
    
    # Create index
    index_params = {
        "metric_type": "${metric}",
        "index_type": "IVF_FLAT",
        "params": {"nlist": 128}
    }
    collection.create_index(field_name="embedding", index_params=index_params)
    
    print(f"Collection '${col_name}' created successfully")
    
    connections.disconnect("default")
except Exception as e:
    print(f"Error: {e}")
PYTHON

    press_any_key
}

# Drop collection
drop_collection() {
    list_collections
    echo ""
    read -p "Enter collection name to drop: " col_name
    
    if [ -z "$col_name" ]; then
        return
    fi
    
    print_warning "This will permanently delete collection ${col_name}"
    read -p "Continue? (y/n): " confirm
    
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        python3 - <<PYTHON
from pymilvus import connections, utility

try:
    connections.connect(host="localhost", port="19530")
    utility.drop_collection("${col_name}")
    print(f"Collection '${col_name}' dropped")
    connections.disconnect("default")
except Exception as e:
    print(f"Error: {e}")
PYTHON
    fi
    
    press_any_key
}

# Collection info
collection_info() {
    list_collections
    echo ""
    read -p "Enter collection name: " col_name
    
    python3 - <<PYTHON
from pymilvus import connections, Collection

try:
    connections.connect(host="localhost", port="19530")
    collection = Collection("${col_name}")
    
    print(f"\nCollection: ${col_name}")
    print(f"Schema: {collection.schema}")
    print(f"Number of entities: {collection.num_entities}")
    print(f"Indexes: {collection.indexes}")
    
    connections.disconnect("default")
except Exception as e:
    print(f"Error: {e}")
PYTHON

    press_any_key
}

# Load/Release collection
load_collection() {
    list_collections
    echo ""
    read -p "Enter collection name to load: " col_name
    
    python3 - <<PYTHON
from pymilvus import connections, Collection

try:
    connections.connect(host="localhost", port="19530")
    collection = Collection("${col_name}")
    collection.load()
    print(f"Collection '${col_name}' loaded into memory")
    connections.disconnect("default")
except Exception as e:
    print(f"Error: {e}")
PYTHON

    press_any_key
}

release_collection() {
    list_collections
    echo ""
    read -p "Enter collection name to release: " col_name
    
    python3 - <<PYTHON
from pymilvus import connections, Collection

try:
    connections.connect(host="localhost", port="19530")
    collection = Collection("${col_name}")
    collection.release()
    print(f"Collection '${col_name}' released from memory")
    connections.disconnect("default")
except Exception as e:
    print(f"Error: {e}")
PYTHON

    press_any_key
}

# Data operations placeholders
insert_data() {
    show_header
    print_info "Insert Data"
    print_warning "Use Python SDK or Attu web interface for data insertion"
    print_info "Python example:"
    echo '
from pymilvus import connections, Collection
import random

connections.connect(host="localhost", port="19530")
collection = Collection("your_collection")

# Prepare data
data = [[random.random() for _ in range(128)] for _ in range(100)]
entities = [data]

# Insert
collection.insert(entities)
collection.flush()
'
    press_any_key
}

search_vectors() {
    show_header
    print_info "Search Vectors"
    print_warning "Use Python SDK or Attu web interface for vector search"
    print_info "Python example:"
    echo '
from pymilvus import connections, Collection

connections.connect(host="localhost", port="19530")
collection = Collection("your_collection")
collection.load()

# Search
search_params = {"metric_type": "L2", "params": {"nprobe": 10}}
results = collection.search(data=[[0.1]*128], anns_field="embedding", param=search_params, limit=10)
'
    press_any_key
}

query_data() {
    show_header
    print_info "Query Data"
    print_warning "Use Python SDK or Attu web interface"
    press_any_key
}

delete_data() {
    show_header
    print_info "Delete Data"
    print_warning "Use Python SDK or Attu web interface"
    press_any_key
}

# Backup
backup_milvus() {
    show_header
    print_info "Backing up Milvus data..."
    
    backup_file="${BACKUP_DIR}/milvus_$(date +%Y%m%d_%H%M%S).tar.gz"
    
    cd "$MILVUS_DIR"
    docker compose stop
    
    tar -czf "$backup_file" volumes/
    
    docker compose start
    
    print_success "Backup created: $backup_file"
    press_any_key
}

# Restore
restore_milvus() {
    show_header
    echo "Available backups:"
    ls -lh "${BACKUP_DIR}"/milvus_*.tar.gz
    echo ""
    read -p "Enter backup file path: " backup_file
    
    if [ ! -f "$backup_file" ]; then
        print_error "Backup file not found"
        press_any_key
        return
    fi
    
    print_warning "This will replace current data!"
    read -p "Continue? (y/n): " confirm
    
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        cd "$MILVUS_DIR"
        docker compose stop
        rm -rf volumes/*
        tar -xzf "$backup_file"
        docker compose start
        print_success "Restore completed"
    fi
    
    press_any_key
}

# System metrics
system_metrics() {
    show_header
    echo -e "${CYAN}Milvus System Metrics:${NC}"
    echo ""
    
    python3 - <<'PYTHON'
from pymilvus import connections, utility

try:
    connections.connect(host="localhost", port="19530")
    
    print("System Info:")
    print(utility.get_server_version())
    
    connections.disconnect("default")
except Exception as e:
    print(f"Error: {e}")
PYTHON

    press_any_key
}

# Connection test
connection_test() {
    show_header
    print_info "Testing Milvus connection..."
    
    python3 - <<'PYTHON'
from pymilvus import connections

try:
    connections.connect(host="localhost", port="19530")
    print("✓ Connection successful!")
    connections.disconnect("default")
except Exception as e:
    print(f"✗ Connection failed: {e}")
PYTHON

    press_any_key
}
