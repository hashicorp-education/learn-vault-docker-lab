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
  env      = ["GF_SECURITY_ADMIN_USER=admin", "GF_SECURITY_ADMIN_PASSWORD=2LearnVault", "GF_DASHBOARDS_DEFAULT_HOME_DASHBOARD_PATH=/var/lib/grafana/dashboards/vault.json"]
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

# -----------------------------------------------------------------------
# Main configuration
# -----------------------------------------------------------------------

  volumes {
    host_path      = "${path.cwd}/datasource.yaml"
    container_path = "/etc/grafana/provisioning/datasources/prometheus_datasource.yml"
  }

# -----------------------------------------------------------------------
# Dashboards configuration
# -----------------------------------------------------------------------

  volumes {
    host_path      = "${path.cwd}/dashboards"
    container_path = "/var/lib/grafana/dashboards"
  }

  volumes {
    host_path      = "${path.cwd}/dashboards.yaml"
    container_path = "/etc/grafana/provisioning/dashboards/main.yaml"
  }

# -----------------------------------------------------------------------
# TLS configuration
# -----------------------------------------------------------------------

  volumes {
    host_path      = "${path.cwd}/certs/vault-docker-lab-ca.pem"
    container_path = "/etc/grafana/vault-docker-lab-ca.crt"
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
