#!/bin/bash

# Source required files
source "$(dirname "${BASH_SOURCE[0]}")/../config/colors.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../utils/common.sh"

# Get disk usage information
get_disk_usage() {
    print_section_header "$DISK_USAGE"

    if check_command_available "df"; then
        print_list "$FILESYSTEM_USAGE" "$(df -h | grep -v "tmpfs" | grep -v "udev")"
    fi
}

# Get disk information
get_disk_info() {
    print_section_header "$DISK_INFO"

    if check_command_available "lsblk"; then
        print_list "$DISK_DEVICES" "$(lsblk -o NAME,SIZE,TYPE,MOUNTPOINT,FSTYPE)"
    fi
}

# Get SMART information for disks
get_smart_info() {
    print_section_header "$SMART_DISK_INFO"

    if check_command_available "smartctl"; then
        for disk in $(lsblk -d -o NAME | grep -v "NAME"); do
            print_key_value "$DISK_DEVICE /dev/$disk" ""
            print_list "" "$(sudo smartctl -i /dev/$disk 2>/dev/null | grep -E "Model Family|Device Model|Serial Number|Firmware Version|User Capacity")"
            
            # Get SMART health status
            print_list "$SMART_HEALTH_STATUS" "$(sudo smartctl -H /dev/$disk 2>/dev/null | grep "SMART overall-health")"
        done
    fi
}

# Get disk temperature
get_disk_temperature() {
    print_section_header "$DISK_TEMPERATURES"

    if check_command_available "hddtemp"; then
        print_list "$DISK_TEMPERATURES" "$(sudo hddtemp /dev/sd[a-z] 2>/dev/null)"
    fi
}

# Get disk I/O statistics
get_disk_io_stats() {
    print_section_header "$DISK_IO_STATS"

    if check_command_available "iostat"; then
        print_list "$DISK_IO_STATS" "$(iostat -x 1 1)"
    fi
}

# Get basic storage information
get_basic_storage_info() {
    print_section_header "$DISK_INFO"

    if check_command_available "lsblk"; then
        # Print the storage devices title
        print_section_header "Storage Devices"
        
        # Get physical drives
        local device_count=0
        for disk in $(lsblk -d -o NAME | grep -v "NAME"); do
            if [[ $disk == *"nvme"* ]] || [[ $disk == *"sd"* ]]; then
                local vendor=$(lsblk -d -o VENDOR /dev/$disk | tail -n 1 | sed 's/^[ \t]*//;s/[ \t]*$//')
                local model=$(lsblk -d -o MODEL /dev/$disk | tail -n 1 | sed 's/^[ \t]*//;s/[ \t]*$//')
                local size=$(lsblk -d -o SIZE /dev/$disk | tail -n 1)
                
                # Determine storage type
                local type
                if [[ $disk == *"nvme"* ]]; then
                    type="NVMe SSD"
                elif [[ $model == *"SSD"* ]]; then
                    type="SATA SSD"
                else
                    type="HDD"
                fi
                
                # Clean up model name
                model=$(echo "$model" | sed 's/SSD//g' | sed 's/^[ \t]*//;s/[ \t]*$//')
                
                # Increment device counter
                ((device_count++))
                
                # Print each device on a new line with proper indentation
                echo -e "  ${YELLOW}${device_count}. ${type}${RESET}: $vendor $model - $size"
            fi
        done
    fi
}

# Main storage information gathering function
gather_storage_info() {
    if [ "$DETAILED" = true ]; then
        get_disk_usage
        get_disk_info
        get_smart_info
        get_disk_temperature
        get_disk_io_stats
    else
        get_basic_storage_info
    fi
} 