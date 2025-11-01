#!/usr/bin/env bash
set -Eeuo pipefail

echo "[*] Installing Docker CE for RHEL 8/9..."

# 1) Prereqs
sudo dnf -y install dnf-plugins-core || true

# 2) Docker CE repo (CentOS/RHEL channel works for RHEL 8/9)
if ! sudo dnf repolist | grep -qi docker-ce; then
  sudo dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
fi

# 3) Install engine + CLI + plugins (Compose v2)
sudo dnf -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# 4) Enable and start service
sudo systemctl enable --now docker

# 5) Optional: allow current user to run docker without sudo (relogin required)
if id -nG "${SUDO_USER:-$USER}" | grep -qvw docker; then
  sudo usermod -aG docker "${SUDO_USER:-$USER}" || true
  echo "[INFO] Added ${SUDO_USER:-$USER} to docker group (log out/in to take effect)"
fi

echo "[*] Docker version:"
docker --version || true
echo "[*] Compose plugin version:"
docker compose version || true

echo "[*] All done"
