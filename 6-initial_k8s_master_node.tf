resource "null_resource" "master-node-initial" {
  depends_on = [null_resource.additional-setup-control-plane-node, null_resource.master-node-install-k8s]
  count      = length(digitalocean_droplet.master-node)
  triggers = {
    droplet_id = digitalocean_droplet.master-node[count.index].id
  }
  provisioner "file" {
    source      = "config/kubeconfig"
    destination = "/tmp/kubeconfig"
    connection {
      type        = "ssh"
      user        = "root"
      host        = digitalocean_droplet.master-node[count.index].ipv4_address
      private_key = trimspace(replace(replace(file("~/.ssh/id_rsa"), "\uFEFF", ""), "\r", ""))
    }
  }

  provisioner "file" {
    source      = "joiner/join-master.sh"
    destination = "/tmp/join-master.sh"
    connection {
      type        = "ssh"
      user        = "root"
      host        = digitalocean_droplet.master-node[count.index].ipv4_address
      private_key = trimspace(replace(replace(file("~/.ssh/id_rsa"), "\uFEFF", ""), "\r", ""))
    }
  }

  provisioner "file" {
    source      = "k8s/joiner.yaml"
    destination = "/tmp/master-join.yaml"
    connection {
      type        = "ssh"
      user        = "root"
      host        = digitalocean_droplet.master-node[count.index].ipv4_address
      private_key = trimspace(replace(replace(file("~/.ssh/id_rsa"), "\uFEFF", ""), "\r", ""))
    }
  }

  provisioner "remote-exec" {
    inline = [
      "export KUBEADM_API_ENDPOINT=\"$(cat /tmp/join-master.sh | awk '{print $3}')\"",
      "export KUBEADM_JOIN_CACERT=\"$(cat /tmp/join-master.sh | awk '{print $7}')\"",
      "export KUBEADM_JOIN_TOKEN=\"$(cat /tmp/join-master.sh | awk '{print $5}')\"",
      "sed -i -e \"s/{{control-plane-endpoint}}/$KUBEADM_API_ENDPOINT/g\" /tmp/master-join.yaml",
      "sed -i -e \"s/{{control-plane-join-token}}/$KUBEADM_JOIN_TOKEN/g\" /tmp/master-join.yaml",
      "sed -i -e \"s/{{control-plane-ca-cert-hash}}/$KUBEADM_JOIN_CACERT/g\" /tmp/master-join.yaml",
      "sed -i -e \"s/{{node-ipv4}}/${digitalocean_droplet.master-node[count.index].ipv4_address}/g\" /tmp/master-join.yaml",
      "sed -i -e \"s/{{node-ipv6}}/${digitalocean_droplet.master-node[count.index].ipv6_address}/g\" /tmp/master-join.yaml",
      "kubeadm join --config=/tmp/master-join.yaml"
    ]
    connection {
      type        = "ssh"
      user        = "root"
      host        = digitalocean_droplet.master-node[count.index].ipv4_address
      private_key = trimspace(replace(replace(file("~/.ssh/id_rsa"), "\uFEFF", ""), "\r", ""))
      timeout     = "600s"
    }
  }
}