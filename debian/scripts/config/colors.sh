#!/bin/bash

# Color definitions
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
GRAY='\033[0;37m'
RESET='\033[0m'
BOLD='\033[1m'

# Terminal width configuration
TERM_WIDTH=$(tput cols)
if [ -z "$TERM_WIDTH" ] || [ "$TERM_WIDTH" -lt 80 ]; then
    TERM_WIDTH=80
fi 