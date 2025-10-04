# E-commerce Profile Configuration
# Version: 2.2.0

PROFILE_NAME="ecommerce"
PROFILE_DESCRIPTION="High-performance e-commerce websites (WooCommerce, Magento, etc.)"
PROFILE_TYPE="php"

# PHP Configuration (High Performance)
PHP_VERSION="8.2"
PHP_MEMORY_LIMIT="1024M"  # High memory for product catalogs
PHP_MAX_EXECUTION_TIME="600"
PHP_UPLOAD_MAX_FILESIZE="128M"  # For product images
PHP_POST_MAX_SIZE="128M"
PHP_MAX_INPUT_VARS="10000"  # For complex forms

# Required PHP Extensions
PHP_EXTENSIONS=(
    "php${PHP_VERSION}-mysql"
    "php${PHP_VERSION}-curl"
    "php${PHP_VERSION}-gd"
    "php${PHP_VERSION}-mbstring"
    "php${PHP_VERSION}-xml"
    "php${PHP_VERSION}-zip"
    "php${PHP_VERSION}-imagick"
    "php${PHP_VERSION}-redis"
    "php${PHP_VERSION}-intl"
    "php${PHP_VERSION}-soap"
    "php${PHP_VERSION}-bcmath"
)

# Database Configuration (Optimized)
DATABASE_TYPE="mysql"
DATABASE_CHARSET="utf8mb4"
DATABASE_COLLATE="utf8mb4_unicode_ci"
DATABASE_INNODB_BUFFER_POOL_SIZE="512M"
DATABASE_MAX_CONNECTIONS="200"

# WordPress/WooCommerce Configuration
WP_VERSION="latest"
INSTALL_WOOCOMMERCE=true
WP_PLUGINS=(
    "woocommerce"
    "woocommerce-gateway-stripe"
    "woocommerce-gateway-paypal-express-checkout"
    "yoast-seo"
    "wordfence"
    "redis-cache"
)

# Features to enable
ENABLE_SSL=true
ENABLE_REDIS_CACHE=true
ENABLE_REDIS_OBJECT_CACHE=true
ENABLE_REDIS_SESSION=true
ENABLE_CDN=false
ENABLE_PHPMYADMIN=true
ENABLE_BACKUP=true
ENABLE_MONITORING=true

# Redis Configuration
REDIS_MAXMEMORY="512M"
REDIS_MAXMEMORY_POLICY="allkeys-lru"

# Security Settings
SECURITY_LEVEL="high"
ENABLE_WAF=true
ENABLE_RATE_LIMITING=true
RATE_LIMIT_CHECKOUT="strict"

# Backup Configuration (Frequent for e-commerce)
BACKUP_SCHEDULE="twice_daily"
BACKUP_TIMES="03:00,15:00"
BACKUP_RETENTION_DAYS=14
BACKUP_INCLUDE_DATABASE=true

# Nginx Configuration
NGINX_CLIENT_MAX_BODY_SIZE="128M"
NGINX_FASTCGI_CACHE=true
NGINX_FASTCGI_CACHE_SIZE="512M"
NGINX_GZIP=true
NGINX_PROXY_TIMEOUT=300
NGINX_FASTCGI_READ_TIMEOUT=300

# Performance Optimization
ENABLE_OPCACHE=true
OPCACHE_MEMORY_CONSUMPTION=256
OPCACHE_REVALIDATE_FREQ=60
