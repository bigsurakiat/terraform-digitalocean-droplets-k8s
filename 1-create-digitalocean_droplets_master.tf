resource "digitalocean_droplet" "master-node" {
  depends_on = [digitalocean_droplet.control-plane-node]
  count      = var.master_nodes_count
  name       = "${var.cluster_name}-master-${count.index + 1}"
  image      = var.droplet_images
  region     = var.digitalocean_region
  size       = var.master_node_droplet_size
  vpc_uuid   = var.digitalocean_vpc
  ssh_keys   = var.digitalocean_ssh_list
  ipv6       = true
  tags       = var.digitalocean_tags
}