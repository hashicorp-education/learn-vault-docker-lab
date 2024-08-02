MY_NAME_IS := [Prometheus container]
THIS_FILE := $(lastword $(MAKEFILE_LIST))
UNAME := $$(uname)
PROMETHEUS_ACL = ./prometheus_acl.hcl
PROMETHEUS_CONFIG = ./prometheus.yml
PROMETHEUS_CONTAINER_LOG_FILE = ./prometheus_container.log
ROOT_TOKEN=$$(grep 'Initial Root Token' ../.vault_docker_lab_1_init | awk '{print $$NF}')

default: all

all: provision

stage: provision

provision:
	@printf $(ROOT_TOKEN) > ./prometheus-token
	@printf "$(MY_NAME_IS) Initializing Terraform workspace ..."
	@terraform init > $(PROMETHEUS_CONTAINER_LOG_FILE)
	@echo 'Done.'
	@printf "$(MY_NAME_IS) Applying Terraform configuration ..."
	@terraform apply -auto-approve >> $(PROMETHEUS_CONTAINER_LOG_FILE)
	@echo 'Done.'

clean:
	@printf "$(MY_NAME_IS) Destroying Terraform configuration ..."
	@terraform destroy -auto-approve >> $(PROMETHEUS_CONTAINER_LOG_FILE)
	@echo 'Done.'
	@printf "$(MY_NAME_IS) Removing artifacts created by $(MY_NAME_IS) ..."
	@rm -f ./prometheus-token
	@echo 'Done.'

cleanest: clean
	@printf "$(MY_NAME_IS) Removing all Terraform runtime configuration and state ..."
	@rm -f terraform.tfstate
	@rm -f terraform.tfstate.backup
	@rm -rf .terraform
	@rm -f .terraform.lock.hcl
	@echo 'Done.'

.PHONY: all
