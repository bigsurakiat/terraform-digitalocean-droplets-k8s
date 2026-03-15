#!/bin/bash

# Rocky Linux K8s Installation with Cilium Enabled on CRI-O
# This scripts for Control Plane Node

if [ -z "$1" ] && [ -z "$2" ] && [ -z "$3" ]
then
  echo "IP Address is Empty!"
  exit 1
fi

export CONTROL_PLANE_NODE_IP=$1
export CONTROL_PLANE_NODE_IPV6=$2
export NODE_NAME=$3

cat <<EOF | sudo tee cluster-config.yaml
apiVersion: kubeadm.k8s.io/v1beta4
kind: InitConfiguration
localAPIEndpoint:
    advertiseAddress: ${CONTROL_PLANE_NODE_IP}
    bindPort: 6443
nodeRegistration:
    criSocket: unix:///run/containerd/containerd.sock
    kubeletExtraArgs:
        - name: node-ip
          value: ${CONTROL_PLANE_NODE_IP},${CONTROL_PLANE_NODE_IPV6}
skipPhases:
  - addon/kube-proxy
---
apiVersion: kubeadm.k8s.io/v1beta4
kind: ClusterConfiguration
apiServer:
    certSANs:
    - "${CONTROL_PLANE_NODE_IP}"
controlPlaneEndpoint: "${CONTROL_PLANE_NODE_IP}:6443"
clusterName: "${NODE_NAME}"
networking:
    podSubnet: 10.131.0.0/16,2001:db8:42:0::/96
    serviceSubnet: 10.45.0.0/16,2001:db8:42:1::/112
controllerManager:
    extraArgs:
        - name: node-cidr-mask-size-ipv4
          value: "24"
        - name: node-cidr-mask-size-ipv6
          value: "112"
kubernetesVersion: "stable"
---
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
failSwapOn: true
cgroupDriver: cgroupfs
EOF

kubeadm init \
  --ignore-preflight-errors=NumCPU \
  --config=cluster-config.yaml \
  --upload-certs \

mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf ${HOME}/.kube/config
chown $(id -u):$(id -g) ${HOME}/.kube/config

sudo echo $(kubeadm token create --print-join-command) --certificate-key $(sudo kubeadm init phase upload-certs --upload-certs --config cluster-config.yaml | grep -vw -e certificate -e Namespace) >> join-control-plane.sh
kubeadm token create --print-join-command >> ./join-worker.sh
cp -i /etc/kubernetes/admin.conf ./kubeconfig