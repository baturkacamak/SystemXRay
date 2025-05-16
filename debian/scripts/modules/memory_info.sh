#!/bin/bash

# Source required files
source "$(dirname "${BASH_SOURCE[0]}")/../config/colors.sh"

# Get basic RAM information
get_basic_ram_info() {
    echo -e "\n${BOLD}${BLUE}$MEMORY_INFO${RESET}"
    echo -e "${CYAN}----------------------------------------${RESET}"

    if command -v dmidecode &> /dev/null; then
        # Get total RAM
        TOTAL_RAM=$(free -h | grep "Mem:" | awk '{print $2}')
        echo -e "${YELLOW}$TOTAL_MEMORY:${RESET} $TOTAL_RAM"

        # Get RAM modules
        echo -e "\n${YELLOW}$MEMORY_MODULES:${RESET}"
        INSTALLED_MODULE_COUNT=0
        
        # Process each memory device
        while IFS= read -r line; do
            # Start of a new module
            if [[ $line == *"Memory Device"* ]]; then
                MODULE_INFO=""
                HAS_MODULE=false
            # Skip if no module installed
            elif [[ $line == *"No Module Installed"* ]]; then
                HAS_MODULE=false
            # Collect module information
            elif [[ $line == *"Size:"* ]] && [[ $line != *"No Module Installed"* ]]; then
                SIZE=$(echo "$line" | sed 's/^.*Size: *//')
                INSTALLED_MODULE_COUNT=$((INSTALLED_MODULE_COUNT + 1))
                MODULE_INFO="RAM $INSTALLED_MODULE_COUNT: $SIZE"
                HAS_MODULE=true
            elif [[ $line == *"Type:"* ]] && [[ $line != *"Unknown"* ]] && [[ $HAS_MODULE == true ]]; then
                TYPE=$(echo "$line" | sed 's/^.*Type: *//')
                MODULE_INFO="$MODULE_INFO, $TYPE"
            elif [[ $line == *"Speed:"* ]] && [[ $line != *"Unknown"* ]] && [[ $HAS_MODULE == true ]]; then
                SPEED=$(echo "$line" | sed 's/^.*Speed: *//')
                MODULE_INFO="$MODULE_INFO, $SPEED"
            elif [[ $line == *"Manufacturer:"* ]] && [[ $line != *"Not Specified"* ]] && [[ $HAS_MODULE == true ]]; then
                MANUFACTURER=$(echo "$line" | sed 's/^.*Manufacturer: *//')
                MODULE_INFO="$MODULE_INFO, $MANUFACTURER"
            elif [[ $line == *"Part Number:"* ]] && [[ $line != *"Not Specified"* ]] && [[ $HAS_MODULE == true ]]; then
                PART_NUMBER=$(echo "$line" | sed 's/^.*Part Number: *//')
                MODULE_INFO="$MODULE_INFO, $PART_NUMBER"
                # Print the complete module info
                echo -e "  $MODULE_INFO"
            fi
        done < <(sudo dmidecode -t memory 2>/dev/null)
    fi
}

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
    if [ "$DETAILED" = true ]; then
        get_ram_info
        get_swap_info
        get_memory_usage_details
    else
        get_basic_ram_info
    fi
} 