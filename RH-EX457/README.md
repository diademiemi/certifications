# EX457: Red Hat Certified Specialist in Ansible Network Automation exam
This exam is mainly focused on knowledge of networking and automating network devices with Ansible. It requires knowledge of Ansible, but more importantly, knowledge of networking and network devices using Cisco IOS and VyOS. The exam leans heavily into using Jinja2 templates to generate configurations for network devices. Getting efficient with Jinja2 can save a lot of time on this exam.

VLANs, BGP and OSPF are listed as objectives. I have written code to configure these with Ansible that you can find in this directory. In the exam I will be mostly using the `ios_config` and `vyos_config` modules instead of fancy modules like `ios_vlan` and `vyos_bgp`. While nice, these are not required to pass the exam and will only cost me time. If you aren't as familiar with IOS and VyOS, it couldn't hurt to learn these instead, but I already have a lot of experience with IOS and VyOS and knew the commands to configure these technologies through that. I have put a list of these commands at the bottom of this README.  

I have access to a network lab with many Cisco switches at my old college, I returned here to practice for this exam. This directory will contain code I ran on these hosts to practice for the EX457 exam.  

# Thoughts after exam
This exam focuses heavily on Ansible, with less focus than I expected on networking. While you definitely need to know networking, you don't need to know it in-depth. I would recommend to focus on Ansible and Jinja2 templating, as this is where most of the points are to be gained. You'll need an understanding of the networking protocols listed in the exam objectives, but you don't need to know them in-depth, this exam focuses more on the Ansible side of how to automate them, not the networking side of how they work.

Make sure to check for exact naming when you turn in the exam, I got 0% on a few categories and I suspect this is due to using a slightly different name than the exam check script they use expect. I still passed the exam and got a 100% on everything else!  

# Exam objectives
These exam objectives are tackled in this repository:

```markdown
- Gather facts about devices and systems
- Configure routers, switches and ports
- Configure OSPF
- Configure BGP
- Configure VLANs
- Create a multi-play playbook to back up a device configuration
```

## Host table

Name | IPs | Type | Notes
--- | --- | --- | ---:
RO1 | 192.168.1.251/24 | Cisco 2821 | Knows default route to simulated internet
RO2 | 192.168.1.252/24 | Cisco 2821 | Knows default route to simulated internet
SW1 | 192.168.1.241/24 | Cisco WS-C3750G | Used to ensure at least one switch connected to a router is available
SW2 | 192.168.1.242/24 | Cisco WS-C3750G | Used to ensure at least one switch connected to a router is available
SW3 | 192.168.2.243/25 | Cisco WS-C3750G | Used to connect all devices to a common management network
SW4 | 192.168.1.244/24, 192.168.2.254/24 | Cisco WS-C3750G | To practice BGP & OSPF
SW5 | 192.168.1.245/24, 192.168.2.245/24, 192.168.3.254.24 | Cisco WS-C3750G | To practice OSPF

## Network diagram

<img src="network_diagram.png" alt="Made with diagrams.net" height="600"/>

## Ansible

### Initial Provisioning

The network lab has all network devices available over Telnet. I created a playbook `01-initial-setup.yml` that connects to the Telnet ports of all devices and configures them with IP addresses, common username and password and enables SSH.  

The commands this will run are defined in the host and group variables. The host variables are defined in the `host_vars` directory. The group variables are defined in the `group_vars` directory.

I define a variable `global_commands` that is included in the `commands` variable of all hosts. This variable contains the commands that are common to all hosts, like SSH configuration.  
For example, the `commands` variable for the `SW5` host looks like the following:
```yaml
commands:
  - "{{ global_commands }}"
  - ip routing

```

The following Ansible task will send these commands:

<details><summary><code>Configurations</code></summary>

```yaml
- name: Configurations
  ansible.builtin.shell:
    cmd: |+
      netcat -C {{ telnet_host }} {{ telnet_port }} -w 10 <<EOF


      enable
      terminal length 0
      configure terminal
      {% for command in commands | default([]) %}
      {{ command }}
      {% endfor %}
      exit
      exit


      EOF
  delegate_to: localhost
  changed_when: false

```

</details>

This will send these commands with Netcat to the Telnet port of the host. The `changed_when` parameter is set to `false` because the `shell` module will always report a change, even if the commands are the same. I attempted an idempotency check later, but this will require more work to get right.  

The same happens with the `interface_commands` variable. This variable contains the commands that are specific an interface, it will enter the interface configuration and send these commands.

From that point onward, I can connect my laptop to the network and use Ansible to configure the network devices over SSH. The connection can be tested with the `02-test-connection.yml` playbook. This playbook will connect to all devices and run the `show version` command to verify the connection.  

### Ansible setup

The `03-setup.yml` playbook will configure the network devices with the technologies listed in the exam objectives.
 - VLANs
 - BGP
 - OSPF

It does this by using modules in the `cisco.ios` collection. The `cisco.ios` collection is not installed by default, so I need to install it first. Please install the Galaxy requirements with the following command:
```bash
ansible-galaxy collection install -r requirements.yml
```
This uses variables `ios_vlans`, `bgp_config` and `ospfv2_config` to configure the network devices. These variables are defined per host. For example, this is the configuration for `SW4`:

<details><summary><code>host_vars/SW4.yml</code></summary>

```yaml
ios_vlans:
  - name: servers
    vlan_id: 30
    ports:
      - GigabitEthernet1/0/1
      - GigabitEthernet1/0/2
      - GigabitEthernet1/0/3
      - GigabitEthernet1/0/4
      - GigabitEthernet1/0/5
    trunk_ports:
      - GigabitEthernet1/0/25
    trunk_encapsulation: dot1q
    state: active
    shutdown: disabled
    ipv4:
      address: 192.168.2.254/24

bgp_config:
  as: 65002
  router_id: "{{ ansible_host }}"
  redistribute:
    - protocol: ospf
      id: 400
  networks:
    - 192.168.2.0/24
  neighbours:
   - remote_as: 65001
     addresses:
      - 192.168.1.251
      - 192.168.1.252
     description: routers

ospfv2_config:
  - process_id: 400
    areas:
      - id: 0
        area_type: ""  # Leave default to not configure special area settings
        summary: false
    networks:
      - address: 192.168.2.254
        wildcard: 0.0.0.0
        area: 0
    reference_bandwidth: 10000

```

</details>

This will create a VLAN with ID 30 and name `servers`. It will be trunked over port `GigabitEthernet1/0/25` and the other 5 ports will be access ports. The VLAN will be configured with IP address `192.168.2.254/24` and will be brought up.  

BGP will be configured with AS number `65002` and router ID matching the IP address of the host. It will redistribute OSPF routes and advertise the `192.168.2.0/24` network. It will peer with the two routers so that they can reach the `192.168.2.0/24` network too. These routers are configured as one AS since they are active-stanby routers.  

OSPF will be configured with process ID `400` and will listen on the address `192.168.2.254`. This will receive the `192.168.3.0/24` network from `SW5` and advertise it to the other routers through BGP.  

The tasks that achieve this are long and use complicated Jinja2 magic, so I won't be pasting them here, but you can read them in the `03-setup.yml` playbook.  

### Dump network configuration

The `04-dump-config.yml` playbook will dump the configuration of all network devices to the `cisco_facts` directory. This is useful to see what the configuration looks like after the setup. Backing up the configuration is also a requirement for the exam. This is a simple playbook that just uses the `cisco.ios.ios_facts` module to gather the configuration and then writes it to a JSON file on the Ansible controller.  

I have ran this playbook and kept the `cisco_facts` directory in this repository, feel free to take a look at the configuration that was generated.  

## Result

The result of this is that the VLANs on `SW4` and `SW5` are up and accessible on every device.  

Notably, the `RO1` router can access `192.168.3.0/24`, this verifies all functionality is working as expected. `192.168.3.254/24` is an SVI on the *VLAN* on `SW5` which is advertised over *OSPF* to `SW4` which then redistributes it into *BGP* which then advertises it to `RO1`.  

```r
RO1#sh ip route
Codes: L - local, C - connected, S - static, R - RIP, M - mobile, B - BGP
       D - EIGRP, EX - EIGRP external, O - OSPF, IA - OSPF inter area
       N1 - OSPF NSSA external type 1, N2 - OSPF NSSA external type 2
       E1 - OSPF external type 1, E2 - OSPF external type 2
       i - IS-IS, su - IS-IS summary, L1 - IS-IS level-1, L2 - IS-IS level-2
       ia - IS-IS inter area, * - candidate default, U - per-user static route
       o - ODR, P - periodic downloaded static route, H - NHRP, l - LISP
       + - replicated route, % - next hop override

Gateway of last resort is 122.21.8.174 to network 0.0.0.0

S*    0.0.0.0/0 [254/0] via 122.21.8.174
      122.0.0.0/8 is variably subnetted, 2 subnets, 2 masks
C        122.21.8.172/30 is directly connected, GigabitEthernet0/1
L        122.21.8.173/32 is directly connected, GigabitEthernet0/1
      192.168.1.0/24 is variably subnetted, 2 subnets, 2 masks
C        192.168.1.0/24 is directly connected, GigabitEthernet0/0
L        192.168.1.251/32 is directly connected, GigabitEthernet0/0
B     192.168.2.0/24 [20/0] via 192.168.1.244, 01:28:05
B     192.168.3.0/24 [20/20] via 192.168.1.244, 00:00:01

```

## Commands
These are some notes on IOS & VyOS commands used for this exam.

### Ping

<details><summary> VyOS </summary>

```
ping {{ ip }} interface {{ interface }} count {{ count }}
ping {{ ip }} source {{ source_ip }} count {{ count }}
```

</details>

<details><summary> IOS </summary>

```
ping {{ ip }} interface {{ interface }} repeat {{ count }}
ping {{ ip }} source {{ source_ip }} repeat {{ count }}
```

</details>

### SNMP

<details><summary> VyOS </summary>

```
set service snmp community {{ community_string | default('pass') }} authorization ro
set service snmp community routers client 10.10.10.1
set service snmp community routers network 10.10.10.0/24
```

</details>

<details><summary> IOS </summary>

```
# 1 stands for access-list
access-list 50 permit ip host 10.10.10.1
access-list 50 permit ip 10.10.10.0 0.0.0.255
snmp-server community {{ community_string | default('pass') }} RO 50
```

</details>

### Logging

<details><summary> VyOS </summary>

```
set system syslog host {{ syslog_host }} facility {{ facility | default('all') }} level {{ loglevel | default(6) }}
```

</details>

<details><summary> IOS </summary>

```
service timestamps log datetime
service timestamps debug datetime

logging {{ syslog_host }}
loging trap {{ loglevel | default(6) }}

access-list 1 permit ip host {{ source_ip | default('192.168.100.1/24') | ipaddr('address') }} log
```

</details>

### OSPF

<details><summary> VyOS </summary>

```
set protocols ospf area 0 network 10.10.10.0/24
set protocols ospf parameters router-id 10.10.10.1
set protocols ospf log-adjacency-changes

# Prevent OSPF packets on interface
set protocol ospf passive-interface eth5
```

</details>

<details><summary> IOS </summary>

```
router ospf 1
  router-id 10.20.20.1
  network 10.20.20.0 0.0.0.255 area 0
  passive-interface GigabitEthernet5
```

</details>

### BGP

<details><summary> VyOS </summary>

```
set protocols bgp 100 parameters router-id 10.10.10.1
set protocols bgp 100 network 10.10.10.1/24
set protocols bgp 100 neighbour 10.20.20.1 remote-as '200'
set protocols bgp system-as 100
set protocols bgp address-family ipv4-unicast redistribute {{ source | default('connected') }}
```

</details>

<details><summary> IOS </summary>

```
router bgp 200 # AS
  address-family ipv4
  neighbour 10.10.10.1 remote-as '100'
  network 10.20.20.1 mask 255.255.255.0
  redistribute connected subnets
```

</details>

### Routes

<details><summary> VyOS </summary>

```
set protocols static route 10.10.10.0/24 interface eth2
set protocols static route 10.10.10.0/24 next-hop 10.20.10.1
```

</details>

<details><summary> IOS </summary>

```
ip route 10.10.10.0 255.255.255.0 GigabitEthernet2 
ip route 10.10.20.0 255.255.255.0 10.20.10.1
```

</details>

### Access Lists

<details><summary> IOS </summary>

```
# REMEMBER: Rules are applied in order of appearance from top to bottom. New rules will be appended at the bottom. If no rules match, it will block by default.
# Deleting a rule from an ACL will delete *the entire ACL*. Make sure to always recreate an ACL

# Deny ping from host 10.1.1.1
access-list 1 deny icmp host 10.1.1.1

# Allow all traffic from 10.1.1.0/24
access-list 1 permit ip 10.1.1.0 0.0.0.255

# Allow traffic from 10.1.2.0/24 to 10.1.3.0/24
access-list 1 permit ip 10.1.2.0 0.0.0.255 10.1.3.0 0.0.0.255

# Allow SSH
access-list 1 permit tcp 10.1.1.0/24 eq 22 # Or use a well-known name "ssh"

# Allow everything
access-list 1 permit any
```

</details>

### VLANs

<details><summary> IOS </summary>

```
# Tagged VLAN
int fa0/1.10
  encapsulation dot1q 10
  ip address 10.10.10.1 255.255.255.0

int fa0/1.20
  encapsulation dot1q 20
  ip address 10.20.20.1 255.255.255.0


int fa0/24
  switchport mode trunk
  switchport trunk encapsulation dot1q
  spanning-tree portfast trunk
  switchport trunk allowed vlan 10,20 # (VLANs allowed through)
  switchport trunk native vlan 10 # Devices that don't support VLANs will be put in this VLAN (untagged)

# Untagged VLAN
int fa0/3
  switchport mode access
  switchport access vlan 30
  spanning-tree portfast

int vlan20
  ip address 10.30.30.1 255.255.255.0

```

</details>


<details><summary> VyOS </summary>

```
# Tagged VLAN
set interfaces ethernet eth1 vif 10
set interfaces ethernet eth1 vif 10 address 10.10.10.1/24

set interfaces ethernet eth24 vif 10


# Untagged VLAN

set interfaces virtual-ethernet eth2 vif 20 address 10.20.20.1/24
```

</details>

### NAT

<details><summary> IOS </summary>

```
int fa0/1
  ip nat outside
  ip add dhcp
  no shut

int fa0/2
  ip nat inside
  ip add 10.10.10.1/24
  no shut

ip nat inside source list 1 interface fa0/1 overload
access-list 1 permit ip 10.10.10.0 0.0.0.255
```

</details>


<details><summary> VyOS </summary>

```
set nat source rule 10 outbound-interface eth0
set nat source rule 10 source address 10.10.10.0/24
set nat source rule 10 translation address masquerade
```

</details>

### Port Forwarding

<details><summary> IOS </summary>

```
ip nat inside source static tcp 10.10.10.80 80 1.1.1.1 80
ip nat inside source static tcp 10.10.10.80 80 interface GigabitEthernet0/0 80
```

</details>

<details><summary> VyOS </summary>

```
set nat destination rule 10 destination port 80
set nat destination rule 10 inbound-interface eth0
set nat destination rule 10 protocol tcp
set nat destination rule 10 translation address 10.10.10.80
set nat destination rule 10 translation port 80
```

</details>