# Ansible Collection - csmart.swift

An Ansible collection for deploying and managing OpenStack Swift clusters.

Currently supports PACO nodes running all Swift services: Proxy, Account, Container and Object.

## Features

- Prepare Swift nodes, including SELinux and SSH access
- Add repositories and install packages
- Configure dependent services (logging, rsyncd, memcached)
- Configure keepalived for failover of proxy VIPs
- Configure Swift PACO services
- Create initial account, container and object rings
- Prepare disks on each node, format and mount according to the rings
- Build and distribute the rings
- Configure dispersion
- Operational tasks: re-configure services, update/distribute rings, generate reports

## Requirements

- ansible-core >= 2.16, < 2.17 (EL 8 targets require Python 3.6 support)
- Python `netaddr` library on the controller (`pip install netaddr`)
- Target nodes running an EL 8 or 9 based distribution with networking pre-configured
- An admin box (included in `swift_admin` group) from which all Swift nodes are managed

### Collection Dependencies

Install required collections:

```bash
ansible-galaxy collection install -r requirements.yml
```

Or install individually:

```bash
ansible-galaxy collection install ansible.posix ansible.utils community.general community.crypto
```

## Installation

### From Ansible Galaxy

```bash
ansible-galaxy collection install csmart.swift
```

### From Source

```bash
ansible-galaxy collection build
ansible-galaxy collection install csmart-swift-*.tar.gz
```

## Role: `csmart.swift.swift`

### Role Variables

Default variables are broken out into individual files under `roles/swift/defaults/main/`.
These include common settings for a Swift cluster as well as defaults for specific Swift services.

#### Required Global Variables

| Variable | Description | Default |
|---|---|---|
| `swift_hash_suffix` | Hash suffix of the cluster (never change after setup) | `07b4ef9c-2e01-4ea2-a109-5ffc5273225f` |
| `swift_hash_prefix` | Hash prefix of the cluster (never change after setup) | `f9175259-ace0-48bb-af9d-e7ac505b89d2` |
| `swift_outward_subnet` | Routable CIDR subnet for external connections | `203.0.113.0/24` |
| `swift_cluster_subnet` | Cluster communication CIDR subnet | `192.0.2.0/24` |
| `swift_replication_subnet` | Replication CIDR subnet | `198.51.100.0/24` |
| `swift_cluster_api_hostname` | DNS name for the cluster API | `swift.local` |

#### Required Per-Node Variables

| Variable | Description | Example |
|---|---|---|
| `swift_outward_ip` | IP on the outward network | `203.0.113.11` |
| `swift_cluster_ip` | IP on the cluster network | `192.0.2.11` |
| `swift_replication_ip` | IP on the replication network | `198.51.100.11` |
| `swift_vips` | List of proxy VIP 4th octets (proxy nodes only) | `[111, 112, 113]` |
| `swift_rings_disks` | Disk configuration for rings (storage nodes only) | See below |

#### Execution Control Variables

These variables allow skipping certain tasks, useful for container-based testing
or environments where specific features are not available.

| Variable | Description | Default |
|---|---|---|
| `swift_skip_hosts` | Skip SSH key setup and host configuration | `false` |
| `swift_skip_reboot` | Skip reboot after package updates | `false` |
| `swift_skip_disk_prepare` | Skip disk formatting and mounting | `false` |
| `swift_update` | Run system package updates (must be defined and `true`) | undefined |
| `swift_selinux_state` | SELinux state: `disabled`, `permissive`, or `enforcing` | `permissive` |
| `swift_firewall` | Configure firewalld rules | `true` |
| `swift_firewall_zone` | Firewalld zone for Swift ports | `public` |

#### Service Configuration

| Variable | Description | Default |
|---|---|---|
| `swift_user` | Swift system user | `swift` |
| `swift_group` | Swift system group | `swift` |
| `swift_uid` | Swift user UID | `160` |
| `swift_gid` | Swift group GID | `160` |
| `swift_retries` | Number of retries for package operations | `10` |
| `swift_delay` | Delay in seconds between retries | `5` |

#### Port Configuration

| Variable | Description | Default |
|---|---|---|
| `swift_proxy_port` | Proxy server listening port | `8080` |
| `swift_account_port` | Account server listening port | `6202` |
| `swift_container_port` | Container server listening port | `6201` |
| `swift_object_port` | Object server listening port | `6200` |
| `swift_memcached_port` | Memcached listening port | `11211` |

#### Ring Configuration

| Variable | Description | Default |
|---|---|---|
| `swift_account_rings_part_power` | Account ring partition power | `10` |
| `swift_account_rings_replicas` | Account ring replicas | `3` |
| `swift_account_rings_min_part_hours` | Account ring minimum partition hours | `0` |
| `swift_container_rings_part_power` | Container ring partition power | `10` |
| `swift_container_rings_replicas` | Container ring replicas | `3` |
| `swift_container_rings_min_part_hours` | Container ring minimum partition hours | `0` |
| `swift_object_rings_part_power` | Object ring partition power | `17` |
| `swift_object_rings_replicas` | Object ring replicas | `3` |
| `swift_object_rings_min_part_hours` | Object ring minimum partition hours | `0` |
| `swift_object_rings_policy_type` | Object ring storage policy type | `replication` |

#### SSL/TLS Configuration

The role configures TLS termination via Hitch. Default values contain example
certificates for testing only -- replace them for production use.

| Variable | Description | Default |
|---|---|---|
| `swift_ssl_cert` | SSL certificate (PEM) | Example cert |
| `swift_ssl_key` | SSL private key (PEM) | Example key |
| `swift_ssl_cacert` | CA certificate (PEM) | Example CA cert |
| `swift_ssl_cakey` | CA private key (PEM) | Example CA key |

#### Package and Repository Configuration

| Variable | Description | Default |
|---|---|---|
| `swift_common_repos` | List of repos to enable | CentOS PowerTools (vault) |
| `swift_common_deps` | Common dependencies | `centos-release-openstack-wallaby` |
| `swift_common_packages` | Common packages to install | crudini, git, openstack-selinux, etc. |
| `swift_custom_deps` | Additional custom dependencies | `[]` |

#### Proxy Pipeline

The proxy server pipeline is highly configurable. Each middleware filter can be
toggled via a `swift_proxy_pipeline_<filter>` variable. See
`roles/swift/defaults/main/proxy.yml` for the full list of filters and their
defaults. Key filters:

| Variable | Description | Default |
|---|---|---|
| `swift_proxy_pipeline_tempauth` | Enable tempauth middleware | `true` |
| `swift_proxy_pipeline_authtoken` | Enable Keystone authtoken middleware | `false` |
| `swift_proxy_pipeline_keystoneauth` | Enable Keystone auth middleware | `false` |
| `swift_proxy_pipeline_s3api` | Enable S3 API compatibility | `false` |
| `swift_proxy_pipeline_encryption` | Enable at-rest encryption | `false` |

Example `swift_rings_disks`:

```yaml
swift_rings_disks:
  - disk:
      device: sdb
      rings:
        - name: account
          weight: 0
        - name: container
          weight: 0
        - name: object
          weight: 100
  - disk:
      device: nvme0n1
      rings:
        - name: account
          weight: 100
        - name: container
          weight: 100
        - name: object
          weight: 0
```

### Inventory Groups

Your inventory should include the following groups:

- `swift` (or `all`) - all Swift nodes
- `swift_admin` - admin node
- `swift_proxy` - proxy nodes
- `swift_account` - account server nodes
- `swift_container` - container server nodes
- `swift_object` - object server nodes

Example inventory for a three-node PACO cluster:

```yaml
swift:
  hosts:
    swift-admin:
    swift-[01:03]:
  children:
    swift_admin:
      hosts:
        swift-admin:
    swift_proxy:
      hosts:
        swift-[01:03]:
    swift_account:
      hosts:
        swift-[01:03]:
    swift_container:
      hosts:
        swift-[01:03]:
    swift_object:
      hosts:
        swift-[01:03]:
```

### Example Playbook

```yaml
---
- hosts: swift
  tasks:
    - name: Deploy Swift cluster
      ansible.builtin.include_role:
        name: csmart.swift.swift
```

Run the playbook:

```bash
ansible-playbook -i inventory/ site.yml
```

### Tags

The role includes tags for granular execution:

`account`, `common`, `config`, `container`, `disks`, `dispersion`, `firewall`,
`hosts`, `keepalived`, `logging`, `memcached`, `object`, `packages`, `prep`,
`proxy`, `rings`, `rsyncd`, `selinux`, `services`, `ssl`, `system`, `update`

Example - re-configure account services only:

```bash
ansible-playbook -i inventory/ site.yml --tags account
```

## Included Playbooks

The collection ships with ready-to-use playbooks under `playbooks/` along with
a sample inventory under `playbooks/inventory/`.

| Playbook | Description |
|---|---|
| `site.yml` | Full cluster deployment (all tags) |
| `common.yml` | Common system preparation (SELinux, repos, packages) |
| `swift-prep.yml` | Swift node preparation (hosts, user, firewall, services) |
| `swift-hosts.yml` | SSH keys and `/etc/hosts` configuration |
| `swift-rings.yml` | Build and rebalance rings |
| `swift-rings-distribute.yml` | Distribute rings to all nodes |
| `swift-rings-destroy.yml` | Destroy existing rings |
| `swift-disk-prepare.yml` | Format and mount disks |
| `swift-configure.yml` | Configure all Swift services |
| `swift-proxy-configure.yml` | Configure proxy service only |
| `swift-account-configure.yml` | Configure account service only |
| `swift-container-configure.yml` | Configure container service only |
| `swift-object-configure.yml` | Configure object service only |

Run a collection playbook directly:

```bash
ansible-playbook -i inventory/ csmart.swift.site
```

Or from the collection source:

```bash
ansible-playbook -i playbooks/inventory/ playbooks/site.yml
```

A sample test script is also provided at `scripts/test-swift.sh` to validate a
deployed cluster using tempauth:

```bash
./scripts/test-swift.sh 203.0.113.111
```

## Testing

This collection uses [Molecule](https://molecule.readthedocs.io/) for testing.

```bash
pip install molecule
molecule test
```

## Legacy Role

If you need the original standalone Ansible role (before the collection
conversion), it is available under the `role` tag in this repository.

## License

GPLv3+

## Author

Chris Smart - https://blog.christophersmart.com
