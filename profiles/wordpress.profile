# WordPress Profile Configuration
# Version: 2.2.0

PROFILE_NAME="wordpress"
PROFILE_DESCRIPTION="WordPress Blog, Business Website, or WooCommerce Store"
PROFILE_TYPE="php"

# PHP Configuration
PHP_VERSION="8.2"
PHP_MEMORY_LIMIT="256M"
PHP_MAX_EXECUTION_TIME="300"
PHP_UPLOAD_MAX_FILESIZE="64M"
PHP_POST_MAX_SIZE="64M"

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
)

# Database Configuration
DATABASE_TYPE="mysql"
DATABASE_CHARSET="utf8mb4"
DATABASE_COLLATE="utf8mb4_unicode_ci"

# WordPress Configuration
WP_VERSION="latest"
WP_LOCALE="en_US"

# WordPress Plugins (comma-separated)
WP_PLUGINS=(
    "yoast-seo"
    "wordfence"
    "wp-super-cache"
    "contact-form-7"
    "akismet"
)

# Features to enable
ENABLE_SSL=true
ENABLE_CACHE=true
ENABLE_FTP=true
ENABLE_PHPMYADMIN=true
ENABLE_BACKUP=true
ENABLE_EMAIL=false

# Security Settings
SECURITY_LEVEL="high"
DISABLE_FILE_EDIT=true
BLOCK_XMLRPC=true
PROTECT_WP_CONFIG=true

# Backup Configuration
BACKUP_SCHEDULE="daily"
BACKUP_TIME="03:00"
BACKUP_RETENTION_DAYS=7

# Nginx Configuration
NGINX_CLIENT_MAX_BODY_SIZE="64M"
NGINX_FASTCGI_CACHE=true
NGINX_GZIP=true
