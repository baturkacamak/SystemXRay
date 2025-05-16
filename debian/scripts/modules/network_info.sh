#!/bin/bash

# Source required files
source "$(dirname "${BASH_SOURCE[0]}")/../config/colors.sh"

# Get network interfaces information
get_network_interfaces() {
    echo -e "\n${BOLD}${BLUE}Ağ Arayüzleri${RESET}"
    echo -e "${CYAN}----------------------------------------${RESET}"

    if command -v ip &> /dev/null; then
        echo -e "${YELLOW}Ağ Arayüzleri ve IP Adresleri:${RESET}"
        ip addr show | grep -E "^[0-9]+:|inet " | sed 's/^/  /'
    fi
}

# Get network connection status
get_network_status() {
    echo -e "\n${BOLD}${BLUE}Ağ Bağlantı Durumu${RESET}"
    echo -e "${CYAN}----------------------------------------${RESET}"

    if command -v nmcli &> /dev/null; then
        echo -e "${YELLOW}Bağlantı Durumu:${RESET}"
        nmcli device status | sed 's/^/  /'
    fi
}

# Get network speed and statistics
get_network_stats() {
    echo -e "\n${BOLD}${BLUE}Ağ İstatistikleri${RESET}"
    echo -e "${CYAN}----------------------------------------${RESET}"

    if command -v netstat &> /dev/null; then
        echo -e "${YELLOW}Aktif Bağlantılar:${RESET}"
        netstat -tuln | grep LISTEN | sed 's/^/  /'
    fi

    if command -v ifconfig &> /dev/null; then
        echo -e "\n${YELLOW}Arayüz İstatistikleri:${RESET}"
        ifconfig | grep -E "RX|TX" | sed 's/^/  /'
    fi
}

# Get wireless information
get_wireless_info() {
    echo -e "\n${BOLD}${BLUE}Kablosuz Ağ Bilgileri${RESET}"
    echo -e "${CYAN}----------------------------------------${RESET}"

    if command -v iwconfig &> /dev/null; then
        echo -e "${YELLOW}Kablosuz Arayüz Bilgileri:${RESET}"
        iwconfig 2>/dev/null | grep -v "no wireless" | sed 's/^/  /'
    fi
}

# Get network routing information
get_routing_info() {
    echo -e "\n${BOLD}${BLUE}Ağ Yönlendirme Bilgileri${RESET}"
    echo -e "${CYAN}----------------------------------------${RESET}"

    if command -v route &> /dev/null; then
        echo -e "${YELLOW}Yönlendirme Tablosu:${RESET}"
        route -n | sed 's/^/  /'
    fi
}

# Get DNS information
get_dns_info() {
    echo -e "\n${BOLD}${BLUE}DNS Bilgileri${RESET}"
    echo -e "${CYAN}----------------------------------------${RESET}"

    if command -v cat &> /dev/null; then
        echo -e "${YELLOW}DNS Sunucuları:${RESET}"
        cat /etc/resolv.conf | grep "nameserver" | sed 's/^/  /'
    fi
}

# Main network information gathering function
gather_network_info() {
    get_network_interfaces
    get_network_status
    get_network_stats
    get_wireless_info
    get_routing_info
    get_dns_info
} 