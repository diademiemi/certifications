# EX374: Red Hat Certified Specialist in Deployment and Systems Management

# Thoughts after exam
I passed this exam, but I needed all the time allocated. This is definitely the hardest exam I've taken thus far, but that makes sense, as I don't work with Satellite daily. It was definitely tricky, and my PXE boot not working at the end stressed me out, since usually I'd just search through endless forum threads, but those of course weren't accessible to me. But I managed to get it working in the end. I'm glad I passed, but I'm also glad I don't have to do this again. I would really recommend trying every exam objective without using forums. Remember that in every Red Hat exam you get access to the documentation, so learn how to search through it quickly.

I ended up scoring a 288/300, with my only error being in the small Ansible part of the exam, how ironic. I was being a smartass and thought I'd picked up on a trick question, but I was overthinking it..

# Exam Practice
To ensure I'm not sharing exam details, these are notes I took *before* the exam based on studying the exam objectives.

In preparation for this I wrote an Ansible collection [diademiemi.foreman](https://github.com/diademiemi/ansible_collection_diademiemi.foreman).

Most of my effort went into this Ansible Collection, while of course I can't do it with Ansible during the exam (nor would I want to due to time constraints) it helped me understand the concepts and how they relate to each other. I felt that by automating it in Ansible I would get a deeper understanding of how Foreman & Katello / Satellite actually ticks. I see it this way as it forces you to execute everything in order.

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
 - `foreman.terraform.test`: Foreman & Katello Server
    250GiB disk, 8 CPUs, 20GiB RAM
    CentOS Stream 8
    `192.168.21.51/24`
 - `vyos.terraform.test`: VyOS DNS server
    8GiB disk, 2 CPUs, 2GiB RAM
    VyOS 1.5.0, image compiled before running (will prompt for required sudo password)
    `192.168.21.2/24`
- `client`: A bare VM
    20GiB disk, 1 CPUs, 2GiB RAM
    No OS, can be used to test PXE provisioning

Foreman and a Foreman Proxy (Capsule server) will be installed on the `foreman.terraform.test` host, this can take up to 30 minutes to run. The default variables will also deploy a sync plan to synchronize the CentOS Stream 8 repository. This is 100GiB large and will take quite a while to download (40 minutes for me). You can modify the default variables if this is not something you want.

The sections below explain more what this project does.

## Using Foreman / Satellite
Commands here will show `foreman-installer`, as it's what I practiced with. Commands are generally the same in `satellite-installer`. Notable changes are:
- `satellite-installer` replaces `foreman-installer`
- `--scenario scenario` replaces `--scenario katello`
- `capsule-certs-generate` replaces `foreman-proxy-certs-generate`
- Some options referring to "`foreman-proxy`" are replaced with "`capsule`"

### Install Foreman / Satellite
```bash
# Assuming dependencies are satisfied
# This can be automated with my role diademiemi.foreman.install

foreman-installer --scenario katello \
    --foreman-initial-location 'Default Location' \
    --foreman-initial-organization 'Default Organization' \
    --foreman-initial-admin-username 'admin' \
    --foreman-initial-admin-password 'admin'

```

### Install Smart Proxy / Capsule
```bash
# Assuming dependencies are satisfied
# This can be automated with my role diademiemi.foreman.install with foreman_install_skip_installer: true

# Generate certificates on Satellite host
foreman-proxy-certs-generate --foreman-proxy-fqdn "capsule.example.com" --certs-tar "~/capsule.example.com-certs.tar"

# Copy certificates to Capsule host
scp ~/capsule.example.com-certs.tar capsule:/root

# Run installer on Capsule host
# This command is given by the `foreman-proxy-certs-generate` command
foreman-installer --scenario foreman-proxy-content \
    --certs-tar-file ~/capsule.example.com-certs.tar \
    --foreman-proxy-register-in-foreman "true" \
    --foreman-proxy-foreman-base-url "https://foreman.example.com" \
    --foreman-proxy-trusted-hosts "foreman.example.com" \
    --foreman-proxy-trusted-hosts "capsule.example.com" \
    --foreman-proxy-oauth-consumer-key "xxx" \
    --foreman-proxy-oauth-consumer-secret "xxx"

```

I also wrote an Ansible role to automate this: [diademiemi.foreman.install](https://github.com/diademiemi/ansible_collection_diademiemi.foreman/tree/main/roles/install)

### Configuring Smart Proxy / Capsule

#### Set up DNS
```bash
foreman-installer \
    --enable-foreman-proxy \
    --foreman-proxy-dns true \
    --foreman-proxy-dns-managed true \
    --foreman-proxy-dns-provider nsupdate \
    --foreman-proxy-dns-zone example.com \
    --foreman-proxy-dns-server=127.0.0.1 \
    --foreman-proxy-dns-interface=eth0 \
    --foreman-proxy-dns-reverse=0.168.192.in-addr.arpa \
    --foreman-proxy-keyfile=/etc/rndc.key

```


#### Set up DHCP
```bash
foreman-installer \
    --enable-foreman-proxy \
    --foreman-proxy-dhcp true \
    --foreman-proxy-dhcp-managed true \
    --foreman-proxy-dhcp-interface eth0 \
    --foreman-proxy-dhcp-network 192.168.0.0 \
    --foreman-proxy-dhcp-gateway 192.168.0.1 \
    --foreman-proxy-dhcp-nameservers 192.168.0.1 \
    --foreman-proxy-dhcp-range "192.168.0.100 192.168.0.200" \
    --foreman-proxy-dhcp-omapi-port 7911 \
    --foreman-proxy-dhcp-ping-free-ip true \
    --foreman-proxy-dhcp-provider isc \
    --foreman-proxy-dhcp-server 127.0.0.1

```

#### Set up TFTP
```bash
foreman-installer \
    --enable-foreman-proxy \
    --foreman-proxy-tftp true \
    --foreman-proxy-tftp-managed true \
    --foreman-proxy-tftp-root /var/lib/tftpboot \
    --foreman-proxy-tftp-servername capsule.terraform.test

```

I also wrote an Ansible role to automate these: [diademiemi.foreman.smart_proxy](https://github.com/diademiemi/ansible_collection_diademiemi.foreman/tree/main/roles/smart_proxy)

### Configuring Foreman / Satellite
This section is about creating the resources in Foreman / Satellite, such as content views, activation keys, host groups, operating systems, etc.

I wrote an Ansible role to automate this, for the parts related to Katello (products, content views, sync plans, etc) you can find them here: [diademiemi.foreman.configure_katello](https://github.com/diademiemi/ansible_collection_diademiemi.foreman/tree/main/roles/configure_katello)
The important parts are:
 - The tasks file: [diademiemi.foreman.configure_katello/tasks/setup/default.yml](https://github.com/diademiemi/ansible_collection_diademiemi.foreman/blob/main/roles/configure_katello/tasks/setup/default.yml)
    This creates the host groups, operating systems, domains, subnets, etc.
 - The default variables file: [diademiemi.foreman.configure_katello/defaults/main.yml](https://github.com/diademiemi/ansible_collection_diademiemi.foreman/blob/main/roles/configure_katello/defaults/main.yml)
    This contains the variables used by the tasks file. This is far more important to look at, this is what is actually created on the server. The variables are in order, so this is a good place to start to see what is created and how it relates to each other.

You can find the parts to configure Foreman (host groups, operating systems, domains, subnets, etc) here: [diademiemi.foreman.configure](https://github.com/diademiemi/ansible_collection_diademiemi.foreman/tree/main/roles/configure)
The important parts are:
 - The tasks file: [diademiemi.foreman.configure/tasks/setup/default.yml](https://github.com/diademiemi/ansible_collection_diademiemi.foreman/blob/main/roles/configure/tasks/setup/default.yml)
    This creates the host groups, operating systems, domains, subnets, etc.
 - The default variables file: [diademiemi.foreman.configure/defaults/main.yml](https://github.com/diademiemi/ansible_collection_diademiemi.foreman/blob/main/roles/configure/defaults/main.yml)
    This contains the variables used by the tasks file. This is far more important to look at, this is what is actually created on the server. The variables are in order, so this is a good place to start to see what is created and how it relates to each other.


#### Provisioning Template Example
Here is an example provisioning template for CentOS:
```
    yum makecache

    <% if !host_param('host_packages').blank? -%>
    echo "Installing prerequisites"

    yum install -y <%= host_param('host_packages') %>
    <% end -%>

    <% if !host_param('create_user_name').blank? -%>
    echo "Creating user"

    <% if !host_param('create_user_home').blank? -%>
        useradd --create-home --home-dir <%= host_param('create_user_home') %> <%= host_param('create_user_name') %>
    <% else -%>
        useradd --create-home <%= host_param('create_user_name') %>
    <% end -%>

    <% if !host_param('create_user_password').blank? -%>
        echo '<%= host_param('create_user_name') %>:<%= host_param('create_user_password') %>' | /usr/sbin/chpasswd
    <% elsif !host_param('create_user_hash').blank? -%>
        echo '<%= host_param('create_user_name') %>:<%= host_param('create_user_password') %>' | /usr/sbin/chpasswd -e
    <% end -%>

    <% if host_param_true?('create_user_sudo') -%>
        usermod -aG wheel <%= host_param('create_user_name') %>
    <% end -%>

    <% end -%>
```

For this to be executed, name it `Kickstart default finish custom post` as type `snippet`.

### Backing up Foreman / Satellite
```bash
# Stop the server while backing up
foreman-maintain backup offline /tmp/backup

# Keep the server running
foreman-maintain backup online /tmp/backup

# Incremental backup
foreman-maintain backup online --incremental /tmp/backup

# Skip pulp content
foreman-maintain backup online --skip-pulp-content /tmp/backup
```

### Restoring Foreman / Satellite
```bash
foreman-maintain restore /tmp/backup/foreman-backup-YYYY-MM-DD-HH-MM-SS
```


## Building an RPM

### Install build tools
```bash
yum install -y rpmdevtools rpm-build rpm-sign rpmlint gcc rng-tools
```

## Set up build environment
```bash

cd /root

# Reset RPM build environment
rm -rdf /root/rpmbuild

rpmdev-setuptree

```

### Create example RPM

```

cd /root/rpmbuild/SOURCES

mkdir example-1.0.0

cat << EOF >> example-1.0.0/example.sh
#!/bin/bash
echo "Hello World"
EOF

chmod 755 example-1.0.0/example.sh

tar -cvzf example-1.0.0.tar.gz example-1.0.0

cd /root/rpmbuild/SPECS

rpmdev-newspec example
```

### Fill in example.spec
```bash

cat << EOF > example.spec
Name: example
Version: 1.0.0
Release: 1%{?dist}
Summary: Example RPM
BuildArch: noarch

License: GPLv3
URL: example.com
Source0: %{name}-%{version}.tar.gz

%description
This is an example RPM.

%prep
%setup -q

%install
rm -rf \$RPM_BUILD_ROOT
mkdir -p \$RPM_BUILD_ROOT/%{_bindir}
cp %{name}.sh \$RPM_BUILD_ROOT/%{_bindir}

%clean
rm -rf \$RPM_BUILD_ROOT

%files
%{_bindir}/%{name}.sh

EOF

```

### Build example RPM
```bash
# Verify spec file
rpmlint example.spec


# Build source RPM
cd /root/rpmbuild/SRPMS
rpmbuild -bs /root/rpmbuild/SPECS/example.spec
# Build binary RPM
cd /root/rpmbuild/RPMS
rpmbuild -bb /root/rpmbuild/SPECS/example.spec

```

### Sign example RPM
```bash

# Generate GPG key
gpg --gen-key  # Enter "Package" as name, and "example@example" as email

# Export key
gpg --export --armor 'Package' > RPM-GPG-KEY-Package

# Import key into RPM
rpm --import RPM-GPG-KEY-Package

cat << EOF > ~/.rpmmacros
%_signature gpg
%_gpg_path /root/.gnupg
%_gpg_name Package
%_gpgbin /usr/bin/gpg

EOF

# Sign RPM
rpm --addsign /root/rpmbuild/RPMS/noarch/example-1.0.0-1.el8.noarch.rpm

# Verify RPM
rpm --checksig /root/rpmbuild/RPMS/noarch/example-1.0.0-1.el8.noarch.rpm
# Signature should be OK

```

### Upload Example RPM to Foreman / Satellite
```bash
hammer repository upload-content --name "CentOS Stream 8 - BaseOS" --product "CentOS Product" --organization "Default Organization" --path /root/rpmbuild/RPMS/noarch/example-1.0.0-1.el8.noarch.rpm
```
