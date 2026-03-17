#!/bin/bash
#
# @file        worker-install.sh
# @brief       Join k3s worker node to cluster
# @usage       ./worker-install.sh <MASTER_IP> <TOKEN> [PROXY_ADDR] [NODE_NAME]
#
# Proxy Configuration:
#   Interactive prompt will ask whether to enable proxy
#   Default proxy address: 10.10.10.0:5050
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

show_help() {
    echo "Usage: $0 <MASTER_IP> <TOKEN> [PROXY_ADDR] [NODE_NAME]"
    echo ""
    echo "Parameters:"
    echo "  MASTER_IP    IP address of the k3s master node"
    echo "  TOKEN        Join token from master node (see below)"
    echo "  PROXY_ADDR   Optional: HTTP proxy for image pulling (default: 10.10.10.0:5050)"
    echo "  NODE_NAME    Optional: Worker node name (default: hostname)"
    echo ""
    echo "How to get TOKEN from master node:"
    echo "  ssh <master-ip> 'sudo cat /var/lib/rancher/k3s/server/node-token'"
    echo ""
    echo "Examples:"
    echo "  $0 192.168.1.10 K10xxxxx::server:xxxxxx"
    echo "  $0 192.168.1.10 K10xxxxx::server:xxxxxx 192.168.1.100:7890 worker-01"
}

check_token() {
    # K3s token format: K10<64-hex>::server:<16-hex>
    if [[ ! "$TOKEN" =~ ^K10[0-9a-f]+::server:[0-9a-f]+$ ]]; then
        log::warn "Token format seems invalid"
        log::info "Expected format: K10xxxxxxxx...::server:xxxxxxxx"
        log::info "To get the correct token from master, run:"
        log::info "  sudo cat /var/lib/rancher/k3s/server/node-token"
    fi
}

# Arguments
if [[ $# -lt 2 ]]; then
    show_help
    exit 1
fi

readonly MASTER_IP="$1"
readonly TOKEN="$2"
readonly PROXY_ADDR="${3:-10.10.10.0:5050}"
readonly NODE_NAME="${4:-$(hostname)}"
readonly K3S_VERSION="v1.35.1+k3s1"

log::info "Joining k3s Worker Node"
log::info "Master: ${MASTER_IP}"
log::info "Node Name: ${NODE_NAME}"
log::info "Version: ${K3S_VERSION}"

check_k3s_installed() {
    if command -v k3s-agent &>/dev/null || command -v k3s &>/dev/null; then
        log::warn "k3s already installed"
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

    log::info "Configuring k3s agent proxy: ${proxy_addr}"

    # Create k3s-agent systemd service directory
    mkdir -p /etc/systemd/system/k3s-agent.service.d/

    # Create proxy configuration
    cat > /etc/systemd/system/k3s-agent.service.d/http-proxy.conf <<EOF
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

install_k3s_agent() {
    curl -sfL https://rancher-mirror.rancher.cn/k3s/k3s-install.sh | \
        INSTALL_K3S_MIRROR=cn \
        INSTALL_K3S_VERSION="${K3S_VERSION}" \
        K3S_URL="https://${MASTER_IP}:6443" \
        K3S_TOKEN="${TOKEN}" \
        INSTALL_K3S_EXEC="agent \
            --node-name ${NODE_NAME}" \
        sh -

    log::info "Waiting for agent to start..."
    sleep 5
}

main() {
    check_token
    check_k3s_installed
    configure_k3s_proxy "${PROXY_ADDR}"
    log::info "Installing k3s agent..."
    install_k3s_agent
    log::ok "Worker node joined successfully!"
    log::info "Run 'kubectl get nodes' on master to verify."
}

main "$@"