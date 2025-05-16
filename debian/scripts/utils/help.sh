#!/bin/bash

# Help utility functions for hardware-report script

# Display help message
show_help() {
    echo -e "${BOLD}${GREEN}$HELP_TITLE${RESET}"
    echo -e "${CYAN}===============================================${RESET}\n"
    echo -e "${BOLD}$HELP_USAGE${RESET}"
    echo -e "$HELP_USAGE_DESC\n"
    echo -e "${BOLD}$HELP_OPTIONS${RESET}"
    echo -e "$HELP_OPTION_HELP"
    echo -e "$HELP_OPTION_OUTPUT"
    echo -e "$HELP_OPTION_HTML"
    echo -e "$HELP_OPTION_INTERACTIVE"
    echo -e "$HELP_OPTION_SECTIONS"
    echo -e "$HELP_OPTION_SECTIONS_DESC"
    echo -e "$HELP_OPTION_LANGUAGE\n"
    echo -e "${BOLD}$HELP_EXAMPLES${RESET}"
    echo -e "$HELP_EXAMPLE_DEFAULT"
    echo -e "$HELP_EXAMPLE_LANGUAGE"
    echo -e "$HELP_EXAMPLE_OUTPUT"
    echo -e "$HELP_EXAMPLE_HTML"
    echo -e "$HELP_EXAMPLE_SECTIONS"
    echo -e "$HELP_EXAMPLE_INTERACTIVE\n"
    echo -e "${BOLD}$HELP_SUPPORTED_LANGUAGES${RESET}"
    echo -e "$HELP_LANGUAGE_EN"
    echo -e "$HELP_LANGUAGE_ES"
    echo -e "$HELP_LANGUAGE_FR"
    echo -e "$HELP_LANGUAGE_DE"
    echo -e "$HELP_LANGUAGE_IT"
    echo -e "$HELP_LANGUAGE_PT"
    echo -e "$HELP_LANGUAGE_RU"
    echo -e "$HELP_LANGUAGE_ZH"
    echo -e "$HELP_LANGUAGE_JA"
    echo -e "$HELP_LANGUAGE_KO"
    echo -e "$HELP_LANGUAGE_AR"
    echo -e "$HELP_LANGUAGE_HI"
    echo -e "$HELP_LANGUAGE_TR"
    echo -e "$HELP_LANGUAGE_MORE\n"
    echo -e "${BOLD}$HELP_NOTE${RESET}"
    echo -e "$HELP_NOTE_DEFAULT"
    echo -e "$HELP_NOTE_FALLBACK"
    echo -e "\n${CYAN}===============================================${RESET}"
}

# Show section-specific help
show_section_help() {
    local section="$1"
    case "$section" in
        "cpu")
            echo -e "${BOLD}$HELP_SECTION_CPU_TITLE${RESET}"
            echo -e "$HELP_SECTION_CPU_DESC"
            echo -e "$HELP_SECTION_CPU_MODEL"
            echo -e "$HELP_SECTION_CPU_CORES"
            echo -e "$HELP_SECTION_CPU_SPEED"
            echo -e "$HELP_SECTION_CPU_TEMP"
            echo -e "$HELP_SECTION_CPU_ARCH"
            ;;
        "gpu")
            echo -e "${BOLD}$HELP_SECTION_GPU_TITLE${RESET}"
            echo -e "$HELP_SECTION_GPU_DESC"
            echo -e "$HELP_SECTION_GPU_MODEL"
            echo -e "$HELP_SECTION_GPU_DRIVER"
            echo -e "$HELP_SECTION_GPU_MEMORY"
            echo -e "$HELP_SECTION_GPU_USAGE"
            echo -e "$HELP_SECTION_GPU_DISPLAY"
            ;;
        "memory")
            echo -e "${BOLD}$HELP_SECTION_MEMORY_TITLE${RESET}"
            echo -e "$HELP_SECTION_MEMORY_DESC"
            echo -e "$HELP_SECTION_MEMORY_TOTAL"
            echo -e "$HELP_SECTION_MEMORY_MODULES"
            echo -e "$HELP_SECTION_MEMORY_SWAP"
            echo -e "$HELP_SECTION_MEMORY_PROCESSES"
            ;;
        "storage")
            echo -e "${BOLD}$HELP_SECTION_STORAGE_TITLE${RESET}"
            echo -e "$HELP_SECTION_STORAGE_DESC"
            echo -e "$HELP_SECTION_STORAGE_DISK"
            echo -e "$HELP_SECTION_STORAGE_FS"
            echo -e "$HELP_SECTION_STORAGE_MOUNT"
            echo -e "$HELP_SECTION_STORAGE_HEALTH"
            ;;
        "network")
            echo -e "${BOLD}$HELP_SECTION_NETWORK_TITLE${RESET}"
            echo -e "$HELP_SECTION_NETWORK_DESC"
            echo -e "$HELP_SECTION_NETWORK_INTERFACES"
            echo -e "$HELP_SECTION_NETWORK_IP"
            echo -e "$HELP_SECTION_NETWORK_SPEED"
            echo -e "$HELP_SECTION_NETWORK_CONNECTIONS"
            ;;
        "system")
            echo -e "${BOLD}$HELP_SECTION_SYSTEM_TITLE${RESET}"
            echo -e "$HELP_SECTION_SYSTEM_DESC"
            echo -e "$HELP_SECTION_SYSTEM_OS"
            echo -e "$HELP_SECTION_SYSTEM_KERNEL"
            echo -e "$HELP_SECTION_SYSTEM_HOSTNAME"
            echo -e "$HELP_SECTION_SYSTEM_UPTIME"
            ;;
        *)
            echo -e "${RED}Error: Unknown section: $section${RESET}"
            echo -e "Available sections: cpu, gpu, memory, storage, network, system"
            ;;
    esac
} 