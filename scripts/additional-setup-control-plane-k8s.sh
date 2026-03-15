# Install DigitalOcean Volumes
export KUBECONFIG=/tmp/kubeconfig

curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
sudo chmod 700 get_helm.sh
sudo ./get_helm.sh
sudo cp /usr/local/bin/helm /usr/bin/helm

kubectl apply -f /tmp/digitalocean-secret.yaml -n kube-system
export CSI_DO_VERSION=$(wget -qO - "https://api.github.com/repos/digitalocean/csi-digitalocean/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
kubectl apply -fhttps://raw.githubusercontent.com/digitalocean/csi-digitalocean/master/deploy/kubernetes/releases/csi-digitalocean-$CSI_DO_VERSION/{crds.yaml,driver.yaml,snapshot-controller.yaml}

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm upgrade --install --namespace kube-system -f /tmp/prometheus-stack-values.yaml prometheus-stack prometheus-community/kube-prometheus-stack