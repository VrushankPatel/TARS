#!/bin/bash

print_help() {
    cat << "EOF"
 ______  ___   ____   _____ 
/_  __/ /   | / __ \ / ___/
 / /   / /| |/ /_/ / \__ \ 
/ /   / ___ / _, _/ ___/ / 
/_/   /_/  |/_/ |_| /____/  

TARS Application Manager
------------------------

DESCRIPTION:
    This script manages the startup of TARS applications. It can start individual
    applications or all applications at once.

USAGE:
    sudo ./start.sh <app_name | all | --help>

OPTIONS:
    app_name    Name of the application to start (must exist in apps directory)
    all         Start all available applications
    --help      Display this help message

EXAMPLES:
    sudo ./start.sh immich     # Start the immich application
    sudo ./start.sh all        # Start all available applications

DIRECTORY STRUCTURE:
    The script expects applications to be organized as follows:
    apps/
    ├── app1/
    │   └── start-app1.sh
    ├── app2/
    │   └── start-app2.sh
    └── ...

NOTE:
    - This script requires sudo privileges
    - Each application must have a start script named: start-<app_name>.sh
    - All start scripts will be made executable automatically
EOF
}

# Check for help flag
if [ "$1" == "--help" ] || [ $# -eq 0 ]; then
    print_help
    exit 0
fi

# Check if script is run as root/sudo
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as sudo"
    echo "Use --help for more information"
    exit 1
fi

# Store the argument
APP_NAME=$1

# Check if apps directory exists
if [ ! -d "apps" ]; then
    echo "Error: 'apps' directory not found"
    exit 1
fi

# Function to execute single app script
execute_app_script() {
    local app=$1
    local base_path
    if [ -n "$SUDO_USER" ]; then
        base_path="/home/$SUDO_USER/TARS"
    else
        base_path="$PWD"
    fi
    local script_path="$base_path/apps/${app}/start-${app}.sh"
    
    if [ -f "$script_path" ]; then
        echo "Executing $script_path"
        chmod +x "$script_path"
        cd "$(dirname "$script_path")" && sudo -u "$SUDO_USER" ./$(basename "$script_path")
    else
        echo "Error: Script not found at $script_path"
        exit 1
    fi
}

# If argument is 'all'
if [ "$APP_NAME" = "all" ]; then
    # Loop through all directories in apps
    for dir in apps/*/; do
        if [ -d "$dir" ]; then
            app_dir=$(basename "$dir")
            execute_app_script "$app_dir"
        fi
    done
else
    # Check if the specified app directory exists
    if [ ! -d "apps/$APP_NAME" ]; then
        echo "Error: App '$APP_NAME' not found in apps directory"
        echo "Use --help to see usage information"
        exit 1
    fi
    
    # Execute specific app script
    execute_app_script "$APP_NAME"
fi
