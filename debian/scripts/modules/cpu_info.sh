#!/bin/bash

# Source required files
source "$(dirname "${BASH_SOURCE[0]}")/../config/colors.sh"

# Get basic CPU information
get_basic_cpu_info() {
    echo -e "\n${BOLD}${BLUE}$CPU_INFO${RESET}"
    echo -e "${CYAN}----------------------------------------${RESET}"

    if command -v lscpu &> /dev/null; then
        MODEL=$(lscpu | grep "Model name" | sed 's/^.*: *//')
        CORES=$(lscpu | grep "CPU(s):" | head -1 | awk '{print $2}')
        THREADS=$(lscpu | grep "Thread(s) per core" | awk '{print $4}')
        TOTAL_THREADS=$((CORES * THREADS))
        
        echo -e "${YELLOW}Processor:${RESET} $MODEL"
        echo -e "${YELLOW}Cores/Threads:${RESET} $CORES cores, $TOTAL_THREADS threads"
    fi
}

# Get CPU information
get_cpu_info() {
    echo -e "\n${BOLD}${BLUE}$CPU_INFO${RESET}"
    echo -e "${CYAN}----------------------------------------${RESET}"

    # Basic CPU information
    if command -v lscpu &> /dev/null; then
        echo -e "${YELLOW}$CPU_MODEL:${RESET}"
        lscpu | grep "Model name" | sed 's/^.*: *//'
        
        echo -e "\n${YELLOW}$CPU_FEATURES:${RESET}"
        echo -e "$CPU_CORES: $(lscpu | grep "CPU(s):" | head -1 | awk '{print $2}')"
        echo -e "$CPU_THREADS: $(lscpu | grep "Thread(s) per core" | awk '{print $4}')"
        echo -e "$CPU_MAX_SPEED: $(lscpu | grep "CPU max MHz" | awk '{print $4}') MHz"
        echo -e "$CPU_CACHE: $(lscpu | grep "L3 cache" | awk '{print $3}')"
    fi

    # CPU temperature if available
    if command -v sensors &> /dev/null; then
        echo -e "\n${YELLOW}$CPU_TEMP:${RESET}"
        sensors | grep -E "Core|Package" | grep -v "crit" | sed 's/^/  /'
    fi

    # CPU usage
    echo -e "\n${YELLOW}$CPU_USAGE:${RESET}"
    top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1"%"}'
}

# Get CPU architecture information
get_cpu_arch_info() {
    echo -e "\n${BOLD}${BLUE}$CPU_ARCH_INFO${RESET}"
    echo -e "${CYAN}----------------------------------------${RESET}"

    if command -v lscpu &> /dev/null; then
        echo -e "${YELLOW}$ARCHITECTURE_DETAILS:${RESET}"
        lscpu | grep -E "Architecture|CPU op-mode|Byte Order|Vendor ID|Virtualization|Hypervisor vendor"
    fi
}

# Get CPU flags and features
get_cpu_features() {
    echo -e "\n${BOLD}${BLUE}$CPU_FEATURES_AND_FLAGS${RESET}"
    echo -e "${CYAN}----------------------------------------${RESET}"

    if command -v lscpu &> /dev/null; then
        echo -e "${YELLOW}$CPU_FLAGS:${RESET}"
        lscpu | grep "Flags" | sed 's/^.*: *//' | fold -s -w 80
    fi
}

# Main CPU information gathering function
gather_cpu_info() {
    if [ "$DETAILED" = true ]; then
        get_cpu_info
        get_cpu_arch_info
        get_cpu_features
    else
        get_basic_cpu_info
    fi
} 