#!/bin/bash

# Source color definitions
source "$(dirname "${BASH_SOURCE[0]}")/../config/colors.sh"

# Spinning progress indicator animation
show_spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    local start_time=$(date +%s)

    echo -ne "${YELLOW}${LOADING_MSG} "

    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local current_time=$(date +%s)
        local elapsed=$((current_time - start_time))

        local temp=${spinstr#?}
        printf "${YELLOW}[%c] (%ds)${RESET}" "${spinstr}" "$elapsed"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\r"
        echo -ne "${YELLOW}${LOADING_MSG} "
    done

    printf "\r${GREEN}${DONE_MSG}    ${RESET}\n"
} 