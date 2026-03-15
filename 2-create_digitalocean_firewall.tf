resource "digitalocean_firewall" "web" {
  name        = "${var.cluster_name}-k8s-firewall"
  depends_on  = [digitalocean_droplet.worker-node, digitalocean_droplet.control-plane-node]
  droplet_ids = [for item in concat(digitalocean_droplet.worker-node, digitalocean_droplet.control-plane-node) : item.id]

  inbound_rule {
    protocol           = "tcp"
    port_range         = "1-65535"
    source_tags        = var.digitalocean_tags
    source_droplet_ids = [for item in concat(digitalocean_droplet.worker-node, digitalocean_droplet.control-plane-node) : item.id]
  }

  inbound_rule {
    protocol           = "udp"
    port_range         = "1-65535"
    source_tags        = var.digitalocean_tags
    source_droplet_ids = [for item in concat(digitalocean_droplet.worker-node, digitalocean_droplet.control-plane-node) : item.id]
  }

  inbound_rule {
    protocol         = "icmp"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "443"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  inbound_rule {
    protocol         = "udp"
    port_range       = "443"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "6443"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "tcp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "udp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "icmp"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
}