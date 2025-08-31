#!/bin/bash
# Script to create systemd service for TARS Docker containers

SERVICE_NAME="tars-containers.service"
SERVICE_PATH="/etc/systemd/system/$SERVICE_NAME"
USER_HOME=$(eval echo "~$SUDO_USER")

# Create systemd unit
sudo tee "$SERVICE_PATH" > /dev/null <<EOF
[Unit]
Description=Start TARS Docker Containers
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
ExecStart=/bin/bash $USER_HOME/TARS/tars.sh start all
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd
sudo systemctl daemon-reexec

# Enable service
sudo systemctl enable $SERVICE_NAME

echo "✅ Systemd service '$SERVICE_NAME' created and enabled."
echo "It will start all TARS containers at boot."
