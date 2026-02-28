#!/bin/bash

set -e

# 定义颜色变量
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# 检查 sudo 免密权限
check_sudo() {
    echo -e "${YELLOW}>>> [01/05] 检查 sudo 免密权限${NC}"
    if ! sudo -n true 2>/dev/null; then
        echo -e "${RED}错误: 当前用户无 sudo 免密权限${NC}"
        exit 1
    fi
    echo -e "${GREEN}>>> [01/05] 完成${NC}"
}

# 安装 Docker 仓库
add_repo() {
    echo -e "${YELLOW}>>> [02/05] 安装 Docker 仓库${NC}"
    DOCKER_GPG_URL="https://mirrors.aliyun.com/docker-ce/linux/ubuntu/gpg"
    DOCKER_REPO="https://mirrors.aliyun.com/docker-ce/linux/ubuntu"
    curl -fsSL "$DOCKER_GPG_URL" | sudo gpg --yes --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] $DOCKER_REPO $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt update
    echo -e "${GREEN}>>> [02/05] 完成${NC}"
}

# 安装 Docker
install_docker() {
    echo -e "${YELLOW}>>> [03/05] 安装 Docker${NC}"
    sudo apt remove "$(dpkg --get-selections docker.io docker-compose docker-compose-v2 docker-doc podman-docker containerd runc | cut -f1)"
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    cat <<EOF | sudo tee /etc/docker/daemon.json
{
    "exec-opts": [
        "native.cgroupdriver=systemd"
    ],
    "log-driver": "json-file",
    "log-opts": {
        "compress": "true",
        "max-file": "5",
        "max-size": "50m"
    },
    "registry-mirrors": [
        "https://docker.1ms.run",
        "https://docker.m.daocloud.io",
        "https://docker.xuanyuan.me",
        "https://docker.1panel.live",
        "https://hub.rat.dev",
        "https://dockerproxy.net",
        "https://registry.cyou",
        "https://proxy.vvvv.ee"
    ],
    "storage-driver": "overlay2",
    "live-restore": true
}
EOF
    sudo systemctl enable --now docker.service
    sudo systemctl enable --now containerd.service
    sudo groupadd docker 2>/dev/null || true
    sudo usermod -aG docker "$USER"
    echo -e "${GREEN}>>> [03/05] 完成${NC}"
}

# 配置 sysctl
sysctl_config() {
    echo -e "${YELLOW}>>> [04/05] 配置优化容器相关 sysctl 参数${NC}"
    cat <<EOF | sudo tee /etc/sysctl.d/99-containerd.conf
net.bridge.bridge-nf-call-arptables = 1
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
net.ipv4.conf.all.forwarding = 1
EOF
    sudo sysctl --system
    echo -e "${GREEN}>>> [04/05] 完成${NC}"
}

# 验证 Docker 安装
verify_docker() {
    echo -e "${YELLOW}>>> [05/05] 验证 Docker 安装${NC}"
    if ! sudo docker version; then
        echo -e "${RED}错误: Docker 安装失败${NC}"
        exit 1
    fi
    echo -e "${GREEN}>>> [05/05] 完成${NC}"
}

# 主函数
main() {
    check_sudo
    add_repo
    install_docker
    sysctl_config
    verify_docker
    newgrp docker
}

# 执行主函数
main "$@"