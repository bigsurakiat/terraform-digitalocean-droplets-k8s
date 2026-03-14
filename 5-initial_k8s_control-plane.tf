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
      & 'C:/Windows/System32/OpenSSH/scp.exe' -o StrictHostKeyChecking=no -i $keyPath "root@${digitalocean_droplet.control-plane-node[count.index].ipv4_address}:./join-master.sh" "joiner/join-master.sh"
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