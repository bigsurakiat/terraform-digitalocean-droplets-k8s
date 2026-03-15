resource "digitalocean_droplet" "control-plane-node" {
  image    = var.droplet_images
  count    = var.control_plane_node_count
  name     = "${var.cluster_name}-control-plane-${count.index + 1}"
  region   = var.digitalocean_region
  size     = var.control_plane_node_droplet_size
  vpc_uuid = var.digitalocean_vpc
  ssh_keys = var.digitalocean_ssh_list
  ipv6     = true
  tags     = var.digitalocean_tags
}