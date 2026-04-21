#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEV_CONTAINER_NAME="vault-tls-dev"
DEV_IMAGE="${VAULT_DEV_IMAGE:-hashicorp/vault:latest}"
ROOT_TTL="${VAULT_DOCKER_LAB_ROOT_TTL:-87600h}"
INTERMEDIATE_TTL="${VAULT_DOCKER_LAB_INTERMEDIATE_TTL:-43800h}"
SERVER_TTL="${VAULT_DOCKER_LAB_SERVER_TTL:-8760h}"
TMP_DIR="$(mktemp -d)"

cleanup() {
  docker rm -f "$DEV_CONTAINER_NAME" >/dev/null 2>&1 || true
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

require() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

require docker
require python3

run_vault() {
  docker exec -i "$DEV_CONTAINER_NAME" sh -lc "export VAULT_ADDR=http://127.0.0.1:8200 VAULT_TOKEN=root; $*"
}

json_field() {
  local file="$1"
  local expression="$2"
  python3 - "$file" "$expression" <<'PY'
import json
import sys

path = sys.argv[2].split('.')
value = json.load(open(sys.argv[1]))
for part in path:
    if part.isdigit():
        value = value[int(part)]
    else:
        value = value[part]
if isinstance(value, list):
    print("\n".join(value))
else:
    print(value)
PY
}

write_issue_files() {
  local node_dir="$1"
  local json_file="$2"
  local leaf_cert chain_cert
  mkdir -p "$node_dir"
  leaf_cert="$(json_field "$json_file" data.certificate)"
  chain_cert="$(json_field "$json_file" data.ca_chain)"
  printf '%s\n%s\n' "$leaf_cert" "$chain_cert" > "$node_dir/server_cert.pem"
  json_field "$json_file" data.private_key > "$node_dir/server_key.pem"
  chmod 600 "$node_dir/server_key.pem"
}

echo "[refresh-tls] Starting Vault dev server in Docker..."
docker rm -f "$DEV_CONTAINER_NAME" >/dev/null 2>&1 || true
docker run -d \
  --name "$DEV_CONTAINER_NAME" \
  -e VAULT_DEV_ROOT_TOKEN_ID=root \
  "$DEV_IMAGE" >/dev/null

for _ in $(seq 1 30); do
  if docker exec "$DEV_CONTAINER_NAME" sh -lc 'export VAULT_ADDR=http://127.0.0.1:8200 VAULT_TOKEN=root; vault status >/dev/null 2>&1'; then
    break
  fi
  sleep 1
done

echo "[refresh-tls] Configuring root PKI mount..."
run_vault "vault secrets enable pki >/dev/null"
run_vault "vault secrets tune -max-lease-ttl=${ROOT_TTL} pki >/dev/null"
run_vault "vault write -field=certificate pki/root/generate/internal common_name='vault-docker-lab.lan' issuer_name='root-2026' ttl='${ROOT_TTL}'" > "$TMP_DIR/root_ca.pem"
run_vault "vault write pki/roles/2026-servers allow_any_name=true >/dev/null"
run_vault "vault write pki/config/urls issuing_certificates='http://127.0.0.1:8200/v1/pki/ca' crl_distribution_points='http://127.0.0.1:8200/v1/pki/crl' >/dev/null"

echo "[refresh-tls] Configuring intermediate PKI mount..."
run_vault "vault secrets enable -path=pki_int pki >/dev/null"
run_vault "vault secrets tune -max-lease-ttl=${INTERMEDIATE_TTL} pki_int >/dev/null"
run_vault "vault write -format=json pki_int/intermediate/generate/internal common_name='vault-docker-lab.lan Intermediate Authority' issuer_name='vault-docker-lab-intermediate' key_type='rsa' key_bits='4096'" > "$TMP_DIR/intermediate_csr.json"
json_field "$TMP_DIR/intermediate_csr.json" data.csr > "$TMP_DIR/intermediate.csr"
run_vault "vault write -format=json pki/root/sign-intermediate csr=@/dev/stdin format=pem_bundle ttl='${INTERMEDIATE_TTL}' use_csr_values=true" < "$TMP_DIR/intermediate.csr" > "$TMP_DIR/intermediate_cert.json"
json_field "$TMP_DIR/intermediate_cert.json" data.certificate > "$TMP_DIR/intermediate_bundle.pem"
run_vault "vault write pki_int/intermediate/set-signed certificate=@/dev/stdin >/dev/null" < "$TMP_DIR/intermediate_bundle.pem"
run_vault "vault write pki_int/roles/vault-docker-lab-dot-lan issuer_ref='default' allowed_domains='localhost,vault-docker-lab.lan' allow_subdomains=true max_ttl='${INTERMEDIATE_TTL}' ttl='17520h' >/dev/null"

python3 - "$TMP_DIR/intermediate_bundle.pem" "$TMP_DIR/intermediate_ca.pem" <<'PY'
import sys
src, dst = sys.argv[1], sys.argv[2]
blocks = []
current = []
inside = False
for line in open(src):
    if 'BEGIN CERTIFICATE' in line:
        current = [line]
        inside = True
    elif inside:
        current.append(line)
        if 'END CERTIFICATE' in line:
            blocks.append(''.join(current))
            inside = False
open(dst, 'w').write(blocks[0])
PY
cat "$TMP_DIR/intermediate_ca.pem" "$TMP_DIR/root_ca.pem" > "$TMP_DIR/ca_chain.pem"

echo "[refresh-tls] Issuing node certificates..."
for node in 1 2 3 4 5; do
  ip="10.1.42.10${node}"
  fqdn="vault-docker-lab${node}.vault-docker-lab.lan"
  issue_json="$TMP_DIR/node_${node}.json"
  run_vault "vault write -format=json pki_int/issue/vault-docker-lab-dot-lan alt_names='localhost' common_name='${fqdn}' ip_sans='127.0.0.1,${ip}' ttl='${SERVER_TTL}'" > "$issue_json"
  cert_dir="$ROOT_DIR/containers/vault_docker_lab_${node}/certs"
  write_issue_files "$cert_dir" "$issue_json"
  cp "$TMP_DIR/ca_chain.pem" "$cert_dir/vault_docker_lab_ca.pem"
  cp "$TMP_DIR/ca_chain.pem" "$cert_dir/vault_docker_lab_ca_chain.pem"
  echo "[refresh-tls] Updated $cert_dir"
done

echo "[refresh-tls] TLS assets refreshed successfully."
echo "[refresh-tls] Manual reference: $ROOT_DIR/containers/README-TLS.md"
