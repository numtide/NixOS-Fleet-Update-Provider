variable "hosts" {
  type = list(object({
    nixos_system = string
    target_host = string
    target_user = string
    target_port = number
    ssh_private_key = string
    ignore_systemd_errors = bool
    healthcheck_script = string

  }))
  description = "List of the target hosts, NixOS configurations and healthcheck scripts."
}
