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
    stop        Stop one or more applications
    restart     Restart one or more applications (stop followed by start)
    logs        View logs for a specific application
    log         Alias for logs command
    --help      Display this help message

Get help for specific commands:
    ./tars.sh start --help     Show help for start command
    ./tars.sh stop --help      Show help for stop command
    ./tars.sh logs --help      Show help for logs command

EXAMPLES:
    ./tars.sh start immich     Start a specific application
    ./tars.sh start all        Start all applications
    ./tars.sh logs immich      View logs for a specific application
    ./tars.sh log n8n          View logs for a specific application
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

# Function to print restart help
print_restart_help() {
    print_banner
    cat << "EOF"

RESTART COMMAND
--------------
Restart one or more TARS applications.

USAGE:
    ./tars.sh restart <app_name | all | --help>

OPTIONS:
    app_name    Name of the application to restart (must exist in apps directory)
    all         Restart all available applications
    --help      Display this help message

EXAMPLES:
    ./tars.sh restart immich     Restart the immich application
    ./tars.sh restart all        Restart all applications

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
    - Applications are restarted using 'docker compose down' followed by 'up -d'
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

# Function to print logs help
print_logs_help() {
    print_banner
    cat << "EOF"

LOGS COMMAND
-----------
View logs for a TARS application.

USAGE:
    ./tars.sh logs <app_name | --help>
    ./tars.sh log <app_name | --help>

OPTIONS:
    app_name    Name of the application to view logs for (must exist in apps directory)
    --help      Display this help message

EXAMPLES:
    ./tars.sh logs immich      View logs for the immich application
    ./tars.sh log n8n          View logs for the n8n application

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
    - Logs are displayed using 'docker compose logs' command
    - Use Ctrl+C to exit the logs view
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
    "restart")
        if [ $# -eq 0 ] || [ "$1" == "--help" ]; then
            print_restart_help
            exit 0
        fi
        ;;
    "logs"|"log")
        if [ $# -eq 0 ] || [ "$1" == "--help" ]; then
            print_logs_help
            exit 0
        fi
        ;;
    *)
        echo "Error: Invalid command '$COMMAND'"
        echo "Valid commands are: start, stop, restart, logs, log"
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

# Function to ensure required directories exist
ensure_directories() {
    local app=$1
    local created_new=false
    
    # Check if base data directory exists
    if [ ! -d "/opt/tars-data" ]; then
        echo "Creating base data directory at /opt/tars-data"
        sudo mkdir -p /opt/tars-data
        sudo chown $USER:$USER /opt/tars-data
        created_new=true
    fi
    
    # Create app-specific directories based on .env file
    if [ -f "$BASE_DIR/apps/$app/.env" ]; then
        # Extract all paths from .env that end in _LOCATION
        local paths=$(grep "_LOCATION=" "$BASE_DIR/apps/$app/.env" | cut -d= -f2)
        
        for path in $paths; do
            if [[ $path == /* ]]; then  # Only process absolute paths
                if [ ! -d "$path" ]; then
                    echo "Creating new directory: $path"
                    sudo mkdir -p "$path"
                    sudo chown $USER:$USER "$path"
                    created_new=true
                else
                    echo "Using existing directory: $path"
                fi
            fi
        done
    fi
    
    if [ "$created_new" = true ]; then
        echo "Note: New directories were created. Setting up permissions..."
        sudo chown -R 1000:1000 /opt/tars-data/
        sudo chmod -R 755 /opt/tars-data/
        echo "Directory permissions have been configured."
    else
        echo "All required directories already exist."
    fi
}

# Function to execute docker compose command for a single app
execute_docker_compose() {
    local app=$1
    local cmd=$2
    local compose_file="$BASE_DIR/apps/${app}/docker-compose.yml"
    
    # Ensure required directories exist before starting
    if [ "$cmd" = "start" ]; then
        ensure_directories "$app"
    fi
    
    if [ -f "$compose_file" ]; then
        echo "Managing $app application..."
        case "$cmd" in
            "start")
                docker compose -f "$compose_file" up -d
                ;;
            "stop")
                docker compose -f "$compose_file" down
                ;;
            "logs")
                echo "Viewing logs for $app application..."
                echo "Press Ctrl+C to exit logs view"
                echo "----------------------------------------"
                docker compose -f "$compose_file" logs -f
                ;;
        esac
    else
        echo "Error: docker-compose.yml not found for $app at $compose_file"
        exit 1
    fi
}

# Function to stop all applications
stop_all_apps() {
    echo "Stopping all applications..."
    for dir in "$BASE_DIR"/apps/*/; do
        if [ -d "$dir" ]; then
            app_dir=$(basename "$dir")
            execute_docker_compose "$app_dir" "stop"
        fi
    done
}

# Function to start all applications
start_all_apps() {
    echo "Starting all applications..."
    for dir in "$BASE_DIR"/apps/*/; do
        if [ -d "$dir" ]; then
            app_dir=$(basename "$dir")
            execute_docker_compose "$app_dir" "start"
        fi
    done
}

# Handle different commands
if [ "$COMMAND" = "logs" ] || [ "$COMMAND" = "log" ]; then
    # Check if the specified app directory exists
    if [ ! -d "$BASE_DIR/apps/$APP_NAME" ]; then
        echo "Error: App '$APP_NAME' not found in apps directory"
        echo "Use --help to see usage information"
        exit 1
    fi
    
    # Execute logs command for the specific app
    execute_docker_compose "$APP_NAME" "logs"
elif [ "$COMMAND" = "restart" ]; then
    if [ "$APP_NAME" = "all" ]; then
        echo "=== Restarting all applications ==="
        stop_all_apps
        echo "Waiting for containers to stop completely..."
        sleep 2
        start_all_apps
    else
        # Check if the specified app directory exists
        if [ ! -d "$BASE_DIR/apps/$APP_NAME" ]; then
            echo "Error: App '$APP_NAME' not found in apps directory"
            echo "Use --help to see usage information"
            exit 1
        fi
        echo "=== Restarting $APP_NAME ==="
        execute_docker_compose "$APP_NAME" "stop"
        echo "Waiting for containers to stop completely..."
        sleep 2
        execute_docker_compose "$APP_NAME" "start"
    fi
else
    # Handle regular start/stop commands
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
fi
