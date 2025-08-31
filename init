#!/bin/bash

# TARS System Initialization Script for Debian 12.11 Bookworm
# This script automatically sets up the complete TARS environment

set -e  # Exit on any error

# Color definitions for better output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${CYAN}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        print_warning "Running as root. This is acceptable for initial system setup."
        print_warning "The script will install sudo and then switch to a regular user for TARS setup."
        return 0
    fi
}

# Function to check if running on Debian
check_debian() {
    if ! command -v lsb_release >/dev/null 2>&1; then
        print_error "lsb_release not found. This script is designed for Debian-based systems."
        exit 1
    fi
    
    local distro=$(lsb_release -si)
    local version=$(lsb_release -sr)
    
    if [[ "$distro" != "Debian" ]]; then
        print_error "This script is designed for Debian. Detected: $distro"
        exit 1
    fi
    
    if [[ "$version" != "12.11" ]]; then
        print_warning "This script is tested on Debian 12.11. Detected: $version"
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

# Function to get target username
get_target_username() {
    if [[ $EUID -eq 0 ]]; then
        # If running as root, ask for target username
        echo ""
        echo -e "${YELLOW}Since you're running as root, please specify the target user for TARS setup:${NC}"
        read -p "Enter target username: " target_user
        if [[ -z "$target_user" ]]; then
            print_error "Username cannot be empty"
            exit 1
        fi
        
        # Check if user exists
        if ! id "$target_user" >/dev/null 2>&1; then
            print_error "User '$target_user' does not exist. Please create the user first or use an existing username."
            exit 1
        fi
        
        echo "$target_user"
    else
        # If running as regular user, use current user
        echo "$(whoami)"
    fi
}

# Function to get target home directory
get_target_home() {
    local username="$1"
    if [[ $EUID -eq 0 ]]; then
        # If running as root, get target user's home directory
        echo "$(eval echo ~$username)"
    else
        # If running as regular user, use current home
        echo "$HOME"
    fi
}

# Function to get script directory
get_script_dir() {
    echo "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
}

# Function to update system
update_system() {
    print_status "Updating system packages..."
    apt update
    apt upgrade -y
    print_success "System updated successfully"
}

# Function to install basic packages
install_basic_packages() {
    print_status "Installing basic packages..."
    apt install -y sudo curl wget vim git htop net-tools
    print_success "Basic packages installed successfully"
}

# Function to setup user sudo access
setup_sudo_access() {
    local username="$1"
    print_status "Setting up sudo access for user: $username"
    
    # Check if user is already in sudo group
    if groups "$username" | grep -q sudo; then
        print_success "User $username already has sudo access"
    else
        usermod -aG sudo "$username"
        print_success "User $username added to sudo group"
        print_warning "You may need to log out and back in for sudo changes to take effect"
    fi
}

# Function to setup avahi-daemon
setup_avahi() {
    print_status "Setting up avahi-daemon for network discovery..."
    apt install -y avahi-daemon libnss-mdns
    systemctl enable avahi-daemon
    systemctl start avahi-daemon
    print_success "Avahi-daemon setup completed"
}

# Function to setup MOTD (moved after TARS setup)
setup_motd() {
    local username="$1"
    local home_dir="$2"
    local tars_dir="$home_dir/TARS"
    
    print_status "Setting up custom MOTD..."
    
    # Check if motd-template exists in TARS directory
    if [[ -f "$tars_dir/motd-template/10-sysinfo" ]]; then
        cp "$tars_dir/motd-template/10-sysinfo" /etc/update-motd.d/10-sysinfo
        chmod +x /etc/update-motd.d/10-sysinfo
        print_success "Custom MOTD template installed"
    else
        print_warning "MOTD template not found at $tars_dir/motd-template/10-sysinfo, skipping..."
    fi
    
    # Disable default MOTD components
    chmod -x /etc/update-motd.d/10-uname 2>/dev/null || true
    chmod -x /etc/update-motd.d/50-motd-news 2>/dev/null || true
    
    # Update MOTD
    run-parts /etc/update-motd.d/ 2>/dev/null || true
    print_success "MOTD setup completed"
}

# Function to install Docker
install_docker() {
    print_status "Installing Docker..."
    
    # Check if Docker is already installed
    if command -v docker >/dev/null 2>&1; then
        print_success "Docker is already installed"
        return 0
    fi
    
    # Add Docker's official GPG key
    apt-get update
    apt-get install -y ca-certificates curl
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
    chmod a+r /etc/apt/keyrings/docker.asc
    
    # Add the repository to Apt sources
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    apt-get update
    
    # Install Docker
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    # Add user to docker group
    local username="$1"
    usermod -aG docker "$username"
    
    # Start and enable Docker service
    systemctl start docker
    systemctl enable docker
    
    # Test Docker installation
    docker run --rm hello-world
    
    print_success "Docker installed successfully"
    print_warning "You may need to log out and back in for Docker group changes to take effect"
}

# Function to install additional tools
install_additional_tools() {
    print_status "Installing additional system monitoring tools..."
    
    # Install btop (better top)
    if ! command -v btop >/dev/null 2>&1; then
        apt install -y btop
        print_success "btop installed"
    else
        print_success "btop already installed"
    fi
    
    # Note: lazydocker requires Go, which might not be available in Debian 12.11
    # We'll skip it for now as it's not essential for TARS operation
    print_warning "lazydocker installation skipped (requires Go runtime)"
}

# Function to install Tailscale
install_tailscale() {
    print_status "Installing Tailscale..."
    
    # Check if Tailscale is already installed
    if command -v tailscale >/dev/null 2>&1; then
        print_success "Tailscale is already installed"
        return 0
    fi
    
    # Add Tailscale repository
    curl -fsSL https://pkgs.tailscale.com/stable/debian/bookworm.noarmor.gpg | tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null
    curl -fsSL https://pkgs.tailscale.com/stable/debian/bookworm.tailscale-keyring.list | tee /etc/apt/sources.list.d/tailscale.list
    
    apt-get update
    apt-get install -y tailscale
    
    print_success "Tailscale installed successfully"
    print_warning "Run 'sudo tailscale up' to connect to your Tailscale network"
}

# Function to setup TARS (runs as target user)
setup_tars() {
    local username="$1"
    local home_dir="$2"
    local tars_dir="$home_dir/TARS"
    
    print_status "Setting up TARS system for user: $username..."
    
    # Check if TARS directory already exists
    if [[ -d "$tars_dir" ]]; then
        print_warning "TARS directory already exists at $tars_dir"
        read -p "Remove existing directory and reinstall? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf "$tars_dir"
        else
            print_status "Using existing TARS installation"
            return 0
        fi
    fi
    
    # Clone TARS repository
    print_status "Cloning TARS repository..."
    git clone https://github.com/VrushankPatel/TARS.git "$tars_dir"
    
    # Change ownership to target user
    chown -R "$username:$username" "$tars_dir"
    
    # Make ALL TARS scripts executable
    print_status "Setting executable permissions for all TARS scripts..."
    find "$tars_dir" -name "*.sh" -type f -exec chmod +x {} \;
    find "$tars_dir" -name "tars" -type f -exec chmod +x {} \;
    print_success "All TARS scripts are now executable"
    
    # Setup bash aliases for target user
    print_status "Setting up bash aliases for user: $username..."
    local bashrc="$home_dir/.bashrc"
    
    # Add TARS aliases
    if ! grep -q "TARS shutdown alias" "$bashrc"; then
        echo "" >> "$bashrc"
        echo "# TARS System Aliases" >> "$bashrc"
        echo "alias shutdown='sudo \$HOME/TARS/tars stop all && sudo shutdown now'" >> "$bashrc"
        echo "alias reboot='sudo \$HOME/TARS/tars stop all && sudo reboot'" >> "$bashrc"
        echo "alias btop='btop --force-utf'" >> "$bashrc"
        echo "export PATH=\$PATH:\$HOME/TARS" >> "$bashrc"
        print_success "Bash aliases configured for $username"
    else
        print_success "Bash aliases already configured for $username"
    fi
    
    print_success "TARS setup completed for user: $username"
}

# Function to setup systemd service
setup_systemd_service() {
    local username="$1"
    local home_dir="$2"
    local tars_dir="$home_dir/TARS"
    
    print_status "Setting up TARS systemd service for user: $username..."
    
    # Check if service file exists
    if [[ -f "$tars_dir/services/tars-containers.service" ]]; then
        # Update the service file with correct username
        local service_content="[Unit]
Description=Start TARS Docker Containers
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
ExecStart=/bin/bash $tars_dir/tars start all
RemainAfterExit=yes
User=$username
Group=$username

[Install]
WantedBy=multi-user.target"
        
        echo "$service_content" | tee /etc/systemd/system/tars-containers.service > /dev/null
        
        # Reload systemd and enable service
        systemctl daemon-reload
        systemctl enable tars-containers.service
        
        print_success "TARS systemd service configured and enabled for user: $username"
    else
        print_warning "TARS service template not found at $tars_dir/services/tars-containers.service, skipping systemd setup..."
    fi
}

# Function to create TARS data directory
setup_tars_data() {
    local username="$1"
    print_status "Setting up TARS data directory..."
    
    if [[ ! -d "/opt/tars-data" ]]; then
        mkdir -p /opt/tars-data
        chown "$username:$username" /opt/tars-data
        chmod 755 /opt/tars-data
        print_success "TARS data directory created at /opt/tars-data"
    else
        print_success "TARS data directory already exists"
    fi
}

# Function to display final instructions
display_final_instructions() {
    local username="$1"
    local home_dir="$2"
    
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}🎉 TARS System Setup Completed! 🎉${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo -e "${WHITE}Setup Summary:${NC}"
    echo -e "  ${CYAN}Target User:${NC} $username"
    echo -e "  ${CYAN}TARS Location:${NC} $home_dir/TARS"
    echo -e "  ${CYAN}Data Directory:${NC} /opt/tars-data"
    echo ""
    echo -e "${WHITE}Next Steps for User '$username':${NC}"
    echo -e "1. ${YELLOW}Log out and log back in${NC} to activate sudo and Docker group changes"
    echo -e "2. ${YELLOW}Connect to Tailscale:${NC} sudo tailscale up"
    echo -e "3. ${YELLOW}Test TARS:${NC} cd ~/TARS && ./tars --help"
    echo -e "4. ${YELLOW}Start your applications:${NC} ./tars start all"
    echo ""
    echo -e "${WHITE}Useful Commands:${NC}"
    echo -e "  ${GREEN}./tars start all${NC}     - Start all applications"
    echo -e "  ${GREEN}./tars health all${NC}    - Check health of all apps"
    echo -e "  ${GREEN}./tars logs <app>${NC}    - View application logs"
    echo -e "  ${GREEN}./tars --help${NC}        - Show all available commands"
    echo ""
    echo -e "${WHITE}System Aliases Added:${NC}"
    echo -e "  ${GREEN}shutdown${NC}             - Safely stop TARS and shutdown"
    echo -e "  ${GREEN}reboot${NC}               - Safely stop TARS and reboot"
    echo -e "  ${GREEN}btop${NC}                 - Enhanced system monitor"
    echo ""
    echo -e "${CYAN}For more information, see the README.md file${NC}"
    echo ""
}

# Main execution function
main() {
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}🚀 TARS System Initialization Script${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo -e "${WHITE}Target System:${NC} Debian 12.11 Bookworm"
    echo -e "${WHITE}Current User:${NC} $(whoami)"
    echo -e "${WHITE}Running as Root:${NC} $([[ $EUID -eq 0 ]] && echo "Yes" || echo "No")"
    echo ""
    
    # Pre-flight checks
    check_root
    check_debian
    
    # Get target user information
    local target_username=$(get_target_username)
    local target_home=$(get_target_home "$target_username")
    
    echo -e "${WHITE}Target User:${NC} $target_username"
    echo -e "${WHITE}Target Home:${NC} $target_home"
    echo ""
    
    # Confirmation
    echo -e "${YELLOW}This script will:${NC}"
    echo -e "  • Update system packages"
    echo -e "  • Install essential tools (Docker, Tailscale, etc.)"
    echo -e "  • Setup TARS system for user: ${CYAN}$target_username${NC}"
    echo -e "  • Configure auto-start service"
    echo -e "  • Setup user permissions and aliases"
    echo ""
    read -p "Continue with installation? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status "Installation cancelled by user"
        exit 0
    fi
    
    # Execute setup steps in correct order
    update_system
    install_basic_packages
    setup_sudo_access "$target_username"
    setup_avahi
    install_docker "$target_username"
    install_additional_tools
    install_tailscale
    setup_tars "$target_username" "$target_home"          # TARS must be setup before MOTD and service
    setup_motd "$target_username" "$target_home"          # MOTD setup moved after TARS (so files exist)
    setup_systemd_service "$target_username" "$target_home"
    setup_tars_data "$target_username"
    
    # Display completion message
    display_final_instructions "$target_username" "$target_home"
}

# Execute main function
main "$@"
