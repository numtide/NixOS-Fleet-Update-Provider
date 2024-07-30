terraform {
  backend "local" {
    path = "state.tfstate"
  }
}

module "fleet-provider-test" {
  source = "../"
  hosts = [ {
    nixos_system = "nixos_system1"
    target_host = "target_host1"
    target_user = "target_user1"
    target_port = 22
    ssh_private_key = "ssh_private_key1"
    healthcheck_script = "healthcheck_script1"
    ignore_systemd_errors = false
  },
  {
    nixos_system = "nixos_system2"
    target_host = "target_host2"
    target_user = "target_user2"
    target_port = 22
    ssh_private_key = "ssh_private_key2"
    healthcheck_script = "healthcheck_script2"
    ignore_systemd_errors = true
  }
]
}
