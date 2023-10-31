# EX374: Red Hat Certified Specialist in Developing Automation with Ansible Automation Platform

I'm familiar enough with Ansible that I'm fairly confident in not needing to practice every thing in this exam. I'll be focusing on the things I'm not familiar with, and the things I'm not confident in only.

Practice related to AWX / Automation Hub is not included in this directory, you can find that at [../RH-EX467](../RH-EX467).

# Thoughts after exam
I passed this exam. This exam comes down to much more in-depth Ansible knowledge than EX294, this is definitely a better test of skill than EX294. You'll need to know how to build an execution environment from scratch and use it in Automation Hub. Knowledge on how to use and configure Ansible Navigator is also required, but these are all objectives that are listed on the official exam page.

# Exam Practice
To ensure I'm not sharing exam details, these are notes I took *before* the exam based on studying the exam objectives.

## Building an Execution Environment
Create a file `execution-enviroment.yml`:
```yaml
---
version: 1

build_arg_defaults:
  EE_BASE_IMAGE: quay.io/ansible/creator-ee:latest
  EE_BUILDER_IMAGE: quay.io/ansible/creator-ee:latest

ansible_config: ansible.cfg

dependencies:
  ansible_core:
    package_pip: ansible-core>=2.14.0,<2.15.0
  ansible_runner:
    package_pip: ansible-runner
  galaxy: requirements.yml  # Can be a file or a multiline string
  python: requirements.txt
  system: bindep.txt
#   system: |
#     rsync [platform:rpm]
#     kubernetes-client [platform:rpm]

additional_build_steps:
  append_base:
    - RUN echo "This is an additional build step"

```

Create a file `requirements.yml`:
```yaml
---
collections:
  - name: kubernetes.core
    # version: X.Y.Z

roles:
  - name: diademiemi.k3s

```

Create a file `requirements.txt`:
```txt
netaddr
# netaddr==X.Y.Z
# netaddr>=X.Y.Z,<A.B.C

```

Create a file `bindep.txt`:
```txt
rsync [platform:rpm]
kubernetes-client [platform:rpm]

```

Create a file `ansible.cfg`:
```ini
[defaults]
# inventory = /path/to/inventory
# remote_user = root
roles_path = ./roles
collections_paths = ./collections
log_path = ./ansible.log


# vault_identity_list = dev@./.vault-dev, test@./.vault-test, acc@./.vault-acc, prod@./.vault-prod

callback_enabled = timer, profile_tasks, profile_roles
stdout_callback = yaml
force_color =1
nocows = 1
deprecation_warnings = True

[galaxy]
server_list = my_server, automation_hub, galaxy

[galaxy:my_server]
url = https://my_server.example.com/
token = xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

[galaxy:automation_hub]
url = https://console.redhat.com/api/automation-hub/
auth_url = https://sso.redhat.com/auth/realms/redhat-external/protocol/openid-connect/token

[galaxy:galaxy]
url = https://galaxy.ansible.com/

```

Build the execution environment:
```bash
ansible-builder build -t quay.io/example/new-ee:latest

ansible-builder build -t quay.io/example/new-ee:latest --container-runtime docker
```

Push to a registry:
```bash
podman push quay.io/example/new-ee:latest

docker push quay.io/example/new-ee:latest
```

## Ansible Navigator commands

Show current Ansible configuration:
```bash
ansible-navigator config
```

Run a playbook:
```bash
ansible-navigator run playbook.yml
```

Run a playbook with an execution environment:
```bash
ansible-navigator run playbook.yml --eei ee-supported-rhel8

# Define a pull policy, which can be "always", "missing", "never", or "tag"
ansible-navigator run playbook.yml --eei quay.io/ansible/creator-ee --pp always

# The default is "tag", which will download if the image isn't already present or *always* if the tag is "latest"
ansible-navigator run playbook.yml --eei quay.io/ansible/creator-ee:latest
```

Inspect an execution environment:
```bash
ansible-navigator images --eei quay.io/ansible/creator-ee
```

Run a playbook outputting to stdout like `ansible-playbook`:
```bash
ansible-navigator run playbook.yml --mode stdout
```

You can save these settings to a config file called `ansible-navigator.yml` in the current directory:
```yaml
---
ansible-navigator:
  execution-environment:
    image: quay.io/ansible/creator-ee
    pull:
      policy: always
    environment-variables:
      ANSIBLE_CONFIG: /home/runner/RH-EX374/ansible.cfg

  mode: stdout

...
```

Disable playbook artifacts:
```bash
# Playbook artifacts store information about the playbook run
ansible-navigator run playbook.yml --pae false
```
