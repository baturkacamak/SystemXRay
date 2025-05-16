#!/bin/bash

# Source required files
source "$(dirname "${BASH_SOURCE[0]}")/../config/colors.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../utils/common.sh"

# Get network interfaces information
get_network_interfaces() {
    print_section_header "$NETWORK_INTERFACES_HEADER"

    if check_command_available "ip"; then
        print_list "$NETWORK_INTERFACES_LABEL" "$(ip addr show | grep -E "^[0-9]+:|inet ")"
    fi
}

# Get network connection status
get_network_status() {
    print_section_header "$NETWORK_STATUS_HEADER"

    if check_command_available "nmcli"; then
        print_list "$NETWORK_STATUS_LABEL" "$(nmcli device status)"
    fi
}

# Get network speed and statistics
get_network_stats() {
    print_section_header "$NETWORK_STATS_HEADER"

    if check_command_available "netstat"; then
        print_list "$ACTIVE_CONNECTIONS_LABEL" "$(netstat -tuln | grep LISTEN)"
    fi

    if check_command_available "ifconfig"; then
        print_list "$INTERFACE_STATS_LABEL" "$(ifconfig | grep -E "RX|TX")"
    fi
}

# Get wireless information
get_wireless_info() {
    print_section_header "$WIRELESS_INFO_HEADER"

    if check_command_available "iwconfig"; then
        print_list "$WIRELESS_INTERFACE_LABEL" "$(iwconfig 2>/dev/null | grep -v "no wireless")"
    fi
}

# Get network routing information
get_routing_info() {
    print_section_header "$ROUTING_INFO_HEADER"

    if check_command_available "route"; then
        print_list "$ROUTING_TABLE_LABEL" "$(route -n)"
    fi
}

# Get DNS information
get_dns_info() {
    print_section_header "$DNS_INFO_HEADER"

    if check_command_available "cat"; then
        print_list "$DNS_SERVERS_LABEL" "$(cat /etc/resolv.conf | grep "nameserver")"
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