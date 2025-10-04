# Static HTML Profile Configuration
# Version: 2.2.0

PROFILE_NAME="static"
PROFILE_DESCRIPTION="Static HTML/CSS/JS websites and landing pages"
PROFILE_TYPE="static"

# No PHP or application server needed
PHP_VERSION=""
NODE_VERSION=""

# Features to enable
ENABLE_SSL=true
ENABLE_FTP=true
ENABLE_BACKUP=true
ENABLE_GZIP=true
ENABLE_CACHE_HEADERS=true

# Cache Configuration
CACHE_HTML="1h"
CACHE_CSS_JS="1y"
CACHE_IMAGES="1y"
CACHE_FONTS="1y"

# Security Settings
SECURITY_LEVEL="medium"
ENABLE_SECURITY_HEADERS=true
ENABLE_HOTLINK_PROTECTION=false

# Backup Configuration
BACKUP_SCHEDULE="weekly"
BACKUP_TIME="03:00"
BACKUP_RETENTION_DAYS=30

# Nginx Configuration
NGINX_INDEX="index.html index.htm"
NGINX_GZIP=true
NGINX_GZIP_TYPES="text/plain text/css text/xml text/javascript application/javascript application/xml+rss application/json"
NGINX_CLIENT_MAX_BODY_SIZE="10M"

# Directory Listing
ENABLE_DIRECTORY_LISTING=false

# Custom Error Pages
CUSTOM_404_PAGE="/404.html"
CUSTOM_50X_PAGE="/50x.html"
