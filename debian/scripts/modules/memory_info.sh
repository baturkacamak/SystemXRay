#!/bin/bash

# Source required files
source "$(dirname "${BASH_SOURCE[0]}")/../config/colors.sh"

# Get RAM information
get_ram_info() {
    echo -e "\n${BOLD}${BLUE}$MEMORY_INFO${RESET}"
    echo -e "${CYAN}----------------------------------------${RESET}"

    if command -v free &> /dev/null; then
        echo -e "${YELLOW}$MEMORY_USAGE:${RESET}"
        free -h | grep -v "Swap" | sed 's/^/  /'
    fi

    if command -v dmidecode &> /dev/null; then
        echo -e "\n${YELLOW}$MEMORY_MODULES:${RESET}"
        sudo dmidecode -t memory | grep -E "Size|Type|Speed|Manufacturer|Serial Number|Part Number" | grep -v "Unknown" | sed 's/^/  /'
    fi
}

# Get swap information
get_swap_info() {
    echo -e "\n${BOLD}${BLUE}$SWAP_INFO${RESET}"
    echo -e "${CYAN}----------------------------------------${RESET}"

    if command -v free &> /dev/null; then
        echo -e "${YELLOW}$SWAP_USAGE:${RESET}"
        free -h | grep "Swap" | sed 's/^/  /'
    fi

    if command -v swapon &> /dev/null; then
        echo -e "\n${YELLOW}$SWAP_AREAS:${RESET}"
        swapon --show | sed 's/^/  /'
    fi
}

# Get memory usage details
get_memory_usage_details() {
    echo -e "\n${BOLD}${BLUE}$MEMORY_USAGE_DETAILS${RESET}"
    echo -e "${CYAN}----------------------------------------${RESET}"

    if command -v ps &> /dev/null; then
        echo -e "${YELLOW}$TOP_MEMORY_PROCESSES:${RESET}"
        ps aux --sort=-%mem | head -6 | sed 's/^/  /'
    fi
}

# Main memory information gathering function
gather_memory_info() {
    get_ram_info
    get_swap_info
    get_memory_usage_details
} 