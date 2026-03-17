#!/bin/bash
#
# @file        master-install.sh
# @brief       Install k3s master node
# @usage       ./master-install.sh [MASTER_IP] [NODE_NAME] [PROXY_ADDR]
#
# Proxy Configuration:
#   Interactive prompt will ask whether to enable proxy
#   Default proxy address: 10.10.10.0:5050
#
# Usage with custom proxy:
#   ./master-install.sh [MASTER_IP] [NODE_NAME] [PROXY_ADDR]
#   ./master-install.sh 192.168.1.10 my-node 192.168.1.100:7890
#

set -euo pipefail

# Auto sudo if not root
if [[ $EUID -ne 0 ]]; then
    exec sudo -E "$0" "$@"
fi

# Colors
readonly C_RED='\033[0;31m'
readonly C_GREEN='\033[0;32m'
readonly C_YELLOW='\033[1;33m'
readonly C_BLUE='\033[0;34m'
readonly C_NC='\033[0m'

# log function
function log::info() { echo -e "${C_BLUE}[INFO]${C_NC} $*"; }
function log::ok() { echo -e "${C_GREEN}[OK]${C_NC} $*"; }
function log::warn() { echo -e "${C_YELLOW}[WARN]${C_NC} $*"; }
function log::error() { echo -e "${C_RED}[ERROR]${C_NC} $*" >&2; }

readonly MASTER_IP="${1:-$(hostname -I | awk '{print $1}')}"
readonly NODE_NAME="${2:-$(hostname)}"
readonly K3S_VERSION="v1.35.1+k3s1"
readonly PROXY_ADDR="${3:-10.10.10.0:5050}"

log::info "Installing k3s Master Node"
log::info "Master IP: ${MASTER_IP}"
log::info "Node Name: ${NODE_NAME}"
log::info "Version: ${K3S_VERSION}"

check_k3s_installed() {
    if command -v k3s &>/dev/null; then
        log::warn "k3s already installed"
        k3s --version
        exit 0
    fi
}

configure_k3s_proxy() {
    local proxy_addr="${1:-10.10.10.0:5050}"

    # Ask user if proxy should be enabled
    log::info "Configure proxy for k3s image pulling?"
    echo -n "Enable proxy [y/N] (default: N): "
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        log::info "Proxy disabled"
        return 0
    fi

    log::info "Configuring k3s proxy: ${proxy_addr}"

    mkdir -p /etc/systemd/system/k3s.service.d/

    cat > /etc/systemd/system/k3s.service.d/http-proxy.conf <<EOF
[Service]
Environment="HTTP_PROXY=http://${proxy_addr}"
Environment="HTTPS_PROXY=http://${proxy_addr}"
Environment="NO_PROXY=localhost,127.0.0.1,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16,.svc,.cluster.local,${MASTER_IP}"
EOF

    # Also set for install script environment
    export HTTP_PROXY="http://${proxy_addr}"
    export HTTPS_PROXY="http://${proxy_addr}"
    export NO_PROXY="localhost,127.0.0.1,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16,.svc,.cluster.local,${MASTER_IP}"

    # Reload systemd
    if command -v systemctl &>/dev/null; then
        systemctl daemon-reload
    fi

    log::ok "Proxy configured: ${proxy_addr}"
}

install_k3s_server() {
    curl -sfL https://rancher-mirror.rancher.cn/k3s/k3s-install.sh | \
        INSTALL_K3S_MIRROR=cn \
        INSTALL_K3S_VERSION="${K3S_VERSION}" \
        INSTALL_K3S_EXEC="server \
            --tls-san ${MASTER_IP} \
            --node-name ${NODE_NAME} \
            --cluster-cidr 10.42.0.0/16 \
            --service-cidr 10.43.0.0/16 \
            --cluster-dns 10.43.0.10 \
            --disable traefik \
            --disable servicelb" \
        sh -
    log::info "Waiting for node ready..."
    sleep 5
    until kubectl get nodes | grep -q "Ready"; do
        log::info "Waiting..."
        sleep 3
    done
}

main() {
    check_k3s_installed
    configure_k3s_proxy "${PROXY_ADDR}"
    log::info "Installing k3s server..."
    install_k3s_server
    log::ok "k3s master installed successfully!"
    log::info "Node Status:"
    kubectl get nodes -o wide
}

main "$@"