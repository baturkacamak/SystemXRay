#!/bin/bash

# Source required files
source "$(dirname "${BASH_SOURCE[0]}")/../config/colors.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../utils/common.sh"

# Get basic CPU information
get_basic_cpu_info() {
    print_section_header "$CPU_INFO"

    if check_command_available "lscpu"; then
        local model=$(extract_value "lscpu" "Model name" 's/^.*: *//')
        local cores=$(extract_value "lscpu" "CPU(s):" 's/^.*: *//')
        local threads=$(extract_value "lscpu" "Thread(s) per core" 's/^.*: *//')
        
        # Ensure we have valid numbers for calculation
        if [[ "$cores" =~ ^[0-9]+$ ]] && [[ "$threads" =~ ^[0-9]+$ ]]; then
            local total_threads=$((cores * threads))
            print_key_value "$CPU_MODEL" "$model"
            print_key_value "$CPU_CORES_THREADS" "$cores cores, $total_threads threads"
        else
            print_key_value "$CPU_MODEL" "$model"
            print_key_value "$CPU_CORES" "$cores"
            print_key_value "$CPU_THREADS" "$threads"
        fi
    fi
}

# Get CPU information
get_cpu_info() {
    print_section_header "$CPU_INFO"

    if check_command_available "lscpu"; then
        print_key_value "$CPU_MODEL" "$(extract_value "lscpu" "Model name" 's/^.*: *//')"
        
        # Get CPU features with proper error handling
        local cpu_features=$(lscpu | grep -E "CPU\(s\)|Thread\(s\) per core|CPU max MHz|L3 cache" | sed 's/^.*: *//')
        if [ ! -z "$cpu_features" ]; then
            print_list "$CPU_FEATURES" "$cpu_features"
        fi
    fi

    if check_command_available "sensors"; then
        local temp_info=$(sensors | grep -E "Core|Package" | grep -v "crit")
        if [ ! -z "$temp_info" ]; then
            print_list "$CPU_TEMP" "$temp_info"
        fi
    fi

    if check_command_available "top"; then
        local cpu_usage=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1"%"}')
        if [ ! -z "$cpu_usage" ]; then
            print_key_value "$CPU_USAGE" "$cpu_usage"
        fi
    fi
}

# Get CPU architecture information
get_cpu_arch_info() {
    print_section_header "$CPU_ARCH_INFO"

    if check_command_available "lscpu"; then
        local arch_info=$(lscpu | grep -E "Architecture|CPU op-mode|Byte Order|Vendor ID|Virtualization|Hypervisor vendor")
        if [ ! -z "$arch_info" ]; then
            print_list "$ARCHITECTURE_DETAILS" "$arch_info"
        fi
    fi
}

# Get CPU flags and features
get_cpu_features() {
    print_section_header "$CPU_FEATURES_AND_FLAGS"

    if check_command_available "lscpu"; then
        local flags=$(lscpu | grep "Flags" | sed 's/^.*: *//' | fold -s -w 80)
        if [ ! -z "$flags" ]; then
            print_list "$CPU_FLAGS" "$flags"
        fi
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