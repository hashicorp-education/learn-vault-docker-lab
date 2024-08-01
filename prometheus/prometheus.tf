# Vault Docker Lab is a minimal Vault cluster Terraformed on Docker
# It is useful for development and testing, but not for production.

# EXTRA: Prometheus Docker container

# -----------------------------------------------------------------------
# Provider configuration
# -----------------------------------------------------------------------

provider "docker" {
  host = var.docker_host
}

# -----------------------------------------------------------------------
# Prometheus image
# -----------------------------------------------------------------------

resource "docker_image" "prometheus" {
  name         = "prom/prometheus:latest"
  keep_locally = true
}

# -----------------------------------------------------------------------
# Prometheus container resources
# -----------------------------------------------------------------------

resource "docker_container" "vault-docker-lab-prometheus" {
  name     = "prometheus"
  hostname = "prometheus"
  image    = docker_image.prometheus.repo_digest
  must_run = true
  rm       = false

  networks_advanced {
    name         = "vault_docker_lab_network"
    ipv4_address = "10.1.42.201"
  }

  ports {
    internal = 9090
    external = 9090
    protocol = "tcp"
  }

  volumes {
    host_path      = "${path.cwd}/prometheus.yml"
    container_path = "/etc/prometheus/prometheus.yml"
  }

  volumes {
    host_path      = "${path.cwd}/prometheus-token"
    container_path = "/etc/prometheus/prometheus-token"
  }

}
