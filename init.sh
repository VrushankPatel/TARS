apt install sudo curl wget vim git htop net-tools -y
su -
usermod -aG sudo vrushankpatel
sudo apt update
sudo apt install avahi-daemon libnss-mdns -y
sudo systemctl enable avahi-daemon --now
# copy from 10-sysinfo to /etc/update-motd.d/10-sysinfo
sudo cp ./motd-template/10-sysinfo /etc/update-motd.d/10-sysinfo
sudo chmod +x /etc/update-motd.d/10-sysinfo
sudo chmod -x /etc/update-motd.d/10-uname
sudo chmod -x /etc/update-motd.d/50-motd-news
run-parts /etc/update-motd.d/

# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
# docker install
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo docker run hello-world

# tailscale install
curl -fsSL https://pkgs.tailscale.com/stable/debian/bookworm.noarmor.gpg | sudo tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null
curl -fsSL https://pkgs.tailscale.com/stable/debian/bookworm.tailscale-keyring.list | sudo tee /etc/apt/sources.list.d/tailscale.list
sudo apt-get update
sudo apt-get install tailscale


