#!/bin/bash

user_name=${1:-"sudoer"}
custom_cidr=${2:-"192.168.8.150/24"}
custom_gateway=${3:-"192.168.8.1"}
custom_nameserver=${4:-$3}
custom_ip=${custom_cidr%%/*}

sudo passwd -d vagrant 1>/dev/null
sudo sed -i 's/^[[:space:]#]*PasswordAuthentication[[:space:]]\+yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo systemctl restart ssh.service 1>/dev/null
if ! id "$user_name" &>/dev/null; then
sudo useradd -m -s /bin/bash "$user_name"
sudo mkdir -p /home/"$user_name"/.ssh
sudo mv /tmp/authorized_keys /home/"$user_name"/.ssh/authorized_keys
sudo chown -R "$user_name":"$user_name" /home/"$user_name"/.ssh
sudo chmod 700 /home/"$user_name"/.ssh
sudo chmod 600 /home/"$user_name"/.ssh/authorized_keys
echo "$user_name ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/"$user_name" > /dev/null
fi
sudo timedatectl set-timezone Asia/Shanghai
sudo sed -i 's|http://.*.ubuntu.com/ubuntu/|https://mirrors.aliyun.com/ubuntu/|g' /etc/apt/sources.list.d/ubuntu.sources
sudo apt update && sudo apt upgrade -y
sudo rm -f /etc/netplan/*.yaml
cat <<EOF | sudo tee /etc/netplan/99-custom.yaml &>/dev/null
network:
  version: 2
  ethernets:
    eth0:
      addresses: [$custom_cidr]
      routes:
        - to: default
          via: $custom_gateway
      nameservers:
        addresses: [$custom_nameserver]
EOF
chmod 600 /etc/netplan/99-custom.yaml
cat <<EOF | sudo tee /etc/hosts &>/dev/null
127.0.0.1 localhost
$custom_ip $HOSTNAME

::1     ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
EOF
sudo poweroff