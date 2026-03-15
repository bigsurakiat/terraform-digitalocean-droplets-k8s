resource "null_resource" "control-plane-node-initial" {
  depends_on = [null_resource.control-plane-node-install-k8s]
  count      = length(digitalocean_droplet.control-plane-node)
  triggers = {
    droplet_id = digitalocean_droplet.control-plane-node[count.index].id
  }
  provisioner "file" {
    source      = var.container_library == "crio" ? "scripts/initial-k8s-control-plane-crio.sh" : "scripts/initial-k8s-control-plane-containerd.sh"
    destination = "/tmp/initial-k8s-control-plane.sh"
    connection {
      type        = "ssh"
      user        = "root"
      host        = digitalocean_droplet.control-plane-node[count.index].ipv4_address
      private_key = trimspace(replace(replace(file("~/.ssh/id_rsa"), "\uFEFF", ""), "\r", ""))
    }
  }

  provisioner "remote-exec" {
    inline = [
      "sudo sed -i 's/\\r$//' /tmp/initial-k8s-control-plane.sh",
      "sudo chmod +x /tmp/initial-k8s-control-plane.sh",
      "sudo bash /tmp/initial-k8s-control-plane.sh ${digitalocean_droplet.control-plane-node[count.index].ipv4_address} ${digitalocean_droplet.control-plane-node[count.index].ipv6_address} ${var.cluster_name}"
    ]
    connection {
      type        = "ssh"
      user        = "root"
      host        = digitalocean_droplet.control-plane-node[count.index].ipv4_address
      private_key = trimspace(replace(replace(file("~/.ssh/id_rsa"), "\uFEFF", ""), "\r", ""))
      timeout     = "600s"
    }
  }

  provisioner "local-exec" {
    interpreter = ["PowerShell", "-NoProfile", "-Command"]
    command = <<-EOT
      $raw = Get-Content -Raw "$HOME/.ssh/id_rsa"
      $m = [regex]::Match($raw, '-----BEGIN OPENSSH PRIVATE KEY-----(?<body>[\s\S]*?)-----END OPENSSH PRIVATE KEY-----')
      if (-not $m.Success) { throw 'Could not parse OpenSSH private key block from ~/.ssh/id_rsa' }
      $body = ($m.Groups['body'].Value -replace '\s', '')
      $chunks = [System.Collections.Generic.List[string]]::new()
      for ($i = 0; $i -lt $body.Length; $i += 70) {
        $len = [Math]::Min(70, $body.Length - $i)
        $chunks.Add($body.Substring($i, $len))
      }
      $normalized = "-----BEGIN OPENSSH PRIVATE KEY-----`n$($chunks -join "`n")`n-----END OPENSSH PRIVATE KEY-----`n"
      $keyPath = Join-Path $env:TEMP 'tf_id_rsa'
      New-Item -ItemType Directory -Force -Path 'joiner' | Out-Null
      [System.IO.File]::WriteAllText($keyPath, $normalized, (New-Object System.Text.UTF8Encoding($false)))
      & 'C:/Windows/System32/OpenSSH/scp.exe' -o StrictHostKeyChecking=no -i $keyPath "root@${digitalocean_droplet.control-plane-node[count.index].ipv4_address}:./join-control-plane.sh" "joiner/join-control-plane.sh"
      if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    EOT
  }

  provisioner "local-exec" {
    interpreter = ["PowerShell", "-NoProfile", "-Command"]
    command = <<-EOT
      $raw = Get-Content -Raw "$HOME/.ssh/id_rsa"
      $m = [regex]::Match($raw, '-----BEGIN OPENSSH PRIVATE KEY-----(?<body>[\s\S]*?)-----END OPENSSH PRIVATE KEY-----')
      if (-not $m.Success) { throw 'Could not parse OpenSSH private key block from ~/.ssh/id_rsa' }
      $body = ($m.Groups['body'].Value -replace '\s', '')
      $chunks = [System.Collections.Generic.List[string]]::new()
      for ($i = 0; $i -lt $body.Length; $i += 70) {
        $len = [Math]::Min(70, $body.Length - $i)
        $chunks.Add($body.Substring($i, $len))
      }
      $normalized = "-----BEGIN OPENSSH PRIVATE KEY-----`n$($chunks -join "`n")`n-----END OPENSSH PRIVATE KEY-----`n"
      $keyPath = Join-Path $env:TEMP 'tf_id_rsa'
      New-Item -ItemType Directory -Force -Path 'joiner' | Out-Null
      [System.IO.File]::WriteAllText($keyPath, $normalized, (New-Object System.Text.UTF8Encoding($false)))
      & 'C:/Windows/System32/OpenSSH/scp.exe' -o StrictHostKeyChecking=no -i $keyPath "root@${digitalocean_droplet.control-plane-node[count.index].ipv4_address}:./join-worker.sh" "joiner/join-worker.sh"
      if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    EOT
  }

  provisioner "local-exec" {
    interpreter = ["PowerShell", "-NoProfile", "-Command"]
    command = <<-EOT
      $raw = Get-Content -Raw "$HOME/.ssh/id_rsa"
      $m = [regex]::Match($raw, '-----BEGIN OPENSSH PRIVATE KEY-----(?<body>[\s\S]*?)-----END OPENSSH PRIVATE KEY-----')
      if (-not $m.Success) { throw 'Could not parse OpenSSH private key block from ~/.ssh/id_rsa' }
      $body = ($m.Groups['body'].Value -replace '\s', '')
      $chunks = [System.Collections.Generic.List[string]]::new()
      for ($i = 0; $i -lt $body.Length; $i += 70) {
        $len = [Math]::Min(70, $body.Length - $i)
        $chunks.Add($body.Substring($i, $len))
      }
      $normalized = "-----BEGIN OPENSSH PRIVATE KEY-----`n$($chunks -join "`n")`n-----END OPENSSH PRIVATE KEY-----`n"
      $keyPath = Join-Path $env:TEMP 'tf_id_rsa'
      New-Item -ItemType Directory -Force -Path 'config' | Out-Null
      [System.IO.File]::WriteAllText($keyPath, $normalized, (New-Object System.Text.UTF8Encoding($false)))
      & 'C:/Windows/System32/OpenSSH/scp.exe' -o StrictHostKeyChecking=no -i $keyPath "root@${digitalocean_droplet.control-plane-node[count.index].ipv4_address}:./kubeconfig" "config/kubeconfig"
      if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    EOT
  }
}

resource "null_resource" "control-plane-node-join" {
  depends_on = [null_resource.additional-setup-control-plane-node, null_resource.control-plane-node-install-k8s]
  count      = length(digitalocean_droplet.control-plane-node) > 1 ? length(digitalocean_droplet.control-plane-node) - 1 : 0
  triggers = {
    droplet_id = digitalocean_droplet.control-plane-node[count.index + 1].id
  }
  provisioner "file" {
    source      = "config/kubeconfig"
    destination = "/tmp/kubeconfig"
    connection {
      type        = "ssh"
      user        = "root"
      host        = digitalocean_droplet.control-plane-node[count.index + 1].ipv4_address
      private_key = trimspace(replace(replace(file("~/.ssh/id_rsa"), "\uFEFF", ""), "\r", ""))
    }
  }

  provisioner "file" {
    source      = "joiner/join-control-plane.sh"
    destination = "/tmp/join-control-plane.sh"
    connection {
      type        = "ssh"
      user        = "root"
      host        = digitalocean_droplet.control-plane-node[count.index].ipv4_address
      private_key = trimspace(replace(replace(file("~/.ssh/id_rsa"), "\uFEFF", ""), "\r", ""))
    }
  }

  provisioner "file" {
    source      = "k8s/joiner.yaml"
    destination = "/tmp/control-plane-join.yaml"
    connection {
      type        = "ssh"
      user        = "root"
      host        = digitalocean_droplet.control-plane-node[count.index + 1].ipv4_address
      private_key = trimspace(replace(replace(file("~/.ssh/id_rsa"), "\uFEFF", ""), "\r", ""))
    }
  }

  provisioner "remote-exec" {
    inline = [
      "export KUBEADM_API_ENDPOINT=\"$(cat /tmp/join-control-plane.sh | awk '{print $3}')\"",
      "export KUBEADM_JOIN_CACERT=\"$(cat /tmp/join-control-plane.sh | awk '{print $7}')\"",
      "export KUBEADM_JOIN_TOKEN=\"$(cat /tmp/join-control-plane.sh | awk '{print $5}')\"",
      "sed -i -e \"s/{{control-plane-endpoint}}/$KUBEADM_API_ENDPOINT/g\" /tmp/control-plane-join.yaml",
      "sed -i -e \"s/{{control-plane-join-token}}/$KUBEADM_JOIN_TOKEN/g\" /tmp/control-plane-join.yaml",
      "sed -i -e \"s/{{control-plane-ca-cert-hash}}/$KUBEADM_JOIN_CACERT/g\" /tmp/control-plane-join.yaml",
      "sed -i -e \"s/{{node-ipv4}}/${digitalocean_droplet.control-plane-node[count.index + 1].ipv4_address}/g\" /tmp/control-plane-join.yaml",
      "sed -i -e \"s/{{node-ipv6}}/${digitalocean_droplet.control-plane-node[count.index + 1].ipv6_address}/g\" /tmp/control-plane-join.yaml",
      "kubeadm join --config=/tmp/control-plane-join.yaml"
    ]
    connection {
      type        = "ssh"
      user        = "root"
      host        = digitalocean_droplet.control-plane-node[count.index + 1].ipv4_address
      private_key = trimspace(replace(replace(file("~/.ssh/id_rsa"), "\uFEFF", ""), "\r", ""))
      timeout     = "600s"
    }
  }
}
