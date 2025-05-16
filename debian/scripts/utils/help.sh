#!/bin/bash

# Help utility functions for hardware-report script

# Display help message
show_help() {
    echo -e "${BOLD}${GREEN}$HELP_TITLE${RESET}"
    echo -e "${CYAN}===============================================${RESET}\n"
    echo -e "${BOLD}$HELP_USAGE:${RESET}"
    echo -e "  ./hardware-report.sh [OPTIONS]\n"
    echo -e "${BOLD}$HELP_OPTIONS:${RESET}"
    echo -e "  -h, --help                 $HELP_OPTION_HELP"
    echo -e "  -o, --output FILE          $HELP_OPTION_OUTPUT"
    echo -e "  -H, --html                 $HELP_OPTION_HTML"
    echo -e "  -i, --interactive          $HELP_OPTION_INTERACTIVE"
    echo -e "  -s, --sections SECTIONS    $HELP_OPTION_SECTIONS"
    echo -e "                             Available sections: cpu, gpu, memory, storage, network, system"
    echo -e "  -l, --language LANG        $HELP_OPTION_LANGUAGE\n"
    echo -e "${BOLD}$HELP_EXAMPLES:${RESET}"
    echo -e "  ./hardware-report.sh                    # $HELP_EXAMPLE_FULL"
    echo -e "  ./hardware-report.sh -l es              # $HELP_EXAMPLE_LANGUAGE"
    echo -e "  ./hardware-report.sh -o report.txt      # $HELP_EXAMPLE_OUTPUT"
    echo -e "  ./hardware-report.sh -H                 # $HELP_EXAMPLE_HTML"
    echo -e "  ./hardware-report.sh -s cpu,memory      # $HELP_EXAMPLE_SECTIONS"
    echo -e "  ./hardware-report.sh -i                 # $HELP_EXAMPLE_INTERACTIVE\n"
    echo -e "${BOLD}$HELP_SUPPORTED_LANGUAGES:${RESET}"
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
    echo -e "${BOLD}$HELP_NOTE:${RESET}"
    echo -e "  $HELP_NOTE_LANGUAGE"
    echo -e "  $HELP_NOTE_FALLBACK"
    echo -e "\n${CYAN}===============================================${RESET}"
}

# Show section-specific help
show_section_help() {
    local section="$1"
    case "$section" in
        "cpu")
            echo -e "${BOLD}$HELP_SECTION_CPU${RESET}"
            echo -e "$HELP_CPU_DETAILS"
            echo -e "  - $HELP_CPU_MODEL"
            echo -e "  - $HELP_CPU_CORES"
            echo -e "  - $HELP_CPU_SPEED"
            echo -e "  - $HELP_CPU_TEMP"
            echo -e "  - $HELP_CPU_ARCH"
            ;;
        "gpu")
            echo -e "${BOLD}$HELP_SECTION_GPU${RESET}"
            echo -e "$HELP_GPU_DETAILS"
            echo -e "  - $HELP_GPU_MODEL"
            echo -e "  - $HELP_GPU_DRIVER"
            echo -e "  - $HELP_GPU_MEMORY"
            echo -e "  - $HELP_GPU_UTIL"
            echo -e "  - $HELP_GPU_DISPLAYS"
            ;;
        "memory")
            echo -e "${BOLD}$HELP_SECTION_MEMORY${RESET}"
            echo -e "$HELP_MEMORY_DETAILS"
            echo -e "  - $HELP_MEMORY_TOTAL"
            echo -e "  - $HELP_MEMORY_MODULES"
            echo -e "  - $HELP_MEMORY_SWAP"
            echo -e "  - $HELP_MEMORY_PROCESSES"
            ;;
        "storage")
            echo -e "${BOLD}$HELP_SECTION_STORAGE${RESET}"
            echo -e "$HELP_STORAGE_DETAILS"
            echo -e "  - $HELP_STORAGE_DISK"
            echo -e "  - $HELP_STORAGE_FS"
            echo -e "  - $HELP_STORAGE_MOUNT"
            echo -e "  - $HELP_STORAGE_HEALTH"
            ;;
        "network")
            echo -e "${BOLD}$HELP_SECTION_NETWORK${RESET}"
            echo -e "$HELP_NETWORK_DETAILS"
            echo -e "  - $HELP_NETWORK_INTERFACES"
            echo -e "  - $HELP_NETWORK_ADDRESSES"
            echo -e "  - $HELP_NETWORK_SPEED"
            echo -e "  - $HELP_NETWORK_CONNECTIONS"
            ;;
        "system")
            echo -e "${BOLD}$HELP_SECTION_SYSTEM${RESET}"
            echo -e "$HELP_SYSTEM_DETAILS"
            echo -e "  - $HELP_SYSTEM_OS"
            echo -e "  - $HELP_SYSTEM_KERNEL"
            echo -e "  - $HELP_SYSTEM_HOSTNAME"
            echo -e "  - $HELP_SYSTEM_UPTIME"
            ;;
        *)
            echo -e "${RED}$HELP_SECTION_UNKNOWN: $section${RESET}"
            echo -e "$HELP_SECTION_AVAILABLE: cpu, gpu, memory, storage, network, system"
            ;;
    esac
} 