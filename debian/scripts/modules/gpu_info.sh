#!/bin/bash

# Source required files
source "$(dirname "${BASH_SOURCE[0]}")/../config/colors.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../utils/common.sh"

# Get basic GPU information
get_basic_gpu_info() {
    print_section_header "$GPU_INFO"

    local gpu_count=0
    local found_gpu=false
    local gpu_info=""

    # Check for NVIDIA GPU
    if check_command_available "nvidia-smi"; then
        local nvidia_info=$(nvidia-smi --query-gpu=name,memory.total --format=csv,noheader 2>/dev/null)
        if [ ! -z "$nvidia_info" ] && [[ ! "$nvidia_info" =~ "failed" ]] && [[ ! "$nvidia_info" =~ "error" ]] && [[ ! "$nvidia_info" =~ "NVIDIA-SMI" ]]; then
            while IFS=, read -r name memory; do
                if [[ ! "$name" =~ "NVIDIA-SMI" ]] && [[ ! "$name" =~ "failed" ]]; then
                    gpu_count=$((gpu_count + 1))
                    gpu_info+="GPU $gpu_count: $name, $memory\n"
                    found_gpu=true
                fi
            done <<< "$nvidia_info"
        fi
    fi

    # Check for AMD GPU
    if check_command_available "rocm-smi"; then
        local amd_info=$(rocm-smi --showproductname --showmeminfo vram 2>/dev/null)
        if [ ! -z "$amd_info" ] && [[ ! "$amd_info" =~ "failed" ]] && [[ ! "$amd_info" =~ "error" ]]; then
            gpu_count=$((gpu_count + 1))
            gpu_info+="GPU $gpu_count: $amd_info\n"
            found_gpu=true
        fi
    fi

    # Check for integrated GPU or any GPU using lspci
    if [ "$found_gpu" = false ]; then
        if check_command_available "lspci"; then
            local integrated_gpus=$(lspci | grep -i "vga\|3d\|display" | grep -v "NVIDIA" | sed 's/^.*: //')
            if [ ! -z "$integrated_gpus" ]; then
                while IFS= read -r gpu; do
                    if [[ ! "$gpu" =~ "NVIDIA" ]] || [[ "$gpu" =~ "NVIDIA" && "$found_gpu" = false ]]; then
                        gpu_count=$((gpu_count + 1))
                        gpu_info+="GPU $gpu_count: $gpu\n"
                    fi
                done <<< "$integrated_gpus"
            fi
        fi
    fi

    # Additional check for GPU using glxinfo if available
    if [ "$found_gpu" = false ] && [ "$gpu_count" -eq 0 ]; then
        if check_command_available "glxinfo"; then
            local glx_info=$(glxinfo 2>/dev/null | grep "OpenGL renderer string" | sed 's/.*: //')
            if [ ! -z "$glx_info" ] && [[ ! "$glx_info" =~ "llvmpipe" ]] && [[ ! "$glx_info" =~ "software" ]]; then
                gpu_count=$((gpu_count + 1))
                gpu_info+="GPU $gpu_count: $glx_info\n"
            fi
        fi
    fi

    # Print GPU information
    if [ "$gpu_count" -eq 0 ]; then
        print_key_value "$NO_GPU_FOUND" ""
    else
        print_list "" "$gpu_info"
    fi
}

# Get NVIDIA GPU information
get_nvidia_gpu_info() {
    if check_command_available "nvidia-smi"; then
        print_section_header "$NVIDIA_GPU_INFO"

        # Basic GPU information
        print_list "$GPU_MODEL_FEATURES" "$(nvidia-smi --query-gpu=name,memory.total,driver_version --format=csv,noheader)"

        # GPU usage and temperature
        print_list "$GPU_USAGE_TEMP" "$(nvidia-smi --query-gpu=utilization.gpu,utilization.memory,temperature.gpu --format=csv,noheader)"
    fi
}

# Get AMD GPU information
get_amd_gpu_info() {
    if check_command_available "rocm-smi"; then
        print_section_header "$AMD_GPU_INFO"

        # Basic GPU information
        print_list "$GPU_MODEL_FEATURES" "$(rocm-smi --showproductname --showmeminfo vram --showdriverversion)"

        # GPU usage and temperature
        print_list "$GPU_USAGE_TEMP" "$(rocm-smi --showuse --showtemp)"
    fi
}

# Get integrated GPU information
get_integrated_gpu_info() {
    print_section_header "$INTEGRATED_GPU_INFO"

    if check_command_available "lspci"; then
        print_list "$INTEGRATED_GPU_DETAILS" "$(lspci | grep -i "vga\|3d" | grep -i "intel\|amd")"
    fi
}

# Get display information
get_display_info() {
    if check_command_available "xrandr"; then
        print_section_header "$DISPLAY_INFO"
        print_list "$CONNECTED_DISPLAYS" "$(xrandr --query | grep " connected")"
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