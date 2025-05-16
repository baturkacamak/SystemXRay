#!/bin/bash

# Source required files
source "$(dirname "${BASH_SOURCE[0]}")/../config/colors.sh"

# Print a section header with consistent formatting
print_section_header() {
    local title="$1"
    echo -e "\n${BOLD}${BLUE}$title${RESET}"
    echo -e "${CYAN}----------------------------------------${RESET}"
}

# Check if a command is available
check_command_available() {
    local command="$1"
    command -v "$command" &> /dev/null
    return $?
}

# Format output with consistent indentation
format_output() {
    local text="$1"
    local indent_level="${2:-1}"
    local indent=""
    
    # Create indentation string
    for ((i=0; i<indent_level; i++)); do
        indent+="  "
    done
    
    echo "$text" | sed "s/^/$indent/"
}

# Safely execute a command and handle errors
safe_command_execution() {
    local command="$1"
    local error_message="${2:-Command execution failed}"
    
    if ! check_command_available "$command"; then
        echo -e "${RED}Error: $error_message${RESET}"
        return 1
    fi
    
    return 0
}

# Get command output with error handling
get_command_output() {
    local command="$1"
    local error_message="${2:-Failed to get command output}"
    
    if ! check_command_available "$command"; then
        echo -e "${RED}Error: $error_message${RESET}"
        return 1
    fi
    
    eval "$command"
    return $?
}

# Print a key-value pair with consistent formatting
print_key_value() {
    local key="$1"
    local value="$2"
    local indent_level="${3:-1}"
    
    echo -e "$(format_output "${YELLOW}$key:${RESET} $value" "$indent_level")"
}

# Print a list of items with consistent formatting
print_list() {
    local title="$1"
    local items="$2"
    local indent_level="${3:-1}"
    
    if [ -n "$title" ]; then
        print_key_value "$title" "" "$indent_level"
    fi
    
    while IFS= read -r item; do
        if [ -n "$item" ]; then
            format_output "$item" "$((indent_level + 1))"
        fi
    done <<< "$items"
}

# Check if running with sudo privileges
check_sudo_privileges() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}Error: This operation requires sudo privileges${RESET}"
        return 1
    fi
    return 0
}

# Get a value from a command output using grep and sed
extract_value() {
    local command="$1"
    local pattern="$2"
    local sed_pattern="$3"
    
    if ! check_command_available "$command"; then
        return 1
    fi
    
    eval "$command" | grep "$pattern" | sed "$sed_pattern"
    return $?
} 