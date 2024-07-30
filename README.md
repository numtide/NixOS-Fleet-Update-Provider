# NixOS Fleet Update Provider

**status**: bleeding edge, very unstable, may eat your kittens.

This is a terraform provider aiming to manage updates for a homogeneous fleet of NixOS machines. By homogeneous, we mean machines sharing the same configuration. We originally designed this provider to update the nodes of a Kubernetes cluster.

Provided a list of hostnames, their associated NixOS configurations, and a healthcheck script to perform, this provider updates the various hosts one by one. If the healthcheck fails on a host, the host configuration is rollbacked and the overall deployment canceled.

## Inputs

This module takes a list of hosts. Each host is defined with:

- **nixos_system**: the NixOS system to deploy.
- **target_hosgt**: the hostname of the system to deploy.
- **target_user**: user used to deploy. Defaults to `root`.
- **target_port**: listening port of the ssh server. Defaults to `22`.
- **ssh_private_key**: content of the private key used to connect to the target_host. If set to -, no key is passed to openssh, it fallback to its local config.
- **ignore_systemd_errors**: do not fail the deployment if a systemd service fails after activation.
- **healthcheck**: bash script run on the host after the deployment. Considered failed if exits with a non 0 code.

## Usage Example

```hcl
module "fleet-provider-test" {
  source   = "git::https://github.com/numtide/nixos-fleet-provider.git"
  hosts = [ {
    nixos_system = ""
    target_host = "111.111.111.111"
    target_user = "root"
    target_port = 22
    ssh_private_key = "/run/secrets/deployment-key"
    healthcheck_script = "${path.module}/healcheck.sh"
    ignore_systemd_errors = false
  },
  hosts = [ {
    nixos_system = ""
    target_host = "222.222.222.222"
    target_user = "root"
    target_port = 22
    ssh_private_key = "/run/secrets/deployment-key"
    healthcheck_script = "${path.module}/healcheck.sh"
    ignore_systemd_errors = false
  },
]
}
```
