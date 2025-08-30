#!/bin/bash

print_banner() {
    cat << "EOF"
  ______  ___      ____   _____ 
 /_  __/ /   |    / __ \ / ___/
  / /   / /| |   / /_/ / \__ \ 
 / /   / ___ |  / _, _/ ___/ / 
/_/   /_/  |_| /_/ |_| /____/  

TARS Application Manager
------------------------
EOF
}

print_main_help() {
    print_banner
    cat << "EOF"

DESCRIPTION:
    TARS (Tooling and Application Runtime System) is a management tool for your applications.
    It provides a unified interface to control multiple applications and services.

USAGE:
    ./tars.sh <command> [options]

AVAILABLE COMMANDS:
    start       Start one or more applications
    stop        Stop one or more applications [Coming soon]
    --help      Display this help message

Get help for specific commands:
    ./tars.sh start --help     Show help for start command
    ./tars.sh stop --help      Show help for stop command

EXAMPLES:
    ./tars.sh start immich     Start a specific application
    ./tars.sh start all        Start all applications
EOF
}

print_start_help() {
    print_banner
    cat << "EOF"

START COMMAND
------------
Start one or more TARS applications.

USAGE:
    ./tars.sh start <app_name | all | --help>

OPTIONS:
    app_name    Name of the application to start (must exist in apps directory)
    all         Start all available applications
    --help      Display this help message

EXAMPLES:
    ./tars.sh start immich     Start the immich application
    ./tars.sh start all        Start all available applications

DIRECTORY STRUCTURE:
    The script expects applications to be organized as follows:
    apps/
    ├── app1/
    │   └── start-app1.sh
    ├── app2/
    │   └── start-app2.sh
    └── ...

NOTE:
    - Each application must have a start script named: start-<app_name>.sh
    - All scripts will be made executable automatically
EOF
}

# Handle help text based on arguments
if [ $# -eq 0 ] || [ "$1" == "--help" ]; then
    print_main_help
    exit 0
fi

if [ $# -eq 1 ]; then
    if [ "$1" == "start" ]; then
        print_start_help
        exit 0
    elif [ "$1" == "stop" ]; then
        echo "Stop command functionality coming soon!"
        exit 0
    else
        print_main_help
        exit 1
    fi
fi

# Store the command and app name
COMMAND=$1
APP_NAME=$2

# Check if command is valid
if [ "$COMMAND" != "start" ] && [ "$COMMAND" != "stop" ]; then
    echo "Error: Invalid command '$COMMAND'"
    echo "Valid commands are: start, stop"
    echo "Use --help to see usage information"
    exit 1
fi

# Check if apps directory exists
if [ ! -d "apps" ]; then
    echo "Error: 'apps' directory not found"
    exit 1
fi

# Function to execute single app script
execute_app_script() {
    local app=$1
    local cmd=$2
    local script_path="apps/${app}/${cmd}-${app}.sh"
    
    if [ -f "$script_path" ]; then
        echo "Executing $script_path"
        chmod +x "$script_path"
        cd "$(dirname "$script_path")" && ./$(basename "$script_path")
    else
        echo "Error: Script not found at $script_path"
        exit 1
    fi
}

# If app_name is 'all'
if [ "$APP_NAME" = "all" ]; then
    # Loop through all directories in apps
    for dir in apps/*/; do
        if [ -d "$dir" ]; then
            app_dir=$(basename "$dir")
            execute_app_script "$app_dir" "$COMMAND"
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
    execute_app_script "$APP_NAME" "$COMMAND"
fi
