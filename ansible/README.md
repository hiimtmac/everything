# Ansible - Raspberry Pi k3s Cluster Setup

Ansible playbooks for preparing Raspberry Pi 4 nodes and bootstrapping a k3s cluster.

## Prerequisites

### On Your Local Machine

1. **Install Ansible**

   ```bash
   # macOS
   brew install ansible

   # Ubuntu/Debian
   sudo apt install ansible
   ```

2. **SSH key setup**

   Generate an SSH key if you don't have one:

   ```bash
   ssh-keygen -t ed25519 -C "your-email@example.com"
   ```

### Preparing the Raspberry Pis

Each Pi needs to be set up with Raspberry Pi OS before Ansible can manage it.

1. **Flash Raspberry Pi OS Lite (64-bit)** to each SD card using [Raspberry Pi Imager](https://www.raspberrypi.com/software/)

2. **In Raspberry Pi Imager, configure OS customization** (gear icon):
   - Set hostname (e.g., `pi-control`, `pi-worker-1`, `pi-worker-2`, `pi-worker-3`)
   - Enable SSH with password authentication (temporarily)
   - Set username to `pi` and choose a password
   - Set locale/timezone
   - Set ssh access by pubkey (instead of password auth) and configure key

3. **Boot each Pi** and find their IP addresses:

   ```bash
   # From your router's admin page, or scan the network:
   nmap -sn 192.168.1.0/24
   # Or check ARP table for Raspberry Pi MAC prefixes (dc:a6:32, e4:5f:01, etc.):
   arp -a | grep -E "dc:a6:32|e4:5f:01|28:cd:c1"
   ```

   > Not needed if you beforehand set a static IP via router

4. **Copy your SSH key to each Pi**:

   ```bash
   ssh-copy-id pi@192.168.1.100  # control
   ssh-copy-id pi@192.168.1.101  # worker-1
   ssh-copy-id pi@192.168.1.102  # worker-2
   ssh-copy-id pi@192.168.1.103  # worker-3
   ```

   > Not needed if you did the ssh setup during the imager

5. **Verify SSH access** (should connect without password):

   ```bash
   ssh pi@192.168.1.100 "hostname"
   ```

6. **Update inventory** with your actual IP addresses:

   Edit `inventory/hosts.yaml` and replace the IP addresses with your Pis' actual IPs.

## Configuration

### Inventory (`inventory/hosts.yaml`)

Update the IP addresses to match your network:

```yaml
k3s_server:
  hosts:
    pi-control:
      ansible_host: 192.168.1.100 # Your control Pi IP

k3s_agents:
  hosts:
    pi-worker-1:
      ansible_host: 192.168.1.101 # Your worker 1 IP
    # ... etc
```

### Variables (`inventory/group_vars/all.yaml`)

Adjust as needed:

- `k3s_version`: Pin to a specific k3s release
- `timezone`: Set your timezone
- `k3s_server_extra_args`: Control plane flags (traefik/servicelb disabled by default)

### SSH Key (`ansible.cfg`)

If your SSH key is not at the default `~/.ssh/id_ed25519`, update `ansible.cfg`:

```ini
private_key_file = ~/.ssh/your_key
```

## Usage

```bash
# Install required Ansible collections
make deps

# Verify connectivity to all Pis
make ping

# Preview changes without applying (dry-run)
make check

# Full setup: prepare nodes + install k3s
make setup

# Just install k3s (if nodes already prepared)
make install

# Update system packages (one node at a time)
make update

# Tear down cluster (destructive!)
make reset
```

## Configuring kubectl

The playbook automatically saves the kubeconfig to `~/.kube/config-everything` with the correct server IP.

```bash
# Use directly
kubectl --kubeconfig ~/.kube/config-everything get nodes

# Or set as default
export KUBECONFIG=~/.kube/config-everything
kubectl get nodes
```

To merge with existing clusters (for managing multiple contexts):

```bash
# Rename the context for clarity
sed -i '' 's/: default/: everything/g' ~/.kube/config-everything

# Backup existing config
cp ~/.kube/config ~/.kube/config.bak

# Merge configs
KUBECONFIG=~/.kube/config:~/.kube/config-everything kubectl config view --flatten > ~/.kube/config-merged
mv ~/.kube/config-merged ~/.kube/config

# Verify contexts
kubectl config get-contexts

# Switch clusters
kubectl config use-context everything
```

## Playbooks

| Playbook           | Description                                     |
| ------------------ | ----------------------------------------------- |
| `site.yaml`        | Full setup: system prep + k3s installation      |
| `k3s-install.yaml` | k3s installation only (skip system prep)        |
| `update.yaml`      | Update system packages, reboot if needed        |
| `k3s-reset.yaml`   | Uninstall k3s and clean up (destructive)        |

## Troubleshooting

### "Permission denied" SSH errors

Ensure your SSH key is copied to all Pis:

```bash
ssh-copy-id pi@<pi-ip-address>
```

### Nodes stuck in "NotReady" state

Check if cgroups are enabled (requires reboot after first run):

```bash
ssh pi@<pi-ip> "cat /proc/cgroups | grep memory"
```

### Connection timeouts

Verify Pi IPs in inventory match actual addresses:

```bash
ansible all -m ping
```

## Configuration Details

### Why Traefik and ServiceLB are Disabled

By default, k3s bundles Traefik as an ingress controller and ServiceLB for LoadBalancer services. These are disabled in `group_vars/all.yaml` because:

- **Traefik**: You may prefer a different ingress controller (nginx-ingress, Istio, etc.) or want to manage the version separately
- **ServiceLB**: On bare metal clusters, MetalLB provides better LoadBalancer support with IP address management

To re-enable these defaults, remove the `--disable` flags from `k3s_server_extra_args`.

## Post-Installation

Ansible's scope ends once k3s is running. The following are deployed via Kubernetes tooling (Helm, kubectl, etc.), not Ansible:

- **LoadBalancer support**: MetalLB for assigning external IPs to services
- **Ingress controller**: nginx-ingress, Traefik, or similar for HTTP routing
- **Storage**: Longhorn or NFS provisioner for persistent volumes
- **Certificates**: cert-manager for automated TLS
