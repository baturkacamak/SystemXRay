#!/bin/bash

# Help utility functions for hardware-report script

# Display help message
show_help() {
    echo -e "${BOLD}${GREEN}SystemXRay - Hardware Information Reporter${RESET}"
    echo -e "${CYAN}===============================================${RESET}\n"
    echo -e "${BOLD}Usage:${RESET}"
    echo -e "  ./hardware-report.sh [OPTIONS]\n"
    echo -e "${BOLD}Options:${RESET}"
    echo -e "  -h, --help                 Show this help message"
    echo -e "  -o, --output FILE          Save report to specified file"
    echo -e "  -H, --html                 Generate report in HTML format"
    echo -e "  -i, --interactive          Run in interactive mode"
    echo -e "  -s, --sections SECTIONS    Specify sections to include (comma-separated)"
    echo -e "                             Available sections: cpu, gpu, memory, storage, network, system"
    echo -e "  -l, --language LANG        Set report language (e.g., en, es, fr, de, etc.)\n"
    echo -e "${BOLD}Examples:${RESET}"
    echo -e "  ./hardware-report.sh                    # Generate full report in default language"
    echo -e "  ./hardware-report.sh -l es              # Generate report in Spanish"
    echo -e "  ./hardware-report.sh -o report.txt      # Save report to file"
    echo -e "  ./hardware-report.sh -H                 # Generate HTML report"
    echo -e "  ./hardware-report.sh -s cpu,memory      # Show only CPU and memory information"
    echo -e "  ./hardware-report.sh -i                 # Run in interactive mode\n"
    echo -e "${BOLD}Supported Languages:${RESET}"
    echo -e "  en - English (default)"
    echo -e "  es - Spanish"
    echo -e "  fr - French"
    echo -e "  de - German"
    echo -e "  it - Italian"
    echo -e "  pt - Portuguese"
    echo -e "  ru - Russian"
    echo -e "  zh - Chinese"
    echo -e "  ja - Japanese"
    echo -e "  ko - Korean"
    echo -e "  ar - Arabic"
    echo -e "  hi - Hindi"
    echo -e "  tr - Turkish"
    echo -e "  And many more...\n"
    echo -e "${BOLD}Note:${RESET}"
    echo -e "  If no language is specified, the script will try to use your system's default language."
    echo -e "  If your system language is not supported, it will fall back to English."
    echo -e "\n${CYAN}===============================================${RESET}"
}

# Show section-specific help
show_section_help() {
    local section="$1"
    case "$section" in
        "cpu")
            echo -e "${BOLD}CPU Information Section${RESET}"
            echo -e "Shows detailed information about your CPU including:"
            echo -e "  - CPU model and manufacturer"
            echo -e "  - Number of cores and threads"
            echo -e "  - CPU speed and cache information"
            echo -e "  - CPU temperature and usage"
            echo -e "  - CPU architecture details"
            ;;
        "gpu")
            echo -e "${BOLD}GPU Information Section${RESET}"
            echo -e "Shows detailed information about your graphics cards including:"
            echo -e "  - GPU model and manufacturer"
            echo -e "  - Driver information"
            echo -e "  - Memory usage and temperature"
            echo -e "  - GPU utilization"
            echo -e "  - Connected displays"
            ;;
        "memory")
            echo -e "${BOLD}Memory Information Section${RESET}"
            echo -e "Shows detailed information about your system memory including:"
            echo -e "  - Total RAM and usage"
            echo -e "  - Memory modules information"
            echo -e "  - Swap space usage"
            echo -e "  - Top memory-consuming processes"
            ;;
        "storage")
            echo -e "${BOLD}Storage Information Section${RESET}"
            echo -e "Shows detailed information about your storage devices including:"
            echo -e "  - Disk usage and partitions"
            echo -e "  - Filesystem information"
            echo -e "  - Mount points"
            echo -e "  - Storage device health"
            ;;
        "network")
            echo -e "${BOLD}Network Information Section${RESET}"
            echo -e "Shows detailed information about your network configuration including:"
            echo -e "  - Network interfaces"
            echo -e "  - IP addresses and MAC addresses"
            echo -e "  - Network speed and status"
            echo -e "  - Active connections"
            ;;
        "system")
            echo -e "${BOLD}System Information Section${RESET}"
            echo -e "Shows detailed information about your system including:"
            echo -e "  - Operating system details"
            echo -e "  - Kernel version"
            echo -e "  - Hostname and domain"
            echo -e "  - System uptime"
            ;;
        *)
            echo -e "${RED}Error: Unknown section: $section${RESET}"
            echo -e "Available sections: cpu, gpu, memory, storage, network, system"
            ;;
    esac
} 