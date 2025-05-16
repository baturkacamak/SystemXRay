#!/bin/bash

# Source required files
source "$(dirname "${BASH_SOURCE[0]}")/../config/colors.sh"

# Get system information
get_system_info() {
    echo -e "\n${BOLD}${BLUE}Sistem Bilgileri${RESET}"
    echo -e "${CYAN}----------------------------------------${RESET}"

    if command -v hostnamectl &> /dev/null; then
        echo -e "${YELLOW}Sistem Bilgileri:${RESET}"
        hostnamectl | sed 's/^/  /'
    fi
}

# Get OS information
get_os_info() {
    echo -e "\n${BOLD}${BLUE}İşletim Sistemi Bilgileri${RESET}"
    echo -e "${CYAN}----------------------------------------${RESET}"

    if [ -f /etc/os-release ]; then
        echo -e "${YELLOW}İşletim Sistemi:${RESET}"
        cat /etc/os-release | grep -E "PRETTY_NAME|VERSION" | sed 's/^/  /'
    fi
}

# Get kernel information
get_kernel_info() {
    echo -e "\n${BOLD}${BLUE}Çekirdek (Kernel) Bilgileri${RESET}"
    echo -e "${CYAN}----------------------------------------${RESET}"

    echo -e "${YELLOW}Kernel Sürümü:${RESET}"
    uname -a | sed 's/^/  /'
}

# Get system uptime
get_uptime_info() {
    echo -e "\n${BOLD}${BLUE}Sistem Çalışma Süresi${RESET}"
    echo -e "${CYAN}----------------------------------------${RESET}"

    if command -v uptime &> /dev/null; then
        echo -e "${YELLOW}Çalışma Süresi:${RESET}"
        uptime | sed 's/^/  /'
    fi
}

# Get system load
get_system_load() {
    echo -e "\n${BOLD}${BLUE}Sistem Yükü${RESET}"
    echo -e "${CYAN}----------------------------------------${RESET}"

    if command -v top &> /dev/null; then
        echo -e "${YELLOW}Sistem Yükü:${RESET}"
        top -bn1 | grep "load average" | sed 's/^/  /'
    fi
}

# Get running processes
get_running_processes() {
    echo -e "\n${BOLD}${BLUE}Çalışan İşlemler${RESET}"
    echo -e "${CYAN}----------------------------------------${RESET}"

    if command -v ps &> /dev/null; then
        echo -e "${YELLOW}En Çok CPU Kullanan İşlemler:${RESET}"
        ps aux --sort=-%cpu | head -6 | sed 's/^/  /'
    fi
}

# Get system services
get_system_services() {
    echo -e "\n${BOLD}${BLUE}Sistem Servisleri${RESET}"
    echo -e "${CYAN}----------------------------------------${RESET}"

    if command -v systemctl &> /dev/null; then
        echo -e "${YELLOW}Aktif Servisler:${RESET}"
        systemctl list-units --type=service --state=running | head -10 | sed 's/^/  /'
    fi
}

# Get system users
get_system_users() {
    echo -e "\n${BOLD}${BLUE}Sistem Kullanıcıları${RESET}"
    echo -e "${CYAN}----------------------------------------${RESET}"

    echo -e "${YELLOW}Aktif Kullanıcılar:${RESET}"
    who | sed 's/^/  /'
}

# Main system information gathering function
gather_system_info() {
    get_system_info
    get_os_info
    get_kernel_info
    get_uptime_info
    get_system_load
    get_running_processes
    get_system_services
    get_system_users
} 