#!/bin/bash

# Source required files
source "$(dirname "${BASH_SOURCE[0]}")/../config/colors.sh"

# Get NVIDIA GPU information
get_nvidia_gpu_info() {
    if command -v nvidia-smi &> /dev/null; then
        echo -e "\n${BOLD}${BLUE}${NVIDIA_GPU_INFO}${RESET}"
        echo -e "${CYAN}----------------------------------------${RESET}"

        # Basic GPU information
        echo -e "${YELLOW}${GPU_MODEL_FEATURES}:${RESET}"
        nvidia-smi --query-gpu=name,memory.total,driver_version --format=csv,noheader

        # GPU usage and temperature
        echo -e "\n${YELLOW}${GPU_USAGE_TEMP}:${RESET}"
        nvidia-smi --query-gpu=utilization.gpu,utilization.memory,temperature.gpu --format=csv,noheader
    fi
}

# Get AMD GPU information
get_amd_gpu_info() {
    if command -v rocm-smi &> /dev/null; then
        echo -e "\n${BOLD}${BLUE}${AMD_GPU_INFO}${RESET}"
        echo -e "${CYAN}----------------------------------------${RESET}"

        # Basic GPU information
        echo -e "${YELLOW}${GPU_MODEL_FEATURES}:${RESET}"
        rocm-smi --showproductname --showmeminfo vram --showdriverversion

        # GPU usage and temperature
        echo -e "\n${YELLOW}${GPU_USAGE_TEMP}:${RESET}"
        rocm-smi --showuse --showtemp
    fi
}

# Get integrated GPU information
get_integrated_gpu_info() {
    echo -e "\n${BOLD}${BLUE}${INTEGRATED_GPU_INFO}${RESET}"
    echo -e "${CYAN}----------------------------------------${RESET}"

    if command -v lspci &> /dev/null; then
        echo -e "${YELLOW}${INTEGRATED_GPU_DETAILS}:${RESET}"
        lspci | grep -i "vga\|3d" | grep -i "intel\|amd" | sed 's/^/  /'
    fi
}

# Get display information
get_display_info() {
    if command -v xrandr &> /dev/null; then
        echo -e "\n${BOLD}${BLUE}${DISPLAY_INFO}${RESET}"
        echo -e "${CYAN}----------------------------------------${RESET}"

        echo -e "${YELLOW}${CONNECTED_DISPLAYS}:${RESET}"
        xrandr --query | grep " connected" | sed 's/^/  /'
    fi
}

# Main GPU information gathering function
gather_gpu_info() {
    get_nvidia_gpu_info
    get_amd_gpu_info
    get_integrated_gpu_info
    get_display_info
} 