MY_NAME_IS := Vault Benchmark
THIS_FILE := $(lastword $(MAKEFILE_LIST))
UNAME := $$(uname)
VDL_INIT = ../../.vdl_node_1_init
ROOT_TOKEN=$$(grep 'Initial Root Token' $(VDL_INIT) | awk '{print $$NF}')
VAULT-BENCHMARK_CONTAINER_LOG_FILE = ./vault-benchmark_docker_lab.log

default: all

all: benchmark

benchmark:
	@printf "[+] Vault Benchmark Initializing Terraform workspace ..."
	@terraform init > $(VAULT-BENCHMARK_CONTAINER_LOG_FILE)
	@echo 'Done.'
	@printf "[+] Vault Benchmark Applying Terraform configuration ..."
	@terraform apply -auto-approve >> $(VAULT-BENCHMARK_CONTAINER_LOG_FILE)
	@echo 'done.'

clean:
	@printf "[-] Vault Benchmark Destroying Terraform configuration ..."
	@terraform destroy -auto-approve >> $(VAULT-BENCHMARK_CONTAINER_LOG_FILE)
	@echo 'Done.'

cleanest: clean
	@printf "[-] Vault Benchmark Removing all Terraform runtime configuration and state ..."
	@rm -f terraform.tfstate
	@rm -f terraform.tfstate.backup
	@rm -rf .terraform
	@rm -f .terraform.lock.hcl
	@echo 'done.'

.PHONY: all
