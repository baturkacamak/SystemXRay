#!/bin/bash

# Source required files
source "$(dirname "${BASH_SOURCE[0]}")/../config/colors.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../utils/spinner.sh"

# Auto install missing tools
auto_install_tools() {
    local missing="$1"
    local optional="$2"
    local distro_type=""
    local install_success=true

    # Detect distribution type
    if [ -f /etc/debian_version ]; then
        distro_type="debian"
    elif [ -f /etc/redhat-release ]; then
        distro_type="redhat"
    elif [ -f /etc/arch-release ]; then
        distro_type="arch"
    else
        distro_type="unknown"
    fi

    # Fix package names
    local packages_to_install=""
    local all_tools="$missing $optional"

    for tool in $all_tools; do
        case $tool in
            "nvidia-smi")
                if [ "$distro_type" = "debian" ]; then
                    if ! dpkg -l | grep -q nvidia-driver; then
                        echo -e "${YELLOW}$ERROR_NO_NVIDIA_DRIVER${RESET}"
                        packages_to_install="$packages_to_install nvidia-driver-525"
                    fi
                fi
                ;;
            "rocm-smi")
                echo -e "${YELLOW}$ERROR_NO_ROCM${RESET}"
                ;;
            "sensors")
                packages_to_install="$packages_to_install lm-sensors"
                ;;
            "hddtemp")
                if [ "$distro_type" = "debian" ]; then
                    sudo add-apt-repository universe -y &>/dev/null
                    packages_to_install="$packages_to_install hddtemp"
                fi
                ;;
            *)
                packages_to_install="$packages_to_install $tool"
                ;;
        esac
    done

    # Clean up spaces
    packages_to_install=$(echo "$packages_to_install" | tr -s ' ' | sed 's/^ *//' | sed 's/ *$//')

    if [ -z "$packages_to_install" ]; then
        echo -e "${GREEN}$NO_PACKAGES_TO_INSTALL${RESET}"
        return 0
    fi

    echo -e "${CYAN}$UPDATING_PACKAGE_LIST${RESET}"

    case $distro_type in
        debian)
            # Update package list (in background)
            sudo apt-get update -qq &>/dev/null &
            update_pid=$!
            show_spinner $update_pid
            wait $update_pid

            # Install each package separately and show progress
            local total_pkgs=$(echo "$packages_to_install" | wc -w)
            local current_pkg=1

            for pkg in $packages_to_install; do
                echo -e "${CYAN}[$current_pkg/$total_pkgs] $INSTALLING: $pkg${RESET}"

                # Install package in background
                sudo apt-get install -y -qq $pkg &>/dev/null &
                install_pid=$!
                show_spinner $install_pid

                # Check if installation completed successfully
                if wait $install_pid; then
                    echo -e "${GREEN}✓ $INSTALLATION_SUCCESSFUL: $pkg${RESET}"
                else
                    echo -e "${RED}✗ $INSTALLATION_FAILED: $pkg${RESET}"
                    install_success=false
                fi

                ((current_pkg++))
            done
            ;;
        redhat)
            for pkg in $packages_to_install; do
                echo -e "${CYAN}$INSTALLING: $pkg${RESET}"
                sudo yum install -y -q $pkg &>/dev/null &
                install_pid=$!
                show_spinner $install_pid

                if wait $install_pid; then
                    echo -e "${GREEN}✓ $INSTALLATION_SUCCESSFUL: $pkg${RESET}"
                else
                    echo -e "${RED}✗ $INSTALLATION_FAILED: $pkg${RESET}"
                    install_success=false
                fi
            done
            ;;
        arch)
            for pkg in $packages_to_install; do
                echo -e "${CYAN}$INSTALLING: $pkg${RESET}"
                sudo pacman -S --noconfirm --quiet $pkg &>/dev/null &
                install_pid=$!
                show_spinner $install_pid

                if wait $install_pid; then
                    echo -e "${GREEN}✓ $INSTALLATION_SUCCESSFUL: $pkg${RESET}"
                else
                    echo -e "${RED}✗ $INSTALLATION_FAILED: $pkg${RESET}"
                    install_success=false
                fi
            done
            ;;
        *)
            echo -e "${RED}$AUTO_INSTALL_NOT_SUPPORTED${RESET}"
            return 1
            ;;
    esac

    if [ "$install_success" = true ]; then
        echo -e "${GREEN}$ALL_PACKAGES_INSTALLED${RESET}"
        return 0
    else
        echo -e "${YELLOW}$SOME_PACKAGES_FAILED${RESET}"
        return 1
    fi
}

# Check required tools
check_requirements() {
    echo -e "${YELLOW}$CHECKING_REQUIRED_TOOLS${RESET}"

    MISSING_TOOLS=""

    # Basic tools
    for cmd in lscpu free lsblk dmidecode lspci; do
        if ! command -v $cmd &> /dev/null; then
            MISSING_TOOLS="$MISSING_TOOLS $cmd"
        fi
    done

    # Optional tools
    OPTIONAL_TOOLS=""
    for cmd in smartctl xrandr nvidia-smi rocm-smi inxi sensors lm-sensors hddtemp nmap qrencode bc; do
        if ! command -v $cmd &> /dev/null; then
            OPTIONAL_TOOLS="$OPTIONAL_TOOLS $cmd"
        fi
    done

    if [ ! -z "$MISSING_TOOLS" ]; then
        echo -e "${RED}$MISSING_REQUIRED_TOOLS:${RESET} ${MISSING_TOOLS}"
        echo -e "${YELLOW}$SCRIPT_MAY_NOT_WORK${RESET}"
    fi

    if [ ! -z "$OPTIONAL_TOOLS" ]; then
        echo -e "${YELLOW}$MISSING_OPTIONAL_TOOLS:${RESET} ${OPTIONAL_TOOLS}"
        echo -e "${GRAY}$INSTALL_FOR_MORE_INFO${RESET}"
    fi

    if [ ! -z "$MISSING_TOOLS" ] || [ ! -z "$OPTIONAL_TOOLS" ]; then
        echo -e "${YELLOW}$AUTO_INSTALL_PROMPT${RESET}"
        read -n 1 -r
        echo
        if [[ $REPLY =~ ^[Ee]$ ]]; then
            auto_install_tools "$MISSING_TOOLS" "$OPTIONAL_TOOLS"
            # Clear variables if installation successful
            if [ $? -eq 0 ]; then
                MISSING_TOOLS=""
                OPTIONAL_TOOLS=""
            fi
        fi
    fi

    # If required tools are still missing, ask whether to continue
    if [ ! -z "$MISSING_TOOLS" ]; then
        echo -e "${YELLOW}$STILL_MISSING_TOOLS${RESET}"
        read -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Ee]$ ]]; then
            exit 1
        fi
    fi
} 