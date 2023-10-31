
variable "client_hostname" {
  type    = string
  default = "libvirt_server"
}

variable "client_memory" {
  type    = number
  default = 2048
}

variable "client_vcpu" {
  type    = number
  default = 2
}

variable "client_disk_size" {
  type    = number
  default = 64424509440 # 60GB
}

variable "client_autostart" {
  type    = bool
  default = true
}

variable "client_disk_passthroughs" {
  type    = list(string)
  default = []
}

variable "client_network_interfaces" {
  type = list(object({
    name           = optional(string)
    network_id     = optional(string)
    network_name   = optional(string)
    macvtap        = optional(string)
    hostname       = optional(string)
    wait_for_lease = optional(bool)

    dhcp        = optional(bool)
    ip          = optional(string)
    gateway     = optional(string)
    nameservers = optional(list(string))
    mac         = optional(string)

    additional_routes = optional(list(object({
      network = string
      gateway = string
    })))
  }))
  default = []
}

variable "client_spice_server_enabled" {
  type    = bool
  default = false
}
