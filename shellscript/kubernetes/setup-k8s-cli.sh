#!/bin/bash
#
# @file        setup-k8s-cli.sh
# @brief       Install kubectl and helm on management machine (local)
# @usage       ./setup-k8s-cli.sh
#

set -euo pipefail

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

check_prerequisites() {
    if [[ $ARCH == x86_64 ]]; then
        ARCH="amd64"
    else
        log::error "Unsupported architecture: $ARCH"
        exit 1
    fi

    if [[ $SHELL != /bin/bash ]]; then
        log::error "Unsupported shell: $SHELL"
        exit 1
    fi
}

install_dependencies() {
    if command -v apt &>/dev/null; then
        sudo apt-get update
        sudo apt-get install -y apt-transport-https ca-certificates curl gnupg bash-completion jq
    else
        log::error "Failed to install dependencies"
        exit 1
    fi
}

# Install kubectl
install_kubectl() {
    if command -v kubectl &>/dev/null; then
        log::warn "kubectl already installed, skipping..."
        return
    fi

    curl -fsSL https://pkgs.k8s.io/core:/stable:/v${KUBECTL_VERSION}/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
    sudo chmod 644 /etc/apt/keyrings/kubernetes-apt-keyring.gpg
    echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v${KUBECTL_VERSION}/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list
    sudo chmod 644 /etc/apt/sources.list.d/kubernetes.list
    sudo apt-get update
    sudo apt-get install -y kubectl
    echo "source <(kubectl completion bash)" >>~/.bashrc
}

# Install helm
install_helm() {
    if command -v helm &>/dev/null; then
        log::warn "helm already installed, skipping..."
        return
    fi

    sudo apt-get install curl gpg apt-transport-https --yes
    curl -fsSL https://packages.buildkite.com/helm-linux/helm-debian/gpgkey | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
    echo "deb [signed-by=/usr/share/keyrings/helm.gpg] https://packages.buildkite.com/helm-linux/helm-debian/any/ any main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
    sudo apt-get update
    sudo apt-get install -y helm

    # Add helm repo mirror

    helm repo add stable https://charts.helm.sh/stable || true
    helm repo update || true
}

# Setup kubeconfig directory
setup_kubeconfig() {
    mkdir -p ~/.kube

    if [[ -f ~/.kube/config ]]; then
        log::warn "\~/.kube/config already exists, will backup to ~/.kube/config.bak"
        cp ~/.kube/config ~/.kube/config.bak."$(date +%Y%m%d%H%M%S)"
    fi

    log::info "Kubeconfig directory: ~/.kube/"
    echo "After k3s is deployed, copy kubeconfig:"
    echo "  scp root@<MASTER_IP>:/etc/rancher/k3s/k3s.yaml ~/.kube/config-dev"
    echo "  export KUBECONFIG=~/.kube/config-dev"
}

# Install k9s (optional, TUI tool)
install_k9s() {
    if command -v k9s &>/dev/null; then
        log::warn "k9s already installed, skipping..."
        return
    fi
    curl -sL "https://cdn.gh-proxy.com/https://github.com/derailed/k9s/releases/download/${K9S_VERSION}/k9s_Linux_${ARCH}.tar.gz" | tar -xz -C /tmp k9s
    sudo mv /tmp/k9s /usr/local/bin/
}

# Main
main() {
    ARCH=$(uname -m)
    check_prerequisites
    install_dependencies

    readonly KUBECTL_VERSION="1.35"
    log::info "Installing kubectl ${KUBECTL_VERSION}..."
    install_kubectl
    log::ok "kubectl ${KUBECTL_VERSION} installed"

    log::info "Installing helm..."
    install_helm
    log::ok "helm installed"

    log::info "Setting up kubeconfig directory..."
    setup_kubeconfig
    
    K9S_VERSION=$(curl -s https://api.github.com/repos/derailed/k9s/releases/latest | jq -r .tag_name)
    readonly K9S_VERSION
    if [[ -z $K9S_VERSION ]]; then
        log::error "Failed to get k9s version"
        exit 1
    fi
    log::info "Installing k9s $K9S_VERSION..."
    install_k9s
    log::ok "k9s $K9S_VERSION installed"

    log::info "Installation Summary"
    log::ok "kubectl: $(kubectl version --client | head -1 2>/dev/null || echo 'N/A')"
    log::ok "helm:    $(helm version --short 2>/dev/null || echo 'N/A')"
    log::ok "k9s:     $(k9s version --short 2>/dev/null || echo 'N/A')"
}

main "$@"