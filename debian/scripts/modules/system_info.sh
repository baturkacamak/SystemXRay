#!/bin/bash

# Source required files
source "$(dirname "${BASH_SOURCE[0]}")/../config/colors.sh"

# Get basic system information (vendor and model)
get_basic_system_info() {
    echo -e "\n${BOLD}${BLUE}$SYSTEM_INFO${RESET}"
    echo -e "${CYAN}----------------------------------------${RESET}"

    if command -v dmidecode &> /dev/null; then
        VENDOR=$(sudo dmidecode -s system-manufacturer 2>/dev/null)
        MODEL=$(sudo dmidecode -s system-product-name 2>/dev/null)
        
        if [ ! -z "$VENDOR" ] && [ ! -z "$MODEL" ]; then
            echo -e "${YELLOW}System:${RESET} $VENDOR $MODEL"
        fi
    fi
}

# Get system information
get_system_info() {
    echo -e "\n${BOLD}${BLUE}$SYSTEM_INFO${RESET}"
    echo -e "${CYAN}----------------------------------------${RESET}"

    if command -v hostnamectl &> /dev/null; then
        echo -e "${YELLOW}$SYSTEM_INFO:${RESET}"
        hostnamectl | sed 's/^/  /'
    fi
}

# Get OS information
get_os_info() {
    echo -e "\n${BOLD}${BLUE}$OS_INFO${RESET}"
    echo -e "${CYAN}----------------------------------------${RESET}"

    if [ -f /etc/os-release ]; then
        echo -e "${YELLOW}$OS:${RESET}"
        cat /etc/os-release | grep -E "PRETTY_NAME|VERSION" | sed 's/^/  /'
    fi
}

# Get kernel information
get_kernel_info() {
    echo -e "\n${BOLD}${BLUE}$KERNEL_INFO${RESET}"
    echo -e "${CYAN}----------------------------------------${RESET}"

    echo -e "${YELLOW}$KERNEL_VERSION:${RESET}"
    uname -a | sed 's/^/  /'
}

# Get system uptime
get_uptime_info() {
    echo -e "\n${BOLD}${BLUE}$UPTIME_INFO${RESET}"
    echo -e "${CYAN}----------------------------------------${RESET}"

    if command -v uptime &> /dev/null; then
        echo -e "${YELLOW}$UPTIME:${RESET}"
        uptime | sed 's/^/  /'
    fi
}

# Get system load
get_system_load() {
    echo -e "\n${BOLD}${BLUE}$SYSTEM_LOAD${RESET}"
    echo -e "${CYAN}----------------------------------------${RESET}"

    if command -v top &> /dev/null; then
        echo -e "${YELLOW}$SYSTEM_LOAD:${RESET}"
        top -bn1 | grep "load average" | sed 's/^/  /'
    fi
}

# Get running processes
get_running_processes() {
    echo -e "\n${BOLD}${BLUE}$RUNNING_PROCESSES${RESET}"
    echo -e "${CYAN}----------------------------------------${RESET}"

    if command -v ps &> /dev/null; then
        echo -e "${YELLOW}$TOP_CPU_PROCESSES:${RESET}"
        ps aux --sort=-%cpu | head -6 | sed 's/^/  /'
    fi
}

# Get system services
get_system_services() {
    echo -e "\n${BOLD}${BLUE}$SYSTEM_SERVICES${RESET}"
    echo -e "${CYAN}----------------------------------------${RESET}"

    if command -v systemctl &> /dev/null; then
        echo -e "${YELLOW}$ACTIVE_SERVICES:${RESET}"
        systemctl list-units --type=service --state=running | head -10 | sed 's/^/  /'
    fi
}

# Get system users
get_system_users() {
    echo -e "\n${BOLD}${BLUE}$SYSTEM_USERS${RESET}"
    echo -e "${CYAN}----------------------------------------${RESET}"

    echo -e "${YELLOW}$ACTIVE_USERS:${RESET}"
    who | sed 's/^/  /'
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