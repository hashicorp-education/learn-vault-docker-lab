MY_NAME_IS := Vault Docker Lab
HERE := $$(pwd)
THIS_FILE := $(lastword $(MAKEFILE_LIST))
UNAME := $$(uname)
GRAFANA_CONTAINER_LOG_FILE = $(HERE)/grafana_docker_lab.log
PROMETHEUS_CONTAINER_LOG_FILE = $(HERE)/prometheus_container.log
VDL_AUDIT_LOG = /vault/logs/vault_audit.log
VDL_DATA = $(HERE)/containers/vdl_node_?/data/*
VDL_INIT = $(HERE)/.vdl_node_1_init
VDL_LOG_FILE = $(HERE)/vaut_docker_lab.log
VDL_VAULT_LOGS = $(HERE)/containers/vdl_node_?/logs/*

default: all done-vault

all: prerequisites \
	provision \
	vault_status \
	unseal_nodes \
	audit_device \
	prometheus_token \
	benchmark_token

stage: prerequisites provision done-stage

greetings:
	@echo "👋 Hello from $(MY_NAME_IS)"

telemetry: greetings telemetry-prometheus telemetry-grafana

telemetry-prometheus:
	@cd $(HERE)/containers/prometheus && printf "[+] [Prometheus] initializing Terraform workspace ..." && terraform init > $(PROMETHEUS_CONTAINER_LOG_FILE) && echo 'done.' && printf "[+] [Prometheus] Applying Terraform configuration ..." && terraform apply -auto-approve >> $(PROMETHEUS_CONTAINER_LOG_FILE) && echo 'done.' && cd $(HERE)
	@echo "[i] [Prometheus] web interface available at http://127.0.0.1:9090"

telemetry-grafana:
	@cd $(HERE)/containers/grafana && printf "[+] [Grafana] initializing Terraform workspace ..." && terraform init > $(GRAFANA_CONTAINER_LOG_FILE) && echo 'done.' && printf "[+] [Grafana] Applying Terraform configuration ..." && terraform apply -auto-approve >> $(GRAFANA_CONTAINER_LOG_FILE) && echo 'done.' && cd $(HERE)
	@echo "[i] [Grafana] web interface available at http://127.0.0.1:3001"

load-test:
	@echo "[+] Vault Benchmark load test"

done-vault:
	@echo "\n[i] Export VAULT_ADDR for the active node: export VAULT_ADDR=https://127.0.0.1:8200"
	@echo "[i] Login to Vault with initial root token: vault login $(ROOT_TOKEN)"

done-stage:
	@echo "\n[i] Export VAULT_ADDR for the active node: export VAULT_ADDR=https://127.0.0.1:8200"
	@echo "[i] Vault is not initialized or unsealed. You must initialize and unseal Vault before use."

DOCKER_OK=$$(docker info > /dev/null 2>&1; printf $$?)
TERRAFORM_BINARY_OK=$$(which terraform > /dev/null 2>&1 ; printf $$?)
VAULT_BINARY_OK=$$(which vault > /dev/null 2>&1 ; printf $$?)
prerequisites: greetings
	@if [ $(VAULT_BINARY_OK) -ne 0 ] ; then echo "[e] Vault binary not found in path!"; echo "install Vault and try again: https://developer.hashicorp.com/vault/downloads." ; exit 1 ; fi
	@if [ $(TERRAFORM_BINARY_OK) -ne 0 ] ; then echo "[e] Terraform CLI binary not found in path!" ; echo "install Terraform CLI and try again: https://developer.hashicorp.com/terraform/downloads" ; exit 1 ; fi
	@if [ $(DOCKER_OK) -ne 0 ] ; then echo "[e] can't get Docker info; ensure that Docker is running, and try again." ; exit 1 ; fi

provision:
	@if [ "$(UNAME)" = "Linux" ]; then echo "[i] [Linux] Setting ownership on container volume directories ..."; echo "[i] [Linux] You could be prompted for your user password by sudo."; sudo chown -R $$USER:$$USER containers; sudo chmod -R 0777 containers; fi
	@printf "[+] Initializing Terraform workspace ..."
	@terraform init > $(VDL_LOG_FILE)
	@echo 'done.'
	@printf "[+] Applying Terraform configuration ..."
	@terraform apply -auto-approve >> $(VDL_LOG_FILE)
	@echo 'done.'

UNSEAL_KEY=$$(grep 'Unseal Key 1' $(VDL_INIT) | awk '{print $$NF}')
unseal_nodes:
	@printf "[+] Unsealing cluster nodes ..."
	@until [ $$(VAULT_ADDR=https://127.0.0.1:8220 vault status | grep "Initialized" | awk '{print $$2}') = "true" ] ; do sleep 1 ; printf . ; done
	@VAULT_ADDR=https://127.0.0.1:8220 vault operator unseal $(UNSEAL_KEY) >> $(VDL_LOG_FILE)
	@printf 'node 2. '
	@until [ $$(VAULT_ADDR=https://127.0.0.1:8230 vault status | grep "Initialized" | awk '{print $$2}') = "true" ] ; do sleep 1 ; printf . ; done
	@VAULT_ADDR=https://127.0.0.1:8230 vault operator unseal $(UNSEAL_KEY) >> $(VDL_LOG_FILE)
	@printf 'node 3. '
	@until [ $$(VAULT_ADDR=https://127.0.0.1:8240 vault status | grep "Initialized" | awk '{print $$2}') = "true" ] ; do sleep 1 ; printf . ; done
	@VAULT_ADDR=https://127.0.0.1:8240 vault operator unseal $(UNSEAL_KEY) >> $(VDL_LOG_FILE)
	@printf 'node 4. '
	@until [ $$(VAULT_ADDR=https://127.0.0.1:8250 vault status | grep "Initialized" | awk '{print $$2}') = "true" ] ; do sleep 1 ; printf . ; done
	@VAULT_ADDR=https://127.0.0.1:8250 vault operator unseal $(UNSEAL_KEY) >> $(VDL_LOG_FILE)
	@printf 'node 5. '
	@echo 'done.'

ROOT_TOKEN=$$(grep 'Initial Root Token' $(VDL_INIT) | awk '{print $$NF}')
audit_device:
	@printf "[+] Enable audit device on vdl_node_1 in $(VDL_AUDIT_LOG) "
	@VAULT_ADDR=https://127.0.0.1:8200 VAULT_TOKEN=$(ROOT_TOKEN) vault audit enable file file_path=$(VDL_AUDIT_LOG) > /dev/null 2>&1
	@echo 'done.'

prometheus_token:
	@printf $(ROOT_TOKEN) > $(HERE)/containers/prometheus/prometheus-token

benchmark_token:
	@printf $(ROOT_TOKEN) > $(HERE)/containers/benchmark/benchmark-token

vault_status:
	@printf "[+] Check Vault active node status ..."
	@until [ $$(VAULT_ADDR=https://127.0.0.1:8200 vault status > /dev/null 2>&1 ; printf $$?) -eq 0 ] ; do sleep 1 && printf . ; done
	@echo 'ok.'
	@printf "[+] Check Vault initialization status ..."
	@until [ $$(VAULT_ADDR=https://127.0.0.1:8200 vault status | grep "Initialized" | awk '{print $$2}') = "true" ] ; do sleep 1 ; printf . ; done
	@echo 'ok.'

clean: greetings clean-base

clean-base:
	@if [ "$(UNAME)" = "Linux" ]; then echo "[i] [Linux] setting ownership on container volume directories ..."; echo "[i] [Linux] You could be prompted for your user password by sudo."; sudo chown -R $$USER:$$USER containers; fi
	@printf "[-] Destroying Terraform configuration ..."
	@terraform destroy -auto-approve >> $(VDL_LOG_FILE)
	@echo 'done.'
	@printf "[-] Removing created artifacts ..."
	@rm -rf $(VDL_DATA)
	@rm -f $(VAULT_DOCKER_LAB_INIT)
	@rm -rf $(VDL_VAULT_LOGS)
	@rm -f $(VDL_LOG_FILE)
	@rm -f $(GRAFANA_CONTAINER_LOG_FILE)
	@rm -f $(PROMETHEUS_CONTAINER_LOG_FILE)
	@rm -f $(HERE)/containers/prometheus/prometheus-token
	@rm -f $(HERE)/containers/benchmark/benchmark-token
	@echo 'done.'

clean-grafana:
	@cd $(HERE)/containers/grafana && printf "[-] [Grafana] Destroying Terraform configuration ..." && terraform destroy -auto-approve >> $(PROMETHEUS_CONTAINER_LOG_FILE) && echo 'done.' && printf "[-] [Grafana] Removing artifacts created by $(MY_NAME_IS) ..." && echo 'done.' && cd $(HERE)

clean-prometheus:
	@cd $(HERE)/containers/prometheus && printf "[-] [Prometheus] Destroying Terraform configuration ..." && terraform destroy -auto-approve >> $(PROMETHEUS_CONTAINER_LOG_FILE) && echo 'done.' && printf "[-] [Prometheus] Removing artifacts created by $(MY_NAME_IS) ..." && echo 'done.' && cd $(HERE)

clean-telemetry: greetings clean-grafana clean-prometheus

cleanest: greetings clean-base
	@printf "[-] Removing all Terraform runtime configuration and state ..."
	@rm -f terraform.tfstate
	@rm -f terraform.tfstate.backup
	@rm -rf .terraform
	@rm -f .terraform.lock.hcl
	@echo 'done.'

.PHONY: all
