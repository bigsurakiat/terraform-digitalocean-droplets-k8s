resource "null_resource" "additional-setup-control-plane-node" {
  depends_on = [null_resource.control-plane-node-initial]
  count      = length(digitalocean_droplet.control-plane-node)
  triggers = {
    droplet_id = digitalocean_droplet.control-plane-node[count.index].id
  }

  provisioner "file" {
    source      = "k8s/metrics-server.yaml"
    destination = "/tmp/metrics-server.yaml"
    connection {
      type        = "ssh"
      user        = "root"
      host        = digitalocean_droplet.control-plane-node[count.index].ipv4_address
      private_key = trimspace(replace(replace(file("~/.ssh/id_rsa"), "\uFEFF", ""), "\r", ""))
    }
  }

  provisioner "file" {
    source      = var.container_library == "crio" ? "scripts/additional-setup-k8s-crio.sh" : "scripts/additional-setup-k8s-containerd.sh"
    destination = "/tmp/additional-setup-k8s.sh"
    connection {
      type        = "ssh"
      user        = "root"
      host        = digitalocean_droplet.control-plane-node[count.index].ipv4_address
      private_key = trimspace(replace(replace(file("~/.ssh/id_rsa"), "\uFEFF", ""), "\r", ""))
    }
  }

  provisioner "remote-exec" {
    inline = [
      "export CILIUM_KUBEPROXY_REPLACEMENT='${var.cilium_kubeproxy_replacement}'",
      "export CILIUM_IPV4_CIDR='${var.cilium_ipv4_cidr}'",
      "export CILIUM_IPV6_CIDR='${var.cilium_ipv6_cidr}'",
      "export CILIUM_IPV4_MASK_SIZE='${var.cilium_ipv4_mask_size}'",
      "export CILIUM_IPV6_MASK_SIZE='${var.cilium_ipv6_mask_size}'",
      "sudo sed -i 's/\\r$//' /tmp/additional-setup-k8s.sh",
      "sudo chmod +x /tmp/additional-setup-k8s.sh",
      "sudo bash /tmp/additional-setup-k8s.sh ${digitalocean_droplet.control-plane-node[count.index].ipv4_address} ${digitalocean_droplet.control-plane-node[count.index].ipv6_address}"
    ]
    connection {
      type        = "ssh"
      user        = "root"
      host        = digitalocean_droplet.control-plane-node[count.index].ipv4_address
      private_key = trimspace(replace(replace(file("~/.ssh/id_rsa"), "\uFEFF", ""), "\r", ""))
      timeout     = "600s"
    }
  }
}