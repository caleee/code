#!/bin/bash

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}请以 root 用户运行此脚本${NC}"
        exit 1
    fi
}

usage() {
    echo -e "${YELLOW}用法:${NC} $0 <VM编号> <CPU核心数> <内存(GB)> <磁盘大小(GB)> <服务器ID>"
    echo -e "${YELLOW}示例:${NC} $0 151 2 4 20 19"
    exit 1
}

check_args() {
    if [ "$#" -ne 5 ]; then
        echo -e "${RED}参数数量错误！${NC}"
        usage
    fi

    for arg in "$@"; do
        if ! [[ "$arg" =~ ^[0-9]+$ ]]; then
            echo -e "${RED}参数 '$arg' 必须是纯数字！${NC}"
            usage
        fi
    done
}

create_vm() {
    export VM_ID="$1"
    export VM_NAME="u$VM_ID"
    export VM_CORES="$2"
    export VM_MEMORY_G="$3"
    export VM_MEMORY="$((VM_MEMORY_G * 1024))"
    export VM_SIZE="$4"G
    export VM_SERVER_ID="$5"
    export STORAGE="local-lvm"
    export IMAGE="noble-server-cloudimg-amd64.img"
    export VM_USER="sudoer"
    export VM_USER_KEY="$HOME/.ssh/sudoer.pub"
    export IPv4_CIDR="10.10.$VM_SERVER_ID.$VM_ID/16"
    export IPv4_GW="10.10.0.1"
    export IPv6="dhcp"
    export NAMESERVER="10.10.0.1"

    if [ ! -f "$VM_USER_KEY" ]; then
        echo -e "${RED}SSH公钥文件 $VM_USER_KEY 不存在！${NC}"
        echo -e "${YELLOW}请先创建该文件，例如：${NC}"
        echo -e "${YELLOW}ssh-keygen -t rsa -b 4096 -f ~/.ssh/sudoer -N ''${NC}"
        exit 1
    fi

    qm create "$VM_ID" --name "$VM_NAME" --memory "$VM_MEMORY" --cores "$VM_CORES" --net0 virtio,bridge=vmbr0
    qm importdisk "$VM_ID" /var/lib/vz/template/iso/$IMAGE $STORAGE
    qm set "$VM_ID" --scsihw virtio-scsi-pci --scsi0 $STORAGE:vm-"$VM_ID"-disk-0
    qm resize "$VM_ID" scsi0 "$VM_SIZE"
    qm set "$VM_ID" --ide2 $STORAGE:cloudinit
    qm set "$VM_ID" --boot c --bootdisk scsi0
    qm set "$VM_ID" --serial0 socket --vga serial0
    qm set "$VM_ID" --agent enabled=1
    qm set "$VM_ID" --ciuser "$VM_USER"
    qm set "$VM_ID" --sshkeys "$VM_USER_KEY"
    qm set "$VM_ID" --ipconfig0 ip="$IPv4_CIDR",gw="$IPv4_GW",ip6="$IPv6"
    qm set "$VM_ID" --nameserver "$NAMESERVER"
}

main() {
    check_root
    check_args "$@"
    create_vm "$@"
    echo -e "${GREEN}VM $VM_ID ($VM_NAME) 创建完成！${NC}"
}

main "$@"