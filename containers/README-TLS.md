# Self-Signed TLS Details

The TLS certificates and keys used by vault-docker-lab are self-signed and were generated with the Vault PKI secrets engine based on the guidance in the [Build Your Own Certificate Authority (CA)](https://developer.hashicorp.com/vault/tutorials/secrets-management/pki-engine) tutorial.

You can use the script `containers/bin/generate-tls` to regenerate new TLS material for the project. This script requires a running Vault dev mode server with VAULT_ADDR=http://localhost:8200 and VAULT_TOKEN=root. It does the following:

- Creates a root certificate authority (CA)
- Creates an intermediate CA signed by the root CA
- Creates certificates and keys for Vault nodes and extras
- Installs the certificates and keys into each container filesystem

Here are the exact commands used to generate the current set.

## Root CA

```shell
vault secrets enable pki
```

```shell
vault secrets tune -max-lease-ttl=87600h pki
```

```shell
vault write -field=certificate pki/root/generate/internal \
     common_name="vault-docker-lab.lan" \
     issuer_name="root-2025" \
     ttl=87600h > root_2025_ca.crt
```

```shell
vault write pki/roles/2025-servers \
    allow_any_name=true \
     allow_subdomains=true \
    allow_localhost=true
```

```shell
vault write pki/config/urls \
     issuing_certificates="$VAULT_ADDR/v1/pki/ca" \
     crl_distribution_points="$VAULT_ADDR/v1/pki/crl"
```

## Intermediate CA

```shell
vault secrets enable -path=pki_int pki
```

```shell
vault secrets tune -max-lease-ttl=43800h pki_int
```

```shell
vault write -format=json pki_int/intermediate/generate/internal \
     common_name="vault-docker-lab.lan Intermediate Authority" \
     issuer_name="vault-docker-lab-dot-lan-intermediate" \
     | jq -r '.data.csr' > pki_intermediate.csr
```

```shell
vault write -format=json pki/root/sign-intermediate \
     issuer_ref="root-2025" \
     csr=@pki_intermediate.csr \
     format=pem_bundle ttl="43800h" \
     | jq -r '.data.certificate' > intermediate.cert.pem
```

```shell
vault write pki_int/intermediate/set-signed certificate=@intermediate.cert.pem
```

```shell
vault write pki_int/roles/vault-docker-lab-dot-lan \
     issuer_ref="$(vault read -field=default pki_int/config/issuers)" \
     allowed_domains="vault-docker-lab.lan" \
     allow_subdomains=true \
     allow_localhost=true \
     allow_any_name=true \
     max_ttl="8760h"
```

## Certificates and Keys

```shell
vault write pki_int/issue/vault-docker-lab-dot-lan \
    alt_names="localhost" \
    common_name="vault-docker-lab1.vault-docker-lab.lan" \
    ip_sans="127.0.0.1,10.1.42.101" \
    ttl="8760h"
```

```shell
vault write pki_int/issue/vault-docker-lab-dot-lan \
    alt_names="localhost" \
    common_name="vault-docker-lab2.vault-docker-lab.lan" \
    ip_sans="127.0.0.1,10.1.42.102" \
    ttl="8760h"
```

```shell
vault write pki_int/issue/vault-docker-lab-dot-lan \
    alt_names="localhost" \
    common_name="vault-docker-lab3.vault-docker-lab.lan" \
    ip_sans="127.0.0.1,10.1.42.103" \
    ttl="8760h"
```

```shell
vault write pki_int/issue/vault-docker-lab-dot-lan \
    alt_names="localhost" \
    common_name="vault-docker-lab4.vault-docker-lab.lan" \
    ip_sans="127.0.0.1,10.1.42.104" \
    ttl="8760h"
```

```shell
vault write pki_int/issue/vault-docker-lab-dot-lan \
    alt_names="localhost" \
    common_name="vault-docker-lab5.vault-docker-lab.lan" \
    ip_sans="127.0.0.1,10.1.42.105" \
    ttl="8760h"
```

```shell
vault write pki_int/issue/vault-docker-lab-dot-lan \
    alt_names="localhost" \
    common_name="loadbalancer.vault-docker-lab.lan" \
    ip_sans="127.0.0.1,10.1.42.10" \
    ttl="8760h"
```

```shell
vault write pki_int/issue/vault-docker-lab-dot-lan \
    alt_names="localhost" \
    common_name="prometheus.vault-docker-lab.lan" \
    ip_sans="127.0.0.1,10.1.42.211" \
    ttl="8760h"
```

```shell
vault write pki_int/issue/vault-docker-lab-dot-lan \
    alt_names="localhost" \
    common_name="grafana.vault-docker-lab.lan" \
    ip_sans="127.0.0.1,10.1.42.212" \
    ttl="8760h"
```
