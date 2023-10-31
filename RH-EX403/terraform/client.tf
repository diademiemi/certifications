resource "libvirt_volume" "client_disk" {
  name = "${var.client_hostname}_disk"
  pool = var.libvirt_pool
  size = var.client_disk_size
}

resource "libvirt_domain" "client_domain" {
  name   = var.client_hostname
  memory = var.client_memory
  vcpu   = var.client_vcpu

  cpu {
    mode = "host-passthrough"
  }

  autostart = var.client_autostart

  disk {
    volume_id = libvirt_volume.client_disk.id
  }

  dynamic "disk" {
    for_each = var.client_disk_passthroughs
    content {
      block_device = disk.value
    }
  }

  boot_device {
    dev = ["network", "hd"]
  }

  dynamic "network_interface" {
    for_each = var.client_network_interfaces

    content {
      macvtap        = network_interface.value.macvtap
      network_name   = network_interface.value.network_name
      network_id     = network_interface.value.network_id
      hostname       = network_interface.value.hostname
      wait_for_lease = network_interface.value.wait_for_lease
      mac            = network_interface.value.mac // For some providers, this is required
    }
  }

  xml {
    xslt = file("${path.module}/nicmodel.xsl")
  }

  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  graphics {
    type        = "spice"
    listen_type = var.client_spice_server_enabled ? "address" : "none"
  }

}
