resource "null_resource" "master-node-prometheus-setup" {
  depends_on = [null_resource.master-node-initial, null_resource.worker-node-initial]
  count      = length(digitalocean_droplet.master-node)
  triggers = {
    droplet_id = digitalocean_droplet.master-node[count.index].id
  }

  provisioner "file" {
    source      = "k8s/prometheus-stack-values.yaml"
    destination = "/tmp/prometheus-stack-values.yaml"
    connection {
      type        = "ssh"
      user        = "root"
      host        = digitalocean_droplet.master-node[count.index].ipv4_address
      private_key = trimspace(replace(replace(file("~/.ssh/id_rsa"), "\uFEFF", ""), "\r", ""))
    }
  }

  provisioner "remote-exec" {
    inline = [
      "sed -i \"s|{{control-plane-node}}|${digitalocean_droplet.control-plane-node[count.index].name}|g\" /tmp/prometheus-stack-values.yaml",
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

resource "null_resource" "master-node-add-digitalocean-csi" {
  depends_on = [null_resource.master-node-prometheus-setup, null_resource.worker-node-initial]
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
    source      = "k8s/digitalocean-secret.yaml"
    destination = "/tmp/digitalocean-secret.yaml"
    connection {
      type        = "ssh"
      user        = "root"
      host        = digitalocean_droplet.master-node[count.index].ipv4_address
      private_key = trimspace(replace(replace(file("~/.ssh/id_rsa"), "\uFEFF", ""), "\r", ""))
    }
  }

  provisioner "remote-exec" {
    inline = [
      "sed -i -e \"s|{{access-token}}|${var.do_token}|g\" /tmp/digitalocean-secret.yaml",
      "sed -i \"s|{{control-plane-node}}|${digitalocean_droplet.control-plane-node[count.index].name}|g\" /tmp/prometheus-stack-values.yaml",
    ]
    connection {
      type        = "ssh"
      user        = "root"
      host        = digitalocean_droplet.master-node[count.index].ipv4_address
      private_key = trimspace(replace(replace(file("~/.ssh/id_rsa"), "\uFEFF", ""), "\r", ""))
      timeout     = "600s"
    }
  }

  provisioner "file" {
    source      = "scripts/additional-setup-master-k8s.sh"
    destination = "/tmp/additional-setup-master-k8s.sh"
    connection {
      type        = "ssh"
      user        = "root"
      host        = digitalocean_droplet.master-node[count.index].ipv4_address
      private_key = trimspace(replace(replace(file("~/.ssh/id_rsa"), "\uFEFF", ""), "\r", ""))
    }
  }

  provisioner "remote-exec" {
    inline = [
      "sudo sed -i 's/\\r$//' /tmp/additional-setup-master-k8s.sh",
      "sudo chmod +x /tmp/additional-setup-master-k8s.sh",
      "sudo bash /tmp/additional-setup-master-k8s.sh"
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

resource "null_resource" "master-node-add-cilium-lb-ppols" {
  depends_on = [null_resource.master-node-add-digitalocean-csi, null_resource.worker-node-initial]
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
    source      = "k8s/cilium-lb-ip-pool.yaml"
    destination = "/tmp/cilium-lb-ip-pool.yaml"
    connection {
      type        = "ssh"
      user        = "root"
      host        = digitalocean_droplet.master-node[count.index].ipv4_address
      private_key = trimspace(replace(replace(file("~/.ssh/id_rsa"), "\uFEFF", ""), "\r", ""))
    }
  }

  provisioner "remote-exec" {
    inline = [
      "sed -i -e \"s|{{ipv4-ip}}|${digitalocean_droplet.master-node[count.index].ipv4_address}|g\" /tmp/cilium-lb-ip-pool.yaml",
      "sed -i -e \"s|{{ipv6-ip}}|${digitalocean_droplet.master-node[count.index].ipv6_address}|g\" /tmp/cilium-lb-ip-pool.yaml",
    ]
    connection {
      type        = "ssh"
      user        = "root"
      host        = digitalocean_droplet.master-node[count.index].ipv4_address
      private_key = trimspace(replace(replace(file("~/.ssh/id_rsa"), "\uFEFF", ""), "\r", ""))
      timeout     = "600s"
    }
  }

  provisioner "remote-exec" {
    inline = [
      "export KUBECONFIG=/tmp/kubeconfig",
      "kubectl apply -f /tmp/cilium-lb-ip-pool.yaml"
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