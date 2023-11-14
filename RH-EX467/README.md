# EX467: Red Hat Certified Specialist in Managing Automation with Ansible Automation Platform

# Exam Practice
To ensure I'm not sharing exam details, these are notes I took *before* the exam based on studying the exam objectives.

I wrote a test environment that deploys AWX and Ansible Galaxy-NG in Kubernetes. These are the upstream of Ansible Automation Platform and Ansible Private Automation Hub. These are deployed in Kubernetes, this is not part of the exam, that's just what I'm used to.

I primarily practiced for this exam by just running these VMs and messing around in AWX and automation hub. You can find more information about how I used these in [../RH-EX374](../RH-EX374).

## Thoughts after exam
Make sure to practice installing AAP with the official installer, like in the exam objectives! I ended up passing this exam with a perect score! 300/300! It was quite easy, if you know the hang of AWX and Galaxy, learn the enterprise versions and give this exam a go!

## Terraform + Ansible test environment
To run the Ansible and Terraform code I wrote to run this, make sure you have a working Libvirt environment. Enter your connection URL as environment variable `TF_VAR_libvirt_uri`, it will default to `qemu:///system`, this is fine if it is your local machine.
Install the Galaxy requirements: `ansible-galaxy install -r requirements.yml`
Run the playbook with the Terraform inventory:
```bash
ansible-playbook -i inventory/terraform playbooks/deploy.yml
```

Trigger a rebuild of the environment
```bash
ansible-playbook -i inventory/terraform playbooks/deploy.yml -e state=recreate
```

Trigger a destroy of the environment
```bash
ansible-playbook -i inventory/terraform playbooks/deploy.yml -e state=destroy
```

With any of these commands you can add `-e etchosts=true` to sync the hostnames of the VMs to `/etc/hosts` on the Ansible controller (the machine you run the playbook from). This is helpful for accessing the VMs by hostname. This is not required for Ansible connection, the connection variables are generated through Terraform.

This deploys:
 - `awx.terraform.test`: AWX server
    30GiB thin disk, 4 CPUs, 8GiB RAM
    Ubuntu 20.04
    `192.168.21.51/24`
 - `galaxy.terraform.test`: Galaxy-NG server
    30GiB thin disk, 4 CPUs, 8GiB RAM
    Ubuntu 20.04
    `192.168.21.52/24`
 - `vyos.terraform.test`: VyOS DNS server
    8GiB thin disk, 2 CPUs, 2GiB RAM
    VyOS 1.5.0, image compiled before running (will prompt for required sudo password)
    `192.168.21.2/24`
- `client01.terraform.test`: A bare Ubuntu VM
    20GiB disk, 1 CPUs, 2GiB RAM
    Ubuntu 20.04
    `192.168.21.11/24`
- `client02.terraform.test`: A bare Ubuntu VM
    20GiB disk, 1 CPUs, 2GiB RAM
    Ubuntu 20.04
    `192.168.21.12/24`

The password for the root user is `root` for all VMs.

## AWX

AWX (the upstream version of Ansible Automation Platform Controller) is installed on the host `awx.terraform.test` through the AWX operator. This is different than how it's installed in the exam, but it's the same software with generally the same abilities.

### Manage AWX with Ansible
This isn't a part of the exam, but I've used AWX before and configured it through Ansible in an earlier project, you can find the source for that here:

Links:
 - https://github.com/diademiemi/experiments/blob/main/foreman-provisioning-with-awx/playbooks/combined/02-configure-awx.yml

   Playbook that adds the required organisation, credentials, inventories, projects, job templates, etc. to AWX.

 - https://github.com/diademiemi/experiments/blob/main/foreman-provisioning-with-awx/inventories/terraform/host_vars/awx/awx.yml

    Variables for the AWX host.

### Run job templates from API
AWX/AAP has an API available at `/api/v2`, you can list all endpoints with a `GET` to that address:
```bash
curl -X GET --user admin:admin -k https://awx.terraform.test/api/v2/
```

You can get a list of job templates with a `GET` to `/api/v2/job_templates`:
```bash
curl -X GET --user admin:admin -k https://awx.terraform.test/api/v2/job_templates
```

Every job template will have an ID, you can launch a specific one by sending a `POST` to `/api/v2/job_templates/<id>/launch/`:
```bash
curl -X POST --user admin:admin -k https://awx.terraform.test/api/v2/job_templates/1/launch/
```


### Automation Mesh
I wasn't able to test this in my homelab, but I did find some documentation on it. I've included it here for reference. This is a required part of the exam.

Ansible Automation Mesh is based on [Receptor](https://github.com/ansible/receptor), the Ansible Automation Platform installer project automatically deploys this to select nodes.

There are four types of nodes:
- Control Plane nodes

  These run the control plane services like the UI and API. They are responsible for managing the mesh, and running the mesh services.
- Execution nodes
  
  These are the Ansible Controllers that AWX/AAP will use to run playbooks from
- Hop nodes
  
  These are nodes that will be used to forward traffic between execution nodes and control plane nodes. These are optional, but can be used to reduce the number of connections required between execution nodes and control plane nodes.
- Hybrid nodes
  
  These are nodes that run both execution and control plane services. These are optional, but can be used to reduce the number of nodes required.

To add a mesh highly-available topology to the Ansible Automation Platform installer, you need to modify the inventory of the project.

```ini
; These will be the control plane, aka what hosts AWX/AAP & Galaxy/Hub
[automationcontroller]
controlplane1.example.com
controlplane2.example.com
controlplane3.example.com

; Define vars
[automationcontroller:vars]
node_type=control  ; Set these as control plane
peers=execution_nodes  ; Set this group as neighbour nodes, must be within one hop

; These will be the execution nodes, aka where the code will run from
[execution_nodes]
executionnode1.example.com
executionnode2.example.com
hop1.example.com node_type=hop  ; Use this node to reach the execution nodes

[automationhub]  ; These will be the Automation Hub nodes
hub.example.com

[database]
database.example.com

[all:vars]  ; Installer vars
pg_host=database.example.com
admin_password=admin
pg_password=postgres

automation_hub_admin_password=admin
automationhub_pg_host=database.example.com
automationhub_pg_password=postgres
registry_url=hub.example.com
registry_username=admin
registry_password=admin


```

After this, you can run the following command to generate a graphical representation of the mesh:

```bash
./setup.sh -- --tag generate_dot_file
```

Run the installer as normal to deploy Ansible Automation Platform with the mesh.
```bash
./setup.sh
# ./setup.sh -e ignore_preflight_errors=true
```

To remove nodes from the mesh, add the `node_state=deprovision` variable to a host:
```ini
[automationcontroller]
controlplane1.example.com
controlplane2.example.com

; Define vars
[automationcontroller:vars]
node_type=control  ; Set these as control plane
peers=execution_nodes  ; Set this group as neighbour nodes, must be within one hop

; These will be the execution nodes, aka where the code will run from
[execution_nodes]
executionnode1.example.com
executionnode2.example.com
hop1.example.com node_type=hop  ; Use this node to reach the execution nodes

; ... Omitted

[deprovision]
executionnode2.example.com

[deprovision:vars]
node_state=deprovision
```

You'll be able to manage these and assign them into instance groups from the Automation Platform UI under "Administration > Instance Groups". These can then in turn be added to inventories so that you can run playbooks on them from these nodes.

You can read more about Ansible Automation Mesh on the Ansible website: [Posts about Automation Mesh](https://www.ansible.com/blog/topic/automation-mesh)

### Backing up and restoring AWX
Run the `setup.sh` script with the `-b` option:
```bash
cd /opt/ansible-automation-platform/installer
./setup.sh -b
```

This will create a backup in the current directory. You can restore this backup with the `-r` option:
```bash
cd /opt/ansible-automation-platform/installer
./setup.sh -r
```

## Automation Hub

Ansible Galaxy-NG (the upstream version of Ansible Private Automation Hub) is installed on the host `galaxy.terraform.test` through the Pulp operator. This is different than how it's installed in the exam, but it's the same software. 

### Get content from Automation Hub

You'll need to generate a token for your Automation Hub instance. You can do this by logging in to the Automation Hub UI, selecting "API token management" under "Collections"

Create a file `ansible.cfg`:
```ini
[defaults]
; ... normal vars

[galaxy]
server_list = my_server, galaxy
; server_list = my_server, automation_hub, galaxy

[galaxy:my_server]
url = https://my_server.example.com/
token = xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

; [galaxy:automation_hub]
; url = https://console.redhat.com/api/automation-hub/
; auth_url = https://sso.redhat.com/auth/realms/redhat-external/protocol/openid-connect/token

[galaxy:galaxy]
url = https://galaxy.ansible.com/

```

### Upload a collection to Automation Hub

You can now use `ansible-galaxy collection install` to install collections to your Automation Hub instance. To upload collections to Automation Hub, you can use `ansible-galaxy collection publish` command:

```bash
ansible-galaxy collection publish --api-key xxxxx -s https://galaxy.terraform.test/api/galaxy -c diademiemi-example-1.0.0.tar.gz

```
You must create a namespace for the collection (`diademiemi` in this case). Upon uploading you will need to approve this new collection in the Galaxy / Automation Hub UI under "Approval" under "Collections".
