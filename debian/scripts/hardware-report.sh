#!/bin/bash

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source configuration
source "$SCRIPT_DIR/config/colors.sh"

# Source utilities
source "$SCRIPT_DIR/utils/spinner.sh"
source "$SCRIPT_DIR/utils/language.sh"
source "$SCRIPT_DIR/utils/help.sh"

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
SHOW_HELP=false
DETAILED=false

# Parse command line arguments
parse_arguments() {
    # First pass: collect all arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -l|--language)
                LANGUAGE="$2"
                shift 2
                ;;
            -h|--help)
                SHOW_HELP=true
                shift
                ;;
            -o|--output)
                OUTPUT_FILE="$2"
                shift 2
                ;;
            -H|--html)
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
            -d|--detailed)
                DETAILED=true
                shift
                ;;
            *)
                echo -e "${RED}Error: Unknown parameter: $1${RESET}"
                echo -e "Use --help to see available options"
                exit 1
                ;;
        esac
    done

    # Initialize language first
    init_language "$LANGUAGE"

    # Then show help if requested
    if [ "$SHOW_HELP" = true ]; then
        show_help
        exit 0
    fi
}

# Function to gather basic hardware information
gather_basic_info() {
    echo -e "${BOLD}${GREEN}$TITLE${RESET}"
    echo -e "${CYAN}========================================${RESET}"

    # Basic System Information
    echo -e "${BOLD}System Information:${RESET}"
    hostnamectl | grep -E "Operating System|Kernel|Architecture" | sed 's/^[ \t]*//'
    echo

    # Basic CPU Information
    echo -e "${BOLD}CPU Information:${RESET}"
    lscpu | grep -E "Model name|CPU\(s\)|Thread|Core|Socket" | sed 's/^[ \t]*//'
    echo

    # Basic Memory Information
    echo -e "${BOLD}Memory Information:${RESET}"
    free -h | grep -v "Swap" | sed 's/^[ \t]*//'
    echo

    # Basic Storage Information
    echo -e "${BOLD}Storage Information:${RESET}"
    df -h / | sed 's/^[ \t]*//'
    echo

    # Basic GPU Information (if available)
    if command -v lspci &> /dev/null; then
        echo -e "${BOLD}GPU Information:${RESET}"
        lspci | grep -i "vga\|3d" | sed 's/^[ \t]*//'
        echo
    fi
}

# Main function
main() {
    # Parse command line arguments
    parse_arguments "$@"

    # Check requirements first
    check_requirements

    if [ "$DETAILED" = true ]; then
        # Gather detailed hardware information
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
    else
        # Gather basic hardware information
        gather_basic_info
    fi
}

# Run main function
main "$@" 