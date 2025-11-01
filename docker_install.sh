#!/usr/bin/env bash
# Universal Docker CE + Compose installer for Fedora (40–42) and RHEL/Rocky/Alma (8–9)

set -Eeuo pipefail

log()  { printf "[INFO] %s\n" "$*"; }
err()  { printf "[ERROR] %s\n" "$*"; } >&2

require_root() {
  [[ ${EUID:-$(id -u)} -eq 0 ]] || { err "Please run as root or with sudo."; exit 1; }
}

os_id()      { . /etc/os-release; echo "$ID"; }
os_version() { . /etc/os-release; echo "${VERSION_ID%%.*}"; }

install_docker_fedora() {
  log "Detected Fedora $1"

  # Fedora 40+ dropped old add-repo commands → write repo file directly
  if (( $1 >= 40 )); then
    log "Creating Docker CE repo file for Fedora $1"
    cat >/etc/yum.repos.d/docker-ce.repo <<'EOF'
[docker-ce-stable]
name=Docker CE Stable - Fedora
baseurl=https://download.docker.com/linux/fedora/$releasever/$basearch/stable
enabled=1
gpgcheck=1
gpgkey=https://download.docker.com/linux/fedora/gpg
EOF
  else
    log "Using classic dnf (Fedora ≤ 39)"
    dnf install -y dnf-plugins-core
    dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
  fi

  dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
}

install_docker_rhel() {
  log "Detected RHEL-like system"
  dnf -y install dnf-plugins-core
  dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
  dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
}

enable_docker() {
  systemctl enable --now docker
  log "Docker service started"
}

add_user_to_group() {
  local user=${SUDO_USER:-${USER:-root}}
  if [[ "$user" != "root" ]]; then
    usermod -aG docker "$user" && log "Added $user to docker group (log out/in to apply)"
  fi
}

main() {
  require_root
  local id ver
  id=$(os_id)
  ver=$(os_version)
  log "Installing Docker CE on $id $ver"

  case "$id" in
    fedora) install_docker_fedora "$ver" ;;
    rhel|rocky|almalinux|centos|centosstream) install_docker_rhel ;;
    *) err "Unsupported OS: $id"; exit 1 ;;
  esac

  enable_docker
  add_user_to_group

  log "Verifying installation..."
  docker --version
  docker compose version || true

  log "✅ Docker installation complete!"
}

main "$@"
