#!/bin/bash

# ================================================================
# Fan and Temperature Monitor Script
# ================================================================
# Description: This script monitors fan speeds and temperature information
#              on Linux systems using lm_sensors and the /sys filesystem.
# Usage: ./fan_monitor.sh
# ================================================================

# Text formatting
BOLD='\033[1m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to print section headers
print_header() {
    echo -e "\n${BOLD}${BLUE}$1${NC}"
    echo "================================================================"
}

# Function to read and display fan information from /sys
read_fan_info_from_sys() {
    print_header "Fan Information from /sys filesystem"
    
    # Check for fan information in common locations
    fan_files=$(find /sys -name '*fan*_input' -o -name '*fan*rpm*' -o -name 'fan_speed*' 2>/dev/null)
    
    if [ -z "$fan_files" ]; then
        echo -e "${YELLOW}No fan information found in /sys filesystem.${NC}"
    else
        echo -e "${BOLD}Found the following fan-related files:${NC}"
        for file in $fan_files; do
            if [ -r "$file" ]; then
                value=$(cat "$file" 2>/dev/null)
                if [ $? -eq 0 ]; then
                    # Check if the value is the sentinel value (2^32 - 1)
                    if [ "$value" = "4294967295" ]; then
                        echo -e "$(dirname "$file")/$(basename "$file"): ${YELLOW}N/A${NC}"
                    else
                        # Try to determine if the value is in RPM
                        if [[ "$file" == *"rpm"* || "$file" == *"speed"* ]]; then
                            echo -e "$(dirname "$file")/$(basename "$file"): ${GREEN}${value} RPM${NC}"
                        else
                            echo -e "$(dirname "$file")/$(basename "$file"): ${GREEN}${value}${NC}"
                        fi
                    fi
                else
                    echo -e "$(dirname "$file")/$(basename "$file"): ${RED}Unable to read${NC}"
                fi
            else
                echo -e "$(dirname "$file")/$(basename "$file"): ${RED}Permission denied${NC}"
            fi
        done
    fi
    
    # Check for fan mode information
    fan_mode_files=$(find /sys -name '*fan*mode*' 2>/dev/null)
    if [ -n "$fan_mode_files" ]; then
        echo -e "\n${BOLD}Fan Mode Information:${NC}"
        for file in $fan_mode_files; do
            if [ -r "$file" ]; then
                value=$(cat "$file" 2>/dev/null)
                if [ $? -eq 0 ]; then
                    echo -e "$(dirname "$file")/$(basename "$file"): ${GREEN}${value}${NC}"
                else
                    echo -e "$(dirname "$file")/$(basename "$file"): ${RED}Unable to read${NC}"
                fi
            else
                echo -e "$(dirname "$file")/$(basename "$file"): ${RED}Permission denied${NC}"
            fi
        done
    fi
}

# Function to display temperature information from /sys
read_temp_info_from_sys() {
    print_header "Temperature Information from /sys filesystem"
    
    # Look for thermal zones
    if [ -d "/sys/class/thermal" ]; then
        thermal_zones=$(find /sys/class/thermal -name "thermal_zone*" -type d 2>/dev/null)
        
        if [ -n "$thermal_zones" ]; then
            echo -e "${BOLD}Thermal Zones:${NC}"
            for zone in $thermal_zones; do
                if [ -r "${zone}/temp" ] && [ -r "${zone}/type" ]; then
                    zone_type=$(cat "${zone}/type" 2>/dev/null)
                    temp_raw=$(cat "${zone}/temp" 2>/dev/null)
                    # Usually, temperature is reported in millidegrees Celsius
                    if [ -n "$temp_raw" ] && [ "$temp_raw" -lt 1000000 ]; then
                        temp_c=$(echo "scale=1; $temp_raw / 1000" | bc)
                        echo -e "Zone $(basename "$zone") ($zone_type): ${GREEN}${temp_c}°C${NC}"
                    fi
                fi
            done
        else
            echo -e "${YELLOW}No thermal zone information found.${NC}"
        fi
    else
        echo -e "${YELLOW}Thermal class directory not found.${NC}"
    fi
    
    # Look for CPU temperature specifically
    cpu_temp_files=$(find /sys -name "temp*_input" -o -name "*cpu*temp*" 2>/dev/null)
    if [ -n "$cpu_temp_files" ]; then
        echo -e "\n${BOLD}CPU Temperature Sensors:${NC}"
        for file in $cpu_temp_files; do
            if [ -r "$file" ]; then
                temp_raw=$(cat "$file" 2>/dev/null)
                if [ $? -eq 0 ] && [ -n "$temp_raw" ]; then
                    # Check if temperature is in millidegrees
                    if [ "$temp_raw" -gt 1000 ]; then
                        temp_c=$(echo "scale=1; $temp_raw / 1000" | bc)
                        echo -e "$(dirname "$file")/$(basename "$file"): ${GREEN}${temp_c}°C${NC}"
                    else
                        echo -e "$(dirname "$file")/$(basename "$file"): ${GREEN}${temp_raw}°C${NC}"
                    fi
                else
                    echo -e "$(dirname "$file")/$(basename "$file"): ${RED}Unable to read${NC}"
                fi
            fi
        done
    fi
}

# Function to display lm_sensors information
read_sensors_info() {
    print_header "Information from lm_sensors"
    
    if command_exists sensors; then
        sensors_output=$(sensors)
        if [ -n "$sensors_output" ]; then
            # Highlight fan information
            echo "$sensors_output" | while IFS= read -r line; do
                if [[ "$line" == *"fan"* ]]; then
                    echo -e "${GREEN}${line}${NC}"
                elif [[ "$line" == *"temp"* || "$line" == *"Core"* ]]; then
                    echo -e "${YELLOW}${line}${NC}"
                else
                    echo "$line"
                fi
            done
        else
            echo -e "${YELLOW}No sensor information available.${NC}"
        fi
    else
        echo -e "${RED}The 'sensors' command is not available. Please install lm_sensors package.${NC}"
    fi
}

# Function to show power and load information, which may affect fan behavior
show_system_load() {
    print_header "System Load Information"
    
    echo -e "${BOLD}CPU Load:${NC}"
    uptime | awk '{print "  " $0}'
    
    if command_exists mpstat; then
        echo -e "\n${BOLD}CPU Usage:${NC}"
        mpstat | grep -v Linux | awk '{print "  " $0}'
    else
        echo -e "\n${YELLOW}mpstat not available. Install sysstat package for CPU usage stats.${NC}"
    fi
    
    echo -e "\n${BOLD}Top CPU-Consuming Processes:${NC}"
    ps aux --sort=-%cpu | head -6 | awk '{print "  " $0}'
}

# Main execution
echo -e "${BOLD}${GREEN}===== Fan and Temperature Monitor =====${NC}"
echo "Running on: $(hostname) - $(date)"
echo "Kernel: $(uname -r)"

# Run each information gathering function
read_sensors_info
read_fan_info_from_sys
read_temp_info_from_sys
show_system_load

echo -e "\n${BOLD}${GREEN}===== Monitoring Complete =====${NC}"
echo "For continuous monitoring, consider running this script with watch:"
echo "  watch -n 2 ./fan_monitor.sh"

exit 0

