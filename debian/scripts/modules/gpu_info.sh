#!/bin/bash

# Source required files
source "$(dirname "${BASH_SOURCE[0]}")/../config/colors.sh"

# Get basic GPU information
get_basic_gpu_info() {
    echo -e "\n${BOLD}${BLUE}$GPU_INFO${RESET}"
    echo -e "${CYAN}----------------------------------------${RESET}"

    GPU_COUNT=0
    FOUND_GPU=false

    # Check for NVIDIA GPU
    if command -v nvidia-smi &> /dev/null; then
        NVIDIA_INFO=$(nvidia-smi --query-gpu=name,memory.total --format=csv,noheader 2>/dev/null)
        if [ ! -z "$NVIDIA_INFO" ] && [[ ! "$NVIDIA_INFO" =~ "failed" ]] && [[ ! "$NVIDIA_INFO" =~ "error" ]] && [[ ! "$NVIDIA_INFO" =~ "NVIDIA-SMI" ]]; then
            while IFS=, read -r name memory; do
                if [[ ! "$name" =~ "NVIDIA-SMI" ]] && [[ ! "$name" =~ "failed" ]]; then
                    GPU_COUNT=$((GPU_COUNT + 1))
                    echo -e "  GPU $GPU_COUNT: $name, $memory"
                    FOUND_GPU=true
                fi
            done <<< "$NVIDIA_INFO"
        fi
    fi

    # Check for AMD GPU
    if command -v rocm-smi &> /dev/null; then
        AMD_INFO=$(rocm-smi --showproductname --showmeminfo vram 2>/dev/null)
        if [ ! -z "$AMD_INFO" ] && [[ ! "$AMD_INFO" =~ "failed" ]] && [[ ! "$AMD_INFO" =~ "error" ]]; then
            GPU_COUNT=$((GPU_COUNT + 1))
            echo -e "  GPU $GPU_COUNT: $AMD_INFO"
            FOUND_GPU=true
        fi
    fi

    # Check for integrated GPU or any GPU using lspci
    if [ "$FOUND_GPU" = false ]; then
        # First check if lspci is available
        if command -v lspci &> /dev/null; then
            # Check for any GPU-related devices
            INTEGRATED_GPUS=$(lspci | grep -i "vga\|3d\|display" | grep -v "NVIDIA" | sed 's/^.*: //')
            if [ ! -z "$INTEGRATED_GPUS" ]; then
                while IFS= read -r gpu; do
                    if [[ ! "$gpu" =~ "NVIDIA" ]] || [[ "$gpu" =~ "NVIDIA" && "$FOUND_GPU" = false ]]; then
                        GPU_COUNT=$((GPU_COUNT + 1))
                        echo -e "  GPU $GPU_COUNT: $gpu"
                    fi
                done <<< "$INTEGRATED_GPUS"
            fi
        fi
    fi

    # Additional check for GPU using glxinfo if available
    if [ "$FOUND_GPU" = false ] && [ "$GPU_COUNT" -eq 0 ]; then
        if command -v glxinfo &> /dev/null; then
            GLX_INFO=$(glxinfo 2>/dev/null | grep "OpenGL renderer string" | sed 's/.*: //')
            if [ ! -z "$GLX_INFO" ] && [[ ! "$GLX_INFO" =~ "llvmpipe" ]] && [[ ! "$GLX_INFO" =~ "software" ]]; then
                GPU_COUNT=$((GPU_COUNT + 1))
                echo -e "  GPU $GPU_COUNT: $GLX_INFO"
            fi
        fi
    fi

    # If no GPU found
    if [ "$GPU_COUNT" -eq 0 ]; then
        echo -e "  ${YELLOW}$NO_GPU_FOUND${RESET}"
    fi
}

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
    if [ "$DETAILED" = true ]; then
        get_nvidia_gpu_info
        get_amd_gpu_info
        get_integrated_gpu_info
        get_display_info
    else
        get_basic_gpu_info
    fi
} 