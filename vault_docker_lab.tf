#  _   __          ____    ___           __             __        __ 
# | | / /__ ___ __/ / /_  / _ \___  ____/ /_____ ____  / /  ___ _/ / 
# | |/ / _ `/ // / / __/ / // / _ \/ __/  '_/ -_) __/ / /__/ _ `/ _ \
# |___/\_,_/\_,_/_/\__/ /____/\___/\__/_/\_\\__/_/   /____/\_,_/_.__/
#                                                                    
# Vault Docker Lab is a minimal Vault cluster Terraformed on Docker
# It is useful for development and testing, but not for production.

# -----------------------------------------------------------------------
# Provider configuration
# -----------------------------------------------------------------------

provider "docker" {
  host = var.docker_host
}
# -----------------------------------------------------------------------
# Docker network
# -----------------------------------------------------------------------

resource "docker_network" "vault_docker_lab_network" {
  name            = "vault_docker_lab_network"
  attachable      = true
  check_duplicate = true
  ipam_config {
    subnet = "10.1.42.0/24"
  }
}

# -----------------------------------------------------------------------
# Vault image
# -----------------------------------------------------------------------

resource "docker_image" "vault" {
  name         = "hashicorp/${var.vault_edition}:${var.vault_version}"
  keep_locally = true
}

# -----------------------------------------------------------------------
# Vault container resources
# -----------------------------------------------------------------------

locals {
  vault_containers = {
    "vault_docker_lab_1" = { ipv4_address = "10.1.42.101", env = ["SKIP_CHOWN", "VAULT_LICENSE=${var.vault_license}", "VAULT_CLUSTER_ADDR=https://10.1.42.101:8201", "VAULT_REDIRECT_ADDR=https://10.1.42.101:8200", "VAULT_CACERT=/vault/certs/vault_docker_lab_ca.pem"], internal_port = "8200", external_port = "8200", host_path_certs = "${path.cwd}/containers/vault_docker_lab_1/certs", host_path_config = "${path.cwd}/containers/vault_docker_lab_1/config", host_path_data = "${path.cwd}/containers/vault_docker_lab_1/data", host_path_logs = "${path.cwd}/containers/vault_docker_lab_1/logs" },
    "vault_docker_lab_2" = { ipv4_address = "10.1.42.102", env = ["SKIP_CHOWN", "VAULT_LICENSE=${var.vault_license}", "VAULT_CLUSTER_ADDR=https://10.1.42.102:8201", "VAULT_REDIRECT_ADDR=https://10.1.42.102:8200", "VAULT_CACERT=/vault/certs/vault_docker_lab_ca.pem"], internal_port = "8200", external_port = "8220", host_path_certs = "${path.cwd}/containers/vault_docker_lab_2/certs", host_path_config = "${path.cwd}/containers/vault_docker_lab_2/config", host_path_data = "${path.cwd}/containers/vault_docker_lab_2/data", host_path_logs = "${path.cwd}/containers/vault_docker_lab_2/logs" },
    "vault_docker_lab_3" = { ipv4_address = "10.1.42.103", env = ["SKIP_CHOWN", "VAULT_LICENSE=${var.vault_license}", "VAULT_CLUSTER_ADDR=https://10.1.42.103:8201", "VAULT_REDIRECT_ADDR=https://10.1.42.103:8200", "VAULT_CACERT=/vault/certs/vault_docker_lab_ca.pem"], internal_port = "8200", external_port = "8230", host_path_certs = "${path.cwd}/containers/vault_docker_lab_3/certs", host_path_config = "${path.cwd}/containers/vault_docker_lab_3/config", host_path_data = "${path.cwd}/containers/vault_docker_lab_3/data", host_path_logs = "${path.cwd}/containers/vault_docker_lab_3/logs" },
    "vault_docker_lab_4" = { ipv4_address = "10.1.42.104", env = ["SKIP_CHOWN", "VAULT_LICENSE=${var.vault_license}", "VAULT_CLUSTER_ADDR=https://10.1.42.104:8201", "VAULT_REDIRECT_ADDR=https://10.1.42.104:8200", "VAULT_CACERT=/vault/certs/vault_docker_lab_ca.pem"], internal_port = "8200", external_port = "8240", host_path_certs = "${path.cwd}/containers/vault_docker_lab_4/certs", host_path_config = "${path.cwd}/containers/vault_docker_lab_4/config", host_path_data = "${path.cwd}/containers/vault_docker_lab_4/data", host_path_logs = "${path.cwd}/containers/vault_docker_lab_4/logs" },
    "vault_docker_lab_5" = { ipv4_address = "10.1.42.105", env = ["SKIP_CHOWN", "VAULT_LICENSE=${var.vault_license}", "VAULT_CLUSTER_ADDR=https://10.1.42.105:8201", "VAULT_REDIRECT_ADDR=https://10.1.42.105:8200", "VAULT_CACERT=/vault/certs/vault_docker_lab_ca.pem"], internal_port = "8200", external_port = "8250", host_path_certs = "${path.cwd}/containers/vault_docker_lab_5/certs", host_path_config = "${path.cwd}/containers/vault_docker_lab_5/config", host_path_data = "${path.cwd}/containers/vault_docker_lab_5/data", host_path_logs = "${path.cwd}/containers/vault_docker_lab_5/logs" }
  }
}

resource "docker_container" "vault-docker-lab" {
  for_each = local.vault_containers
  name     = each.key
  hostname = each.key
  env      = each.value.env
  command = ["vault",
    "server",
    "-config",
    "/vault/config/server.hcl",
    "-log-level",
    "${var.vault_log_level}"
  ]
  image    = docker_image.vault.repo_digest
  must_run = true
  rm       = false

  capabilities {
    add = ["IPC_LOCK", "SYSLOG"]
  }

  healthcheck {
    test         = ["CMD", "vault", "status"]
    interval     = "10s"
    timeout      = "2s"
    start_period = "10s"
    retries      = 2
  }

  networks_advanced {
    name         = docker_network.vault_docker_lab_network.name
    ipv4_address = each.value.ipv4_address
  }

  ports {
    internal = each.value.internal_port
    external = each.value.external_port
    protocol = "tcp"
  }

  volumes {
    host_path      = each.value.host_path_certs
    container_path = "/vault/certs"
  }

  volumes {
    host_path      = each.value.host_path_config
    container_path = "/vault/config"
  }

  volumes {
    host_path      = each.value.host_path_data
    container_path = "/vault/data"
  }

  volumes {
    host_path      = each.value.host_path_logs
    container_path = "/vault/logs"
  }

}

resource "null_resource" "active_node_init" {
  provisioner "local-exec" {
    command = "while ! curl --insecure --fail --silent https://127.0.0.1:8200/v1/sys/seal-status --output /dev/null ; do printf '.' ; sleep 4 ; done ; vault operator init -key-shares=1 -key-threshold=1 > ${path.cwd}/.vault_docker_lab_1_init"
    environment = {
      VAULT_ADDR = "https://127.0.0.1:8200"
      VAULT_CACERT = "${path.cwd}/containers/vault_docker_lab_1/certs/vault_docker_lab_ca.pem"
    }
  }

  depends_on = [
    docker_container.vault-docker-lab
  ]

}

resource "null_resource" "active_node_unseal" {
  provisioner "local-exec" {
    command = "while [ ! -f ${path.cwd}/.vault_docker_lab_1_init ] ; do printf '.' ; sleep 1 ; done &&export UNSEAL_KEY=$(grep 'Unseal Key 1' ${path.cwd}/.vault_docker_lab_1_init | awk '{print $NF}') && vault operator unseal $UNSEAL_KEY"
    environment = {
      VAULT_ADDR = "https://127.0.0.1:8200"
      VAULT_CACERT = "${path.cwd}/containers/vault_docker_lab_1/certs/vault_docker_lab_ca.pem"
    }
  }

  depends_on = [
    null_resource.active_node_init
  ]

}
