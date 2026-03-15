variable "cilium_kubeproxy_replacement" {
  description = "Cilium kubeProxyReplacement value (true, false, or strict)"
  type        = string
  default     = "true"
}

variable "cilium_ipv4_cidr" {
  description = "Cilium IPv4 Pod CIDR"
  type        = string
  default     = "10.244.0.0/16"
}

variable "cilium_ipv6_cidr" {
  description = "Cilium IPv6 Pod CIDR"
  type        = string
  default     = "2001:db8:42:0::/96"
}

variable "cilium_ipv4_mask_size" {
  description = "Cilium IPv4 mask size"
  type        = number
  default     = 24
}

variable "cilium_ipv6_mask_size" {
  description = "Cilium IPv6 mask size"
  type        = number
  default     = 112
}
variable "do_token" {
  description = "DigitalOcean Personal Access Token"
  type        = string

  validation {
    condition     = var.do_token != null
    error_message = "DigitalOcean PAT Token must not be null!"
  }
}

variable "droplet_images" {
  description = "Droplet Images"
  type        = string
  validation {
    condition     = var.droplet_images != null
    error_message = "Node Images Can't Be Null"
  }
}

variable "control_plane_node_droplet_size" {
  description = "Control Plane Node Droplet Size"
  type        = string
  validation {
    condition     = var.control_plane_node_droplet_size != null
    error_message = "Control Plane Node Droplet Size Can't Be Null"
  }
}

variable "control_plane_node_count" {
  description = "Control Plane Node Counts"
  type        = number
  validation {
    condition     = var.control_plane_node_count % 2 != 0
    error_message = "Control Plane Node must be odd number!"
  }
}

variable "worker_node_droplet_size" {
  description = "Worker Node Droplet Size"
  type        = string
  validation {
    condition     = var.worker_node_droplet_size != null
    error_message = "Worker Node Droplet Size Can't Be Null"
  }
}

variable "worker_nodes_count" {
  description = "Worker Node Counts"
  type        = number
  validation {
    condition     = var.worker_nodes_count != 0
    error_message = "Worker Node must not be zero!"
  }
}

variable "digitalocean_tags" {
  description = "DigitalOcean Droplet Tags"
  type        = list(string)
}

variable "digitalocean_vpc" {
  description = "DigitalOcean VPC"
  type        = string
}

variable "digitalocean_ssh_list" {
  description = "DigitalOcean SSH List"
  type        = list(string)
}

variable "digitalocean_region" {
  description = "DigitalOcean Region"
  type        = string
}

variable "cluster_name" {
  description = "Cluster Name"
  type        = string
  validation {
    condition     = var.cluster_name != null
    error_message = "Cluster Name Shouldn't be Null"
  }
}

variable "container_library" {
  description = "Container Library (e.g. containerD / cri-o)"
  type        = string
  validation {
    condition     = var.container_library != null
    error_message = "Container Library Can't Be Null"
  }
}