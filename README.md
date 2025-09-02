<div align="center">

# TARS — Tooling and Application Runtime System

[![Python](https://img.shields.io/badge/Python-3.9+-3776AB?logo=python&logoColor=white)](#)
[![FastAPI](https://img.shields.io/badge/Backend-FastAPI-009688?logo=fastapi&logoColor=white)](#)
[![React](https://img.shields.io/badge/Frontend-React-61DAFB?logo=react&logoColor=black)](#)
[![Vite](https://img.shields.io/badge/Build-Vite-646CFF?logo=vite&logoColor=white)](#)
[![WebSockets](https://img.shields.io/badge/Realtime-WebSockets-25D366?logo=socketdotio&logoColor=white)](#)
[![Docker](https://img.shields.io/badge/Containers-Docker-2496ED?logo=docker&logoColor=white)](#)
[![License](https://img.shields.io/badge/License-MIT-blue)](#)

![Built by Vrushank Patel](https://img.shields.io/badge/Built_by-Vrushank_Patel-black?labelColor=000000&color=00C853)

<br/>

![TARS UI](Images/Screenshot.png)

</div>

## What is TARS?

TARS is a lightweight, privacy‑first, Umbrel‑like runtime for managing your server and self‑hosted apps. It focuses on running everything in Docker, keeping your system clean, fast, and easy to control — with a modern UI, real‑time updates, and zero fuss.

## Core Principles

- Fast and responsive (no junk, minimal overhead)
- Private by default (runs locally; no cloud required)
- Docker‑first architecture (apps as containers)
- Real‑time control with WebSockets (no polling storms)
- Pragmatic UX (quick actions, meaningful feedback)

## Features

- Containers
  - List, start, stop, restart Docker containers (running and exited)
  - Tail container logs (configurable tail with follow)
  - Health, status, image, and ports display
- Processes
  - Live process table with sorting and adjustable row count
  - Kill process action with confirmation toast
- System
  - Host info (OS, kernel, uptime, CPU, memory)
  - Metrics cards (CPU, memory, disk) with periodic refresh
- Network
  - Total sent/received counters
  - Per‑process activity overview (connections and bytes where supported)
- Power controls
  - Reboot and shutdown hooks with graceful container stop

## High‑Level Architecture

- Backend: FastAPI (Python) serving REST endpoints for system/power and a WebSocket endpoint for realtime data (processes, containers, logs, network)
- Frontend: React + Vite + Tailwind + shadcn/ui for a clean, accessible UI
- Runtime: Docker for isolation and reproducibility

```
React (TARS‑UI)  ⇄  FastAPI (REST + WebSocket)  ⇄  Linux utils + Docker CLI
```

## Quick Start

1) Backend (FastAPI)

```bash
# From project root
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
./start_backend.sh  # or: uvicorn app:app --host 0.0.0.0 --port 8000
```

2) Frontend (TARS‑UI)

```bash
cd TARS-UI
npm ci
npm run build
cd ..
cp -r TARS-UI/dist/* ui/
```

Open the UI at: http://localhost:8000/ui

## Development

Backend dev:

```bash
source venv/bin/activate
uvicorn app:app --reload --host 0.0.0.0 --port 8000
```

Frontend dev:

```bash
cd TARS-UI
npm i
npm run dev
```

## Project Layout (excerpt)

```
TARS/
├─ app.py                  # FastAPI entrypoint
├─ src/                    # Backend source (APIs, utils, schemas)
├─ ui/                     # Served static UI bundle (built artifacts)
├─ TARS-UI/                # React app source
└─ apps/                   # App bundles/docker-compose definitions
```

## Roadmap Ideas

- App store‑like UX for curated stacks (media, backup, AI, etc.)
- Fine‑grained container resource controls
- Notifications and audit log
- Backup/restore workflows

## Security & Privacy

TARS is designed to run locally on your hardware. No external telemetry is sent. Use CORS/hosts restrictions and reverse proxies as needed for your environment.

## License

MIT — do what’s right and contribute back fixes and improvements.

# 🚀 TARS - Tooling and Application Runtime System

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Shell: Bash](https://img.shields.io/badge/Shell-Bash-green.svg)](https://www.gnu.org/software/bash/)
[![Docker: Compose](https://img.shields.io/badge/Docker-Compose-blue.svg)](https://docs.docker.com/compose/)

> **TARS** is a powerful, unified management tool for your Docker Compose applications. It provides an intuitive command-line interface to start, stop, restart, monitor logs, and check health status of multiple applications with beautiful colored output and smart monitoring capabilities.

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

### 1. Make the script executable
```bash
chmod +x tars
```

### 2. Get help
```bash
./tars --help
```

### 3. Start your first application
```bash
./tars start immich
```

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