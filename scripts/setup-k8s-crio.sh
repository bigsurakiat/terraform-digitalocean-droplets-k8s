#!/bin/bash

# CentOS-based Linux K8s Installation with Cilium Enabled on CRI-O
# This scripts for Control Plane / Worker Node

sudo mkdir -p /etc/systemd/system/user@.service.d
cat <<EOF | sudo tee /etc/systemd/system/user@.service.d/delegate.conf
[Service]
Delegate=cpu cpuset io memory pids
EOF
sudo systemctl daemon-reload

dnf makecache --refresh
sudo dnf install yum-plugin-versionlock -y
sudo dnf install -y wget

sudo timedatectl set-timezone America/Los_Angeles

#2) Disable swap & add kernel settings

sudo setenforce 0
sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

sudo yum -y install epel-release
sudo yum -y update

sudo dnf install htop -y
#3) Add  kernel settings & Enable IP tables(CNI Prerequisites)

sudo modprobe overlay
sudo modprobe br_netfilter

cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

cat <<EOF | sudo tee /etc/sysctl.d/kubernetes.conf
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv6.conf.all.forwarding=1
EOF

sudo sysctl --system

# Swap is disabled for Kubernetes best practices
# (If a swapfile exists, it should be turned off and removed)
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab

sudo dnf update -y
sudo dnf install ca-certificates curl gnupg -y

# CRI-O Installation
cat <<EOF | tee /etc/yum.repos.d/cri-o.repo
[cri-o]
name=CRI-O
baseurl=https://pkgs.k8s.io/addons:/cri-o:/prerelease:/main/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/addons:/cri-o:/prerelease:/main/rpm/repodata/repomd.xml.key
EOF
    
# Install CNI Support
export CNI_VERSION=$(wget -qO - "https://api.github.com/repos/containernetworking/plugins/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
mkdir -p /opt/cni/bin/
curl -L -O https://github.com/containernetworking/plugins/releases/download/$CNI_VERSION/cni-plugins-linux-amd64-$CNI_VERSION.tgz
sudo tar Cxzvf /opt/cni/bin/ cni-plugins-linux-amd64-$CNI_VERSION.tgz

#5) Installing kubeadm, kubelet and kubectl

# Update the apt package index and install packages needed to use the Kubernetes apt repository:

sudo dnf update
sudo dnf install -y ca-certificates curl

cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.34/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.34/rpm/repodata/repomd.xml.key
exclude=kubelet kubeadm kubectl
EOF

# Update apt package index, install kubelet, kubeadm and kubectl, and pin their version:

sudo dnf update
sudo dnf install -y cri-o cri-tools

# apt-mark hold will prevent the package from being automatically upgraded or removed.

sudo dnf versionlock cri-o

# Additional Setup for CRI-O
cat <<EOF | sudo tee /etc/crio/crio.conf.d/02-cgroup-manager.conf
[crio.api]
default_capabilities = [
	"CHOWN",
	"DAC_OVERRIDE",
	"FSETID",
	"FOWNER",
	"SETGID",
	"SETUID",
	"SETPCAP",
	"NET_BIND_SERVICE",
	"KILL",
]
[crio.network]
plugin_dirs = [
	"/opt/cni/bin",
]
[crio.runtime]
conmon_cgroup = "pod"
cgroup_manager = "cgroupfs"
EOF

# Enable and start kubelet service
sudo systemctl daemon-reload
sudo systemctl enable --now crio
sudo systemctl start crio

# Initialize Kubernetes
## This Installation without Kube Proxy
## We Use Cilium Instead of Kube-Proxy

sudo dnf install yum-plugin-versionlock -y

dnf makecache
sudo yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
sudo dnf versionlock kubelet kubeadm kubectl
sudo systemctl enable --now kubelet
sudo systemctl enable --now kubelet.service