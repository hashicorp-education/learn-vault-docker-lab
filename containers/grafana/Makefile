MY_NAME_IS := Grafana
THIS_FILE := $(lastword $(MAKEFILE_LIST))
UNAME := $$(uname)
VDL_INIT = ../../.vdl_node_1_init
ROOT_TOKEN=$$(grep 'Initial Root Token' $(VDL_INIT) | awk '{print $$NF}')
GRAFANA_CONTAINER_LOG_FILE = ./grafana_docker_lab.log

default: all

all: provision

provision:
	@printf "$(MY_NAME_IS) Initializing Terraform workspace ..."
	@terraform init > $(GRAFANA_CONTAINER_LOG_FILE)
	@echo 'Done.'
	@printf "$(MY_NAME_IS) Applying Terraform configuration ..."
	@terraform apply -auto-approve >> $(GRAFANA_CONTAINER_LOG_FILE)
	@echo 'Done.'

clean:
	@printf "$(MY_NAME_IS) Destroying Terraform configuration ..."
	@terraform destroy -auto-approve >> $(GRAFANA_CONTAINER_LOG_FILE)
	@echo 'Done.'
	@printf "$(MY_NAME_IS) Removing artifacts created by $(MY_NAME_IS) ..."
	@rm -rf $(PROMETHEUS_DOCKER_LAB_DATA)
	@rm -f $(PROMETHEUS_DOCKER_LAB_INIT)
	@rm -rf $(PROMETHEUS_DOCKER_LAB_AUDIT_LOGS)
	@rm -f $(GRAFANA_CONTAINER_LOG_FILE)
	@echo 'Done.'

cleanest: clean
	@printf "$(MY_NAME_IS) Removing all Terraform runtime configuration and state ..."
	@rm -f terraform.tfstate
	@rm -f terraform.tfstate.backup
	@rm -rf .terraform
	@rm -f .terraform.lock.hcl
	@echo 'Done.'

.PHONY: all
