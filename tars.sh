#!/bin/bash

# Get the absolute path of the script's directory
BASE_DIR="$(dirname "$(readlink -f "$0")")"

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

print_banner() {
    echo -e "${CYAN}"
    cat << "EOF"
  ______  ___      ____   _____ 
 /_  __/ /   |    / __ \ / ___/
  / /   / /| |   / /_/ / \__ \ 
 / /   / ___ |  / _, _/ ___/ / 
/_/   /_/  |_| /_/ |_| /____/  
EOF
    echo -e "${BLUE}------------------------${NC}"
    echo -e "${WHITE}TARS Application Manager${NC}"
    echo -e "${BLUE}------------------------${NC}"
}

print_main_help() {
    print_banner
    echo -e "${WHITE}DESCRIPTION:${NC}"
    echo -e "    ${CYAN}TARS (Tooling and Application Runtime System)${NC} is a management tool for your applications."
    echo -e "    It provides a unified interface to control multiple applications and services."
    echo ""
    echo -e "${WHITE}USAGE:${NC}"
    echo -e "    ${GREEN}./tars.sh <command> [options]${NC}"
    echo ""
    echo -e "${WHITE}AVAILABLE COMMANDS:${NC}"
    echo -e "    ${GREEN}start${NC}       Start one or more applications"
    echo -e "    ${GREEN}stop${NC}        Stop one or more applications"
    echo -e "    ${GREEN}restart${NC}     Restart one or more applications (stop followed by start)"
    echo -e "    ${GREEN}logs${NC}        View logs for a specific application"
    echo -e "    ${GREEN}log${NC}         Alias for logs command"
    echo -e "    ${GREEN}health${NC}      Check health status of applications"
    echo -e "    ${CYAN}--help${NC}      Display this help message"
    echo ""
    echo -e "${WHITE}Get help for specific commands:${NC}"
    echo -e "    ${GREEN}./tars.sh start --help${NC}     Show help for start command"
    echo -e "    ${GREEN}./tars.sh stop --help${NC}      Show help for stop command"
    echo -e "    ${GREEN}./tars.sh logs --help${NC}      Show help for logs command"
    echo -e "    ${GREEN}./tars.sh health --help${NC}    Show help for health command"
    echo ""
    echo -e "${WHITE}EXAMPLES:${NC}"
    echo -e "    ${GREEN}./tars.sh start immich${NC}     Start a specific application"
    echo -e "    ${GREEN}./tars.sh start all${NC}        Start all applications"
    echo -e "    ${GREEN}./tars.sh logs immich${NC}      View logs for a specific application"
    echo -e "    ${GREEN}./tars.sh logs immich -c${NC}   View logs with follow mode"
    echo -e "    ${GREEN}./tars.sh health immich${NC}    Check health of a specific application"
    echo -e "    ${GREEN}./tars.sh health all${NC}       Check health of all applications"
}

print_start_help() {
    print_banner
    echo -e "${WHITE}START COMMAND${NC}"
    echo -e "${BLUE}------------${NC}"
    echo -e "Start one or more TARS applications."
    echo ""
    echo -e "${WHITE}USAGE:${NC}"
    echo -e "    ${GREEN}./tars.sh start <app_name | all | --help>${NC}"
    echo ""
    echo -e "${WHITE}OPTIONS:${NC}"
    echo -e "    ${GREEN}app_name${NC}    Name of the application to start (must exist in apps directory)"
    echo -e "    ${GREEN}all${NC}         Start all available applications"
    echo -e "    ${CYAN}--help${NC}      Display this help message"
    echo ""
    echo -e "${WHITE}EXAMPLES:${NC}"
    echo -e "    ${GREEN}./tars.sh start immich${NC}     Start the immich application"
    echo -e "    ${GREEN}./tars.sh start all${NC}        Start all available applications"
    echo ""
    echo -e "${WHITE}DIRECTORY STRUCTURE:${NC}"
    echo -e "    The script expects applications to be organized as follows:"
    echo -e "    ${CYAN}apps/${NC}"
    echo -e "    ├── ${GREEN}app1/${NC}"
    echo -e "    │   └── ${YELLOW}docker-compose.yml${NC}"
    echo -e "    ├── ${GREEN}app2/${NC}"
    echo -e "    │   └── ${YELLOW}docker-compose.yml${NC}"
    echo -e "    └── ..."
    echo ""
    echo -e "${WHITE}NOTE:${NC}"
    echo -e "    - Each application must have a ${YELLOW}docker-compose.yml${NC} file in its directory"
    echo -e "    - All applications are managed using ${CYAN}Docker Compose${NC}"
}

# Function to print restart help
print_restart_help() {
    print_banner
    echo -e "${WHITE}RESTART COMMAND${NC}"
    echo -e "${BLUE}---------------${NC}"
    echo -e "Restart one or more TARS applications."
    echo ""
    echo -e "${WHITE}USAGE:${NC}"
    echo -e "    ${GREEN}./tars.sh restart <app_name | all | --help>${NC}"
    echo ""
    echo -e "${WHITE}OPTIONS:${NC}"
    echo -e "    ${GREEN}app_name${NC}    Name of the application to restart (must exist in apps directory)"
    echo -e "    ${GREEN}all${NC}         Restart all available applications"
    echo -e "    ${CYAN}--help${NC}      Display this help message"
    echo ""
    echo -e "${WHITE}EXAMPLES:${NC}"
    echo -e "    ${GREEN}./tars.sh restart immich${NC}     Restart the immich application"
    echo -e "    ${GREEN}./tars.sh restart all${NC}        Restart all applications"
    echo ""
    echo -e "${WHITE}DIRECTORY STRUCTURE:${NC}"
    echo -e "    The script expects applications to be organized as follows:"
    echo -e "    ${CYAN}apps/${NC}"
    echo -e "    ├── ${GREEN}app1/${NC}"
    echo -e "    │   └── ${YELLOW}docker-compose.yml${NC}"
    echo -e "    ├── ${GREEN}app2/${NC}"
    echo -e "    │   └── ${YELLOW}docker-compose.yml${NC}"
    echo -e "    └── ..."
    echo ""
    echo -e "${WHITE}NOTE:${NC}"
    echo -e "    - Each application must have a ${YELLOW}docker-compose.yml${NC} file in its directory"
    echo -e "    - Applications are restarted using ${CYAN}'docker compose down'${NC} followed by ${CYAN}'up -d'${NC}"
}

# Function to print stop help
print_stop_help() {
    print_banner
    echo -e "${WHITE}STOP COMMAND${NC}"
    echo -e "${BLUE}-----------${NC}"
    echo -e "Stop one or more TARS applications."
    echo ""
    echo -e "${WHITE}USAGE:${NC}"
    echo -e "    ${GREEN}./tars.sh stop <app_name | all | --help>${NC}"
    echo ""
    echo -e "${WHITE}OPTIONS:${NC}"
    echo -e "    ${GREEN}app_name${NC}    Name of the application to stop (must exist in apps directory)"
    echo -e "    ${GREEN}all${NC}         Stop all available applications"
    echo -e "    ${CYAN}--help${NC}      Display this help message"
    echo ""
    echo -e "${WHITE}EXAMPLES:${NC}"
    echo -e "    ${GREEN}./tars.sh stop immich${NC}     Stop the immich application"
    echo -e "    ${GREEN}./tars.sh stop all${NC}        Stop all applications"
    echo ""
    echo -e "${WHITE}DIRECTORY STRUCTURE:${NC}"
    echo -e "    The script expects applications to be organized as follows:"
    echo -e "    ${CYAN}apps/${NC}"
    echo -e "    ├── ${GREEN}app1/${NC}"
    echo -e "    │   └── ${YELLOW}docker-compose.yml${NC}"
    echo -e "    ├── ${GREEN}app2/${NC}"
    echo -e "    │   └── ${YELLOW}docker-compose.yml${NC}"
    echo -e "    └── ..."
    echo ""
    echo -e "${WHITE}NOTE:${NC}"
    echo -e "    - Each application must have a ${YELLOW}docker-compose.yml${NC} file in its directory"
    echo -e "    - Applications are stopped using ${CYAN}'docker compose down'${NC}"
}

# Function to print logs help
print_logs_help() {
    print_banner
    echo -e "${WHITE}LOGS COMMAND${NC}"
    echo -e "${BLUE}-----------${NC}"
    echo -e "View logs for a TARS application."
    echo ""
    echo -e "${WHITE}USAGE:${NC}"
    echo -e "    ${GREEN}./tars.sh logs <app_name> [--console | -c | --help]${NC}"
    echo -e "    ${GREEN}./tars.sh log <app_name> [--console | -c | --help]${NC}"
    echo ""
    echo -e "${WHITE}OPTIONS:${NC}"
    echo -e "    ${GREEN}app_name${NC}    Name of the application to view logs for (must exist in apps directory)"
    echo -e "    ${CYAN}--console${NC}   Follow logs in real-time (equivalent to -c)"
    echo -e "    ${CYAN}-c${NC}          Follow logs in real-time (equivalent to --console)"
    echo -e "    ${CYAN}--help${NC}      Display this help message"
    echo ""
    echo -e "${WHITE}EXAMPLES:${NC}"
    echo -e "    ${GREEN}./tars.sh logs immich${NC}           View logs for the immich application"
    echo -e "    ${GREEN}./tars.sh logs immich --console${NC} View logs with follow mode"
    echo -e "    ${GREEN}./tars.sh log n8n -c${NC}            View logs with follow mode"
    echo -e "    ${GREEN}./tars.sh logs portainer${NC}        View logs for portainer"
    echo ""
    echo -e "${WHITE}DIRECTORY STRUCTURE:${NC}"
    echo -e "    The script expects applications to be organized as follows:"
    echo -e "    ${CYAN}apps/${NC}"
    echo -e "    ├── ${GREEN}app1/${NC}"
    echo -e "    │   └── ${YELLOW}docker-compose.yml${NC}"
    echo -e "    ├── ${GREEN}app2/${NC}"
    echo -e "    │   └── ${YELLOW}docker-compose.yml${NC}"
    echo -e "    └── ..."
    echo ""
    echo -e "${WHITE}NOTE:${NC}"
    echo -e "    - Each application must have a ${YELLOW}docker-compose.yml${NC} file in its directory"
    echo -e "    - Logs are displayed using ${CYAN}'docker compose logs'${NC} command"
    echo -e "    - Use ${CYAN}--console${NC} or ${CYAN}-c${NC} to follow logs in real-time"
    echo -e "    - Use ${YELLOW}Ctrl+C${NC} to exit the logs view when following"
}

# Function to print health help
print_health_help() {
    print_banner
    echo -e "${WHITE}HEALTH COMMAND${NC}"
    echo -e "${BLUE}--------------${NC}"
    echo -e "Check health status of TARS applications."
    echo ""
    echo -e "${WHITE}USAGE:${NC}"
    echo -e "    ${GREEN}./tars.sh health <app_name | all> [--console | -c | --help]${NC}"
    echo ""
    echo -e "${WHITE}OPTIONS:${NC}"
    echo -e "    ${GREEN}app_name${NC}    Name of the application to check health for"
    echo -e "    ${GREEN}all${NC}         Check health of all available applications"
    echo -e "    ${CYAN}--console${NC}   Monitor health continuously (equivalent to -c)"
    echo -e "    ${CYAN}-c${NC}          Monitor health continuously (equivalent to -c)"
    echo -e "    ${CYAN}--help${NC}      Display this help message"
    echo ""
    echo -e "${WHITE}EXAMPLES:${NC}"
    echo -e "    ${GREEN}./tars.sh health immich${NC}         Check health of immich application"
    echo -e "    ${GREEN}./tars.sh health immich -c${NC}      Monitor immich health continuously"
    echo -e "    ${GREEN}./tars.sh health all${NC}            Check health of all applications"
    echo -e "    ${GREEN}./tars.sh health all --console${NC}  Monitor all applications health continuously"
    echo ""
    echo -e "${WHITE}DIRECTORY STRUCTURE:${NC}"
    echo -e "    The script expects applications to be organized as follows:"
    echo -e "    ${CYAN}apps/${NC}"
    echo -e "    ├── ${GREEN}app1/${NC}"
    echo -e "    │   └── ${YELLOW}docker-compose.yml${NC}"
    echo -e "    ├── ${GREEN}app2/${NC}"
    echo -e "    │   └── ${YELLOW}docker-compose.yml${NC}"
    echo -e "    └── ..."
    echo ""
    echo -e "${WHITE}NOTE:${NC}"
    echo -e "    - Each application must have a ${YELLOW}docker-compose.yml${NC} file in its directory"
    echo -e "    - Health is checked using ${CYAN}'docker compose ps'${NC} command"
    echo -e "    - Use ${CYAN}--console${NC} or ${CYAN}-c${NC} to monitor health continuously"
    echo -e "    - Use ${YELLOW}Ctrl+C${NC} to exit continuous monitoring"
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
    "health")
        if [ $# -eq 0 ] || [ "$1" == "--help" ]; then
            print_health_help
            exit 0
        fi
        ;;
    *)
        echo -e "${RED}Error: Invalid command '$COMMAND'${NC}"
        echo -e "Valid commands are: ${GREEN}start${NC}, ${GREEN}stop${NC}, ${GREEN}restart${NC}, ${GREEN}logs${NC}, ${GREEN}log${NC}, ${GREEN}health${NC}"
        echo -e "Use ${CYAN}--help${NC} to see usage information"
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
    
    # # Create app-specific directories based on .env file
    # if [ -f "$BASE_DIR/apps/$app/.env" ]; then
    #     # Extract all paths from .env that end in _LOCATION
    #     local paths=$(grep "_LOCATION=" "$BASE_DIR/apps/$app/.env" | cut -d= -f2)
        
    #     for path in $paths; do
    #         if [[ $path == /* ]]; then  # Only process absolute paths
    #             if [ ! -d "$path" ]; then
    #                 echo "Creating new directory: $path"
    #                 sudo mkdir -p "$path"
                    
    #                 # Check if this is a PostgreSQL directory
    #                 if [[ "$path" =~ [Pp]ostgres ]]; then
    #                     echo "PostgreSQL directory detected: $path - setting special permissions"
    #                     sudo chown -R 999:999 "$path"
    #                     sudo chmod 700 "$path"
    #                 else
    #                     sudo chown $USER:$USER "$path"
    #                 fi
                    
    #                 created_new=true
    #             else
    #                 echo "Using existing directory: $path"
    #             fi
    #         fi
    #     done
    # fi
    
    # if [ "$created_new" = true ]; then
    #     echo "Note: New directories were created. Setting up permissions..."
    #     sudo chown -R 1000:1000 /opt/tars-data/
    #     sudo chmod -R 755 /opt/tars-data/
    #     echo "Directory permissions have been configured."
    # else
    #     echo "All required directories already exist."
    # fi
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
        echo -e "${CYAN}Managing $app application...${NC}"
        case "$cmd" in
            "start")
                docker compose -f "$compose_file" up -d
                ;;
            "stop")
                docker compose -f "$compose_file" down
                ;;
            "logs")
                echo -e "${CYAN}Viewing logs for $app application...${NC}"
                echo -e "${YELLOW}Press Ctrl+C to exit logs view${NC}"
                echo -e "${BLUE}----------------------------------------${NC}"
                docker compose -f "$compose_file" logs -f
                ;;
            "logs_no_follow")
                echo -e "${CYAN}Viewing logs for $app application...${NC}"
                echo -e "${BLUE}----------------------------------------${NC}"
                docker compose -f "$compose_file" logs
                ;;
        esac
    else
        echo -e "${RED}Error: docker-compose.yml not found for $app at $compose_file${NC}"
        exit 1
    fi
}

# Function to check health of a single app
check_app_health() {
    local app=$1
    local compose_file="$BASE_DIR/apps/${app}/docker-compose.yml"
    
    if [ -f "$compose_file" ]; then
        echo -e "${CYAN}=== Health Status: $app ===${NC}"
        docker compose -f "$compose_file" ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"
        echo ""
    else
        echo -e "${RED}Error: docker-compose.yml not found for $app at $compose_file${NC}"
        return 1
    fi
}

# Function to check health of all apps
check_all_apps_health() {
    echo -e "${CYAN}=== Health Status: All Applications ===${NC}"
    echo ""
    
    for dir in "$BASE_DIR"/apps/*/; do
        if [ -d "$dir" ]; then
            app_dir=$(basename "$dir")
            if [ -f "$BASE_DIR/apps/$app_dir/docker-compose.yml" ]; then
                echo -e "${CYAN}--- $app_dir ---${NC}"
                docker compose -f "$BASE_DIR/apps/$app_dir/docker-compose.yml" ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"
                echo ""
            fi
        fi
    done
}

# Function to monitor health continuously
monitor_health_continuous() {
    local app=$1
    local compose_file="$BASE_DIR/apps/${app}/docker-compose.yml"
    
    if [ -f "$compose_file" ]; then
        echo -e "${CYAN}Monitoring health for $app continuously...${NC}"
        echo -e "${YELLOW}Press Ctrl+C to stop monitoring${NC}"
        echo ""
        
        while true; do
            # Gather data first
            local health_data=""
            health_data+="$(echo -e "${CYAN}=== Live Health Monitor: $app ===${NC}")"$'\n'
            health_data+="$(echo -e "${YELLOW}Last updated: $(date)${NC}")"$'\n'
            health_data+=$'\n'
            health_data+="$(docker compose -f "$compose_file" ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}")"$'\n'
            health_data+=$'\n'
            health_data+="$(echo -e "${YELLOW}Press Ctrl+C to stop monitoring${NC}")"
            
            # Clear screen and display data
            clear
            echo "$health_data"
            sleep 5
        done
    else
        echo -e "${RED}Error: docker-compose.yml not found for $app at $compose_file${NC}"
        exit 1
    fi
}

# Function to monitor all apps health continuously
monitor_all_apps_health_continuous() {
    echo -e "${CYAN}Monitoring health for all applications continuously...${NC}"
    echo -e "${YELLOW}Press Ctrl+C to stop monitoring${NC}"
    echo ""
    
    while true; do
        # Gather data first
        local health_data=""
        health_data+="$(echo -e "${CYAN}=== Live Health Monitor: All Applications ===${NC}")"$'\n'
        health_data+="$(echo -e "${YELLOW}Last updated: $(date)${NC}")"$'\n'
        health_data+=$'\n'
        
        for dir in "$BASE_DIR"/apps/*/; do
            if [ -d "$dir" ]; then
                app_dir=$(basename "$dir")
                if [ -f "$BASE_DIR/apps/$app_dir/docker-compose.yml" ]; then
                    health_data+="$(echo -e "${CYAN}--- $app_dir ---${NC}")"$'\n'
                    health_data+="$(docker compose -f "$BASE_DIR/apps/$app_dir/docker-compose.yml" ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}")"$'\n'
                    health_data+=$'\n'
                fi
            fi
        done
        
        health_data+="$(echo -e "${YELLOW}Press Ctrl+C to stop monitoring${NC}")"
        
        # Clear screen and display data
        clear
        echo "$health_data"
        sleep 5
    done
}

# Function to stop all applications
stop_all_apps() {
    echo -e "${CYAN}Stopping all applications...${NC}"
    for dir in "$BASE_DIR"/apps/*/; do
        if [ -d "$dir" ]; then
            app_dir=$(basename "$dir")
            execute_docker_compose "$app_dir" "stop"
        fi
    done
}

# Function to start all applications
start_all_apps() {
    echo -e "${CYAN}Starting all applications...${NC}"
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
        echo -e "${RED}Error: App '$APP_NAME' not found in apps directory${NC}"
        echo -e "Use ${CYAN}--help${NC} to see usage information"
        exit 1
    fi
    
    # Check for console flag
    if [ "$2" = "--console" ] || [ "$2" = "-c" ]; then
        # Execute logs command with follow mode for the specific app
        execute_docker_compose "$APP_NAME" "logs"
    else
        # Execute logs command without follow mode for the specific app
        execute_docker_compose "$APP_NAME" "logs_no_follow"
    fi
elif [ "$COMMAND" = "health" ]; then
    if [ "$APP_NAME" = "all" ]; then
        # Check if console flag is provided
        if [ "$2" = "--console" ] || [ "$2" = "-c" ]; then
            monitor_all_apps_health_continuous
        else
            check_all_apps_health
        fi
    else
        # Check if the specified app directory exists
        if [ ! -d "$BASE_DIR/apps/$APP_NAME" ]; then
            echo -e "${RED}Error: App '$APP_NAME' not found in apps directory${NC}"
            echo -e "Use ${CYAN}--help${NC} to see usage information"
            exit 1
        fi
        
        # Check if console flag is provided
        if [ "$2" = "--console" ] || [ "$2" = "-c" ]; then
            monitor_health_continuous "$APP_NAME"
        else
            check_app_health "$APP_NAME"
        fi
    fi
elif [ "$COMMAND" = "restart" ]; then
    if [ "$APP_NAME" = "all" ]; then
        echo -e "${CYAN}=== Restarting all applications ===${NC}"
        stop_all_apps
        echo -e "${YELLOW}Waiting for containers to stop completely...${NC}"
        sleep 2
        start_all_apps
    else
        # Check if the specified app directory exists
        if [ ! -d "$BASE_DIR/apps/$APP_NAME" ]; then
            echo -e "${RED}Error: App '$APP_NAME' not found in apps directory${NC}"
            echo -e "Use ${CYAN}--help${NC} to see usage information"
            exit 1
        fi
        echo -e "${CYAN}=== Restarting $APP_NAME ===${NC}"
        execute_docker_compose "$APP_NAME" "stop"
        echo -e "${YELLOW}Waiting for containers to stop completely...${NC}"
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
            echo -e "${RED}Error: App '$APP_NAME' not found in apps directory${NC}"
            echo -e "Use ${CYAN}--help${NC} to see usage information"
            exit 1
        fi
        
        # Execute docker compose command for the specific app
        execute_docker_compose "$APP_NAME" "$COMMAND"
    fi
fi
