#!/bin/bash

# Get the directory where the script is located
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

print_banner() {
    cat << "EOF"
  ______  ___      ____   _____ 
 /_  __/ /   |    / __ \ / ___/
  / /   / /| |   / /_/ / \__ \ 
 / /   / ___ |  / _, _/ ___/ / 
/_/   /_/  |_| /_/ |_| /____/  

TARS System Manager
------------------
EOF
}

print_help() {
    print_banner
    cat << "EOF"

DESCRIPTION:
    Gracefully manage system operations by properly stopping all TARS applications
    before performing system shutdown or reboot.

USAGE:
    sudo ./system.sh <command>

COMMANDS:
    shutdown     Stop all containers and shutdown the system
    reboot      Stop all containers and reboot the system
    --help      Display this help message

EXAMPLES:
    sudo ./system.sh shutdown    # Gracefully stop containers and shutdown
    sudo ./system.sh reboot     # Gracefully stop containers and reboot

NOTE:
    - This script requires sudo privileges
    - All containers will be gracefully stopped before system operation
EOF
}

# Check if script is run as root/sudo
if [ "$EUID" -ne 0 ]; then 
    echo "This script requires sudo privileges to manage system power state"
    echo "Usage: sudo ./system.sh <shutdown|reboot>"
    exit 1
fi

# Check for help flag or no arguments
if [ $# -eq 0 ] || [ "$1" == "--help" ]; then
    print_help
    exit 0
fi

# Store the command
COMMAND=$1

# Validate command
if [ "$COMMAND" != "shutdown" ] && [ "$COMMAND" != "reboot" ]; then
    echo "Error: Invalid command '$COMMAND'"
    echo "Valid commands are: shutdown, reboot"
    echo "Use --help to see usage information"
    exit 1
fi

# Function to stop all containers
stop_containers() {
    echo "Stopping all containers..."
    "$SCRIPT_DIR/tars.sh" stop all
    
    # Wait a moment to ensure all containers are properly stopped
    sleep 2
    echo "All containers stopped successfully."
}

# Main execution
print_banner
echo "Starting $COMMAND sequence..."

# Stop all containers first
stop_containers

# Perform the requested operation
case "$COMMAND" in
    "shutdown")
        echo "Initiating system shutdown..."
        shutdown now
        ;;
    "reboot")
        echo "Initiating system reboot..."
        shutdown -r now
        ;;
esac
