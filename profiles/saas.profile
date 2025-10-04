# Multi-tenant SaaS Profile Configuration
# Version: 2.2.0

PROFILE_NAME="saas"
PROFILE_DESCRIPTION="Multi-tenant Software-as-a-Service applications"
PROFILE_TYPE="php"  # or nodejs, depends on stack

# PHP Configuration
PHP_VERSION="8.2"
PHP_MEMORY_LIMIT="512M"
PHP_MAX_EXECUTION_TIME="300"

# Required PHP Extensions
PHP_EXTENSIONS=(
    "php${PHP_VERSION}-mysql"
    "php${PHP_VERSION}-pgsql"
    "php${PHP_VERSION}-curl"
    "php${PHP_VERSION}-gd"
    "php${PHP_VERSION}-mbstring"
    "php${PHP_VERSION}-xml"
    "php${PHP_VERSION}-zip"
    "php${PHP_VERSION}-redis"
    "php${PHP_VERSION}-bcmath"
)

# Database Configuration (Per-tenant isolation)
DATABASE_TYPE="postgresql"  # Better for multi-tenancy
DATABASE_PER_TENANT=true
DATABASE_SHARED_SCHEMA=false
DATABASE_CHARSET="UTF8"

# Subdomain Configuration
ENABLE_WILDCARD_SUBDOMAIN=true
SUBDOMAIN_PATTERN="*.domain.com"
SUBDOMAIN_SSL_WILDCARD=true

# Features to enable
ENABLE_SSL=true
ENABLE_REDIS=true
ENABLE_QUEUE_WORKER=true
ENABLE_RATE_LIMITING=true
ENABLE_TENANT_ISOLATION=true
ENABLE_BACKUP=true
ENABLE_MONITORING=true
ENABLE_ANALYTICS=true

# Rate Limiting (Per Tenant)
RATE_LIMIT_PER_TENANT=true
RATE_LIMIT_REQUESTS=1000
RATE_LIMIT_WINDOW="1h"
RATE_LIMIT_BURST=50

# Redis Configuration
REDIS_MAXMEMORY="1024M"
REDIS_MAXMEMORY_POLICY="allkeys-lru"
REDIS_DATABASES=16  # Separate DB per tenant if needed

# Queue Configuration
QUEUE_CONNECTION="redis"
QUEUE_WORKERS=4
QUEUE_PER_TENANT=true

# Security Settings
SECURITY_LEVEL="high"
ENABLE_WAF=true
ENABLE_CORS=true
ENABLE_API_KEY_AUTH=true
ENABLE_TENANT_DATA_ENCRYPTION=true

# Backup Configuration
BACKUP_SCHEDULE="daily"
BACKUP_TIME="02:00"
BACKUP_RETENTION_DAYS=30
BACKUP_PER_TENANT=true

# Nginx Configuration
NGINX_CLIENT_MAX_BODY_SIZE="50M"
NGINX_GZIP=true
NGINX_PROXY_TIMEOUT=120
NGINX_RATE_LIMITING=true

# Monitoring & Analytics
ENABLE_USAGE_TRACKING=true
ENABLE_ERROR_TRACKING=true
ENABLE_PERFORMANCE_MONITORING=true

# Tenant Management
AUTO_TENANT_PROVISIONING=true
TENANT_SUBDOMAIN_FORMAT="[tenant].[domain]"
TENANT_DATABASE_PREFIX="tenant_"
