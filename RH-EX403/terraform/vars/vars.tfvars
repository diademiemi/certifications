domain       = "terraform.test"
network      = "192.168.21.0/24"
network_name = "terraform"
network_mode = "nat"

vms = [
  {
    hostname = "vyos"

    vcpu   = 2
    memory = 4096

    cloudinit_image = "/tmp/vyos-1.5.0-cloud-init-5G-qemu.qcow2"

    disk_size = 42949672960 # 40 GiB

    password_auth         = true
    root_password         = "root"
    disable_root          = false
    allow_root_ssh_pwauth = true
    ssh_keys              = []

    domain = "terraform.test"
  
    network_interfaces = [
      {
        name         = "eth0"
        network_name = "terraform"

        dhcp = false
      }
    ]

    spice_server_enabled = false

    cloudinit_custom_user_data = <<-EOT

vyos_config_commands:
  - set system host-name 'vyos'
  - set interfaces ethernet eth0 address '192.168.21.2/24'
  - set interfaces ethernet eth0 description 'Libvirt network'
  - set protocols static route 0.0.0.0/0 next-hop '192.168.21.1'
  - set service dns forwarding listen-address '192.168.21.2'
  - set service dns forwarding system
  - set service ssh port '22'
  - set service ssh listen-address '192.168.21.2'
  - set system static-host-mapping host-name vyos.terraform.test inet '192.168.21.2'
  - set system static-host-mapping host-name vyos.terraform.test alias 'vyos.terraform.test'
  - set system static-host-mapping host-name foreman.terraform.test inet '192.168.21.51'
  - set system static-host-mapping host-name foreman.terraform.test alias 'foreman.terraform.test'
  - set system name-server '9.9.9.9'

EOT

    ansible_groups   = ["networking"]
    ansible_user     = "vyos"
    ansible_ssh_pass = "vyos"
    ansible_host     = "192.168.21.2"
  },
  {
    hostname = "foreman"

    vcpu   = 8
    memory = 20480

    cloudinit_image = "https://cloud.centos.org/centos/8-stream/x86_64/images/CentOS-Stream-GenericCloud-8-latest.x86_64.qcow2"

    # Foreman/Katello is HUGE. 250GiB disk
    disk_size = 268435456000 # 250 GiB

    password_auth         = true
    root_password         = "root"
    disable_root          = false
    allow_root_ssh_pwauth = true
    ssh_keys              = []

    domain = "terraform.test"

    network_interfaces = [
      {
        name         = "ens3"
        network_name = "terraform"

        dhcp = false

        ip      = "192.168.21.51/24"
        gateway = "192.168.21.1"

        nameservers = [
          "192.168.21.2"
        ]
      }
    ]

    spice_server_enabled = false

    # CentOS uses a custom cloud-init network data version 1 still
    cloudinit_use_network_data = false
    cloudinit_custom_network_data = <<-EOT

version: 1
config:
  - type: physical
    name: eth0
    subnets:
      - type: static
        address: 192.168.21.51/24
        gateway: 192.168.21.1
  - type: nameserver
    search:
      - terraform.test
    address:
      - 192.168.21.2
EOT

    ansible_groups   = ["linux", "centos", "ipaserver"]
    ansible_user     = "root"
    ansible_ssh_pass = "root"
  }
]

client_hostname = "client"

client_vcpu   = 4
client_memory = 8192

client_network_interfaces = [
  {
    network_name = "terraform"
  }
]

client_spice_server_enabled = false
