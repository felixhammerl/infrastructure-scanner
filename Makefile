.DEFAULT_GOAL := all
.PHONY: all

all: clean python terraform-apply docker

clean:
	rm -rf build

format:
	find . -name "*.tf" -not -path "*.terraform*" | xargs terraform fmt
	cd steps/list && pipenv install --dev && pipenv run format

test-format:
	find . -name "*.sh" -not -path "*.terraform*" | xargs shellcheck
	find . -name "*.tf" -not -path "*.terraform*" | xargs terraform fmt -check
	cd steps/list && pipenv install --dev && pipenv run test-format

test-unit:
	cd steps/list && pipenv install --dev && pipenv run test-unit

docker:
	cd infra && terraform init -input=false
	/bin/bash scripts/build-docker.sh scan

python:
	cd infra && terraform init -input=false
	/bin/bash scripts/build-python.sh list

terraform-plan:
	cd infra && terraform init -input=false
	cd infra && terraform plan

terraform-apply:
	cd infra && terraform init -input=false
	cd infra && terraform apply -auto-approve

backend: backend-plan backend-apply

backend-plan:
	cd infra/.tf-backend && terraform init -input=false
	cd infra/.tf-backend && terraform plan -state=backend.tfstate -out=backend.tfplan

backend-apply:
	cd infra/.tf-backend && terraform init -input=false
	cd infra/.tf-backend && terraform apply -state=backend.tfstate backend.tfplan
