vault_addr = ""
vault_token = ""
vault_namespace=""
duration = "10s"
cleanup = true

test "approle_auth" "approle_logins" {
weight = 50
config {
   role {
      role_name = "benchmark-role"
      token_ttl="2m"
   }
}
}

test "kvv2_write" "static_secret_writes" {
weight = 50
config {
   numkvs = 100
   kvsize = 100
}
}
