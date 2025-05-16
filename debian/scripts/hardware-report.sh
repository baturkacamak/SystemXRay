#!/bin/bash

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source configuration
source "$SCRIPT_DIR/config/colors.sh"

# Source utilities
source "$SCRIPT_DIR/utils/spinner.sh"
source "$SCRIPT_DIR/utils/language.sh"

# Source modules
source "$SCRIPT_DIR/modules/package_manager.sh"
source "$SCRIPT_DIR/modules/cpu_info.sh"
source "$SCRIPT_DIR/modules/gpu_info.sh"
source "$SCRIPT_DIR/modules/memory_info.sh"
source "$SCRIPT_DIR/modules/storage_info.sh"
source "$SCRIPT_DIR/modules/network_info.sh"
source "$SCRIPT_DIR/modules/system_info.sh"

# Output file options
OUTPUT_FILE=""
HTML_OUTPUT=""
INTERACTIVE=false
SELECTED_SECTIONS=""
LANGUAGE=""

# Parse command line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -o|--output)
                OUTPUT_FILE="$2"
                shift 2
                ;;
            -h|--html)
                HTML_OUTPUT=true
                shift
                ;;
            -i|--interactive)
                INTERACTIVE=true
                shift
                ;;
            -s|--sections)
                SELECTED_SECTIONS="$2"
                shift 2
                ;;
            -l|--language)
                LANGUAGE="$2"
                shift 2
                ;;
            *)
                echo -e "${RED}Unknown parameter: $1${RESET}"
                exit 1
                ;;
        esac
    done
}

# Main function
main() {
    # Parse command line arguments
    parse_arguments "$@"

    # Initialize language
    init_language "$LANGUAGE"

    # Check requirements first
    check_requirements

    # Gather hardware information
    echo -e "${BOLD}${GREEN}$TITLE${RESET}"
    echo -e "${CYAN}========================================${RESET}"

    # System Information
    gather_system_info

    # CPU Information
    gather_cpu_info

    # GPU Information
    gather_gpu_info

    # Memory Information
    gather_memory_info

    # Storage Information
    gather_storage_info

    # Network Information
    gather_network_info
}

# Run main function
main "$@" 