# Laravel Profile Configuration
# Version: 2.2.0

PROFILE_NAME="laravel"
PROFILE_DESCRIPTION="Modern PHP framework for APIs and web applications"
PROFILE_TYPE="php"

# PHP Configuration
PHP_VERSION="8.2"
PHP_MEMORY_LIMIT="512M"
PHP_MAX_EXECUTION_TIME="300"
PHP_UPLOAD_MAX_FILESIZE="20M"
PHP_POST_MAX_SIZE="20M"

# Required PHP Extensions
PHP_EXTENSIONS=(
    "php${PHP_VERSION}-mysql"
    "php${PHP_VERSION}-pgsql"
    "php${PHP_VERSION}-curl"
    "php${PHP_VERSION}-gd"
    "php${PHP_VERSION}-mbstring"
    "php${PHP_VERSION}-xml"
    "php${PHP_VERSION}-zip"
    "php${PHP_VERSION}-bcmath"
    "php${PHP_VERSION}-redis"
    "php${PHP_VERSION}-intl"
)

# Database Configuration
DATABASE_TYPE="mysql"  # or postgresql
DATABASE_CHARSET="utf8mb4"
DATABASE_COLLATE="utf8mb4_unicode_ci"

# Laravel Configuration
LARAVEL_VERSION="latest"
INSTALL_COMPOSER=true
COMPOSER_VERSION="latest"

# Features to enable
ENABLE_SSL=true
ENABLE_CACHE=true
ENABLE_REDIS=true
ENABLE_QUEUE_WORKER=true
ENABLE_SCHEDULER=true
ENABLE_PHPMYADMIN=true
ENABLE_BACKUP=true
ENABLE_GIT=true

# Queue Worker Configuration
QUEUE_CONNECTION="redis"
QUEUE_WORKERS=2

# Security Settings
SECURITY_LEVEL="high"
ENABLE_CORS=true

# Backup Configuration
BACKUP_SCHEDULE="daily"
BACKUP_TIME="03:00"
BACKUP_RETENTION_DAYS=7

# Nginx Configuration
NGINX_CLIENT_MAX_BODY_SIZE="20M"
NGINX_GZIP=true
NGINX_PROXY_TIMEOUT=60
