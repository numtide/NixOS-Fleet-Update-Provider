resource "null_resource" "nixos-fleet-update" {
  triggers = {
    store_path = jsonencode(var.hosts)
  }
  provisioner "local-exec" {
    environment = {
      HOSTS = jsonencode(var.hosts)
      MODULEPATH = path.module
    }
    command = "${path.module}/deploy-fleet.sh"
  }
}
