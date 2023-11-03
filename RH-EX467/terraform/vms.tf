module "vm" {
  source     = "diademiemi/vm/libvirt"
  version    = "4.7.1"
  depends_on = [
    libvirt_network.network
    ]

  for_each = { for vm in var.vms : vm.hostname => vm }

  hostname = each.value.hostname
  domain   = each.value.domain

  vcpu   = each.value.vcpu
  memory = each.value.memory

  autostart = each.value.autostart

  cloudinit_image = each.value.cloudinit_image

  disk_size         = each.value.disk_size
  libvirt_pool      = each.value.libvirt_pool
  disk_passthroughs = coalesce(each.value.disk_passthroughs, [])
  iso_urls          = coalesce(each.value.iso_urls, [])
  iso_paths         = coalesce(each.value.iso_paths, [])

  ssh_keys              = each.value.ssh_keys
  password_auth         = coalesce(each.value.password_auth, false)
  root_password         = coalesce(each.value.root_password, "")
  allow_root_ssh_pwauth = coalesce(each.value.allow_root_ssh_pwauth, false)
  disable_root          = coalesce(each.value.disable_root, true)

  # libvirt_external_interface = each.value.libvirt_external_interface
  # mac = each.value.mac

  network_interfaces = coalesce(each.value.network_interfaces, [])

  spice_server_enabled = coalesce(each.value.spice_server_enabled, false)

  cloudinit_use_user_data = coalesce(each.value.cloudinit_use_user_data, true)
  cloudinit_use_network_data = coalesce(each.value.cloudinit_use_network_data, true)
  cloudinit_custom_user_data = coalesce(each.value.cloudinit_custom_user_data, "# No custom user data\n")
  cloudinit_custom_network_data = coalesce(each.value.cloudinit_custom_network_data, "# No network user data\n")


  ansible_host   = each.value.ansible_host
  ansible_groups = each.value.ansible_groups
  ansible_user   = each.value.ansible_user
  ansible_ssh_pass = each.value.ansible_ssh_pass

}
