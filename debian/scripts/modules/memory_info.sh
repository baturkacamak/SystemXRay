#!/bin/bash

# Source required files
source "$(dirname "${BASH_SOURCE[0]}")/../config/colors.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../utils/common.sh"

# Get basic RAM information
get_basic_ram_info() {
    print_section_header "$MEMORY_INFO"

    if check_command_available "free"; then
        local total_ram=$(free -h | grep "Mem:" | awk '{print $2}')
        print_key_value "$TOTAL_MEMORY" "$total_ram"
    fi

    if check_command_available "dmidecode"; then
        print_list "$MEMORY_MODULES" "$(get_memory_modules_info)"
    fi
}

# Get memory modules information
get_memory_modules_info() {
    local module_info=""
    local installed_module_count=0
    
    while IFS= read -r line; do
        if [[ $line == *"Memory Device"* ]]; then
            module_info=""
            has_module=false
        elif [[ $line == *"No Module Installed"* ]]; then
            has_module=false
        elif [[ $line == *"Size:"* ]] && [[ $line != *"No Module Installed"* ]]; then
            local size=$(echo "$line" | sed 's/^.*Size: *//')
            installed_module_count=$((installed_module_count + 1))
            module_info="RAM $installed_module_count: $size"
            has_module=true
        elif [[ $line == *"Type:"* ]] && [[ $line != *"Unknown"* ]] && [[ $has_module == true ]]; then
            local type=$(echo "$line" | sed 's/^.*Type: *//')
            module_info="$module_info, $type"
        elif [[ $line == *"Speed:"* ]] && [[ $line != *"Unknown"* ]] && [[ $has_module == true ]]; then
            local speed=$(echo "$line" | sed 's/^.*Speed: *//')
            module_info="$module_info, $speed"
        elif [[ $line == *"Manufacturer:"* ]] && [[ $line != *"Not Specified"* ]] && [[ $has_module == true ]]; then
            local manufacturer=$(echo "$line" | sed 's/^.*Manufacturer: *//')
            module_info="$module_info, $manufacturer"
        elif [[ $line == *"Part Number:"* ]] && [[ $line != *"Not Specified"* ]] && [[ $has_module == true ]]; then
            local part_number=$(echo "$line" | sed 's/^.*Part Number: *//')
            module_info="$module_info, $part_number"
            echo "$module_info"
        fi
    done < <(sudo dmidecode -t memory 2>/dev/null)
}

# Get RAM information
get_ram_info() {
    print_section_header "$MEMORY_INFO"

    if check_command_available "free"; then
        print_list "$MEMORY_USAGE" "$(free -h | grep -v "Swap")"
    fi

    if check_command_available "dmidecode"; then
        print_list "$MEMORY_MODULES" "$(sudo dmidecode -t memory | grep -E "Size|Type|Speed|Manufacturer|Serial Number|Part Number" | grep -v "Unknown")"
    fi
}

# Get swap information
get_swap_info() {
    print_section_header "$SWAP_INFO"

    if check_command_available "free"; then
        print_list "$SWAP_USAGE" "$(free -h | grep "Swap")"
    fi

    if check_command_available "swapon"; then
        print_list "$SWAP_AREAS" "$(swapon --show)"
    fi
}

# Get memory usage details
get_memory_usage_details() {
    print_section_header "$MEMORY_USAGE_DETAILS"

    if check_command_available "ps"; then
        print_list "$TOP_MEMORY_PROCESSES" "$(ps aux --sort=-%mem | head -6)"
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