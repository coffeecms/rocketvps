# Node.js Profile Configuration
# Version: 2.2.0

PROFILE_NAME="nodejs"
PROFILE_DESCRIPTION="Node.js applications (Express, Next.js, custom apps)"
PROFILE_TYPE="nodejs"

# Node.js Configuration
NODE_VERSION="20"  # LTS version
NPM_VERSION="latest"
ENABLE_YARN=true
ENABLE_PM2=true

# PM2 Configuration
PM2_INSTANCES=2
PM2_MAX_MEMORY="500M"
PM2_AUTO_RESTART=true
PM2_WATCH=false

# Database Configuration
DATABASE_TYPE="mongodb"  # or postgresql, mysql
DATABASE_NAME_OVERRIDE=""  # Leave empty to use domain_db

# Features to enable
ENABLE_SSL=true
ENABLE_REVERSE_PROXY=true
ENABLE_CACHE=false
ENABLE_BACKUP=true
ENABLE_GIT=true

# Application Configuration
APP_PORT=3000
APP_ENV="production"
NODE_ENV="production"

# Proxy Configuration
PROXY_TIMEOUT=60
PROXY_BUFFER_SIZE="4k"

# Security Settings
SECURITY_LEVEL="medium"
ENABLE_RATE_LIMITING=true
RATE_LIMIT_REQUESTS=100
RATE_LIMIT_WINDOW="1m"

# Backup Configuration
BACKUP_SCHEDULE="daily"
BACKUP_TIME="03:00"
BACKUP_RETENTION_DAYS=7
BACKUP_INCLUDE_NODE_MODULES=false

# Nginx Configuration
NGINX_GZIP=true
NGINX_WEBSOCKET_SUPPORT=true
