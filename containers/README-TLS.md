# Self-Signed TLS Details

TLS certificates and keys used by Vault Docker Lab are self-signed and generated with the Vault PKI secrets engine based on guidance from [Build Your Own Certificate Authority (CA)](https://developer.hashicorp.com/vault/tutorials/secrets-management/pki-engine).

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
     issuer_name="root-2023" \
     ttl=87600h > root_2023_ca.crt
```

```shell
vault write pki/roles/2023-servers allow_any_name=true
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

List issuers to get root CA issuer ID:

```shell
vault list pki/issuers                  
Keys
----
89f920f3-9139-b45d-1b22-4e51382d600e
```

Use issuer ID in PKI issue command:

```shell
vault pki issue \
    --issuer_name=vault-docker-lab-intermediate \
    /pki/issuer/89f920f3-9139-b45d-1b22-4e51382d600e \
    /pki_int/ \
    common_name="vault-docker-lab.lan Intermediate Authority" \
    o="vault-docker-lab" \
    ou="education" \
    key_type="rsa" \
    key_bits="4096" \
    max_depth_len=1 \
    permitted_dns_domains="localhost,vault-docker-lab.lan" \
    ttl="43800h"
```

Create role for intermediate CA.

```shell
vault write pki_int/roles/vault-docker-lab-dot-lan \
     issuer_ref=vault-docker-lab-intermediate \
     allowed_domains="localhost,vault-docker-lab.lan" \
     allow_subdomains=true \
     max_ttl="43800h" \
     ttl="17520"
```

## Certificates and keys

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
