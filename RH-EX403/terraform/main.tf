resource "libvirt_network" "network" {
  name      = var.network_name
  mode      = var.network_mode
  domain    = var.network_name
  addresses = ["${var.network}"]

  dhcp {
    enabled = false
  }
}
  