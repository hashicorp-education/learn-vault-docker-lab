vault_addr = ""
vault_token = ""
vault_namespace=""
duration = "1m"
cleanup = true

test "approle_auth" "approle_logins" {
weight = 20
config {
   role {
      role_name = "benchmark-role"
      token_ttl="2m"
   }
}
}

test "userpass_auth" "userpass_test1" {
    weight = 20
    config {
        username = "test-user"
        password = "password"
    }
}

test "kvv2_read" "kvv2_read_test" {
    weight = 30
    config {
        numkvs = 1000
    }
}

test "kvv2_write" "kvv2_write_test" {
    weight = 30
    config {
        numkvs = 1000
        kvsize = 100
    }
}
