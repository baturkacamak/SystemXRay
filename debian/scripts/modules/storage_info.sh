#!/bin/bash

# Source required files
source "$(dirname "${BASH_SOURCE[0]}")/../config/colors.sh"

# Get disk usage information
get_disk_usage() {
    echo -e "\n${BOLD}${BLUE}Disk Kullanımı${RESET}"
    echo -e "${CYAN}----------------------------------------${RESET}"

    if command -v df &> /dev/null; then
        echo -e "${YELLOW}Dosya Sistemi Kullanımı:${RESET}"
        df -h | grep -v "tmpfs" | grep -v "udev" | sed 's/^/  /'
    fi
}

# Get disk information
get_disk_info() {
    echo -e "\n${BOLD}${BLUE}Disk Bilgileri${RESET}"
    echo -e "${CYAN}----------------------------------------${RESET}"

    if command -v lsblk &> /dev/null; then
        echo -e "${YELLOW}Disk Cihazları:${RESET}"
        lsblk -o NAME,SIZE,TYPE,MOUNTPOINT,FSTYPE | sed 's/^/  /'
    fi
}

# Get SMART information for disks
get_smart_info() {
    echo -e "\n${BOLD}${BLUE}SMART Disk Bilgileri${RESET}"
    echo -e "${CYAN}----------------------------------------${RESET}"

    if command -v smartctl &> /dev/null; then
        for disk in $(lsblk -d -o NAME | grep -v "NAME"); do
            echo -e "${YELLOW}Disk /dev/$disk:${RESET}"
            sudo smartctl -i /dev/$disk 2>/dev/null | grep -E "Model Family|Device Model|Serial Number|Firmware Version|User Capacity" | sed 's/^/  /'
            
            # Get SMART health status
            echo -e "${YELLOW}SMART Sağlık Durumu:${RESET}"
            sudo smartctl -H /dev/$disk 2>/dev/null | grep "SMART overall-health" | sed 's/^/  /'
        done
    fi
}

# Get disk temperature
get_disk_temperature() {
    echo -e "\n${BOLD}${BLUE}Disk Sıcaklıkları${RESET}"
    echo -e "${CYAN}----------------------------------------${RESET}"

    if command -v hddtemp &> /dev/null; then
        echo -e "${YELLOW}Disk Sıcaklıkları:${RESET}"
        sudo hddtemp /dev/sd[a-z] 2>/dev/null | sed 's/^/  /'
    fi
}

# Get disk I/O statistics
get_disk_io_stats() {
    echo -e "\n${BOLD}${BLUE}Disk I/O İstatistikleri${RESET}"
    echo -e "${CYAN}----------------------------------------${RESET}"

    if command -v iostat &> /dev/null; then
        echo -e "${YELLOW}Disk I/O İstatistikleri:${RESET}"
        iostat -x 1 1 | sed 's/^/  /'
    fi
}

# Main storage information gathering function
gather_storage_info() {
    get_disk_usage
    get_disk_info
    get_smart_info
    get_disk_temperature
    get_disk_io_stats
} 