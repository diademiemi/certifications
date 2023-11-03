variable "libvirt_uri" {
  type    = string
  default = "qemu:///system"
}

variable "domain" {
  type    = string
  default = ""
}

variable "network" {
  type    = string
  default = ""
}

variable "network_name" {
  type    = string
  default = ""
}

variable "network_mode" {
  type    = string
  default = ""
}

variable "libvirt_pool" {
  type    = string
  default = "default"
}
