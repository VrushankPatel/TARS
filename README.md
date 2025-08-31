# 🚀 TARS - Tooling and Application Runtime System

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Shell: Bash](https://img.shields.io/badge/Shell-Bash-green.svg)](https://www.gnu.org/software/bash/)
[![Docker: Compose](https://img.shields.io/badge/Docker-Compose-blue.svg)](https://docs.docker.com/compose/)

> **TARS** is a powerful, unified management tool for your Docker Compose applications. It provides an intuitive command-line interface to start, stop, restart, monitor logs, and check health status of multiple applications with beautiful colored output and smart monitoring capabilities.

## 📋 Table of Contents

- [🚀 Features](#-features)
- [🏗️ Directory Structure](#️-directory-structure)
- [⚡ Quick Start](#-quick-start)
- [🔧 System Setup](#-system-setup)
- [📚 Command Reference](#-command-reference)
- [🎨 Color Scheme](#-color-scheme)
- [📋 Examples](#-examples)
- [🔧 Requirements](#-requirements)
- [🚨 Troubleshooting](#-troubleshooting)
- [🤝 Contributing](#-contributing)
- [📄 License](#-license)
- [🙏 Acknowledgments](#-acknowledgments)
- [📞 Support](#-support)

## ✨ Features

- 🎯 **Unified Management**: Control all your Docker Compose applications from one script
- 🎨 **Beautiful Colors**: Rich, colorful output for better user experience
- 📊 **Health Monitoring**: Real-time health status with continuous monitoring options
- 📝 **Smart Logging**: View logs with or without follow mode
- 🔄 **Smart Loading**: No more blank screens during health monitoring updates
- 🚀 **Easy Commands**: Simple, intuitive command structure
- 📁 **Auto-Discovery**: Automatically detects applications in the `apps/` directory
- 🛡️ **Error Handling**: Comprehensive error checking and user-friendly messages

## 🏗️ Directory Structure

```
TARS/
├── tars                    # Main TARS script
├── apps/                   # Applications directory
│   ├── immich/            # Immich application
│   │   └── docker-compose.yml
│   ├── n8n/               # N8N workflow automation
│   │   └── docker-compose.yml
│   ├── portainer/         # Portainer container management
│   │   └── docker-compose.yml
│   └── ...                # More applications
├── services/               # TARS services
├── init.sh                 # Initialization script
└── README.md              # This file
```

## 🚀 Quick Start

### 🆕 New Installation
If you're setting up TARS on a fresh Debian 12.11 Bookworm system:

```bash
# Clone and run automated setup
git clone https://github.com/VrushankPatel/TARS.git
cd TARS
./init.sh
```

### 🔧 Existing Installation
If TARS is already installed:

#### 1. Make the script executable
```bash
chmod +x tars
```

#### 2. Get help
```bash
./tars --help
```

#### 3. Start your first application
```bash
./tars start immich
```

---

## 🔧 System Setup

### 🆕 Fresh Debian 12.11 Bookworm Installation

The TARS system comes with an **automated setup script** that will install everything you need on a fresh Debian 12.11 Bookworm system.

#### Prerequisites
- Fresh Debian 12.11 Bookworm installation
- User with sudo privileges
- Internet connection
- At least 2GB RAM and 10GB free disk space

#### 🚀 One-Command Setup

```bash
# Clone TARS repository
git clone https://github.com/VrushankPatel/TARS.git
cd TARS

# Run the automated setup script
./init.sh
```

#### ✨ What the Setup Script Does

The `init.sh` script automatically:

1. **🔧 System Preparation**
   - Updates system packages
   - Installs essential tools (curl, wget, vim, git, htop, net-tools)
   - Sets up sudo access for your user

2. **🌐 Network Services**
   - Installs and configures avahi-daemon for network discovery
   - Sets up custom MOTD (Message of the Day)

3. **🐳 Docker Installation**
   - Adds Docker's official repository
   - Installs Docker Engine with Compose support
   - Configures user permissions for Docker
   - Tests Docker installation

4. **🛠️ Additional Tools**
   - Installs btop (enhanced system monitor)
   - Installs Tailscale for secure networking

5. **🚀 TARS System Setup**
   - Clones TARS repository to `~/TARS`
   - Makes TARS script executable
   - Sets up bash aliases for shutdown/reboot
   - Configures systemd service for auto-start
   - Creates data directory at `/opt/tars-data`

#### 📋 Setup Process

```bash
# The script will guide you through:
./init.sh

# 1. System compatibility check
# 2. User confirmation
# 3. Automated installation
# 4. Final setup instructions
```

#### 🔄 Post-Setup Steps

After running `init.sh`, you'll need to:

1. **Log out and log back in** to activate sudo and Docker group changes
2. **Connect to Tailscale**: `sudo tailscale up`
3. **Test TARS**: `cd ~/TARS && ./tars --help`
4. **Start applications**: `./tars start all`

#### 🎯 System Aliases Added

The setup script automatically adds these useful aliases to your `.bashrc`:

```bash
shutdown    # Safely stop TARS and shutdown
reboot      # Safely stop TARS and reboot
btop        # Enhanced system monitor
```

#### 🚨 Troubleshooting Setup

If you encounter issues during setup:

```bash
# Check script syntax
bash -n init.sh

# Run with verbose output
bash -x init.sh

# Check system requirements
lsb_release -a
docker --version
```

#### 🔧 Manual Setup (Alternative)

If you prefer manual setup or need to customize the installation:

```bash
# Install Docker manually
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Install TARS manually
git clone https://github.com/VrushankPatel/TARS.git ~/TARS
chmod +x ~/TARS/tars
```

---

## 📚 Command Reference

### 🎯 Main Commands

| Command | Description | Usage |
|---------|-------------|-------|
| `start` | Start applications | `./tars start <app_name \| all>` |
| `stop` | Stop applications | `./tars stop <app_name \| all>` |
| `restart` | Restart applications | `./tars restart <app_name \| all>` |
| `logs` | View application logs | `./tars logs <app_name> [--console \| -c]` |
| `log` | Alias for logs command | `./tars log <app_name> [--console \| -c]` |
| `health` | Check application health | `./tars health <app_name \| all> [--console \| -c]` |

### 🔧 Global Options

| Option | Description |
|--------|-------------|
| `--help` | Show help for any command |

---

## 🚀 Start Command

Start one or more TARS applications.

### Usage
```bash
./tars start <app_name | all | --help>
```

### Options
- **`app_name`**: Name of the application to start (must exist in `apps/` directory)
- **`all`**: Start all available applications
- **`--help`**: Display help message

### Examples
```bash
# Start a specific application
./tars start immich

# Start all applications
./tars start all

# Get help
./tars start --help
```

### What it does
- Ensures required directories exist
- Runs `docker compose up -d` for the specified application(s)
- Provides colored feedback on the process

---

## 🛑 Stop Command

Stop one or more TARS applications.

### Usage
```bash
./tars stop <app_name | all | --help>
```

### Options
- **`app_name`**: Name of the application to stop (must exist in `apps/` directory)
- **`all`**: Stop all available applications
- **`--help`**: Display help message

### Examples
```bash
# Stop a specific application
./tars stop immich

# Stop all applications
./tars stop all

# Get help
./tars stop --help
```

### What it does
- Runs `docker compose down` for the specified application(s)
- Provides colored feedback on the process

---

## 🔄 Restart Command

Restart one or more TARS applications (stop followed by start).

### Usage
```bash
./tars restart <app_name | all | --help>
```

### Options
- **`app_name`**: Name of the application to restart (must exist in `apps/` directory)
- **`all`**: Restart all available applications
- **`--help`**: Display help message

### Examples
```bash
# Restart a specific application
./tars restart immich

# Restart all applications
./tars restart all

# Get help
./tars restart --help
```

### What it does
1. Stops the application(s) using `docker compose down`
2. Waits for containers to stop completely
3. Starts the application(s) using `docker compose up -d`
4. Provides colored feedback throughout the process

---

## 📝 Logs Command

View logs for TARS applications with optional real-time following.

### Usage
```bash
./tars logs <app_name> [--console | -c | --help]
./tars log <app_name> [--console | -c | --help]  # 'log' is an alias for 'logs'
```

### Options
- **`app_name`**: Name of the application to view logs for (must exist in `apps/` directory)
- **`--console`**: Follow logs in real-time (equivalent to `-c`)
- **`-c`**: Follow logs in real-time (equivalent to `--console`)
- **`--help`**: Display help message

### Examples
```bash
# View logs once (no follow mode)
./tars logs immich
./tars log n8n

# View logs with real-time following
./tars logs immich --console
./tars logs immich -c
./tars log portainer --console

# Get help
./tars logs --help
```

### What it does
- **Without `--console` or `-c`**: Shows logs once using `docker compose logs`
- **With `--console` or `-c`**: Shows logs with follow mode using `docker compose logs -f`
- Use `Ctrl+C` to exit when following logs

---

## 🏥 Health Command

Check health status of TARS applications with optional continuous monitoring.

### Usage
```bash
./tars health <app_name | all> [--console | -c | --help]
```

### Options
- **`app_name`**: Name of the application to check health for
- **`all`**: Check health of all available applications
- **`--console`**: Monitor health continuously (equivalent to `-c`)
- **`-c`**: Monitor health continuously (equivalent to `--console`)
- **`--help`**: Display help message

### Examples
```bash
# Check health once
./tars health immich
./tars health all

# Monitor health continuously
./tars health immich --console
./tars health immich -c
./tars health all --console
./tars health all -c

# Get help
./tars health --help
```

### What it does
- **Single app health**: Shows container status using `docker compose ps`
- **All apps health**: Shows health status for all applications
- **Continuous monitoring**: Updates health status every 5 seconds with screen clearing
- **Smart loading**: No blank screens during updates
- Use `Ctrl+C` to exit continuous monitoring

### Health Output Format
```
=== Health Status: immich ===
NAME                    STATUS              PORTS
immich-immich-1        Up 2 hours          3000:3000
immich-postgres-1      Up 2 hours          5432:5432
```

---

## 🎨 Color Scheme

TARS uses a beautiful color scheme to enhance readability:

| Color | Usage |
|-------|-------|
| 🔵 **CYAN** | Headers, titles, and main information |
| ⚪ **WHITE** | Section headers and important text |
| 🟢 **GREEN** | Commands, options, and success messages |
| 🟡 **YELLOW** | Warnings, timestamps, and instructions |
| 🔴 **RED** | Errors and critical messages |
| 🔵 **BLUE** | Sub-headers and secondary information |
| 🟣 **PURPLE** | Additional accent color |

---

## 📋 Examples

### 🚀 Application Management
```bash
# Start all applications
./tars start all

# Stop specific application
./tars stop n8n

# Restart portainer
./tars restart portainer
```

### 📝 Log Management
```bash
# View logs once
./tars logs immich

# Follow logs in real-time
./tars logs n8n --console
./tars log portainer -c
```

### 🏥 Health Monitoring
```bash
# Quick health check
./tars health all

# Monitor specific app continuously
./tars health immich -c

# Monitor all apps continuously
./tars health all --console
```

### 🆘 Getting Help
```bash
# Main help
./tars --help

# Command-specific help
./tars start --help
./tars logs --help
./tars health --help
```

---

## 🔧 Requirements

- **Operating System**: Linux, macOS, or Windows with WSL
- **Shell**: Bash 4.0 or higher
- **Docker**: Docker Engine with Docker Compose support
- **Permissions**: Ability to run Docker commands and use sudo (for directory creation)

---

## 🚨 Troubleshooting

### Common Issues

#### 1. Permission Denied
```bash
chmod +x tars
```

#### 2. App Not Found
- Ensure the application directory exists in `apps/`
- Check that `docker-compose.yml` exists in the app directory
- Verify the app name spelling

#### 3. Docker Compose Issues
- Ensure Docker is running
- Check Docker Compose version compatibility
- Verify `docker-compose.yml` syntax

#### 4. Health Command Not Working
- Ensure containers are running
- Check Docker Compose project status
- Verify network connectivity

### Debug Mode
For troubleshooting, you can check the script syntax:
```bash
bash -n tars
```

---

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

### Development Guidelines
- Follow bash best practices
- Add colors for better UX
- Maintain consistent error handling
- Update help text for new features

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- **Docker Team** for Docker Compose
- **Bash Community** for shell scripting best practices
- **Open Source Contributors** for inspiration and feedback

---

## 📞 Support

If you encounter any issues or have questions:

1. Check the troubleshooting section above
2. Review the help text: `./tars --help`
3. Open an issue on the repository
4. Check existing issues for solutions

---

**Made with ❤️ by the TARS Community**

---

*Last updated: $(date)*
