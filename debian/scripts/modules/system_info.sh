#!/bin/bash

# Source required files
source "$(dirname "${BASH_SOURCE[0]}")/../config/colors.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../utils/common.sh"

# Get basic system information (vendor and model)
get_basic_system_info() {
    print_section_header "$SYSTEM_INFO"

    if check_command_available "dmidecode"; then
        local vendor=$(sudo dmidecode -s system-manufacturer 2>/dev/null)
        local model=$(sudo dmidecode -s system-product-name 2>/dev/null)
        
        if [ ! -z "$vendor" ] && [ ! -z "$model" ]; then
            print_key_value "System" "$vendor $model"
        fi
    fi
}

# Get system information
get_system_info() {
    print_section_header "$SYSTEM_INFO"

    if check_command_available "hostnamectl"; then
        print_list "$SYSTEM_INFO" "$(hostnamectl)"
    fi
}

# Get OS information
get_os_info() {
    print_section_header "$OS_INFO"

    if [ -f /etc/os-release ]; then
        print_list "$OS" "$(cat /etc/os-release | grep -E "PRETTY_NAME|VERSION")"
    fi
}

# Get kernel information
get_kernel_info() {
    print_section_header "$KERNEL_INFO"
    print_list "$KERNEL_VERSION" "$(uname -a)"
}

# Get system uptime
get_uptime_info() {
    print_section_header "$UPTIME_INFO"

    if check_command_available "uptime"; then
        print_list "$UPTIME" "$(uptime)"
    fi
}

# Get system load
get_system_load() {
    print_section_header "$SYSTEM_LOAD"

    if check_command_available "top"; then
        print_list "$SYSTEM_LOAD" "$(top -bn1 | grep "load average")"
    fi
}

# Get running processes
get_running_processes() {
    print_section_header "$RUNNING_PROCESSES"

    if check_command_available "ps"; then
        print_list "$TOP_CPU_PROCESSES" "$(ps aux --sort=-%cpu | head -6)"
    fi
}

# Get system services
get_system_services() {
    print_section_header "$SYSTEM_SERVICES"

    if check_command_available "systemctl"; then
        print_list "$ACTIVE_SERVICES" "$(systemctl list-units --type=service --state=running | head -10)"
    fi
}

# Get system users
get_system_users() {
    print_section_header "$SYSTEM_USERS"
    print_list "$ACTIVE_USERS" "$(who)"
}

# Main system information gathering function
gather_system_info() {
    if [ "$DETAILED" = true ]; then
        get_system_info
        get_os_info
        get_kernel_info
        get_uptime_info
        get_system_load
        get_running_processes
        get_system_services
        get_system_users
    else
        get_basic_system_info
    fi
} 