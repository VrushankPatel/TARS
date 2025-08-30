#!/bin/bash

# Get the absolute path of the script's directory
BASE_DIR="$(dirname "$(readlink -f "$0")")"

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
    │   └── docker-compose.yml
    ├── app2/
    │   └── docker-compose.yml
    └── ...

NOTE:
    - Each application must have a docker-compose.yml file in its directory
    - All applications are managed using Docker Compose
EOF
}

# Function to print stop help
print_stop_help() {
    print_banner
    cat << "EOF"

STOP COMMAND
-----------
Stop one or more TARS applications.

USAGE:
    ./tars.sh stop <app_name | all | --help>

OPTIONS:
    app_name    Name of the application to stop (must exist in apps directory)
    all         Stop all available applications
    --help      Display this help message

EXAMPLES:
    ./tars.sh stop immich     Stop the immich application
    ./tars.sh stop all        Stop all applications

DIRECTORY STRUCTURE:
    The script expects applications to be organized as follows:
    apps/
    ├── app1/
    │   └── docker-compose.yml
    ├── app2/
    │   └── docker-compose.yml
    └── ...

NOTE:
    - Each application must have a docker-compose.yml file in its directory
    - Applications are stopped using 'docker compose down'
EOF
}

# Handle help text and command validation
if [ $# -eq 0 ] || [ "$1" == "--help" ]; then
    print_main_help
    exit 0
fi

COMMAND=$1
shift

# Handle command-specific help and validation
case "$COMMAND" in
    "start")
        if [ $# -eq 0 ] || [ "$1" == "--help" ]; then
            print_start_help
            exit 0
        fi
        ;;
    "stop")
        if [ $# -eq 0 ] || [ "$1" == "--help" ]; then
            print_stop_help
            exit 0
        fi
        ;;
    *)
        echo "Error: Invalid command '$COMMAND'"
        echo "Valid commands are: start, stop"
        echo "Use --help to see usage information"
        exit 1
        ;;
esac

# Store the app name
APP_NAME=$1

# Check if apps directory exists
if [ ! -d "$BASE_DIR/apps" ]; then
    echo "Error: 'apps' directory not found in $BASE_DIR"
    exit 1
fi

# Function to execute docker compose command
execute_docker_compose() {
    local app=$1
    local cmd=$2
    local compose_file="$BASE_DIR/apps/${app}/docker-compose.yml"
    
    if [ -f "$compose_file" ]; then
        echo "Managing $app application..."
        if [ "$cmd" == "start" ]; then
            docker compose -f "$compose_file" up -d
        elif [ "$cmd" == "stop" ]; then
            docker compose -f "$compose_file" down
        fi
    else
        echo "Error: docker-compose.yml not found for $app at $compose_file"
        exit 1
    fi
}

# If app_name is 'all'
if [ "$APP_NAME" = "all" ]; then
    # Loop through all directories in apps
    for dir in "$BASE_DIR"/apps/*/; do
        if [ -d "$dir" ]; then
            app_dir=$(basename "$dir")
            execute_docker_compose "$app_dir" "$COMMAND"
        fi
    done
else
    # Check if the specified app directory exists
    if [ ! -d "$BASE_DIR/apps/$APP_NAME" ]; then
        echo "Error: App '$APP_NAME' not found in apps directory"
        echo "Use --help to see usage information"
        exit 1
    fi
    
    # Execute docker compose command for the specific app
    execute_docker_compose "$APP_NAME" "$COMMAND"
fi
