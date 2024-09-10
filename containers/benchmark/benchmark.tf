# Vault Docker Lab is a minimal Vault cluster Terraformed on Docker
# It is useful for development and testing, but not for production.

# EXTRA: Benchmark Docker container

# -----------------------------------------------------------------------
# Provider configuration
# -----------------------------------------------------------------------

provider "docker" {
  host = var.docker_host
}

# -----------------------------------------------------------------------
# vault-benchmark image
# -----------------------------------------------------------------------

resource "docker_image" "vault-benchmark" {
  name         = "hashicorp/vault-benchmark:latest"
  keep_locally = true
}

# -----------------------------------------------------------------------
# vault-benchmark container resources
# -----------------------------------------------------------------------

resource "docker_container" "vault-docker-lab-benchmark" {
  name     = "vault-benchmark"
  hostname = "vault-benchmark"
  image    = docker_image.vault-benchmark.repo_digest
  env      = [ "VAULT_TOKEN=${templatefile("${path.module}/benchmark-token",{})}",
               "VAULT_ADDR=https://10.1.42.101:8200",
               "VAULT_SKIP_VERIFY=true"
             ]
  command = ["vault-benchmark"]
  entrypoint = ["vault-benchmark",
             "run",
             "-config=",
            "/opt/config/vault-benchmark-config.hcl"
            ]
  must_run = true
  rm       = true

  networks_advanced {
    name         = "vault_docker_lab_network"
    ipv4_address = "10.1.42.203"
  }

  volumes {
    host_path      = "${path.cwd}/config"
    container_path = "/opt/config"
  }

}
