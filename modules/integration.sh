#!/bin/bash

################################################################################
# RocketVPS v2.2.0 - Integration Module
# 
# Integrates Vault and Restore with Profile System
################################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check if vault module exists and source it
if [[ -f "$SCRIPT_DIR/vault.sh" ]]; then
    source "$SCRIPT_DIR/vault.sh"
    VAULT_AVAILABLE=1
else
    VAULT_AVAILABLE=0
fi

################################################################################
# AUTO-SAVE CREDENTIALS TO VAULT
################################################################################

# Auto-save WordPress credentials to vault
integration_save_wordpress_credentials() {
    local domain="$1"
    local admin_user="$2"
    local admin_pass="$3"
    local admin_email="$4"
    local db_name="$5"
    local db_user="$6"
    local db_pass="$7"
    local ftp_user="$8"
    local ftp_pass="$9"
    
    [[ $VAULT_AVAILABLE -eq 0 ]] && return 0
    
    # Check if vault is initialized
    if ! vault_is_initialized; then
        return 0
    fi
    
    # Check if vault is unlocked (don't force unlock)
    if vault_is_locked; then
        return 0
    fi
    
    # Prepare credentials JSON
    local credentials=$(cat <<EOF
{
  "domain_info": {
    "domain": "$domain",
    "document_root": "/var/www/$domain",
    "php_version": "8.2",
    "ssl_enabled": true
  },
  "admin": {
    "url": "https://$domain/wp-admin",
    "username": "$admin_user",
    "password": "$admin_pass",
    "email": "$admin_email"
  },
  "database": {
    "type": "mysql",
    "host": "localhost",
    "port": "3306",
    "database": "$db_name",
    "username": "$db_user",
    "password": "$db_pass"
  },
  "ftp": {
    "host": "$domain",
    "port": "21",
    "username": "$ftp_user",
    "password": "$ftp_pass",
    "path": "/var/www/$domain"
  },
  "services": {
    "redis": {
      "enabled": true,
      "host": "localhost",
      "port": "6379"
    },
    "backup": {
      "enabled": true,
      "schedule": "daily",
      "retention": "7 days"
    }
  }
}
EOF
)
    
    # Add to vault silently
    vault_add_credentials "$domain" "wordpress" "$credentials" >/dev/null 2>&1
}

# Auto-save Laravel credentials to vault
integration_save_laravel_credentials() {
    local domain="$1"
    local db_name="$2"
    local db_user="$3"
    local db_pass="$4"
    local redis_enabled="${5:-true}"
    
    [[ $VAULT_AVAILABLE -eq 0 ]] && return 0
    
    if ! vault_is_initialized || vault_is_locked; then
        return 0
    fi
    
    local credentials=$(cat <<EOF
{
  "domain_info": {
    "domain": "$domain",
    "document_root": "/var/www/$domain",
    "framework": "laravel",
    "php_version": "8.2"
  },
  "database": {
    "type": "mysql",
    "host": "localhost",
    "port": "3306",
    "database": "$db_name",
    "username": "$db_user",
    "password": "$db_pass"
  },
  "services": {
    "redis": {
      "enabled": $redis_enabled,
      "host": "localhost",
      "port": "6379"
    },
    "queue": {
      "enabled": true,
      "workers": 2,
      "supervisor": true
    },
    "scheduler": {
      "enabled": true,
      "cron": "* * * * *"
    }
  }
}
EOF
)
    
    vault_add_credentials "$domain" "laravel" "$credentials" >/dev/null 2>&1
}

# Auto-save Node.js credentials to vault
integration_save_nodejs_credentials() {
    local domain="$1"
    local app_port="$2"
    local pm2_instances="${3:-2}"
    
    [[ $VAULT_AVAILABLE -eq 0 ]] && return 0
    
    if ! vault_is_initialized || vault_is_locked; then
        return 0
    fi
    
    local credentials=$(cat <<EOF
{
  "domain_info": {
    "domain": "$domain",
    "document_root": "/var/www/$domain",
    "runtime": "nodejs",
    "node_version": "20"
  },
  "application": {
    "port": "$app_port",
    "pm2_instances": $pm2_instances,
    "max_memory": "500M"
  },
  "services": {
    "pm2": {
      "enabled": true,
      "cluster_mode": true,
      "instances": $pm2_instances
    },
    "nginx": {
      "reverse_proxy": true,
      "port": "$app_port"
    }
  }
}
EOF
)
    
    vault_add_credentials "$domain" "nodejs" "$credentials" >/dev/null 2>&1
}

# Auto-save Static site credentials to vault
integration_save_static_credentials() {
    local domain="$1"
    
    [[ $VAULT_AVAILABLE -eq 0 ]] && return 0
    
    if ! vault_is_initialized || vault_is_locked; then
        return 0
    fi
    
    local credentials=$(cat <<EOF
{
  "domain_info": {
    "domain": "$domain",
    "document_root": "/var/www/$domain",
    "type": "static_html",
    "ssl_enabled": true
  },
  "services": {
    "nginx": {
      "cache_enabled": true,
      "gzip_enabled": true
    },
    "backup": {
      "enabled": true,
      "schedule": "weekly"
    }
  }
}
EOF
)
    
    vault_add_credentials "$domain" "static" "$credentials" >/dev/null 2>&1
}

# Auto-save E-commerce credentials to vault
integration_save_ecommerce_credentials() {
    local domain="$1"
    local admin_user="$2"
    local admin_pass="$3"
    local admin_email="$4"
    local db_name="$5"
    local db_user="$6"
    local db_pass="$7"
    
    [[ $VAULT_AVAILABLE -eq 0 ]] && return 0
    
    if ! vault_is_initialized || vault_is_locked; then
        return 0
    fi
    
    local credentials=$(cat <<EOF
{
  "domain_info": {
    "domain": "$domain",
    "document_root": "/var/www/$domain",
    "type": "ecommerce",
    "php_version": "8.2"
  },
  "admin": {
    "url": "https://$domain/wp-admin",
    "username": "$admin_user",
    "password": "$admin_pass",
    "email": "$admin_email"
  },
  "database": {
    "type": "mysql",
    "host": "localhost",
    "port": "3306",
    "database": "$db_name",
    "username": "$db_user",
    "password": "$db_pass"
  },
  "services": {
    "redis": {
      "enabled": true,
      "host": "localhost",
      "port": "6379",
      "max_memory": "512M"
    },
    "woocommerce": {
      "enabled": true,
      "version": "latest"
    },
    "backup": {
      "enabled": true,
      "schedule": "twice_daily"
    }
  }
}
EOF
)
    
    vault_add_credentials "$domain" "ecommerce" "$credentials" >/dev/null 2>&1
}

# Auto-save SaaS credentials to vault
integration_save_saas_credentials() {
    local domain="$1"
    local db_type="$2"
    local db_name="$3"
    local db_user="$4"
    local db_pass="$5"
    
    [[ $VAULT_AVAILABLE -eq 0 ]] && return 0
    
    if ! vault_is_initialized || vault_is_locked; then
        return 0
    fi
    
    local credentials=$(cat <<EOF
{
  "domain_info": {
    "domain": "$domain",
    "document_root": "/var/www/$domain",
    "type": "saas",
    "php_version": "8.2",
    "wildcard_dns": true
  },
  "database": {
    "type": "$db_type",
    "host": "localhost",
    "port": "$([[ "$db_type" == "postgresql" ]] && echo "5432" || echo "3306")",
    "database": "$db_name",
    "username": "$db_user",
    "password": "$db_pass"
  },
  "services": {
    "redis": {
      "enabled": true,
      "host": "localhost",
      "port": "6379",
      "max_memory": "1024M"
    },
    "queue": {
      "enabled": true,
      "workers": 4
    },
    "multi_tenancy": {
      "enabled": true,
      "wildcard": "*.$domain"
    }
  }
}
EOF
)
    
    vault_add_credentials "$domain" "saas" "$credentials" >/dev/null 2>&1
}

################################################################################
# INTEGRATION HOOKS FOR PROFILES
################################################################################

# Hook called after successful WordPress setup
integration_hook_wordpress_complete() {
    local domain="$1"
    local admin_user="$2"
    local admin_pass="$3"
    local admin_email="$4"
    local db_name="$5"
    local db_user="$6"
    local db_pass="$7"
    local ftp_user="${8:-wp_admin}"
    local ftp_pass="${9:-$(openssl rand -base64 16)}"
    
    # Save to vault
    integration_save_wordpress_credentials "$domain" "$admin_user" "$admin_pass" "$admin_email" \
        "$db_name" "$db_user" "$db_pass" "$ftp_user" "$ftp_pass"
    
    # Show vault status
    if [[ $VAULT_AVAILABLE -eq 1 ]] && vault_is_initialized && ! vault_is_locked; then
        echo ""
        echo -e "${GREEN}✓ Credentials saved to vault${NC}"
    fi
}

# Hook called after successful Laravel setup
integration_hook_laravel_complete() {
    local domain="$1"
    local db_name="$2"
    local db_user="$3"
    local db_pass="$4"
    
    integration_save_laravel_credentials "$domain" "$db_name" "$db_user" "$db_pass"
    
    if [[ $VAULT_AVAILABLE -eq 1 ]] && vault_is_initialized && ! vault_is_locked; then
        echo ""
        echo -e "${GREEN}✓ Credentials saved to vault${NC}"
    fi
}

# Hook called after successful Node.js setup
integration_hook_nodejs_complete() {
    local domain="$1"
    local app_port="$2"
    
    integration_save_nodejs_credentials "$domain" "$app_port"
    
    if [[ $VAULT_AVAILABLE -eq 1 ]] && vault_is_initialized && ! vault_is_locked; then
        echo ""
        echo -e "${GREEN}✓ Configuration saved to vault${NC}"
    fi
}

# Hook called after successful Static site setup
integration_hook_static_complete() {
    local domain="$1"
    
    integration_save_static_credentials "$domain"
    
    if [[ $VAULT_AVAILABLE -eq 1 ]] && vault_is_initialized && ! vault_is_locked; then
        echo ""
        echo -e "${GREEN}✓ Configuration saved to vault${NC}"
    fi
}

# Hook called after successful E-commerce setup
integration_hook_ecommerce_complete() {
    local domain="$1"
    local admin_user="$2"
    local admin_pass="$3"
    local admin_email="$4"
    local db_name="$5"
    local db_user="$6"
    local db_pass="$7"
    
    integration_save_ecommerce_credentials "$domain" "$admin_user" "$admin_pass" "$admin_email" \
        "$db_name" "$db_user" "$db_pass"
    
    if [[ $VAULT_AVAILABLE -eq 1 ]] && vault_is_initialized && ! vault_is_locked; then
        echo ""
        echo -e "${GREEN}✓ Credentials saved to vault${NC}"
    fi
}

# Hook called after successful SaaS setup
integration_hook_saas_complete() {
    local domain="$1"
    local db_type="$2"
    local db_name="$3"
    local db_user="$4"
    local db_pass="$5"
    
    integration_save_saas_credentials "$domain" "$db_type" "$db_name" "$db_user" "$db_pass"
    
    if [[ $VAULT_AVAILABLE -eq 1 ]] && vault_is_initialized && ! vault_is_locked; then
        echo ""
        echo -e "${GREEN}✓ Credentials saved to vault${NC}"
    fi
}

################################################################################
# VAULT PROMPT FOR NEW USERS
################################################################################

# Prompt user to initialize vault if not initialized
integration_prompt_vault_init() {
    if [[ $VAULT_AVAILABLE -eq 0 ]]; then
        return 0
    fi
    
    if ! vault_is_initialized; then
        echo ""
        echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║              CREDENTIALS VAULT AVAILABLE                       ║${NC}"
        echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "${YELLOW}💡 RocketVPS can securely store all credentials in an encrypted vault.${NC}"
        echo ""
        echo "Benefits:"
        echo "  • AES-256 encryption"
        echo "  • Master password protection"
        echo "  • Auto-save credentials from all profiles"
        echo "  • Easy credential management"
        echo "  • Secure export/import"
        echo ""
        
        read -p "$(echo -e ${CYAN}Would you like to initialize the Credentials Vault? \(y/n\): ${NC})" init_vault
        
        if [[ "$init_vault" =~ ^[Yy] ]]; then
            vault_init
        fi
    elif vault_is_locked; then
        echo ""
        echo -e "${YELLOW}💡 Credentials Vault is locked. Unlock it to enable auto-save.${NC}"
        echo ""
        
        read -p "$(echo -e ${CYAN}Would you like to unlock the vault now? \(y/n\): ${NC})" unlock_vault
        
        if [[ "$unlock_vault" =~ ^[Yy] ]]; then
            vault_unlock
        fi
    fi
}

################################################################################
# EXPORT FUNCTIONS
################################################################################

export -f integration_save_wordpress_credentials integration_save_laravel_credentials
export -f integration_save_nodejs_credentials integration_save_static_credentials
export -f integration_save_ecommerce_credentials integration_save_saas_credentials
export -f integration_hook_wordpress_complete integration_hook_laravel_complete
export -f integration_hook_nodejs_complete integration_hook_static_complete
export -f integration_hook_ecommerce_complete integration_hook_saas_complete
export -f integration_prompt_vault_init
