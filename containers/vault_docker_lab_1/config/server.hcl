disable_mlock = true
ui            = true
api_addr      = "https://10.1.42.101:8200"
cluster_addr  = "https://10.1.42.101:8201"

listener "tcp" {
  address            = "0.0.0.0:8200"
  tls_cert_file      = "/vault/certs/server-cert.pem"
  tls_key_file       = "/vault/certs/server-key.pem"
  tls_client_ca_file = "/vault/certs/vault-docker-lab-ca.pem"
  tls_disable        = "false"
}

storage "raft" {
  path    = "/vault"
  node_id = "vault-1"
}
