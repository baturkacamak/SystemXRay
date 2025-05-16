#!/bin/bash

# Source required files
source "$(dirname "${BASH_SOURCE[0]}")/../config/colors.sh"

# Get CPU information
get_cpu_info() {
    echo -e "\n${BOLD}${BLUE}CPU Bilgileri${RESET}"
    echo -e "${CYAN}----------------------------------------${RESET}"

    # Basic CPU information
    if command -v lscpu &> /dev/null; then
        echo -e "${YELLOW}CPU Model:${RESET}"
        lscpu | grep "Model name" | sed 's/^.*: *//'
        
        echo -e "\n${YELLOW}CPU Özellikleri:${RESET}"
        echo -e "Çekirdek Sayısı: $(lscpu | grep "CPU(s):" | head -1 | awk '{print $2}')"
        echo -e "Thread Sayısı: $(lscpu | grep "Thread(s) per core" | awk '{print $4}')"
        echo -e "Maksimum Hız: $(lscpu | grep "CPU max MHz" | awk '{print $4}') MHz"
        echo -e "Önbellek: $(lscpu | grep "L3 cache" | awk '{print $3}')"
    fi

    # CPU temperature if available
    if command -v sensors &> /dev/null; then
        echo -e "\n${YELLOW}CPU Sıcaklığı:${RESET}"
        sensors | grep -E "Core|Package" | grep -v "crit" | sed 's/^/  /'
    fi

    # CPU usage
    echo -e "\n${YELLOW}CPU Kullanımı:${RESET}"
    top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1"%"}'
}

# Get CPU architecture information
get_cpu_arch_info() {
    echo -e "\n${BOLD}${BLUE}CPU Mimarisi${RESET}"
    echo -e "${CYAN}----------------------------------------${RESET}"

    if command -v lscpu &> /dev/null; then
        echo -e "${YELLOW}Mimari Detayları:${RESET}"
        lscpu | grep -E "Architecture|CPU op-mode|Byte Order|Vendor ID|Virtualization|Hypervisor vendor"
    fi
}

# Get CPU flags and features
get_cpu_features() {
    echo -e "\n${BOLD}${BLUE}CPU Özellikleri ve Bayraklar${RESET}"
    echo -e "${CYAN}----------------------------------------${RESET}"

    if command -v lscpu &> /dev/null; then
        echo -e "${YELLOW}CPU Bayrakları:${RESET}"
        lscpu | grep "Flags" | sed 's/^.*: *//' | fold -s -w 80
    fi
}

# Main CPU information gathering function
gather_cpu_info() {
    get_cpu_info
    get_cpu_arch_info
    get_cpu_features
} 