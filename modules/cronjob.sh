#!/bin/bash

################################################################################
# RocketVPS - Cronjob Management Module
################################################################################

# Cronjob menu
cronjob_menu() {
    while true; do
        show_header
        echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║                  CRONJOB MANAGEMENT                           ║${NC}"
        echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo "  1) Add Cronjob"
        echo "  2) List All Cronjobs"
        echo "  3) Edit Cronjobs"
        echo "  4) Delete Cronjob"
        echo "  5) Add Predefined Cronjob"
        echo "  6) View Cron Log"
        echo ""
        echo "  0) Back to Main Menu"
        echo ""
        echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
        
        read -p "Enter your choice [0-6]: " cron_choice
        
        case $cron_choice in
            1) add_cronjob ;;
            2) list_cronjobs ;;
            3) edit_cronjobs ;;
            4) delete_cronjob ;;
            5) add_predefined_cronjob ;;
            6) view_cron_log ;;
            0) return ;;
            *)
                print_error "Invalid choice"
                sleep 2
                ;;
        esac
    done
}

# Add cronjob
add_cronjob() {
    show_header
    echo -e "${CYAN}Add Cronjob${NC}"
    echo ""
    
    echo "Enter cron schedule (or select preset):"
    echo "  1) Every minute"
    echo "  2) Every hour"
    echo "  3) Every day at midnight"
    echo "  4) Every week (Sunday midnight)"
    echo "  5) Every month (1st day midnight)"
    echo "  6) Custom"
    echo ""
    read -p "Enter choice [1-6]: " schedule_choice
    
    case $schedule_choice in
        1) schedule="* * * * *" ;;
        2) schedule="0 * * * *" ;;
        3) schedule="0 0 * * *" ;;
        4) schedule="0 0 * * 0" ;;
        5) schedule="0 0 1 * *" ;;
        6) 
            read -p "Enter cron expression (e.g., 0 2 * * *): " schedule
            ;;
        *)
            print_error "Invalid choice"
            press_any_key
            return
            ;;
    esac
    
    echo ""
    read -p "Enter command to execute: " command
    
    if [ -z "$command" ]; then
        print_error "Command cannot be empty"
        press_any_key
        return
    fi
    
    # Add to crontab
    (crontab -l 2>/dev/null; echo "${schedule} ${command}") | crontab -
    
    print_success "Cronjob added successfully"
    print_info "Schedule: $schedule"
    print_info "Command: $command"
    
    press_any_key
}

# List cronjobs
list_cronjobs() {
    show_header
    echo -e "${CYAN}All Cronjobs:${NC}"
    echo ""
    
    local crontab_output=$(crontab -l 2>/dev/null)
    
    if [ -z "$crontab_output" ]; then
        print_info "No cronjobs found"
    else
        echo "$crontab_output" | nl
    fi
    
    echo ""
    press_any_key
}

# Edit cronjobs
edit_cronjobs() {
    print_info "Opening crontab editor..."
    crontab -e
    press_any_key
}

# Delete cronjob
delete_cronjob() {
    show_header
    echo -e "${CYAN}Delete Cronjob${NC}"
    echo ""
    
    local crontab_output=$(crontab -l 2>/dev/null)
    
    if [ -z "$crontab_output" ]; then
        print_info "No cronjobs found"
        press_any_key
        return
    fi
    
    echo "Current cronjobs:"
    echo "$crontab_output" | nl
    
    echo ""
    read -p "Enter line number to delete: " line_num
    
    if [ -z "$line_num" ] || ! [[ "$line_num" =~ ^[0-9]+$ ]]; then
        print_error "Invalid line number"
        press_any_key
        return
    fi
    
    # Delete line
    crontab -l | sed "${line_num}d" | crontab -
    
    print_success "Cronjob deleted"
    press_any_key
}

# Add predefined cronjob
add_predefined_cronjob() {
    show_header
    echo -e "${CYAN}Add Predefined Cronjob${NC}"
    echo ""
    
    echo "Select cronjob template:"
    echo "  1) Clear cache daily"
    echo "  2) Update SSL certificates weekly"
    echo "  3) Optimize database weekly"
    echo "  4) Clean logs monthly"
    echo "  5) Update system packages weekly"
    echo "  6) Restart services daily"
    echo "  7) Monitor disk space hourly"
    echo "  8) Backup websites daily"
    echo ""
    read -p "Enter choice [1-8]: " template_choice
    
    case $template_choice in
        1)
            schedule="0 3 * * *"
            command="rm -rf /tmp/* /var/tmp/*"
            description="Clear cache daily at 3 AM"
            ;;
        2)
            schedule="0 3 * * 0"
            command="certbot renew --quiet"
            description="Update SSL certificates weekly"
            ;;
        3)
            schedule="0 4 * * 0"
            command="mysqlcheck --optimize --all-databases"
            description="Optimize database weekly"
            ;;
        4)
            schedule="0 2 1 * *"
            command="find /var/log -type f -name '*.log' -mtime +30 -delete"
            description="Clean old logs monthly"
            ;;
        5)
            schedule="0 2 * * 0"
            command="apt-get update && apt-get upgrade -y"
            description="Update system packages weekly"
            ;;
        6)
            schedule="0 4 * * *"
            command="systemctl restart nginx php*-fpm"
            description="Restart services daily"
            ;;
        7)
            schedule="0 * * * *"
            command="df -h | mail -s 'Disk Space Report' root"
            description="Monitor disk space hourly"
            ;;
        8)
            schedule="0 2 * * *"
            command="${ROCKETVPS_DIR}/auto_backup.sh"
            description="Backup websites daily"
            ;;
        *)
            print_error "Invalid choice"
            press_any_key
            return
            ;;
    esac
    
    print_info "Template: $description"
    print_info "Schedule: $schedule"
    print_info "Command: $command"
    echo ""
    
    read -p "Add this cronjob? (yes/no): " confirm
    
    if [ "$confirm" = "yes" ]; then
        (crontab -l 2>/dev/null; echo "# $description"; echo "${schedule} ${command}") | crontab -
        print_success "Cronjob added successfully"
    else
        print_info "Operation cancelled"
    fi
    
    press_any_key
}

# View cron log
view_cron_log() {
    show_header
    echo -e "${CYAN}Cron Log:${NC}"
    echo ""
    
    if [ -f /var/log/cron.log ]; then
        tail -n 50 /var/log/cron.log
    elif [ -f /var/log/syslog ]; then
        grep CRON /var/log/syslog | tail -n 50
    else
        print_warning "Cron log not found"
    fi
    
    echo ""
    press_any_key
}
