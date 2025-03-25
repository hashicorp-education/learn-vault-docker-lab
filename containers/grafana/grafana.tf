# Vault Docker Lab is a minimal Vault cluster Terraformed on Docker
# It is useful for development and testing, but not for production.

# EXTRA: Grafana Docker container

# -----------------------------------------------------------------------
# Provider configuration
# -----------------------------------------------------------------------

provider "docker" {
  host = var.docker_host
}

# -----------------------------------------------------------------------
# grafana image
# -----------------------------------------------------------------------

resource "docker_image" "grafana" {
  name         = "grafana/grafana-enterprise:latest"
  keep_locally = true
}

# -----------------------------------------------------------------------
# grafana container resources
# -----------------------------------------------------------------------

resource "docker_container" "vault-docker-lab-grafana" {
  name     = "grafana"
  hostname = "grafana"
  image    = docker_image.grafana.repo_digest
  must_run = true
  rm       = false

  networks_advanced {
    name         = "vault_docker_lab_network"
    ipv4_address = "10.1.42.202"
  }

  ports {
    internal = 3000
    external = 3001
    protocol = "tcp"
  }

  volumes {
    host_path      = "${path.cwd}/datasource.yml"
    container_path = "/etc/grafana/provisioning/datasources/prometheus_datasource.yml"
  }

  volumes {
    host_path      = "${path.cwd}/certs/server-cert.pem"
    container_path = "/etc/grafana/grafana.crt"
  }

  volumes {
    host_path      = "${path.cwd}/certs/server-key.pem"
    container_path = "/etc/grafana/grafana.key"
  }

}
